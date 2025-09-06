import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les notifications du système de sinistre
class NotificationSinistre {
  final String id;
  final String? userId; // null si notification par email/SMS uniquement
  final String? email;
  final String? tel;
  final String type;
  final Map<String, dynamic> payload; // Données spécifiques au type
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isRead;
  final String? sessionId; // Lien vers la session d'accident
  final DateTime? dateCreation;

  NotificationSinistre({
    required this.id,
    this.userId,
    this.email,
    this.tel,
    required this.type,
    required this.payload,
    required this.sentAt,
    this.readAt,
    required this.isRead,
    this.sessionId,
    this.dateCreation,
  });

  /// Types de notifications
  static const String TYPE_INVITATION_SESSION = 'invitation_session';
  static const String TYPE_RAPPEL_SAISIE = 'rappel_saisie';
  static const String TYPE_PRET_A_SIGNER = 'pret_a_signer';
  static const String TYPE_SIGNATURE_MANQUANTE = 'signature_manquante';
  static const String TYPE_CONSTAT_SIGNE = 'constat_signe';
  static const String TYPE_CONSTAT_TRANSMIS = 'constat_transmis';
  static const String TYPE_DEMANDE_COMPLEMENT = 'demande_complement';
  static const String TYPE_CONVOCATION_EXPERTISE = 'convocation_expertise';
  static const String TYPE_MISE_A_JOUR_STATUT = 'mise_a_jour_statut';
  static const String TYPE_SESSION_EXPIREE = 'session_expiree';

  factory NotificationSinistre.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationSinistre(
      id: doc.id,
      userId: data['userId'],
      email: data['email'],
      tel: data['tel'],
      type: data['type'] ?? '',
      payload: Map<String, dynamic>.from(data['payload'] ?? {}),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
      sessionId: data['sessionId'],
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'tel': tel,
      'type': type,
      'payload': payload,
      'sentAt': Timestamp.fromDate(sentAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isRead': isRead,
      'sessionId': sessionId,
      'dateCreation': dateCreation != null ? Timestamp.fromDate(dateCreation!) : FieldValue.serverTimestamp(),
    };
  }

  NotificationSinistre copyWith({
    String? id,
    String? userId,
    String? email,
    String? tel,
    String? type,
    Map<String, dynamic>? payload,
    DateTime? sentAt,
    DateTime? readAt,
    bool? isRead,
    String? sessionId,
    DateTime? dateCreation,
  }) {
    return NotificationSinistre(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      tel: tel ?? this.tel,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      sessionId: sessionId ?? this.sessionId,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  /// Marque la notification comme lue
  NotificationSinistre markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }
}

/// Modèle pour l'assignation d'un constat à un agent
class Assignation {
  final String id;
  final String sessionId;
  final String compagnieId;
  final String? agenceId;
  final String? agentId;
  final String statutTraitement;
  final DateTime? dateAssignation;
  final DateTime? dateTraitement;
  final String? commentaires;
  final List<String> actionsRequises; // ['documents_manquants', 'expertise_requise', etc.]
  final DateTime? dateCreation;
  final DateTime? dateModification;

  Assignation({
    required this.id,
    required this.sessionId,
    required this.compagnieId,
    this.agenceId,
    this.agentId,
    required this.statutTraitement,
    this.dateAssignation,
    this.dateTraitement,
    this.commentaires,
    required this.actionsRequises,
    this.dateCreation,
    this.dateModification,
  });

  /// Statuts de traitement
  static const String STATUT_EN_ATTENTE = 'en_attente';
  static const String STATUT_ASSIGNE = 'assigne';
  static const String STATUT_EN_COURS = 'en_cours';
  static const String STATUT_COMPLEMENT_REQUIS = 'complement_requis';
  static const String STATUT_EXPERTISE_PROGRAMMEE = 'expertise_programmee';
  static const String STATUT_EN_EXPERTISE = 'en_expertise';
  static const String STATUT_INDEMNISATION = 'indemnisation';
  static const String STATUT_CLOTURE = 'cloture';
  static const String STATUT_REJETE = 'rejete';

  factory Assignation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignation(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      compagnieId: data['compagnieId'] ?? '',
      agenceId: data['agenceId'],
      agentId: data['agentId'],
      statutTraitement: data['statutTraitement'] ?? STATUT_EN_ATTENTE,
      dateAssignation: (data['dateAssignation'] as Timestamp?)?.toDate(),
      dateTraitement: (data['dateTraitement'] as Timestamp?)?.toDate(),
      commentaires: data['commentaires'],
      actionsRequises: List<String>.from(data['actionsRequises'] ?? []),
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
      dateModification: (data['dateModification'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'compagnieId': compagnieId,
      'agenceId': agenceId,
      'agentId': agentId,
      'statutTraitement': statutTraitement,
      'dateAssignation': dateAssignation != null ? Timestamp.fromDate(dateAssignation!) : null,
      'dateTraitement': dateTraitement != null ? Timestamp.fromDate(dateTraitement!) : null,
      'commentaires': commentaires,
      'actionsRequises': actionsRequises,
      'dateCreation': dateCreation != null ? Timestamp.fromDate(dateCreation!) : FieldValue.serverTimestamp(),
      'dateModification': FieldValue.serverTimestamp(),
    };
  }

  Assignation copyWith({
    String? id,
    String? sessionId,
    String? compagnieId,
    String? agenceId,
    String? agentId,
    String? statutTraitement,
    DateTime? dateAssignation,
    DateTime? dateTraitement,
    String? commentaires,
    List<String>? actionsRequises,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Assignation(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      compagnieId: compagnieId ?? this.compagnieId,
      agenceId: agenceId ?? this.agenceId,
      agentId: agentId ?? this.agentId,
      statutTraitement: statutTraitement ?? this.statutTraitement,
      dateAssignation: dateAssignation ?? this.dateAssignation,
      dateTraitement: dateTraitement ?? this.dateTraitement,
      commentaires: commentaires ?? this.commentaires,
      actionsRequises: actionsRequises ?? this.actionsRequises,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  /// Vérifie si l'assignation est active
  bool get isActive => ![STATUT_CLOTURE, STATUT_REJETE].contains(statutTraitement);

  /// Vérifie si l'assignation nécessite une action
  bool get requiresAction => actionsRequises.isNotEmpty;
}
