

class ProprietaireInfo {
  final String? nom;
  final String? prenom;
  final String? adresse;
  final String? telephone;
  final String? email;
  
  ProprietaireInfo({
    this.nom,
    this.prenom,
    this.adresse,
    this.telephone,
    this.email,
  }
  
  Map<String, dynamic> toMap() {
    return {
      'nom';      'prenom';      'adresse';      'telephone';      'email';      nom: map['nom';      prenom: map['prenom';      adresse: map['adresse';      telephone: map['telephone';      email: map['email';}