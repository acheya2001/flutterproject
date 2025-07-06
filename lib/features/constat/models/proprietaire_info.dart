

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
  });
  
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
    };
  }
  
  factory ProprietaireInfo.fromMap(Map<String, dynamic> map) {
    return ProprietaireInfo(
      nom: map['nom'],
      prenom: map['prenom'],
      adresse: map['adresse'],
      telephone: map['telephone'],
      email: map['email'],
    );
  }
  
  // Ajout des méthodes toJson et fromJson pour compatibilité
  Map<String, dynamic> toJson() => toMap();
  
  factory ProprietaireInfo.fromJson(Map<String, dynamic> json) => ProprietaireInfo.fromMap(json);
}