// lib/data/services/ocr_service.dart

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final Logger _logger = Logger();

  // Méthode pour extraire le texte d'une image
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text;
      _logger.d('Texte extrait: $text');
      
      return text;
    } catch (e) {
      _logger.e('Erreur lors de l\'extraction du texte: $e');
      throw Exception('Impossible d\'extraire le texte de l\'image: $e');
    }
  }

  // Méthode pour extraire les informations du permis de conduire
  Future<Map<String, String>> extractDriverLicenseInfo(File imageFile) async {
    try {
      final String extractedText = await extractTextFromImage(imageFile);
      
      // Analyse du texte pour extraire les informations du permis
      final Map<String, String> driverInfo = _parseDriverLicenseInfo(extractedText);
      
      return driverInfo;
    } catch (e) {
      _logger.e('Erreur lors de l\'extraction des informations du permis: $e');
      throw Exception('Impossible d\'extraire les informations du permis: $e');
    }
  }

  // Méthode pour extraire les informations de la carte d'identité
  Future<Map<String, String>> extractIdCardInfo(File imageFile) async {
    try {
      final String extractedText = await extractTextFromImage(imageFile);
      
      // Analyse du texte pour extraire les informations de la carte d'identité
      final Map<String, String> idInfo = _parseIdCardInfo(extractedText);
      
      return idInfo;
    } catch (e) {
      _logger.e('Erreur lors de l\'extraction des informations de la carte d\'identité: $e');
      throw Exception('Impossible d\'extraire les informations de la carte d\'identité: $e');
    }
  }

  // Méthode pour extraire les informations de la carte grise
  Future<Map<String, String>> extractVehicleRegistrationInfo(File imageFile) async {
    try {
      final String extractedText = await extractTextFromImage(imageFile);
      
      // Analyse du texte pour extraire les informations de la carte grise
      final Map<String, String> vehicleInfo = _parseVehicleRegistrationInfo(extractedText);
      
      return vehicleInfo;
    } catch (e) {
      _logger.e('Erreur lors de l\'extraction des informations de la carte grise: $e');
      throw Exception('Impossible d\'extraire les informations de la carte grise: $e');
    }
  }

  // Méthode privée pour analyser le texte du permis de conduire
  Map<String, String> _parseDriverLicenseInfo(String text) {
    final Map<String, String> result = {};
    
    try {
      // Recherche du nom (généralement après "Nom:" ou similaire)
      final nomRegex = RegExp(r'(?:Nom|NOM)[:\s]+([A-Za-z\s]+)');
      final nomMatch = nomRegex.firstMatch(text);
      if (nomMatch != null && nomMatch.groupCount >= 1) {
        result['nom'] = nomMatch.group(1)!.trim();
      }
      
      // Recherche du prénom (généralement après "Prénom:" ou similaire)
      final prenomRegex = RegExp(r'(?:Prenom|PRENOM)[:\s]+([A-Za-z\s]+)');
      final prenomMatch = prenomRegex.firstMatch(text);
      if (prenomMatch != null && prenomMatch.groupCount >= 1) {
        result['prenom'] = prenomMatch.group(1)!.trim();
      }
      
      // Recherche de la date de naissance (format JJ/MM/AAAA)
      final dateNaissanceRegex = RegExp(r'(\d{2}[/.-]\d{2}[/.-]\d{4})');
      final dateNaissanceMatch = dateNaissanceRegex.firstMatch(text);
      if (dateNaissanceMatch != null) {
        result['dateNaissance'] = dateNaissanceMatch.group(0)!;
      }
      
      // Recherche du numéro de permis
      final numeroPermisRegex = RegExp(r'(?:N|Numero)[:\s]*(\d+[A-Za-z0-9]*)');
      final numeroPermisMatch = numeroPermisRegex.firstMatch(text);
      if (numeroPermisMatch != null && numeroPermisMatch.groupCount >= 1) {
        result['numeroPermis'] = numeroPermisMatch.group(1)!.trim();
      }
      
      // Recherche de la date de délivrance
      final dateDelivranceRegex = RegExp(r'(?:Delivre le|Date de delivrance)[:\s]*(\d{2}[/.-]\d{2}[/.-]\d{4})');
      final dateDelivranceMatch = dateDelivranceRegex.firstMatch(text);
      if (dateDelivranceMatch != null && dateDelivranceMatch.groupCount >= 1) {
        result['dateDelivrance'] = dateDelivranceMatch.group(1)!;
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'analyse du permis de conduire: $e');
    }
    
    return result;
  }

  // Méthode privée pour analyser le texte de la carte d'identité
  Map<String, String> _parseIdCardInfo(String text) {
    final Map<String, String> result = {};
    
    try {
      // Recherche du nom (généralement après "Nom:" ou similaire)
      final nomRegex = RegExp(r'(?:Nom|NOM)[:\s]+([A-Za-z\s]+)');
      final nomMatch = nomRegex.firstMatch(text);
      if (nomMatch != null && nomMatch.groupCount >= 1) {
        result['nom'] = nomMatch.group(1)!.trim();
      }
      
      // Recherche du prénom (généralement après "Prénom:" ou similaire)
      final prenomRegex = RegExp(r'(?:Prenom|PRENOM)[:\s]+([A-Za-z\s]+)');
      final prenomMatch = prenomRegex.firstMatch(text);
      if (prenomMatch != null && prenomMatch.groupCount >= 1) {
        result['prenom'] = prenomMatch.group(1)!.trim();
      }
      
      // Recherche de la date de naissance (format JJ/MM/AAAA)
      final dateNaissanceRegex = RegExp(r'(\d{2}[/.-]\d{2}[/.-]\d{4})');
      final dateNaissanceMatch = dateNaissanceRegex.firstMatch(text);
      if (dateNaissanceMatch != null) {
        result['dateNaissance'] = dateNaissanceMatch.group(0)!;
      }
      
      // Recherche du numéro de CIN
      // Utiliser une chaîne de caractères brute (r) pour éviter les problèmes d'échappement
      final cinRegex = RegExp(r'(?:CIN|Carte d identite)[:\s]*(\d+)');
      final cinMatch = cinRegex.firstMatch(text);
      if (cinMatch != null && cinMatch.groupCount >= 1) {
        result['cin'] = cinMatch.group(1)!.trim();
      }
      
      // Recherche de l'adresse
      final adresseRegex = RegExp(r'(?:Adresse|ADRESSE)[:\s]+(.+?)(?:\n|$)');
      final adresseMatch = adresseRegex.firstMatch(text);
      if (adresseMatch != null && adresseMatch.groupCount >= 1) {
        result['adresse'] = adresseMatch.group(1)!.trim();
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'analyse de la carte d\'identité: $e');
    }
    
    return result;
  }

  // Méthode privée pour analyser le texte de la carte grise
  Map<String, String> _parseVehicleRegistrationInfo(String text) {
    final Map<String, String> result = {};
    
    try {
      // Recherche de la marque (généralement après "MARQUE:" ou similaire)
      final marqueRegex = RegExp(r'(?:MARQUE|Marque)[:\s]+([A-Za-z0-9]+)');
      final marqueMatch = marqueRegex.firstMatch(text);
      if (marqueMatch != null && marqueMatch.groupCount >= 1) {
        result['marque'] = marqueMatch.group(1)!.trim();
      }
      
      // Recherche du modèle (généralement après "MODELE:" ou similaire)
      final modeleRegex = RegExp(r'(?:MODELE|Modele|Type)[:\s]+([A-Za-z0-9]+)');
      final modeleMatch = modeleRegex.firstMatch(text);
      if (modeleMatch != null && modeleMatch.groupCount >= 1) {
        result['modele'] = modeleMatch.group(1)!.trim();
      }
      
      // Recherche du numéro d'immatriculation (format tunisien)
      final immatRegex = RegExp(r'(\d{1,3})\s*(?:TUN|tunisie)\s*(\d{1,4})');
      final immatMatch = immatRegex.firstMatch(text);
      if (immatMatch != null && immatMatch.groupCount >= 2) {
        result['immatriculation'] = '${immatMatch.group(1)} TUN ${immatMatch.group(2)}';
      }
      
      // Recherche du numéro de série (VIN)
      final vinRegex = RegExp(r'(?:VIN|N Chassis|Numero de serie)[:\s]+([A-Z0-9]{17})');
      final vinMatch = vinRegex.firstMatch(text);
      if (vinMatch != null && vinMatch.groupCount >= 1) {
        result['numeroSerie'] = vinMatch.group(1)!.trim();
      }
      
      // Recherche de la date de première mise en circulation
      final dateMiseCirculationRegex = RegExp(r'(?:1ere mise en circulation|Date de 1ere mise en circulation)[:\s]*(\d{2}[/.-]\d{2}[/.-]\d{4})');
      final dateMiseCirculationMatch = dateMiseCirculationRegex.firstMatch(text);
      if (dateMiseCirculationMatch != null && dateMiseCirculationMatch.groupCount >= 1) {
        result['dateMiseCirculation'] = dateMiseCirculationMatch.group(1)!;
      }
      
      // Recherche du nom du propriétaire
      final proprietaireRegex = RegExp(r'(?:Proprietaire|Titulaire)[:\s]+([A-Za-z\s]+)');
      final proprietaireMatch = proprietaireRegex.firstMatch(text);
      if (proprietaireMatch != null && proprietaireMatch.groupCount >= 1) {
        result['proprietaire'] = proprietaireMatch.group(1)!.trim();
      }
    } catch (e) {
      _logger.e('Erreur lors de l\'analyse de la carte grise: $e');
    }
    
    return result;
  }

  // N'oubliez pas de libérer les ressources lorsque vous avez terminé
  void dispose() {
    _textRecognizer.close();
  }
}