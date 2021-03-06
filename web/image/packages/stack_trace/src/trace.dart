// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trace;

import 'dart:collection';
import 'dart:math' as math;

import 'frame.dart';
import 'lazy_trace.dart';
import 'utils.dart';
import 'vm_trace.dart';

final _terseRegExp = new RegExp(r"(-patch)?(/.*)?$");

/// A RegExp to match V8's stack traces.
///
/// V8's traces start with a line that's either just "Error" or else is a
/// description of the exception that occurred. That description can be multiple
/// lines, so we just look for any line other than the first that begins with
/// three or four spaces and "at".
final _v8Trace = new RegExp(r"\n    ?at ");

/// A RegExp to match indidual lines of V8's stack traces.
///
/// This is intended to filter out the leading exception details of the trace
/// though it is possible for the message to match this as well.
final _v8TraceLine = new RegExp(r"    ?at ");

/// A RegExp to match Firefox's stack traces.
///
/// Firefox's trace frames start with the name of the function in which the
/// error occurred, possibly including its parameters inside `()`. For example,
/// `.VW.call$0("arg")@http://pub.dartlang.org/stuff.dart.js:560`.
final _firefoxTrace = new RegExp(r"^([.0-9A-Za-z_$/<]|\(.*\))*@");

/// A RegExp to match this package's stack traces.
final _friendlyTrace = new RegExp(r"^[^\s]+( \d+:\d+)?\s+[^\s]+($|\n)");

/// A stack trace, comprised of a list of stack frames.
class Trace implements StackTrace {
  /// The stack frames that comprise this stack trace.
  final List<Frame> frames;

  /// Returns a human-readable representation of [stackTrace]. If [terse] is
  /// set, this folds together multiple stack frames from the Dart core
  /// libraries, so that only the core library method directly called from user
  /// code is visible (see [Trace.terse]).
  static String format(StackTrace stackTrace, {bool terse: true}) {
    var trace = new Trace.from(stackTrace);
    if (terse) trace = trace.terse;
    return trace.toString();
  }

  /// Returns the current stack trace.
  ///
  /// By default, the first frame of this trace will be the line where
  /// [Trace.current] is called. If [level] is passed, the trace will start that
  /// many frames up instead.
  factory Trace.current([int level=0]) {
    if (level < 0) {
      throw new ArgumentError("Argument [level] must be greater than or equal "
          "to 0.");
    }

    try {
      throw '';
    } catch (_, nativeTrace) {
      var trace = new Trace.from(nativeTrace);
      return new LazyTrace(() => new Trace(trace.frames.skip(level + 1)));
    }
  }

  /// Returns a new stack trace containing the same data as [trace].
  ///
  /// If [trace] is a native [StackTrace], its data will be parsed out; if it's
  /// a [Trace], it will be returned as-is.
  factory Trace.from(StackTrace trace) {
    if (trace is Trace) return trace;
    return new LazyTrace(() => new Trace.parse(trace.toString()));
  }

  /// Parses a string representation of a stack trace.
  ///
  /// [trace] should be formatted in the same way as a Dart VM or browser stack
  /// trace.
  factory Trace.parse(String trace) {
    try {
      if (trace.isEmpty) return new Trace(<Frame>[]);
      if (trace.contains(_v8Trace)) return new Trace.parseV8(trace);
      // Valid Safari traces are a superset of valid Firefox traces.
      if (trace.contains(_firefoxTrace)) return new Trace.parseSafari(trace);
      if (trace.contains(_friendlyTrace)) return new Trace.parseFriendly(trace);

      // Default to parsing the stack trace as a VM trace. This is also hit on
      // IE and Safari, where the stack trace is just an empty string (issue
      // 11257).
      return new Trace.parseVM(trace);
    } on FormatException catch (error) {
      throw new FormatException('${error.message}\nStack trace:\n$trace');
    }
  }

  /// Parses a string representation of a Dart VM stack trace.
  Trace.parseVM(String trace)
      : this(trace.trim().split("\n").map((line) => new Frame.parseVM(line)));

  /// Parses a string representation of a Chrome/V8 stack trace.
  Trace.parseV8(String trace)
      : this(trace.split("\n").skip(1)
          // It's possible that an Exception's description contains a line that
          // looks like a V8 trace line, which will screw this up.
          // Unfortunately, that's impossible to detect.
          .skipWhile((line) => !line.startsWith(_v8TraceLine))
          .map((line) => new Frame.parseV8(line)));

  /// Parses a string representation of an Internet Explorer stack trace.
  ///
  /// IE10+ traces look just like V8 traces. Prior to IE10, stack traces can't
  /// be retrieved.
  Trace.parseIE(String trace)
      : this.parseV8(trace);

  /// Parses a string representation of a Firefox stack trace.
  Trace.parseFirefox(String trace)
      : this(trace.trim().split("\n")
          .map((line) => new Frame.parseFirefox(line)));

  /// Parses a string representation of a Safari stack trace.
  ///
  /// Safari 6+ stack traces look just like Firefox traces, except that they
  /// sometimes (e.g. in isolates) have a "[native code]" frame. We just ignore
  /// this frame to make the stack format more consistent between browsers.
  /// Prior to Safari 6, stack traces can't be retrieved.
  Trace.parseSafari(String trace)
      : this(trace.trim().split("\n")
          .where((line) => line != '[native code]')
          .map((line) => new Frame.parseFirefox(line)));

  /// Parses this package's a string representation of a stack trace.
  Trace.parseFriendly(String trace)
      : this(trace.trim().split("\n")
          .map((line) => new Frame.parseFriendly(line)));

  /// Returns a new [Trace] comprised of [frames].
  Trace(Iterable<Frame> frames)
      : frames = new UnmodifiableListView<Frame>(frames.toList());

  /// Returns a VM-style [StackTrace] object.
  ///
  /// The return value's [toString] method will always return a string
  /// representation in the Dart VM's stack trace format, regardless of what
  /// platform is being used.
  StackTrace get vmTrace => new VMTrace(frames);

  /// Returns a terser version of [this].
  ///
  /// This is accomplished by folding together multiple stack frames from the
  /// core library, as in [foldFrames]. Remaining core library frames have their
  /// libraries, "-patch" suffixes, and line numbers removed.
  Trace get terse {
    return new Trace(foldFrames((frame) => frame.isCore).frames.map((frame) {
      if (!frame.isCore) return frame;
      var library = frame.library.replaceAll(_terseRegExp, '');
      return new Frame(Uri.parse(library), null, null, frame.member);
    }));
  }

  /// Returns a new [Trace] based on [this] where multiple stack frames matching
  /// [predicate] are folded together. This means that whenever there are
  /// multiple frames in a row that match [predicate], only the last one is
  /// kept.
  ///
  /// This is useful for limiting the amount of library code that appears in a
  /// stack trace by only showing user code and code that's called by user code.
  Trace foldFrames(bool predicate(frame)) {
    var newFrames = <Frame>[];
    for (var frame in frames.reversed) {
      if (!predicate(frame)) {
        newFrames.add(frame);
      } else if (newFrames.isEmpty || !predicate(newFrames.last)) {
        newFrames.add(new Frame(
            frame.uri, frame.line, frame.column, frame.member));
      }
    }

    return new Trace(newFrames.reversed);
  }

  /// Returns a human-readable string representation of [this].
  String toString() {
    // Figure out the longest path so we know how much to pad.
    var longest = frames.map((frame) => frame.location.length)
        .fold(0, math.max);

    // Print out the stack trace nicely formatted.
    return frames.map((frame) {
      return '${padRight(frame.location, longest)}  ${frame.member}\n';
    }).join();
  }
}
