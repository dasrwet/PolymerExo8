library contacts;

class Contact implements Comparable {
  var cles, nom, prenom, phone, email,adresse;

  Contact(cle, noms, prenoms, phones, emails,adresses) {
    this.cles=cle;
    this.nom=noms;
    this.prenom=prenoms;
    this.phone=phones;
    this.email=emails;
    this.adresse=adresses;
       
  }

  Contact.fromJson(Map<String, Object> ContactMap) {
    cles = ContactMap['cles'];
    nom = ContactMap['nom'];
    prenom = ContactMap['prenom'];
    phone = ContactMap['phone'];
    email = ContactMap['email'];
    adresse = ContactMap['adresse'];
    
  }

  Map<String, Object> toJson() {
    var ContactMap = new Map<String, Object>();
    ContactMap['cles'] = cles;
    ContactMap['nom'] = nom;
    ContactMap['prenom'] = prenom;
    ContactMap['phone'] = phone;
    ContactMap['email'] = email;
    ContactMap['adresse'] = adresse;
    return ContactMap;
  }

  String toString() {
    return '{cles: ${cles}, nom: ${nom}, prenom: ${prenom}, phone: ${phone}, email: ${email}, adresse: ${adresse}}';
  }

  /**
   * Compares two links based on their names.
   * If the result is less than 0 then the first link is less than the second,
   * if it is equal to 0 they are equal and
   * if the result is greater than 0 then the first is greater than the second.
   */
  int compareTo(Contact contact) {
    if (cles != null && contact.cles != null) {
      return cles.compareTo(contact.cles);
    } else {
      throw new Exception('a contact cle must be present');
    }
  }
}

class Contacts {
  var _list = new List<Contact>();

  Iterator<Contact> get iterator => _list.iterator;
  bool get isEmpty => _list.isEmpty;

  List<Contact> get internalList => _list;
  set internalList(List<Contact> observableList) => _list = observableList;

  bool add(Contact newContact) {
    if (newContact == null) {
      throw new Exception('a new contact must be present');
    }
    for (Contact contact in this) {
      if (newContact.cles == contact.cles) return false;
    }
    _list.add(newContact);
    return true;
  }

  Contact find(var name) {
    for (Contact contact in _list) {
      if (contact.cles == name) return contact;
    }
    return null;
  }

  bool remove(Contact contact) {
    return _list.remove(contact);
  }

  sort() {
    _list.sort();
  }
}

class Model {
  var contacts = new Contacts();

  // singleton design pattern: http://en.wikipedia.org/wiki/Singleton_pattern
  static Model model;
  Model.private();
  static Model get one {
    if (model == null) {
      model = new Model.private();
    }
    return model;
  }
  // singleton

  init() {
    var c1='CO_'+(1).toString()+'_DO';
    var c2='HA_'+(2).toString()+'_AG';
    var c3='SE_'+(3).toString()+'_TO';
    var contact1 = new Contact(c1,'DOSSOU','Codjo','+22995067125','doscodj@yahoo.fr','Carre 721, gbegamey, 04 BP 1331, COTONOU BENIN');
    var contact2 = new Contact(c2,'AGROIA','Harmeet','+33671949662','harm@yahoo.fr','29 rue du prof Joseph Nicolas, 69008 Lyon France');
    var contact3 = new Contact(c3,'TOUDJI','Sestane','+15817775593','sestanetoudji@yahoo.fr','2592 RUE DE LA VENDEE, QC G1T 1B6');
    Model.one.contacts..add(contact1)..add(contact2)..add(contact3);
  }

  List<Map<String, Object>> toJson() {
    var contactList = new List<Map<String, Object>>();
    for (Contact contact in contacts) {
      contactList.add(contact.toJson());
    }
    return contactList;
  }

  fromJson(List<Map<String, Object>> contactList) {
    if (!contacts.isEmpty) {
      throw new Exception('contact are not empty');
    }
    for (Map<String, Object> contactMap in contactList) {
      Contact contact = new Contact.fromJson(contactMap);
      contacts.add(contact);
    }
  }
}
