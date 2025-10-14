import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../core/config/app_config.dart';

/// 📄 Service spécialisé pour l'upload de PDFs vers Cloudinary
class CloudinaryPdfService {
  static const String _tag = 'CloudinaryPDF';

  /// 📤 Upload un PDF vers Cloudinary
  static Future<String> uploadPdf({
    required Uint8List pdfBytes,
    required String fileName,
    required String sessionId,
    String folder = 'constats_pdf',
  }) async {
    try {
      print('🌐 [$_tag] Début upload PDF vers Cloudinary...');
      print('🌐 [$_tag] Fichier: $fileName');
      print('🌐 [$_tag] Taille: ${pdfBytes.length} bytes');

      // Générer signature et timestamp
      final now = DateTime.now();
      final timestamp = (now.millisecondsSinceEpoch ~/ 1000).toString(); // Timestamp en secondes
      final publicId = '${sessionId}_${now.millisecondsSinceEpoch}';

      print('🔐 [$_tag] Timestamp: $timestamp');
      print('🔐 [$_tag] Public ID: $publicId');
      print('🔐 [$_tag] Folder: $folder');

      final signature = _generateSignature(timestamp, folder, publicId);

      // Préparer la requête multipart
      final cloudName = _getCloudinaryCloudName();
      final apiKey = _getCloudinaryApiKey();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload')
      );

      // Ajouter les paramètres
      request.fields.addAll({
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
        'public_id': publicId,
        'resource_type': 'raw', // Important pour les PDFs
        'format': 'pdf',
      });

      // Ajouter le fichier PDF
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
        ),
      );

      print('📤 [$_tag] Envoi vers Cloudinary...');
      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Timeout upload PDF'),
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        final pdfUrl = jsonResponse['secure_url'] as String;

        print('✅ [$_tag] PDF uploadé avec succès: $pdfUrl');
        print('✅ [$_tag] Public ID: ${jsonResponse['public_id']}');
        print('✅ [$_tag] Response complète: $jsonResponse');

        return pdfUrl;
      } else {
        print('❌ [$_tag] Erreur upload: ${response.statusCode}');
        print('❌ [$_tag] Response: $responseBody');
        throw Exception('Erreur upload Cloudinary: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ [$_tag] Exception upload PDF: $e');
      rethrow;
    }
  }

  /// 📤 Upload un fichier PDF depuis le système de fichiers
  static Future<String> uploadPdfFile({
    required File pdfFile,
    required String sessionId,
    String folder = 'constats_pdf',
  }) async {
    try {
      final pdfBytes = await pdfFile.readAsBytes();
      final fileName = pdfFile.path.split('/').last;
      
      return await uploadPdf(
        pdfBytes: pdfBytes,
        fileName: fileName,
        sessionId: sessionId,
        folder: folder,
      );
    } catch (e) {
      print('❌ [$_tag] Erreur lecture fichier PDF: $e');
      rethrow;
    }
  }

  /// 🔐 Générer signature pour Cloudinary
  static String _generateSignature(String timestamp, String folder, String publicId) {
    // ✅ CORRECTION: Utiliser exactement les paramètres que Cloudinary attend
    final params = <String, String>{
      'folder': folder,
      'format': 'pdf',
      'public_id': publicId,
      'timestamp': timestamp,
    };

    // Trier les paramètres par clé alphabétique
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Ajouter le secret (avec fallback)
    final apiSecret = _getCloudinaryApiSecret();
    final stringToSign = '$paramString$apiSecret';

    print('🔐 [CloudinaryPDF] String to sign: $stringToSign');

    // Générer SHA1
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    print('🔐 [CloudinaryPDF] Signature générée: ${digest.toString()}');
    return digest.toString();
  }

  /// 🗑️ Supprimer un PDF de Cloudinary
  static Future<bool> deletePdf(String publicId) async {
    try {
      print('🗑️ [$_tag] Suppression PDF: $publicId');

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final signature = _generateDeleteSignature(timestamp, publicId);

      final cloudName = _getCloudinaryCloudName();
      final apiKey = _getCloudinaryApiKey();

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/destroy'),
        body: {
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
          'public_id': publicId,
          'resource_type': 'raw',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout suppression PDF'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final success = jsonResponse['result'] == 'ok';
        
        if (success) {
          print('✅ [$_tag] PDF supprimé avec succès');
        } else {
          print('⚠️ [$_tag] Échec suppression: ${jsonResponse['result']}');
        }
        
        return success;
      } else {
        print('❌ [$_tag] Erreur suppression: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      print('❌ [$_tag] Exception suppression PDF: $e');
      return false;
    }
  }

  /// 🔐 Générer signature pour la suppression
  static String _generateDeleteSignature(String timestamp, String publicId) {
    final params = <String, String>{
      'public_id': publicId,
      'resource_type': 'raw',
      'timestamp': timestamp,
    };

    // Trier les paramètres par clé alphabétique
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    final apiSecret = _getCloudinaryApiSecret();
    final stringToSign = '$paramString$apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// 🔍 Extraire le public_id depuis une URL Cloudinary
  static String? extractPublicIdFromUrl(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      
      // Format URL Cloudinary: https://res.cloudinary.com/cloud/raw/upload/v123456/folder/file.pdf
      if (pathSegments.length >= 4 && pathSegments.contains('raw')) {
        final startIndex = pathSegments.indexOf('upload') + 2; // Skip 'upload' et version
        final publicIdParts = pathSegments.sublist(startIndex);
        final publicId = publicIdParts.join('/').split('.').first;
        return publicId;
      }
      
      return null;
    } catch (e) {
      print('❌ [$_tag] Erreur extraction public_id: $e');
      return null;
    }
  }

  /// ✅ Vérifier si une URL est une URL Cloudinary valide
  static bool isCloudinaryUrl(String url) {
    return url.contains('cloudinary.com') && 
           (url.contains('/raw/upload/') || url.contains('/image/upload/'));
  }

  /// 📊 Obtenir les informations d'un PDF sur Cloudinary
  static Future<Map<String, dynamic>?> getPdfInfo(String publicId) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final signature = _generateInfoSignature(timestamp, publicId);

      final cloudName = _getCloudinaryCloudName();
      final apiKey = _getCloudinaryApiKey();

      final response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/resources/raw/$publicId')
            .replace(queryParameters: {
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return null;
    } catch (e) {
      print('❌ [$_tag] Erreur récupération info PDF: $e');
      return null;
    }
  }

  /// 🔐 Générer signature pour récupérer les infos
  static String _generateInfoSignature(String timestamp, String publicId) {
    final params = <String, String>{
      'public_id': publicId,
      'timestamp': timestamp,
    };

    // Trier les paramètres par clé alphabétique
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    final apiSecret = _getCloudinaryApiSecret();
    final stringToSign = '$paramString$apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// 🔗 Générer URL signée pour accès direct au PDF
  static String generateSignedUrl(String publicId, {int expirationHours = 24}) {
    try {
      final cloudName = _getCloudinaryCloudName();

      // Pour les ressources publiques, essayons d'abord sans signature
      // Cloudinary permet l'accès direct aux ressources publiques
      final publicUrl = 'https://res.cloudinary.com/$cloudName/raw/upload/$publicId.pdf';

      print('🔗 [$_tag] URL publique générée: $publicUrl');
      return publicUrl;

    } catch (e) {
      print('❌ [$_tag] Erreur génération URL: $e');
      // Fallback vers URL de base
      final cloudName = _getCloudinaryCloudName();
      return 'https://res.cloudinary.com/$cloudName/raw/upload/$publicId.pdf';
    }
  }

  /// 🔗 Générer URL signée avec authentification (si nécessaire)
  static String generateAuthenticatedUrl(String publicId, {int expirationHours = 24}) {
    try {
      final cloudName = _getCloudinaryCloudName();
      final apiSecret = _getCloudinaryApiSecret();
      final apiKey = _getCloudinaryApiKey();

      // Calculer l'expiration (timestamp en secondes)
      final expiration = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + (expirationHours * 3600);

      // Pour l'accès authentifié aux ressources raw
      final params = <String, String>{
        'api_key': apiKey,
        'public_id': publicId,
        'resource_type': 'raw',
        'timestamp': expiration.toString(),
      };

      // Trier les paramètres par clé alphabétique
      final sortedKeys = params.keys.toList()..sort();
      final paramString = sortedKeys
          .map((key) => '$key=${params[key]}')
          .join('&');

      // Générer la signature
      final stringToSign = '$paramString$apiSecret';
      final bytes = utf8.encode(stringToSign);
      final signature = sha1.convert(bytes).toString();

      // Construire l'URL signée avec authentification
      final authenticatedUrl = 'https://res.cloudinary.com/$cloudName/raw/upload/$publicId.pdf'
          '?api_key=$apiKey&timestamp=$expiration&signature=$signature';

      print('🔐 [$_tag] URL authentifiée générée: $authenticatedUrl');
      return authenticatedUrl;

    } catch (e) {
      print('❌ [$_tag] Erreur génération URL authentifiée: $e');
      // Fallback vers URL publique
      return generateSignedUrl(publicId, expirationHours: expirationHours);
    }
  }

  /// 📥 Télécharger un PDF depuis Cloudinary avec plusieurs méthodes
  static Future<Uint8List?> downloadPdfWithAuth(String publicId) async {
    try {
      print('📥 [$_tag] Téléchargement PDF: $publicId');

      final cloudName = _getCloudinaryCloudName();

      // Méthode 1: Essayer avec URL de téléchargement signée
      try {
        final downloadUrl = generateDownloadUrl(publicId);
        print('🔗 [$_tag] Tentative URL signée: $downloadUrl');

        final response = await http.get(Uri.parse(downloadUrl));

        if (response.statusCode == 200) {
          print('✅ [$_tag] PDF téléchargé via URL signée (${response.bodyBytes.length} bytes)');
          return response.bodyBytes;
        } else {
          print('⚠️ [$_tag] URL signée échouée: ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ [$_tag] Erreur URL signée: $e');
      }

      // Méthode 2: Essayer l'URL publique directe (sans authentification)
      final publicUrls = [
        'https://res.cloudinary.com/$cloudName/raw/upload/$publicId.pdf',
        'https://res.cloudinary.com/$cloudName/image/upload/$publicId.pdf',
        'https://res.cloudinary.com/$cloudName/raw/upload/v1/$publicId.pdf',
      ];

      for (final url in publicUrls) {
        try {
          print('🔗 [$_tag] Tentative URL publique: $url');
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            print('✅ [$_tag] PDF téléchargé via URL publique (${response.bodyBytes.length} bytes)');
            return response.bodyBytes;
          } else {
            print('⚠️ [$_tag] URL publique échouée: ${response.statusCode}');
          }
        } catch (e) {
          print('⚠️ [$_tag] Erreur URL publique: $e');
        }
      }

      // Méthode 3: Essayer avec authentification API
      try {
        final apiKey = _getCloudinaryApiKey();
        final apiSecret = _getCloudinaryApiSecret();

        // Générer signature pour l'accès
        final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
        final signature = _generateInfoSignature(timestamp, publicId);

        // URL de l'API Cloudinary pour récupérer la ressource
        final apiUrl = 'https://api.cloudinary.com/v1_1/$cloudName/resources/raw/$publicId';

        print('🔐 [$_tag] Tentative avec authentification: $apiUrl');

        // Faire la requête avec authentification
        final response = await http.get(
          Uri.parse(apiUrl).replace(queryParameters: {
            'api_key': apiKey,
            'timestamp': timestamp,
            'signature': signature,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final secureUrl = data['secure_url'] as String?;

          if (secureUrl != null) {
            print('✅ [$_tag] URL sécurisée obtenue: $secureUrl');

            // Télécharger le fichier depuis l'URL sécurisée
            final fileResponse = await http.get(Uri.parse(secureUrl));

            if (fileResponse.statusCode == 200) {
              print('✅ [$_tag] PDF téléchargé avec auth (${fileResponse.bodyBytes.length} bytes)');
              return fileResponse.bodyBytes;
            }
          }
        } else {
          print('❌ [$_tag] Erreur API Cloudinary: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('⚠️ [$_tag] Authentification échouée: $e');
      }

      print('❌ [$_tag] Toutes les méthodes de téléchargement ont échoué');
      return null;

    } catch (e) {
      print('❌ [$_tag] Erreur générale téléchargement: $e');
      return null;
    }
  }

  /// 🔗 Obtenir la meilleure URL pour accéder au PDF
  static String getBestAccessUrl(String publicId) {
    try {
      final cloudName = _getCloudinaryCloudName();

      // Essayer plusieurs formats d'URL
      final urls = [
        // 1. URL publique directe (la plus simple)
        'https://res.cloudinary.com/$cloudName/raw/upload/$publicId.pdf',

        // 2. URL avec version (si le publicId contient déjà le dossier)
        'https://res.cloudinary.com/$cloudName/raw/upload/v1/$publicId.pdf',

        // 3. URL sans extension (Cloudinary peut l'ajouter automatiquement)
        'https://res.cloudinary.com/$cloudName/raw/upload/$publicId',
      ];

      print('🔗 [$_tag] URLs candidates pour $publicId:');
      for (int i = 0; i < urls.length; i++) {
        print('   ${i + 1}. ${urls[i]}');
      }

      // Retourner la première URL (la plus probable)
      return urls[0];

    } catch (e) {
      print('❌ [$_tag] Erreur génération URL optimale: $e');
      final cloudName = _getCloudinaryCloudName();
      return 'https://res.cloudinary.com/$cloudName/raw/upload/$publicId.pdf';
    }
  }

  /// 🔗 Générer URL de téléchargement avec signature valide
  static String generateDownloadUrl(String publicId) {
    try {
      final cloudName = _getCloudinaryCloudName();
      final apiKey = _getCloudinaryApiKey();
      final apiSecret = _getCloudinaryApiSecret();

      // Timestamp actuel (valide pour 1 heure)
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      // Paramètres pour la signature de téléchargement
      final params = <String, String>{
        'public_id': publicId,
        'resource_type': 'raw',
        'timestamp': timestamp.toString(),
        'type': 'upload',
      };

      // Trier les paramètres par clé alphabétique
      final sortedKeys = params.keys.toList()..sort();
      final paramString = sortedKeys
          .map((key) => '$key=${params[key]}')
          .join('&');

      // Générer la signature
      final stringToSign = '$paramString$apiSecret';
      final bytes = utf8.encode(stringToSign);
      final signature = sha1.convert(bytes).toString();

      // Construire l'URL de téléchargement avec signature
      final downloadUrl = 'https://res.cloudinary.com/$cloudName/raw/upload/$publicId.pdf'
          '?api_key=$apiKey&timestamp=$timestamp&signature=$signature';

      print('🔗 [$_tag] URL de téléchargement générée: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      print('❌ [$_tag] Erreur génération URL téléchargement: $e');
      // Fallback vers URL publique
      final cloudName = _getCloudinaryCloudName();
      return 'https://res.cloudinary.com/$cloudName/raw/upload/$publicId.pdf';
    }
  }

  /// 🌐 Générer URL publique alternative (sans authentification)
  static String generatePublicUrl(String publicId) {
    final cloudName = _getCloudinaryCloudName();

    // Essayer différents formats d'URL publique
    final urls = [
      'https://res.cloudinary.com/$cloudName/raw/upload/fl_attachment/$publicId.pdf',
      'https://res.cloudinary.com/$cloudName/image/upload/fl_attachment/$publicId.pdf',
      'https://res.cloudinary.com/$cloudName/raw/upload/fl_attachment:$publicId/$publicId.pdf',
      'https://res.cloudinary.com/$cloudName/raw/upload/v1/$publicId.pdf',
    ];

    print('🌐 [$_tag] URLs publiques générées pour $publicId:');
    for (int i = 0; i < urls.length; i++) {
      print('   ${i + 1}. ${urls[i]}');
    }

    return urls.first; // Retourner la première URL pour test
  }

  /// 🔧 Méthodes utilitaires avec fallback
  static String _getCloudinaryCloudName() {
    // Utiliser directement la valeur par défaut pour éviter les erreurs d'initialisation
    return 'dgw530dou';
  }

  static String _getCloudinaryApiKey() {
    // Utiliser directement la valeur par défaut pour éviter les erreurs d'initialisation
    return '238965196817439';
  }

  static String _getCloudinaryApiSecret() {
    // Utiliser directement la valeur par défaut pour éviter les erreurs d'initialisation
    return 'UEjPyY-6993xQnAhz8RCvgMYYLM';
  }

  /// 🧪 Test de configuration Cloudinary
  static Map<String, dynamic> testConfiguration() {
    final cloudName = _getCloudinaryCloudName();
    final apiKey = _getCloudinaryApiKey();
    final apiSecret = _getCloudinaryApiSecret();

    return {
      'cloudName': cloudName,
      'apiKey': apiKey.substring(0, 6) + '***', // Masquer la clé
      'apiSecret': apiSecret.substring(0, 6) + '***', // Masquer le secret
      'configured': cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty,
    };
  }
}
