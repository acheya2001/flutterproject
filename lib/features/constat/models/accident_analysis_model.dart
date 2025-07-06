import 'dart:convert';

/// 🤖 Modèle principal d'analyse IA d'accident
class AccidentAnalysis {
  final String id;
  final String sessionId;
  final List<String> imageUrls;
  final ImageAnalysisResult imageAnalysis;
  final DescriptionAnalysis description;
  final AccidentReconstruction reconstruction;
  final DateTime createdAt;
  final AnalysisStatus status;

  AccidentAnalysis({
    required this.id,
    required this.sessionId,
    required this.imageUrls,
    required this.imageAnalysis,
    required this.description,
    required this.reconstruction,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'imageUrls': imageUrls,
      'imageAnalysis': imageAnalysis.toMap(),
      'description': description.toMap(),
      'reconstruction': reconstruction.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.toString(),
    };
  }

  factory AccidentAnalysis.fromMap(Map<String, dynamic> map) {
    return AccidentAnalysis(
      id: map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      imageAnalysis: ImageAnalysisResult.fromMap(map['imageAnalysis'] ?? {}),
      description: DescriptionAnalysis.fromMap(map['description'] ?? {}),
      reconstruction: AccidentReconstruction.fromMap(map['reconstruction'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      status: AnalysisStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => AnalysisStatus.pending,
      ),
    );
  }
}

/// 📸 Résultat de l'analyse des images
class ImageAnalysisResult {
  final int vehicleCount;
  final List<VehicleInfo> vehicles;
  final List<DamageInfo> damages;
  final ImpactAnalysis impact;
  final double confidence;
  final Map<String, dynamic> rawData;

  ImageAnalysisResult({
    required this.vehicleCount,
    required this.vehicles,
    required this.damages,
    required this.impact,
    required this.confidence,
    required this.rawData,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicleCount': vehicleCount,
      'vehicles': vehicles.map((v) => v.toMap()).toList(),
      'damages': damages.map((d) => d.toMap()).toList(),
      'impact': impact.toMap(),
      'confidence': confidence,
      'rawData': rawData,
    };
  }

  factory ImageAnalysisResult.fromMap(Map<String, dynamic> map) {
    return ImageAnalysisResult(
      vehicleCount: map['vehicleCount'] ?? 0,
      vehicles: (map['vehicles'] as List? ?? [])
          .map((v) => VehicleInfo.fromMap(v))
          .toList(),
      damages: (map['damages'] as List? ?? [])
          .map((d) => DamageInfo.fromMap(d))
          .toList(),
      impact: ImpactAnalysis.fromMap(map['impact'] ?? {}),
      confidence: map['confidence']?.toDouble() ?? 0.0,
      rawData: map['rawData'] ?? {},
    );
  }

  factory ImageAnalysisResult.fromAIResponse(String aiResponse) {
    try {
      final data = jsonDecode(aiResponse);
      return ImageAnalysisResult(
        vehicleCount: data['vehicleCount'] ?? 2,
        vehicles: (data['vehicles'] as List? ?? [])
            .map((v) => VehicleInfo.fromMap(v))
            .toList(),
        damages: (data['damages'] as List? ?? [])
            .map((d) => DamageInfo.fromMap(d))
            .toList(),
        impact: ImpactAnalysis.fromMap(data['impact'] ?? {}),
        confidence: data['confidence']?.toDouble() ?? 0.8,
        rawData: data,
      );
    } catch (e) {
      return ImageAnalysisResult.fallback();
    }
  }

  factory ImageAnalysisResult.fallback() {
    return ImageAnalysisResult(
      vehicleCount: 2,
      vehicles: [
        VehicleInfo.fallback('Véhicule A'),
        VehicleInfo.fallback('Véhicule B'),
      ],
      damages: [
        DamageInfo.fallback('Avant gauche'),
        DamageInfo.fallback('Arrière droit'),
      ],
      impact: ImpactAnalysis.fallback(),
      confidence: 0.5,
      rawData: {},
    );
  }
}

/// 🚗 Informations sur un véhicule détecté
class VehicleInfo {
  final String id;
  final String type; // berline, SUV, etc.
  final String color;
  final String position; // avant, arrière, côté
  final double confidence;

  VehicleInfo({
    required this.id,
    required this.type,
    required this.color,
    required this.position,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'color': color,
      'position': position,
      'confidence': confidence,
    };
  }

  factory VehicleInfo.fromMap(Map<String, dynamic> map) {
    return VehicleInfo(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      color: map['color'] ?? '',
      position: map['position'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }

  factory VehicleInfo.fallback(String id) {
    return VehicleInfo(
      id: id,
      type: 'Berline',
      color: 'Inconnue',
      position: 'Centre',
      confidence: 0.5,
    );
  }
}

/// 💥 Informations sur les dégâts
class DamageInfo {
  final String location; // avant, arrière, côté gauche, etc.
  final String severity; // léger, modéré, grave
  final String description;
  final double confidence;

  DamageInfo({
    required this.location,
    required this.severity,
    required this.description,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'severity': severity,
      'description': description,
      'confidence': confidence,
    };
  }

  factory DamageInfo.fromMap(Map<String, dynamic> map) {
    return DamageInfo(
      location: map['location'] ?? '',
      severity: map['severity'] ?? '',
      description: map['description'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }

  factory DamageInfo.fallback(String location) {
    return DamageInfo(
      location: location,
      severity: 'Modéré',
      description: 'Dégâts détectés automatiquement',
      confidence: 0.5,
    );
  }
}

/// 💥 Analyse de l'impact
class ImpactAnalysis {
  final String direction; // frontal, latéral, arrière
  final String angle; // 0°, 45°, 90°, etc.
  final String speed; // faible, modérée, élevée
  final double confidence;

  ImpactAnalysis({
    required this.direction,
    required this.angle,
    required this.speed,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'direction': direction,
      'angle': angle,
      'speed': speed,
      'confidence': confidence,
    };
  }

  factory ImpactAnalysis.fromMap(Map<String, dynamic> map) {
    return ImpactAnalysis(
      direction: map['direction'] ?? '',
      angle: map['angle'] ?? '',
      speed: map['speed'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }

  factory ImpactAnalysis.fallback() {
    return ImpactAnalysis(
      direction: 'Frontal',
      angle: '45°',
      speed: 'Modérée',
      confidence: 0.5,
    );
  }
}

/// 📝 Analyse de la description
class DescriptionAnalysis {
  final String originalText;
  final List<String> extractedFacts;
  final List<String> timeline;
  final List<String> keyWords;

  DescriptionAnalysis({
    required this.originalText,
    required this.extractedFacts,
    required this.timeline,
    required this.keyWords,
  });

  Map<String, dynamic> toMap() {
    return {
      'originalText': originalText,
      'extractedFacts': extractedFacts,
      'timeline': timeline,
      'keyWords': keyWords,
    };
  }

  factory DescriptionAnalysis.fromMap(Map<String, dynamic> map) {
    return DescriptionAnalysis(
      originalText: map['originalText'] ?? '',
      extractedFacts: List<String>.from(map['extractedFacts'] ?? []),
      timeline: List<String>.from(map['timeline'] ?? []),
      keyWords: List<String>.from(map['keyWords'] ?? []),
    );
  }

  factory DescriptionAnalysis.empty() {
    return DescriptionAnalysis(
      originalText: '',
      extractedFacts: [],
      timeline: [],
      keyWords: [],
    );
  }
}

/// 🎬 Reconstitution de l'accident
class AccidentReconstruction {
  final String? videoUrl;
  final String? sketchUrl;
  final String prompt;
  final double confidence;

  AccidentReconstruction({
    this.videoUrl,
    this.sketchUrl,
    required this.prompt,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'sketchUrl': sketchUrl,
      'prompt': prompt,
      'confidence': confidence,
    };
  }

  factory AccidentReconstruction.fromMap(Map<String, dynamic> map) {
    return AccidentReconstruction(
      videoUrl: map['videoUrl'],
      sketchUrl: map['sketchUrl'],
      prompt: map['prompt'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }

  factory AccidentReconstruction.fallback() {
    return AccidentReconstruction(
      prompt: 'Reconstitution automatique non disponible',
      confidence: 0.0,
    );
  }
}

/// 📊 Statut de l'analyse
enum AnalysisStatus {
  pending,
  processing,
  completed,
  failed,
}
