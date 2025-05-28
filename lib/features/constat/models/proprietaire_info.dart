class ProprietaireInfo {
  final String nom;
  final String prenom;
  final String adresse;
  final String telephone;

  ProprietaireInfo({
    required this.nom,
    required this.prenom,
    required this.adresse,
    required this.telephone,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'telephone': telephone,
    };
  }

  factory ProprietaireInfo.fromJson(Map<String, dynamic> json) {
    return ProprietaireInfo(
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
    );
  }

  ProprietaireInfo copyWith({
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
  }) {
    return ProprietaireInfo(
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
    );
  }
}
