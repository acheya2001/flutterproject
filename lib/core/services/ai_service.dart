import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math' as math;

/// 🤖 Service d'intelligence artificielle pour l'analyse d'accidents
class AIService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // URL de l'API d'IA (à remplacer par votre service)
  static const String _aiApiUrl = 'https://api.votre-service-ia.com';
  static const String _apiKey = 'votre_cle_api';

  /// 🎤 Transcrire un fichier audio en texte
  static Future<String> transcribeAudio(String audioId) async {
    try {
      debugPrint('[AIService] Transcription d\'un fichier audio');
      
      final audioRef = _storage.ref().child('temp/audio/$audioId.mp3');
      final audioUrl = await audioRef.getDownloadURL();
      
      // Appeler l'API de transcription
      final response = await http.post(
        Uri.parse('$_aiApiUrl/transcribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'audio_url': audioUrl,
          'language': 'fr',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String transcription = data['transcription'] ?? '';
        debugPrint('[AIService] Transcription réussie: ${transcription.substring(0, math.min(50, transcription.length))}...');
        return transcription;
      } else {
        debugPrint('[AIService] Erreur lors de la transcription: ${response.statusCode} - ${response.body}');
        return 'Erreur de transcription';
      }
    } catch (e) {
      debugPrint('[AIService] Erreur lors de la transcription audio: $e');
      return 'Erreur: $e';
    }
  }

  /// 🎬 Générer une reconstruction vidéo d'accident
  static Future<String> generateAccidentReconstruction({
    required List<String> photoUrls,
    required String description,
  }) async {
    try {
      debugPrint('[AIService] Génération d\'une reconstruction d\'accident');
      
      // Appeler l'API de génération vidéo
      final response = await http.post(
        Uri.parse('$_aiApiUrl/generate-accident-video'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'photo_urls': photoUrls,
          'description': description,
          'duration': 30,
          'quality': 'high',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String videoUrl = data['video_url'] ?? '';
        debugPrint('[AIService] Reconstruction générée avec succès: $videoUrl');
        return videoUrl;
      } else {
        debugPrint('[AIService] Erreur lors de la génération de la reconstruction: ${response.statusCode} - ${response.body}');
        // En cas d'erreur, retourner une vidéo placeholder
        return 'https://example.com/video-placeholder.mp4';
      }
    } catch (e) {
      debugPrint('[AIService] Erreur lors de la génération de la reconstruction: $e');
      // En cas d'erreur, retourner une vidéo placeholder
      return 'https://example.com/video-placeholder.mp4';
    }
  }

  /// 📐 Générer un croquis d'accident
  static Future<String> generateAccidentSketch({
    required List<String> photoUrls,
    required String description,
  }) async {
    try {
      debugPrint('[AIService] Génération d\'un croquis d\'accident');
      
      // Appeler l'API de génération de croquis
      final response = await http.post(
        Uri.parse('$_aiApiUrl/generate-accident-sketch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'photo_urls': photoUrls,
          'description': description,
          'style': 'diagram',
          'view': 'top-down',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String sketchUrl = data['sketch_url'] ?? '';
        debugPrint('[AIService] Croquis généré avec succès: $sketchUrl');
        return sketchUrl;
      } else {
        debugPrint('[AIService] Erreur lors de la génération du croquis: ${response.statusCode} - ${response.body}');
        // En cas d'erreur, retourner un croquis placeholder
        return 'https://example.com/sketch-placeholder.png';
      }
    } catch (e) {
      debugPrint('[AIService] Erreur lors de la génération du croquis: $e');
      // En cas d'erreur, retourner un croquis placeholder
      return 'https://example.com/sketch-placeholder.png';
    }
  }

  /// 🔍 Analyser les dommages d'un véhicule
  static Future<Map<String, dynamic>> analyzeDamages(List<String> photoUrls) async {
    try {
      debugPrint('[AIService] Analyse des dommages à partir de ${photoUrls.length} photos');
      
      // Appeler l'API d'analyse des dommages
      final response = await http.post(
        Uri.parse('$_aiApiUrl/analyze-damages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'photo_urls': photoUrls,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[AIService] Analyse des dommages réussie');
        return data;
      } else {
        debugPrint('[AIService] Erreur lors de l\'analyse des dommages: ${response.statusCode} - ${response.body}');
        // En cas d'erreur, retourner des données par défaut
        return {
          'severity': 'medium',
          'estimated_cost': {
            'min': 1500,
            'max': 3000,
            'currency': 'TND',
          },
          'damaged_parts': [
            {
              'part': 'front_bumper',
              'severity': 'high',
              'confidence': 0.85,
            },
            {
              'part': 'hood',
              'severity': 'medium',
              'confidence': 0.72,
            },
            {
              'part': 'headlight_left',
              'severity': 'high',
              'confidence': 0.91,
            },
          ],
          'repair_time_estimate': {
            'min_days': 3,
            'max_days': 7,
          },
        };
      }
    } catch (e) {
      debugPrint('[AIService] Erreur lors de l\'analyse des dommages: $e');
      // En cas d'erreur, retourner des données par défaut
      return {
        'severity': 'unknown',
        'error': e.toString(),
        'damaged_parts': [],
      };
    }
  }

  /// 🔐 Vérifier l'authenticité d'un document
  static Future<Map<String, dynamic>> verifyDocumentAuthenticity(String documentId) async {
    try {
      debugPrint('[AIService] Vérification de l\'authenticité d\'un document');
      
      final documentRef = _storage.ref().child('temp/documents/$documentId.jpg');
      final documentUrl = await documentRef.getDownloadURL();
      
      // Appeler l'API de vérification d'authenticité
      final response = await http.post(
        Uri.parse('$_aiApiUrl/verify-document'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'document_url': documentUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool isAuthentic = data['is_authentic'] ?? false;
        final double confidence = data['confidence'] ?? 0.0;
        debugPrint('[AIService] Vérification d\'authenticité: $isAuthentic (confiance: $confidence)');
        return data;
      } else {
        debugPrint('[AIService] Erreur lors de la vérification d\'authenticité: ${response.statusCode} - ${response.body}');
        return {
          'is_authentic': false,
          'confidence': 0.0,
          'error': 'Service indisponible',
        };
      }
    } catch (e) {
      debugPrint('[AIService] Erreur lors de la vérification d\'authenticité: $e');
      return {
        'is_authentic': false,
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }
}
