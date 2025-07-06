class TemoinModel {
  final String nom;
  final String prenom;
  final String adresse;
  final String telephone;
  final DateTime createdAt;

  TemoinModel({
    required this.nom,
    required this.prenom,
    required this.adresse,
    required this.telephone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'telephone': telephone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TemoinModel.fromMap(Map<String, dynamic> map) {
    return TemoinModel(
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      adresse: map['adresse'] ?? '',
      telephone: map['telephone'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
