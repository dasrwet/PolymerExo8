import 'dart:html';
import 'dart:convert';
import 'package:polymerExo8/contacts.dart';
import 'package:polymer/polymer.dart';

@CustomTag('web-contacts')
class WebContacts extends PolymerElement {
  @published Contacts contacts = Model.one.contacts;

  WebContacts.created() : super.created();

  add(Event e, var detail, Node target) {
    InputElement cle = shadowRoot.querySelector("#cle");
    InputElement nom = shadowRoot.querySelector("#nom");
    InputElement prenom = shadowRoot.querySelector("#prenom");
    InputElement phone = shadowRoot.querySelector("#phone");
    InputElement email = shadowRoot.querySelector("#email");
    InputElement adresse = shadowRoot.querySelector("#adresse");
    LabelElement message = shadowRoot.querySelector("#message");
    var error = false;
    message.text = '';
    if (cle.value.trim() == '') error = true;
    if (nom.value.trim() == '') error = true;
    if (!error) {
      var contact = new Contact(cle.value, nom.value,null,null,null,null);
      if (contacts.add(contact)) {
        contacts.sort();
        save();
      } else {
        message.text = 'web contact with that key already exists';
      }
    }
  }

  delete(Event e, var detail, Node target) {
    InputElement cle = shadowRoot.querySelector("#cle");
    InputElement nom = shadowRoot.querySelector("#nom");
    InputElement prenom = shadowRoot.querySelector("#prenom");
    InputElement phone = shadowRoot.querySelector("#phone");
    InputElement email = shadowRoot.querySelector("#email");
    InputElement adresse = shadowRoot.querySelector("#adresse");
    LabelElement message = shadowRoot.querySelector("#message");
    message.text = '';
    Contact contact = contacts.find(cle.value);
    if (contact == null) {
      message.text = 'web contact with this name does not exist';
    } else {
      nom.value = contact.nom;
      if (contacts.remove(contact)) save();
    }
  }

  save() {
    window.localStorage['polymerexo8'] = JSON.encode(Model.one.toJson());
  }
}