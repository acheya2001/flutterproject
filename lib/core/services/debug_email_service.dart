import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 🔍 Service d'email avec débuggage détaillé pour diagnostiquer les problèmes
class DebugEmailService {
  static const String _tag = '[DebugEmailService]';

  /// 📧 Envoie un email avec débuggage complet
  static Future<Map<String, dynamic>> sendEmailWithDebug({
    required String to,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    final debugInfo = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'to': to,
      'subject': subject,
      'htmlBodyLength': htmlBody.length,
      'textBodyLength': textBody?.length ?? 0,
      'steps': <String>[],
      'errors': <String>[],
      'success': false,
      'method': 'unknown',
    };

    try {
      debugPrint('$_tag ═══════════════════════════════════════');
      debugPrint('$_tag 🚀 DÉBUT ENVOI EMAIL AVEC DÉBUGGAGE');
      debugPrint('$_tag ═══════════════════════════════════════');
      debugPrint('$_tag 📧 Destinataire: $to');
      debugPrint('$_tag 📋 Sujet: $subject');
      debugPrint('$_tag 📄 Taille HTML: ${htmlBody.length} caractères');
      debugPrint('$_tag 📄 Taille Texte: ${textBody?.length ?? 0} caractères');
      debugPrint('$_tag ⏰ Timestamp: ${debugInfo['timestamp']}');

      debugInfo['steps'].add('Début du processus d\'envoi');

      // Étape 1: Validation de l'email
      debugPrint('$_tag ');
      debugPrint('$_tag 🔍 ÉTAPE 1: VALIDATION EMAIL');
      debugPrint('$_tag ─────────────────────────────────────');
      
      if (!_isValidEmail(to)) {
        final error = 'Format d\'email invalide: $to';
        debugInfo['errors'].add(error);
        debugPrint('$_tag ❌ $error');
        throw Exception(error);
      }
      
      debugPrint('$_tag ✅ Email valide: $to');
      debugInfo['steps'].add('Email validé');

      // Étape 2: Préparation du contenu
      debugPrint('$_tag ');
      debugPrint('$_tag 🔍 ÉTAPE 2: PRÉPARATION CONTENU');
      debugPrint('$_tag ─────────────────────────────────────');
      
      final finalTextBody = textBody ?? _htmlToText(htmlBody);
      debugPrint('$_tag 📝 Contenu texte préparé: ${finalTextBody.length} caractères');
      debugInfo['steps'].add('Contenu préparé');

      // Étape 3: Tentative d'envoi via différentes méthodes
      debugPrint('$_tag ');
      debugPrint('$_tag 🔍 ÉTAPE 3: TENTATIVES D\'ENVOI');
      debugPrint('$_tag ─────────────────────────────────────');

      // Méthode 1: URL Launcher (app email locale)
      final urlResult = await _tryUrlLauncher(to, subject, finalTextBody, debugInfo);
      if (urlResult['success']) {
        debugInfo['method'] = 'url_launcher';
        debugInfo['success'] = true;
        return debugInfo;
      }

      // Méthode 2: Webhook simple (si disponible)
      final webhookResult = await _tryWebhook(to, subject, htmlBody, finalTextBody, debugInfo);
      if (webhookResult['success']) {
        debugInfo['method'] = 'webhook';
        debugInfo['success'] = true;
        return debugInfo;
      }

      // Méthode 3: Affichage dans les logs (fallback)
      await _logEmailContent(to, subject, htmlBody, finalTextBody, debugInfo);
      debugInfo['method'] = 'log_display';
      debugInfo['success'] = true;

      return debugInfo;

    } catch (e) {
      debugPrint('$_tag ❌ ERREUR GÉNÉRALE: $e');
      debugInfo['errors'].add('Erreur générale: $e');
      debugInfo['success'] = false;
      return debugInfo;
    } finally {
      debugPrint('$_tag ');
      debugPrint('$_tag 📊 RÉSUMÉ FINAL');
      debugPrint('$_tag ─────────────────────────────────────');
      debugPrint('$_tag 🎯 Succès: ${debugInfo['success']}');
      debugPrint('$_tag 🔧 Méthode: ${debugInfo['method']}');
      debugPrint('$_tag 📝 Étapes: ${debugInfo['steps'].length}');
      debugPrint('$_tag ❌ Erreurs: ${debugInfo['errors'].length}');
      debugPrint('$_tag ═══════════════════════════════════════');
    }
  }

  /// 🔗 Tentative d'envoi via URL Launcher
  static Future<Map<String, dynamic>> _tryUrlLauncher(
    String to,
    String subject,
    String textBody,
    Map<String, dynamic> debugInfo,
  ) async {
    final result = <String, dynamic>{'success': false, 'error': null};

    try {
      debugPrint('$_tag 🔗 Tentative URL Launcher...');
      debugInfo['steps'].add('Tentative URL Launcher');

      // Encoder les paramètres pour l'URL
      final encodedSubject = Uri.encodeComponent(subject);
      final encodedBody = Uri.encodeComponent(textBody);
      
      final emailUrl = 'mailto:$to?subject=$encodedSubject&body=$encodedBody';
      debugPrint('$_tag 🔗 URL générée: ${emailUrl.substring(0, 100)}...');

      final uri = Uri.parse(emailUrl);
      
      // Vérifier si l'URL peut être lancée
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('$_tag 🔍 Peut lancer URL: $canLaunch');

      if (canLaunch) {
        await launchUrl(uri);
        debugPrint('$_tag ✅ URL Launcher réussi');
        debugInfo['steps'].add('URL Launcher réussi');
        result['success'] = true;
      } else {
        const error = 'Impossible de lancer l\'URL mailto';
        debugPrint('$_tag ❌ $error');
        debugInfo['errors'].add(error);
        result['error'] = error;
      }

    } catch (e) {
      final error = 'Erreur URL Launcher: $e';
      debugPrint('$_tag ❌ $error');
      debugInfo['errors'].add(error);
      result['error'] = error;
    }

    return result;
  }

  /// 🌐 Tentative d'envoi via Webhook
  static Future<Map<String, dynamic>> _tryWebhook(
    String to,
    String subject,
    String htmlBody,
    String textBody,
    Map<String, dynamic> debugInfo,
  ) async {
    final result = <String, dynamic>{'success': false, 'error': null};

    try {
      debugPrint('$_tag 🌐 Tentative Webhook...');
      debugInfo['steps'].add('Tentative Webhook');

      // URL de test webhook (remplacer par votre webhook réel)
      const webhookUrl = 'https://httpbin.org/post'; // Service de test

      final payload = {
        'to': to,
        'subject': subject,
        'html': htmlBody,
        'text': textBody,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'constat_tunisie_app',
      };

      debugPrint('$_tag 📤 Envoi vers: $webhookUrl');
      debugPrint('$_tag 📦 Payload: ${payload.keys.join(', ')}');

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'ConstatTunisie/1.0',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 10));

      debugPrint('$_tag 📨 Réponse HTTP: ${response.statusCode}');
      debugPrint('$_tag 📄 Corps réponse: ${response.body.substring(0, 200)}...');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('$_tag ✅ Webhook réussi');
        debugInfo['steps'].add('Webhook réussi');
        result['success'] = true;
      } else {
        final error = 'Webhook échec: ${response.statusCode}';
        debugPrint('$_tag ❌ $error');
        debugInfo['errors'].add(error);
        result['error'] = error;
      }

    } catch (e) {
      final error = 'Erreur Webhook: $e';
      debugPrint('$_tag ❌ $error');
      debugInfo['errors'].add(error);
      result['error'] = error;
    }

    return result;
  }

  /// 📋 Affichage du contenu email dans les logs (fallback)
  static Future<void> _logEmailContent(
    String to,
    String subject,
    String htmlBody,
    String textBody,
    Map<String, dynamic> debugInfo,
  ) async {
    debugPrint('$_tag 📋 Affichage dans les logs (fallback)...');
    debugInfo['steps'].add('Affichage logs');

    debugPrint('$_tag ');
    debugPrint('$_tag ╔══════════════════════════════════════════════════════════╗');
    debugPrint('$_tag ║                    📧 EMAIL GÉNÉRÉ                       ║');
    debugPrint('$_tag ╠══════════════════════════════════════════════════════════╣');
    debugPrint('$_tag ║ 📧 DESTINATAIRE: $to');
    debugPrint('$_tag ║ 📋 SUJET: $subject');
    debugPrint('$_tag ╠══════════════════════════════════════════════════════════╣');
    debugPrint('$_tag ║ 📄 CONTENU TEXTE:');
    
    // Afficher le contenu par lignes
    final lines = textBody.split('\n');
    for (int i = 0; i < lines.length && i < 20; i++) {
      debugPrint('$_tag ║ ${lines[i]}');
    }
    if (lines.length > 20) {
      debugPrint('$_tag ║ ... (${lines.length - 20} lignes supplémentaires)');
    }
    
    debugPrint('$_tag ╠══════════════════════════════════════════════════════════╣');
    debugPrint('$_tag ║ 🌐 CONTENU HTML: ${htmlBody.length} caractères');
    debugPrint('$_tag ╚══════════════════════════════════════════════════════════╝');
    debugPrint('$_tag ');
  }

  /// 🔍 Validation de l'email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// 📝 Conversion HTML vers texte simple
  static String _htmlToText(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Supprimer toutes les balises HTML
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Nettoyer les lignes vides multiples
        .trim();
  }

  /// 📊 Obtenir les statistiques d'envoi
  static Map<String, dynamic> getEmailStats() {
    return {
      'service': 'DebugEmailService',
      'version': '1.0.0',
      'methods': ['url_launcher', 'webhook', 'log_display'],
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 🧪 Test de connectivité email
  static Future<Map<String, dynamic>> testEmailConnectivity() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
    };

    debugPrint('$_tag 🧪 TEST DE CONNECTIVITÉ EMAIL');
    debugPrint('$_tag ═══════════════════════════════════════');

    // Test 1: URL Launcher
    try {
      final testUri = Uri.parse('mailto:test@example.com');
      final canLaunch = await canLaunchUrl(testUri);
      results['tests']['url_launcher'] = {
        'available': canLaunch,
        'error': null,
      };
      debugPrint('$_tag ✅ URL Launcher: $canLaunch');
    } catch (e) {
      results['tests']['url_launcher'] = {
        'available': false,
        'error': e.toString(),
      };
      debugPrint('$_tag ❌ URL Launcher: $e');
    }

    // Test 2: HTTP (pour webhook)
    try {
      final response = await http.get(
        Uri.parse('https://httpbin.org/status/200'),
      ).timeout(const Duration(seconds: 5));
      
      results['tests']['http'] = {
        'available': response.statusCode == 200,
        'status_code': response.statusCode,
        'error': null,
      };
      debugPrint('$_tag ✅ HTTP: ${response.statusCode}');
    } catch (e) {
      results['tests']['http'] = {
        'available': false,
        'error': e.toString(),
      };
      debugPrint('$_tag ❌ HTTP: $e');
    }

    debugPrint('$_tag ═══════════════════════════════════════');
    return results;
  }
}
