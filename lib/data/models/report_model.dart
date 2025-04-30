import 'package:cloud_firestore/cloud_firestore.dart';

class Witness {
  final String name;
  final String firstName;
  final String phone;
  final String address;

  Witness({
    required this.name,
    required this.firstName,
    required this.phone,
    required this.address,
  });

  factory Witness.fromMap(Map<String, dynamic> map) {
    return Witness(
      name: map['nom'] ?? '',
      firstName: map['prenom'] ?? '',
      phone: map['telephone'] ?? '',
      address: map['adresse'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': name,
      'prenom': firstName,
      'telephone': phone,
      'adresse': address,
    };
  }
}

class Injured {
  final String name;
  final String firstName;
  final String severity;
  final bool hospitalized;
  final String details;

  Injured({
    required this.name,
    required this.firstName,
    required this.severity,
    required this.hospitalized,
    required this.details,
  });

  factory Injured.fromMap(Map<String, dynamic> map) {
    return Injured(
      name: map['nom'] ?? '',
      firstName: map['prenom'] ?? '',
      severity: map['gravite'] ?? '',
      hospitalized: map['hospitalisation'] ?? false,
      details: map['details'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': name,
      'prenom': firstName,
      'gravite': severity,
      'hospitalisation': hospitalized,
      'details': details,
    };
  }
}

class Photo {
  final String url;
  final String type;
  final DateTime timestamp;

  Photo({
    required this.url,
    required this.type,
    required this.timestamp,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      url: map['url'] ?? '',
      type: map['type'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class Signature {
  final String image;
  final DateTime timestamp;

  Signature({
    required this.image,
    required this.timestamp,
  });

  factory Signature.fromMap(Map<String, dynamic> map) {
    return Signature(
      image: map['image'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class StatusHistory {
  final String status;
  final DateTime timestamp;
  final String comment;
  final String userId;

  StatusHistory({
    required this.status,
    required this.timestamp,
    required this.comment,
    required this.userId,
  });

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      status: map['statut'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      comment: map['commentaire'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statut': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'commentaire': comment,
      'userId': userId,
    };
  }
}

class ExpertReport {
  final String expertId;
  final DateTime date;
  final String reportUrl;
  final double damageEstimate;
  final String recommendations;
  final List<String> photos;

  ExpertReport({
    required this.expertId,
    required this.date,
    required this.reportUrl,
    required this.damageEstimate,
    required this.recommendations,
    required this.photos,
  });

  factory ExpertReport.fromMap(Map<String, dynamic> map) {
    return ExpertReport(
      expertId: map['expertId'] ?? '',
      date: (map['dateExpertise'] as Timestamp).toDate(),
      reportUrl: map['rapport'] ?? '',
      damageEstimate: (map['estimationDegats'] ?? 0).toDouble(),
      recommendations: map['recommandations'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expertId': expertId,
      'dateExpertise': Timestamp.fromDate(date),
      'rapport': reportUrl,
      'estimationDegats': damageEstimate,
      'recommandations': recommendations,
      'photos': photos,
    };
  }
}

class Decision {
  final double responsibilityA;
  final double responsibilityB;
  final double compensationAmount;
  final DateTime decisionDate;
  final String validatedBy;

  Decision({
    required this.responsibilityA,
    required this.responsibilityB,
    required this.compensationAmount,
    required this.decisionDate,
    required this.validatedBy,
  });

  factory Decision.fromMap(Map<String, dynamic> map) {
  return Decision(
    responsibilityA: (map['responsabiliteA'] ?? 0).toDouble(),
    responsibilityB: (map['responsabiliteB'] ?? 0).toDouble(),
    compensationAmount: (map['montantIndemnisation'] ?? 0).toDouble(),
    decisionDate: map['dateDecision'] != null 
        ? (map['dateDecision'] as Timestamp).toDate() 
        : DateTime.now(),
    validatedBy: map['validePar'] ?? '',
  );
}
  Map<String, dynamic> toMap() {
    return {
      'responsabiliteA': responsibilityA,
      'responsabiliteB': responsibilityB,
      'montantIndemnisation': compensationAmount,
      'dateDecision': Timestamp.fromDate(decisionDate),
      'validePar': validatedBy,
    };
  }
}

class Party {
  final String driverId;
  final String vehicleId;
  final String contractId;
  final String insuranceId;
  final String agencyId;
  final List<String> circumstances;
  final String impactPoint;
  final String damages;
  final String observations;

  Party({
    required this.driverId,
    required this.vehicleId,
    required this.contractId,
    required this.insuranceId,
    required this.agencyId,
    required this.circumstances,
    required this.impactPoint,
    required this.damages,
    required this.observations,
  });

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      driverId: map['conducteurId'] ?? '',
      vehicleId: map['vehiculeId'] ?? '',
      contractId: map['contratId'] ?? '',
      insuranceId: map['assuranceId'] ?? '',
      agencyId: map['agenceId'] ?? '',
      circumstances: List<String>.from(map['circonstances'] ?? []),
      impactPoint: map['pointImpact'] ?? '',
      damages: map['degats'] ?? '',
      observations: map['observations'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conducteurId': driverId,
      'vehiculeId': vehicleId,
      'contratId': contractId,
      'assuranceId': insuranceId,
      'agenceId': agencyId,
      'circonstances': circumstances,
      'pointImpact': impactPoint,
      'degats': damages,
      'observations': observations,
    };
  }
}

class ReportModel {
  final String id;
  final String number;
  final DateTime date;
  final Map<String, dynamic> location;
  final Party partyA;
  final Party partyB;
  final List<Witness> witnesses;
  final List<Injured> injured;
  final List<Photo> photos;
  final Map<String, Signature> signatures;
  final String? sketchUrl;
  final String status;
  final String? expertId;
  final List<StatusHistory> history;
  final ExpertReport? expertise;
  final Decision? decision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  ReportModel({
    required this.id,
    required this.number,
    required this.date,
    required this.location,
    required this.partyA,
    required this.partyB,
    required this.witnesses,
    required this.injured,
    required this.photos,
    required this.signatures,
    this.sketchUrl,
    required this.status,
    this.expertId,
    required this.history,
    this.expertise,
    this.decision,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // Convertir un document Firestore en ReportModel
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convertir les signatures
    Map<String, Signature> signatures = {};
    if (data['signatures'] != null) {
      final signaturesData = data['signatures'] as Map<String, dynamic>;
      if (signaturesData['partieA'] != null) {
        signatures['partieA'] = Signature.fromMap(signaturesData['partieA']);
      }
      if (signaturesData['partieB'] != null) {
        signatures['partieB'] = Signature.fromMap(signaturesData['partieB']);
      }
    }
    
    return ReportModel(
      id: doc.id,
      number: data['numero'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: Map<String, dynamic>.from(data['lieu'] ?? {}),
      partyA: Party.fromMap(data['partieA'] ?? {}),
      partyB: Party.fromMap(data['partieB'] ?? {}),
      witnesses: (data['temoins'] as List<dynamic>? ?? [])
          .map((e) => Witness.fromMap(e as Map<String, dynamic>))
          .toList(),
      injured: (data['blesses'] as List<dynamic>? ?? [])
          .map((e) => Injured.fromMap(e as Map<String, dynamic>))
          .toList(),
      photos: (data['photos'] as List<dynamic>? ?? [])
          .map((e) => Photo.fromMap(e as Map<String, dynamic>))
          .toList(),
      signatures: signatures,
      sketchUrl: data['croquis'],
      status: data['statut'] ?? 'brouillon',
      expertId: data['expertId'],
      history: (data['historique'] as List<dynamic>? ?? [])
          .map((e) => StatusHistory.fromMap(e as Map<String, dynamic>))
          .toList(),
      expertise: data['expertise'] != null
          ? ExpertReport.fromMap(data['expertise'])
          : null,
      decision: data['decision'] != null
          ? Decision.fromMap(data['decision'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  // Convertir ReportModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> signaturesMap = {};
    signatures.forEach((key, value) {
      signaturesMap[key] = value.toMap();
    });
    
    return {
      'numero': number,
      'date': Timestamp.fromDate(date),
      'lieu': location,
      'partieA': partyA.toMap(),
      'partieB': partyB.toMap(),
      'temoins': witnesses.map((e) => e.toMap()).toList(),
      'blesses': injured.map((e) => e.toMap()).toList(),
      'photos': photos.map((e) => e.toMap()).toList(),
      'signatures': signaturesMap,
      'croquis': sketchUrl,
      'statut': status,
      'expertId': expertId,
      'historique': history.map((e) => e.toMap()).toList(),
      'expertise': expertise?.toMap(),
      'decision': decision?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }
}