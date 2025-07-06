import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailValidationService {
  // API pour vérifier si un email existe (exemple avec AbstractAPI)
  static const String _apiKey = 'YOUR_API_KEY'; // Remplacez par votre vraie clé API
  static const String _baseUrl = 'https://emailvalidation.abstractapi.com/v1/';

  /// Vérifie si un email existe réellement
  /// Retourne true si l'email est valide et existe
  static Future<EmailValidationResult> validateEmail(String email) async {
    try {
      debugPrint('[EmailValidation] Validation de l\'email: $email');
      
      // Validation basique du format
      if (!_isValidEmailFormat(email)) {
        return EmailValidationResult(
          isValid: false,
          exists: false,
          error: 'Format d\'email invalide',
        );
      }

      // En mode debug, on peut simuler la validation
      if (kDebugMode) {
        return _simulateEmailValidation(email);
      }

      // Appel API réel pour vérifier l'existence de l'email
      final response = await http.get(
        Uri.parse('$_baseUrl?api_key=$_apiKey&email=$email'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return EmailValidationResult(
          isValid: data['is_valid_format']['value'] == true,
          exists: data['deliverability'] == 'DELIVERABLE',
          error: null,
          details: data,
        );
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[EmailValidation] Erreur: $e');
      return EmailValidationResult(
        isValid: false,
        exists: false,
        error: 'Impossible de vérifier l\'email: $e',
      );
    }
  }

  /// Validation basique du format email
  static bool _isValidEmailFormat(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Simulation pour le développement - ACCEPTE TOUS LES EMAILS VALIDES
  static EmailValidationResult _simulateEmailValidation(String email) {
    debugPrint('[EmailValidation] Mode simulation - validation de: $email');

    // En mode développement, on accepte tous les emails avec un format valide
    // Cela évite de bloquer l'envoi d'emails pour des raisons de validation
    if (_isValidEmailFormat(email)) {
      debugPrint('[EmailValidation] ✅ Email accepté: $email');
      return EmailValidationResult(
        isValid: true,
        exists: true, // On assume que l'email existe
        error: null,
      );
    } else {
      debugPrint('[EmailValidation] ❌ Format invalide: $email');
      return EmailValidationResult(
        isValid: false,
        exists: false,
        error: 'Format d\'email invalide',
      );
    }
  }

  /// Valide une liste d'emails
  static Future<Map<String, EmailValidationResult>> validateEmails(List<String> emails) async {
    Map<String, EmailValidationResult> results = {};
    
    for (String email in emails) {
      if (email.trim().isNotEmpty) {
        results[email] = await validateEmail(email.trim());
        // Petit délai pour éviter de surcharger l'API
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    return results;
  }
}

class EmailValidationResult {
  final bool isValid;
  final bool exists;
  final String? error;
  final Map<String, dynamic>? details;

  EmailValidationResult({
    required this.isValid,
    required this.exists,
    this.error,
    this.details,
  });

  bool get isValidAndExists => isValid && exists && error == null;

  @override
  String toString() {
    return 'EmailValidationResult(isValid: $isValid, exists: $exists, error: $error)';
  }
}
