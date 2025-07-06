import 'package:cloud_firestore/cloud_firestore.dart';

/// 📝 Modèle pour les demandes d'inscription d'agents d'assurance
class AgentRegistrationModel {
  final String id;
  final String email;
  final String password; // Stocké temporairement pour création après approbation
  final String prenom;
  final String nom;
  final String telephone;
  final String compagnie;
  final String agence;
  final String gouvernorat;
  final String poste;
  final String numeroAgent;
  final String? carteIdRecto;
  final String? carteIdVerso;
  final String? permisRecto;
  final String? permisVerso;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? agentUid; // UID Firebase après approbation

  AgentRegistrationModel({
    required this.id,
    required this.email,
    required this.password,
    required this.prenom,
    required this.nom,
    required this.telephone,
    required this.compagnie,
    required this.agence,
    required this.gouvernorat,
    required this.poste,
    required this.numeroAgent,
    this.carteIdRecto,
    this.carteIdVerso,
    this.permisRecto,
    this.permisVerso,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.agentUid,
  });

  /// Créer depuis Map Firestore
  factory AgentRegistrationModel.fromMap(Map<String, dynamic> map, String id) {
    return AgentRegistrationModel(
      id: id,
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      prenom: map['prenom'] ?? '',
      nom: map['nom'] ?? '',
      telephone: map['telephone'] ?? '',
      compagnie: map['compagnie'] ?? '',
      agence: map['agence'] ?? '',
      gouvernorat: map['gouvernorat'] ?? '',
      poste: map['poste'] ?? '',
      numeroAgent: map['numeroAgent'] ?? '',
      carteIdRecto: map['carteIdRecto'],
      carteIdVerso: map['carteIdVerso'],
      permisRecto: map['permisRecto'],
      permisVerso: map['permisVerso'],
      status: map['status'] ?? 'pending',
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'],
      rejectionReason: map['rejectionReason'],
      agentUid: map['agentUid'],
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'prenom': prenom,
      'nom': nom,
      'telephone': telephone,
      'compagnie': compagnie,
      'agence': agence,
      'gouvernorat': gouvernorat,
      'poste': poste,
      'numeroAgent': numeroAgent,
      'carteIdRecto': carteIdRecto,
      'carteIdVerso': carteIdVerso,
      'permisRecto': permisRecto,
      'permisVerso': permisVerso,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'agentUid': agentUid,
    };
  }

  /// Copier avec modifications
  AgentRegistrationModel copyWith({
    String? id,
    String? email,
    String? password,
    String? prenom,
    String? nom,
    String? telephone,
    String? compagnie,
    String? agence,
    String? gouvernorat,
    String? poste,
    String? numeroAgent,
    String? carteIdRecto,
    String? carteIdVerso,
    String? permisRecto,
    String? permisVerso,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? agentUid,
  }) {
    return AgentRegistrationModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      compagnie: compagnie ?? this.compagnie,
      agence: agence ?? this.agence,
      gouvernorat: gouvernorat ?? this.gouvernorat,
      poste: poste ?? this.poste,
      numeroAgent: numeroAgent ?? this.numeroAgent,
      carteIdRecto: carteIdRecto ?? this.carteIdRecto,
      carteIdVerso: carteIdVerso ?? this.carteIdVerso,
      permisRecto: permisRecto ?? this.permisRecto,
      permisVerso: permisVerso ?? this.permisVerso,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      agentUid: agentUid ?? this.agentUid,
    );
  }

  /// Nom complet
  String get fullName => '$prenom $nom';

  /// Statut formaté
  String get statusFormatted {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  /// Couleur du statut
  String get statusColor {
    switch (status) {
      case 'pending':
        return '#FF9800'; // Orange
      case 'approved':
        return '#4CAF50'; // Vert
      case 'rejected':
        return '#F44336'; // Rouge
      default:
        return '#9E9E9E'; // Gris
    }
  }

  /// Icône du statut
  String get statusIcon {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '❓';
    }
  }

  /// Vérifier si la demande est en attente
  bool get isPending => status == 'pending';

  /// Vérifier si la demande est approuvée
  bool get isApproved => status == 'approved';

  /// Vérifier si la demande est rejetée
  bool get isRejected => status == 'rejected';

  /// Durée depuis la soumission
  Duration get timeSinceSubmission => DateTime.now().difference(submittedAt);

  /// Durée depuis la révision (si applicable)
  Duration? get timeSinceReview {
    if (reviewedAt == null) return null;
    return DateTime.now().difference(reviewedAt!);
  }

  /// Texte de durée formaté
  String get submissionTimeText {
    final duration = timeSinceSubmission;
    if (duration.inDays > 0) {
      return 'Il y a ${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return 'Il y a ${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return 'Il y a ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  /// Validation des données
  List<String> validate() {
    final errors = <String>[];

    if (email.isEmpty || !email.contains('@')) {
      errors.add('Email invalide');
    }

    if (password.length < 6) {
      errors.add('Mot de passe trop court (minimum 6 caractères)');
    }

    if (prenom.isEmpty) {
      errors.add('Prénom requis');
    }

    if (nom.isEmpty) {
      errors.add('Nom requis');
    }

    if (telephone.isEmpty) {
      errors.add('Téléphone requis');
    }

    if (compagnie.isEmpty) {
      errors.add('Compagnie requise');
    }

    if (agence.isEmpty) {
      errors.add('Agence requise');
    }

    if (gouvernorat.isEmpty) {
      errors.add('Gouvernorat requis');
    }

    if (poste.isEmpty) {
      errors.add('Poste requis');
    }

    if (numeroAgent.isEmpty) {
      errors.add('Numéro d\'agent requis');
    }

    return errors;
  }

  /// Vérifier si les données sont valides
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'AgentRegistrationModel(id: $id, email: $email, fullName: $fullName, compagnie: $compagnie, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentRegistrationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
