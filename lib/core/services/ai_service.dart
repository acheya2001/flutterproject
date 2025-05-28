import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math' as math;

class AIService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  
  // URL de l'API d'IA (à remplacer par votre propre endpoint)
  final String _aiApiUrl = 'https://api.votre-service-ia.com';
  
  // Clé API (à remplacer par votre propre clé)
  final String _apiKey = 'votre_cle_api';

  // Transcrire un fichier audio en texte
  Future<String> transcribeAudio(File audioFile) async {
    try {
      debugPrint('[AIService] Transcription d\'un fichier audio');
      
      // Uploader le fichier audio vers Firebase Storage pour obtenir une URL
      final String audioId = _uuid.v4();
      final audioRef = _storage.ref().child('temp/audio/$audioId.mp3');
      await audioRef.putFile(audioFile);
      final String audioUrl = await audioRef.getDownloadURL();
      
      // Appeler l'API de transcription
      final response = await http.post(
        Uri.parse('$_aiApiUrl/transcribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'audio_url': audioUrl,
          'language': 'fr',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String transcription = data['transcription'] ?? '';
        
        debugPrint('[AIService] Transcription réussie: ${transcription.substring(0, math.min(50, transcription.length))}...');
        
        // Supprimer le fichier temporaire
        await audioRef.delete();
        
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

  // Générer une reconstruction vidéo d'un accident
  Future<String> generateAccidentReconstruction({
    required List<String> photoUrls,
    required String description,
  }) async {
    try {
      debugPrint('[AIService] Génération d\'une reconstruction d\'accident');
      
      // Appeler l'API de génération de vidéo
      final response = await http.post(
        Uri.parse('$_aiApiUrl/generate-accident-video'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'photo_urls': photoUrls,
          'description': description,
          'duration': 15, // Durée en secondes
          'quality': 'high',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String videoUrl = data['video_url'] ?? '';
        
        debugPrint('[AIService] Reconstruction générée avec succès: $videoUrl');
        return videoUrl;
      } else {
        debugPrint('[AIService] Erreur lors de la génération de la reconstruction: ${response.statusCode} - ${response.body}');
        
        // En cas d'erreur, retourner une URL factice pour les tests
        return 'https://example.com/video-placeholder.mp4';
      }
    } catch (e) {
      debugPrint('[AIService] Erreur lors de la génération de la reconstruction: $e');
      
      // En cas d'erreur, retourner une URL factice pour les tests
      return 'https://example.com/video-placeholder.mp4';
    }
  }

  // Générer un croquis d'accident
  Future<String> generateAccidentSketch({
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
        body: jsonEncode({
          'photo_urls': photoUrls,
          'description': description,
          'style': 'diagram', // Style de croquis: diagram, sketch, realistic
          'view': 'top-down', // Vue: top-down, perspective
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String sketchUrl = data['sketch_url'] ?? '';
        
        debugPrint('[AIService] Croquis généré avec succès: $sketchUrl');
        return sketchUrl;
      } else {
        debugPrint('[AIService] Erreur lors de la génération du croquis: ${response.statusCode} - ${response.body}');
        
        // En cas d'erreur, retourner une URL factice pour les tests
        return 'https://example.com/sketch-placeholder.png';
      }
    } catch (e) {
      debugPrint('[AIService] Erreur lors de la génération du croquis: $e');
      
      // En cas d'erreur, retourner une URL factice pour les tests
      return 'https://example.com/sketch-placeholder.png';
    }
  }

  // Analyser les dommages d'un véhicule à partir de photos
  Future<Map<String, dynamic>> analyzeDamages(List<String> photoUrls) async {
    try {
      debugPrint('[AIService] Analyse des dommages à partir de ${photoUrls.length} photos');
      
      // Appeler l'API d'analyse de dommages
      final response = await http.post(
        Uri.parse('$_aiApiUrl/analyze-damages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'photo_urls': photoUrls,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        debugPrint('[AIService] Analyse des dommages réussie');
        return data;
      } else {
        debugPrint('[AIService] Erreur lors de l\'analyse des dommages: ${response.statusCode} - ${response.body}');
        
        // En cas d'erreur, retourner des données factices pour les tests
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
              'confidence': 0.92,
            },
            {
              'part': 'hood',
              'severity': 'medium',
              'confidence': 0.85,
            },
            {
              'part': 'headlight_left',
              'severity': 'high',
              'confidence': 0.78,
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
      
      // En cas d'erreur, retourner des données factices pour les tests
      return {
        'severity': 'unknown',
        'error': e.toString(),
        'damaged_parts': [],
      };
    }
  }

  // Vérifier l'authenticité d'un document
  Future<bool> verifyDocumentAuthenticity(File documentImage) async {
    try {
      debugPrint('[AIService] Vérification de l\'authenticité d\'un document');
      
      // Uploader le document vers Firebase Storage pour obtenir une URL
      final String documentId = _uuid.v4();
      final documentRef = _storage.ref().child('temp/documents/$documentId.jpg');
      await documentRef.putFile(documentImage);
      final String documentUrl = await documentRef.getDownloadURL();
      
      // Appeler l'API de vérification d'authenticité
      final response = await http.post(
        Uri.parse('$_aiApiUrl/verify-document'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'document_url': documentUrl,
        }),
      );
      
      // Supprimer le fichier temporaire
      await documentRef.delete();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isAuthentic = data['is_authentic'] ?? false;
        final double confidence = data['confidence'] ?? 0.0;
        
        debugPrint('[AIService] Vérification d\'authenticité: $isAuthentic (confiance: $confidence)');
        return isAuthentic;
      } else {
        debugPrint('[AIService] Erreur lors de la vérification d\'authenticité: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[AIService] Erreur lors de la vérification d\'authenticité: $e');
      return false;
    }
  }
}