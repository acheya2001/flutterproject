import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎨 Modèle pour le croquis collaboratif
class CollaborativeSketch {
  final String id;
  final String sessionId;
  final String creatorId;
  final String creatorName;
  final List<SketchElementData> elements;
  final Map<String, ConducteurSignature> signatures;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime? lockedAt;
  final SketchMode mode;
  final Map<String, String> conducteurColors; // conducteurId -> couleur

  CollaborativeSketch({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.creatorName,
    required this.elements,
    required this.signatures,
    required this.isLocked,
    required this.createdAt,
    this.lockedAt,
    required this.mode,
    required this.conducteurColors,
  });

  factory CollaborativeSketch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CollaborativeSketch(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      elements: (data['elements'] as List<dynamic>?)
          ?.map((e) => SketchElementData.fromMap(e))
          .toList() ?? [],
      signatures: Map<String, ConducteurSignature>.from(
        (data['signatures'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, ConducteurSignature.fromMap(value))
        ) ?? {}
      ),
      isLocked: data['isLocked'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lockedAt: data['lockedAt'] != null 
          ? (data['lockedAt'] as Timestamp).toDate() 
          : null,
      mode: SketchMode.values.firstWhere(
        (m) => m.name == data['mode'],
        orElse: () => SketchMode.exclusive,
      ),
      conducteurColors: Map<String, String>.from(data['conducteurColors'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'elements': elements.map((e) => e.toMap()).toList(),
      'signatures': signatures.map((key, value) => MapEntry(key, value.toMap())),
      'isLocked': isLocked,
      'createdAt': Timestamp.fromDate(createdAt),
      'lockedAt': lockedAt != null ? Timestamp.fromDate(lockedAt!) : null,
      'mode': mode.name,
      'conducteurColors': conducteurColors,
    };
  }

  CollaborativeSketch copyWith({
    String? id,
    String? sessionId,
    String? creatorId,
    String? creatorName,
    List<SketchElementData>? elements,
    Map<String, ConducteurSignature>? signatures,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? lockedAt,
    SketchMode? mode,
    Map<String, String>? conducteurColors,
  }) {
    return CollaborativeSketch(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      elements: elements ?? this.elements,
      signatures: signatures ?? this.signatures,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      lockedAt: lockedAt ?? this.lockedAt,
      mode: mode ?? this.mode,
      conducteurColors: conducteurColors ?? this.conducteurColors,
    );
  }
}

/// 🎨 Modes de collaboration
enum SketchMode {
  exclusive, // Seul le créateur peut modifier
  collaborative, // Tous peuvent modifier avec des couleurs différentes
}

/// 🎨 Élément du croquis avec métadonnées
class SketchElementData {
  final String id;
  final String type; // 'vehicle', 'road', 'arrow', etc.
  final List<Map<String, double>> points; // [{x: 0.0, y: 0.0}]
  final String color;
  final double strokeWidth;
  final String? text;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  SketchElementData({
    required this.id,
    required this.type,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.text,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory SketchElementData.fromMap(Map<String, dynamic> map) {
    return SketchElementData(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      points: List<Map<String, double>>.from(
        (map['points'] as List<dynamic>?)?.map((p) => 
          Map<String, double>.from(p)
        ) ?? []
      ),
      color: map['color'] ?? '#000000',
      strokeWidth: (map['strokeWidth'] ?? 3.0).toDouble(),
      text: map['text'],
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'points': points,
      'color': color,
      'strokeWidth': strokeWidth,
      'text': text,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// ✍️ Signature d'un conducteur sur le croquis
class ConducteurSignature {
  final String conducteurId;
  final String conducteurName;
  final bool isAgreed; // true = d'accord, false = désaccord
  final String? disagreementReason; // Raison du désaccord
  final DateTime signedAt;

  ConducteurSignature({
    required this.conducteurId,
    required this.conducteurName,
    required this.isAgreed,
    this.disagreementReason,
    required this.signedAt,
  });

  factory ConducteurSignature.fromMap(Map<String, dynamic> map) {
    return ConducteurSignature(
      conducteurId: map['conducteurId'] ?? '',
      conducteurName: map['conducteurName'] ?? '',
      isAgreed: map['isAgreed'] ?? false,
      disagreementReason: map['disagreementReason'],
      signedAt: (map['signedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conducteurId': conducteurId,
      'conducteurName': conducteurName,
      'isAgreed': isAgreed,
      'disagreementReason': disagreementReason,
      'signedAt': Timestamp.fromDate(signedAt),
    };
  }
}

/// 🎨 État de participation d'un conducteur
class ConducteurParticipation {
  final String conducteurId;
  final String conducteurName;
  final String assignedColor;
  final bool isOnline;
  final DateTime lastSeen;
  final bool canEdit;

  ConducteurParticipation({
    required this.conducteurId,
    required this.conducteurName,
    required this.assignedColor,
    required this.isOnline,
    required this.lastSeen,
    required this.canEdit,
  });

  factory ConducteurParticipation.fromMap(Map<String, dynamic> map) {
    return ConducteurParticipation(
      conducteurId: map['conducteurId'] ?? '',
      conducteurName: map['conducteurName'] ?? '',
      assignedColor: map['assignedColor'] ?? '#000000',
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      canEdit: map['canEdit'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conducteurId': conducteurId,
      'conducteurName': conducteurName,
      'assignedColor': assignedColor,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'canEdit': canEdit,
    };
  }
}
