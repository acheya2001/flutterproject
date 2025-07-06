import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎯 Objectifs mensuels d'un agent
class ObjectifsMensuels {
  final int nouveauxContrats;
  final double chiffreAffaires;

  const ObjectifsMensuels({
    required this.nouveauxContrats,
    required this.chiffreAffaires,
  });

  factory ObjectifsMensuels.fromMap(Map<String, dynamic> map) {
    return ObjectifsMensuels(
      nouveauxContrats: map['nouveaux_contrats'] ?? 0,
      chiffreAffaires: (map['chiffre_affaires'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nouveaux_contrats': nouveauxContrats,
      'chiffre_affaires': chiffreAffaires,
    };
  }
}

/// 📊 Performance d'un agent
class PerformanceAgent {
  final int contratsSignes;
  final double caRealise;

  const PerformanceAgent({
    required this.contratsSignes,
    required this.caRealise,
  });

  factory PerformanceAgent.fromMap(Map<String, dynamic> map) {
    return PerformanceAgent(
      contratsSignes: map['contrats_signes'] ?? 0,
      caRealise: (map['ca_realise'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contrats_signes': contratsSignes,
      'ca_realise': caRealise,
    };
  }

  /// Calculer le taux de réalisation des objectifs
  double getTauxRealisationContrats(int objectif) {
    if (objectif == 0) return 0;
    return (contratsSignes / objectif) * 100;
  }

  double getTauxRealisationCA(double objectif) {
    if (objectif == 0) return 0;
    return (caRealise / objectif) * 100;
  }
}

/// 👨‍💼 Modèle pour un agent d'assurance
class AgentAssuranceModel {
  final String id;
  final String userId; // Lien vers users collection
  final String compagnieId;
  final String agenceId;
  final String matriculeAgent;
  final List<String> specialites;
  final List<String> portefeuilleClients;
  final ObjectifsMensuels objectifsMensuels;
  final PerformanceAgent performance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentAssuranceModel({
    required this.id,
    required this.userId,
    required this.compagnieId,
    required this.agenceId,
    required this.matriculeAgent,
    required this.specialites,
    required this.portefeuilleClients,
    required this.objectifsMensuels,
    required this.performance,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory AgentAssuranceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgentAssuranceModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      compagnieId: data['compagnie_id'] ?? '',
      agenceId: data['agence_id'] ?? '',
      matriculeAgent: data['matricule_agent'] ?? '',
      specialites: List<String>.from(data['specialites'] ?? []),
      portefeuilleClients: List<String>.from(data['portefeuille_clients'] ?? []),
      objectifsMensuels: ObjectifsMensuels.fromMap(data['objectifs_mensuels'] ?? {}),
      performance: PerformanceAgent.fromMap(data['performance'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'compagnie_id': compagnieId,
      'agence_id': agenceId,
      'matricule_agent': matriculeAgent,
      'specialites': specialites,
      'portefeuille_clients': portefeuilleClients,
      'objectifs_mensuels': objectifsMensuels.toMap(),
      'performance': performance.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copier avec modifications
  AgentAssuranceModel copyWith({
    String? id,
    String? userId,
    String? compagnieId,
    String? agenceId,
    String? matriculeAgent,
    List<String>? specialites,
    List<String>? portefeuilleClients,
    ObjectifsMensuels? objectifsMensuels,
    PerformanceAgent? performance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentAssuranceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      matriculeAgent: matriculeAgent ?? this.matriculeAgent,
      specialites: specialites ?? this.specialites,
      portefeuilleClients: portefeuilleClients ?? this.portefeuilleClients,
      objectifsMensuels: objectifsMensuels ?? this.objectifsMensuels,
      performance: performance ?? this.performance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculer le taux de réalisation global
  double getTauxRealisationGlobal() {
    final tauxContrats = performance.getTauxRealisationContrats(objectifsMensuels.nouveauxContrats);
    final tauxCA = performance.getTauxRealisationCA(objectifsMensuels.chiffreAffaires);
    return (tauxContrats + tauxCA) / 2;
  }

  /// Vérifier si l'agent a atteint ses objectifs
  bool hasAtteintObjectifs() {
    return getTauxRealisationGlobal() >= 100;
  }

  @override
  String toString() {
    return 'AgentAssuranceModel(id: $id, matricule: $matriculeAgent, agence: $agenceId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentAssuranceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
