import 'dart:html';
import 'dart:convert';
import 'package:polymerExo8/contacts.dart';
import 'package:polymer/polymer.dart';

@CustomTag('mon-app')
class MonApp extends PolymerElement {

  MonApp.created() : super.created() {
    toObservable(Model.one.contacts.internalList);
    load();
  }

  load() {
    String json = window.localStorage['polymerexo8'];
    if (json == null) {
      Model.one.init();
    } else {
      var list = JSON.decode(json);
      var model = Model.one;
      model.fromJson(list);
    }
  }
}