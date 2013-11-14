import 'dart:html';
import 'dart:convert';
import 'package:polymerExo8/contacts.dart';
import 'package:polymer/polymer.dart';

@CustomTag('web-contacts')
class WebContacts extends PolymerElement {
  @published Contacts contacts = Model.one.contacts;
  @published var ajout='add';

  WebContacts.created() : super.created();
   
  
  add(Event e, var detail, Node target) {
    InputElement cle = shadowRoot.querySelector("#cle");
    InputElement nom = shadowRoot.querySelector("#nom");
    InputElement prenom = shadowRoot.querySelector("#prenom");
    InputElement phone = shadowRoot.querySelector("#phone");
    InputElement email = shadowRoot.querySelector("#email");
    TextAreaElement adresse = shadowRoot.querySelector("#adresse");
    LabelElement message = shadowRoot.querySelector("#message");
    var error = false;
    message.text = '';
    if(ajout=='add')
    cle.value=nom.value.trim()[0]+nom.value.trim()[1]+(contacts.internalList.length).toString()+prenom.value.trim()[0]+prenom.value.trim()[1];
    if (cle.value.trim() == '') error = true;
    if (nom.value.trim() == '') error = true;
    if (!error) {
      var contact = new Contact(cle.value, nom.value,prenom.value,phone.value,email.value,adresse.value);
      if (contacts.add(contact)) {
        contacts.sort();
        save();
      } else {
        if(ajout=='add')
        message.text = 'web contact with that key already exists';
        else
        { Contact cont = contacts.find(cle.value);
          if(contacts.remove(cont))
          {
            contacts.sort();
            save();
          }
          if(contacts.add(contact)){
            contacts.sort();
            save();
            window.alert("Modification effectuee avec succes");
            }
        }
      }
    }
    window.location.reload();
  }

   mdf(Event e, var detail, Node target) {
    //(event.target as ImageElement).id; 
    //window.alert((event.target as ImageElement).id);
     var id = (e.target as ImageElement).id;
     
     InputElement cle = shadowRoot.querySelector("#cle");
     InputElement nom = shadowRoot.querySelector("#nom");
     InputElement prenom = shadowRoot.querySelector("#prenom");
     InputElement phone = shadowRoot.querySelector("#phone");
     InputElement email = shadowRoot.querySelector("#email");
     TextAreaElement adresse = shadowRoot.querySelector("#adresse");
     LabelElement message = shadowRoot.querySelector("#message");

     Contact contact = contacts.find(id);
     
     cle.value=contact.cles;
     nom.value=contact.nom;
     prenom.value=contact.prenom;
     phone.value=contact.phone;
     email.value=contact.email;
     adresse.value=contact.adresse;
     ajout='Modifier';
     
     
    
  }
  spm(Event e, var detail, Node target) {
    //(event.target as ImageElement).id; 
    //window.alert((event.target as ImageElement).id);
    LabelElement message = shadowRoot.querySelector("#message");
    message.text = '';
    var id = (e.target as ImageElement).title;
    Contact contact = contacts.find(id);
    if (contact == null) {
      message.text = 'web contact with this name does not exist';
    } else {
      if (window.confirm("Confirmez la suppression?"))
      {
        if (contacts.remove(contact)) save();
        window.location.reload();
      } 
    }
  }
  delete(Event e, var detail, Node target) {
    InputElement cle = shadowRoot.querySelector("#cle");
    InputElement nom = shadowRoot.querySelector("#nom");
    InputElement prenom = shadowRoot.querySelector("#prenom");
    InputElement phone = shadowRoot.querySelector("#phone");
    InputElement email = shadowRoot.querySelector("#email");
    TextAreaElement adresse = shadowRoot.querySelector("#adresse");
    LabelElement message = shadowRoot.querySelector("#message");
    message.text = '';
    Contact contact = contacts.find(cle.value);
    if (contact == null) {
      message.text = 'web contact with this name does not exist';
    } else {
      nom.value = contact.nom;
      if (contacts.remove(contact)) save();
      window.location.reload();
    }
  }

  save() {
    window.localStorage['polymerexo8'] = JSON.encode(Model.one.toJson());
  }
}