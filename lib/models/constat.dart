import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un constat finalisé
class Constat {
  final String id;
  final String sessionId;
  final String pdfFileId; // URL/ID du PDF généré
  final String hash; // Hash du PDF pour intégrité
  final bool signeParTous;
  final DateTime? transmisAt;
  final List<String> assureursDestinataires; // IDs des assureurs/agences
  final List<Map<String, dynamic>> accusesReception; // [{assureurId, date, status}]
  final DateTime? dateCreation;
  final DateTime? dateModification;

  Constat({
    required this.id,
    required this.sessionId,
    required this.pdfFileId,
    required this.hash,
    required this.signeParTous,
    this.transmisAt,
    required this.assureursDestinataires,
    required this.accusesReception,
    this.dateCreation,
    this.dateModification,
  });

  factory Constat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Constat(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      pdfFileId: data['pdfFileId'] ?? '',
      hash: data['hash'] ?? '',
      signeParTous: data['signeParTous'] ?? false,
      transmisAt: (data['transmisAt'] as Timestamp?)?.toDate(),
      assureursDestinataires: List<String>.from(data['assureursDestinataires'] ?? []),
      accusesReception: List<Map<String, dynamic>>.from(data['accusesReception'] ?? []),
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
      dateModification: (data['dateModification'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'pdfFileId': pdfFileId,
      'hash': hash,
      'signeParTous': signeParTous,
      'transmisAt': transmisAt != null ? Timestamp.fromDate(transmisAt!) : null,
      'assureursDestinataires': assureursDestinataires,
      'accusesReception': accusesReception,
      'dateCreation': dateCreation != null ? Timestamp.fromDate(dateCreation!) : FieldValue.serverTimestamp(),
      'dateModification': FieldValue.serverTimestamp(),
    };
  }

  Constat copyWith({
    String? id,
    String? sessionId,
    String? pdfFileId,
    String? hash,
    bool? signeParTous,
    DateTime? transmisAt,
    List<String>? assureursDestinataires,
    List<Map<String, dynamic>>? accusesReception,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Constat(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      pdfFileId: pdfFileId ?? this.pdfFileId,
      hash: hash ?? this.hash,
      signeParTous: signeParTous ?? this.signeParTous,
      transmisAt: transmisAt ?? this.transmisAt,
      assureursDestinataires: assureursDestinataires ?? this.assureursDestinataires,
      accusesReception: accusesReception ?? this.accusesReception,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  /// Vérifie si le constat a été transmis
  bool get isTransmitted => transmisAt != null;

  /// Vérifie si tous les accusés de réception ont été reçus
  bool get allAcknowledged => accusesReception.length == assureursDestinataires.length;
}

/// Modèle pour une invitation à rejoindre une session
class Invitation {
  final String id;
  final String sessionId;
  final String rolePropose; // A, B, C, D...
  final String urlToken; // Token unique pour l'URL d'invitation
  final String? qrPngFileId; // ID du QR code généré
  final DateTime expiresAt;
  final DateTime? joinedAt;
  final String? joinedByUserId;
  final DateTime? dateCreation;

  Invitation({
    required this.id,
    required this.sessionId,
    required this.rolePropose,
    required this.urlToken,
    this.qrPngFileId,
    required this.expiresAt,
    this.joinedAt,
    this.joinedByUserId,
    this.dateCreation,
  });

  factory Invitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invitation(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      rolePropose: data['rolePropose'] ?? 'B',
      urlToken: data['urlToken'] ?? '',
      qrPngFileId: data['qrPngFileId'],
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? 
          DateTime.now().add(const Duration(hours: 24)),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
      joinedByUserId: data['joinedByUserId'],
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'rolePropose': rolePropose,
      'urlToken': urlToken,
      'qrPngFileId': qrPngFileId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'joinedByUserId': joinedByUserId,
      'dateCreation': dateCreation != null ? Timestamp.fromDate(dateCreation!) : FieldValue.serverTimestamp(),
    };
  }

  /// Vérifie si l'invitation est encore valide
  bool get isValid => DateTime.now().isBefore(expiresAt) && joinedAt == null;

  /// Vérifie si l'invitation a été utilisée
  bool get isUsed => joinedAt != null;

  /// Génère un token unique pour l'invitation
  static String generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 100000).toString().padLeft(5, '0');
    return 'INV-$timestamp-$random';
  }

  Invitation copyWith({
    String? id,
    String? sessionId,
    String? rolePropose,
    String? urlToken,
    String? qrPngFileId,
    DateTime? expiresAt,
    DateTime? joinedAt,
    String? joinedByUserId,
    DateTime? dateCreation,
  }) {
    return Invitation(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      rolePropose: rolePropose ?? this.rolePropose,
      urlToken: urlToken ?? this.urlToken,
      qrPngFileId: qrPngFileId ?? this.qrPngFileId,
      expiresAt: expiresAt ?? this.expiresAt,
      joinedAt: joinedAt ?? this.joinedAt,
      joinedByUserId: joinedByUserId ?? this.joinedByUserId,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
