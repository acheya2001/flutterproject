import 'package:cloud_firestore/cloud_firestore.dart';

/// 📧 Modèle pour les invitations à rejoindre une session d'accident
class AccidentInvitation {
  final String id;
  final String sessionId;
  final String rolePropose; // 'A', 'B', 'C', 'D'...
  final String urlToken; // Token unique pour l'accès invité
  final String? qrPngFileId; // ID du fichier QR code généré
  final DateTime expiresAt; // Expiration du lien (ex: 24h)
  final DateTime? joinedAt; // Quand l'invité a rejoint
  final String? joinedByUserId; // ID utilisateur si inscrit
  final String? joinedByEmail; // Email si non-inscrit
  final String statut; // 'envoyee', 'rejointe', 'expiree', 'refusee'
  final DateTime createdAt;

  AccidentInvitation({
    required this.id,
    required this.sessionId,
    required this.rolePropose,
    required this.urlToken,
    this.qrPngFileId,
    required this.expiresAt,
    this.joinedAt,
    this.joinedByUserId,
    this.joinedByEmail,
    this.statut = 'envoyee',
    required this.createdAt,
  });

  factory AccidentInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AccidentInvitation(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      rolePropose: data['rolePropose'] ?? 'B',
      urlToken: data['urlToken'] ?? '',
      qrPngFileId: data['qrPngFileId'],
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      joinedAt: data['joinedAt'] != null 
          ? (data['joinedAt'] as Timestamp).toDate() 
          : null,
      joinedByUserId: data['joinedByUserId'],
      joinedByEmail: data['joinedByEmail'],
      statut: data['statut'] ?? 'envoyee',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'rolePropose': rolePropose,
      'urlToken': urlToken,
      'qrPngFileId': qrPngFileId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'joinedAt': joinedAt != null 
          ? Timestamp.fromDate(joinedAt!) 
          : null,
      'joinedByUserId': joinedByUserId,
      'joinedByEmail': joinedByEmail,
      'statut': statut,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Vérifie si l'invitation est encore valide
  bool get isValid {
    return statut == 'envoyee' && DateTime.now().isBefore(expiresAt);
  }

  /// Vérifie si l'invitation a été utilisée
  bool get isUsed {
    return statut == 'rejointe' && joinedAt != null;
  }

  /// URL complète de l'invitation
  String getInvitationUrl(String baseUrl) {
    return '$baseUrl/invite/$urlToken';
  }
}

/// 📱 Modèle pour les notifications push/email/SMS
class AccidentNotification {
  final String id;
  final String? userId; // null si destinataire non-inscrit
  final String? email; // pour non-inscrits
  final String? telephone; // pour SMS
  final String type; // 'invitation', 'rappel', 'signature_requise', etc.
  final String titre;
  final String message;
  final Map<String, dynamic> payload; // Données additionnelles
  final DateTime sentAt;
  final DateTime? readAt;
  final String statut; // 'envoye', 'lu', 'echec'

  AccidentNotification({
    required this.id,
    this.userId,
    this.email,
    this.telephone,
    required this.type,
    required this.titre,
    required this.message,
    this.payload = const {},
    required this.sentAt,
    this.readAt,
    this.statut = 'envoye',
  });

  factory AccidentNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AccidentNotification(
      id: doc.id,
      userId: data['userId'],
      email: data['email'],
      telephone: data['telephone'],
      type: data['type'] ?? '',
      titre: data['titre'] ?? '',
      message: data['message'] ?? '',
      payload: Map<String, dynamic>.from(data['payload'] ?? {}),
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null 
          ? (data['readAt'] as Timestamp).toDate() 
          : null,
      statut: data['statut'] ?? 'envoye',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'telephone': telephone,
      'type': type,
      'titre': titre,
      'message': message,
      'payload': payload,
      'sentAt': Timestamp.fromDate(sentAt),
      'readAt': readAt != null 
          ? Timestamp.fromDate(readAt!) 
          : null,
      'statut': statut,
    };
  }
}

/// 📋 Modèle pour les constats générés (PDF)
class AccidentConstat {
  final String id;
  final String sessionId;
  final String pdfFileId; // ID du fichier PDF généré
  final String pdfHash; // Hash pour vérification d'intégrité
  final bool signeParTous; // true si toutes les parties ont signé
  final DateTime? transmisAt; // Quand transmis aux assureurs
  final List<String> assureursDestinataires; // IDs des compagnies
  final List<AccuseReception> accusesReception; // Confirmations de réception
  final DateTime createdAt;

  AccidentConstat({
    required this.id,
    required this.sessionId,
    required this.pdfFileId,
    required this.pdfHash,
    this.signeParTous = false,
    this.transmisAt,
    this.assureursDestinataires = const [],
    this.accusesReception = const [],
    required this.createdAt,
  });

  factory AccidentConstat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AccidentConstat(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      pdfFileId: data['pdfFileId'] ?? '',
      pdfHash: data['pdfHash'] ?? '',
      signeParTous: data['signeParTous'] ?? false,
      transmisAt: data['transmisAt'] != null 
          ? (data['transmisAt'] as Timestamp).toDate() 
          : null,
      assureursDestinataires: List<String>.from(data['assureursDestinataires'] ?? []),
      accusesReception: (data['accusesReception'] as List<dynamic>?)
          ?.map((a) => AccuseReception.fromMap(a))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'pdfFileId': pdfFileId,
      'pdfHash': pdfHash,
      'signeParTous': signeParTous,
      'transmisAt': transmisAt != null 
          ? Timestamp.fromDate(transmisAt!) 
          : null,
      'assureursDestinataires': assureursDestinataires,
      'accusesReception': accusesReception.map((a) => a.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// 📨 Accusé de réception d'un assureur
class AccuseReception {
  final String assureurId;
  final DateTime recuAt;
  final String? agentId; // Agent qui a traité
  final String statut; // 'recu', 'en_traitement', 'traite'

  AccuseReception({
    required this.assureurId,
    required this.recuAt,
    this.agentId,
    this.statut = 'recu',
  });

  factory AccuseReception.fromMap(Map<String, dynamic> map) {
    return AccuseReception(
      assureurId: map['assureurId'] ?? '',
      recuAt: DateTime.parse(map['recuAt']),
      agentId: map['agentId'],
      statut: map['statut'] ?? 'recu',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assureurId': assureurId,
      'recuAt': recuAt.toIso8601String(),
      'agentId': agentId,
      'statut': statut,
    };
  }
}

/// 🎯 Modèle pour l'assignation aux agents
class AccidentAssignation {
  final String id;
  final String sessionId;
  final String compagnieId;
  final String agenceId;
  final String? agentId; // null si pas encore assigné
  final String statutTraitement; // 'nouveau', 'assigne', 'en_cours', 'complete'
  final DateTime createdAt;
  final DateTime? assignedAt;

  AccidentAssignation({
    required this.id,
    required this.sessionId,
    required this.compagnieId,
    required this.agenceId,
    this.agentId,
    this.statutTraitement = 'nouveau',
    required this.createdAt,
    this.assignedAt,
  });

  factory AccidentAssignation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AccidentAssignation(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      compagnieId: data['compagnieId'] ?? '',
      agenceId: data['agenceId'] ?? '',
      agentId: data['agentId'],
      statutTraitement: data['statutTraitement'] ?? 'nouveau',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      assignedAt: data['assignedAt'] != null 
          ? (data['assignedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'agentId': agentId,
      'statutTraitement': statutTraitement,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedAt': assignedAt != null 
          ? Timestamp.fromDate(assignedAt!) 
          : null,
    };
  }
}
