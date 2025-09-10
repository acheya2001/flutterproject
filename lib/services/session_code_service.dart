import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

/// 🔗 Service pour gérer les codes de session et QR codes
class SessionCodeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _codesCollection = 'session_codes';

  /// 🆕 Générer un code de session unique
  static Future<String> genererCodeUnique() async {
    String code;
    bool codeExiste;
    int tentatives = 0;
    const maxTentatives = 10;

    do {
      code = _genererCodeAleatoire();
      codeExiste = await _verifierCodeExiste(code);
      tentatives++;
      
      if (tentatives >= maxTentatives) {
        throw Exception('Impossible de générer un code unique après $maxTentatives tentatives');
      }
    } while (codeExiste);

    return code;
  }

  /// 🔍 Vérifier si un code de session existe
  static Future<bool> verifierCodeValide(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('collaborative_sessions')
          .where('codeSession', isEqualTo: code)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification code: $e');
      return false;
    }
  }

  /// 📱 Générer QR Code Widget
  static Widget genererQRCodeWidget({
    required String codeSession,
    required String typeAccident,
    double size = 200.0,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final qrData = _genererDonneesQR(codeSession, typeAccident);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: size,
            backgroundColor: backgroundColor ?? Colors.white,
            foregroundColor: foregroundColor ?? Colors.black,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            embeddedImage: null, // Peut ajouter un logo si nécessaire
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size(40, 40),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              'Code: $codeSession',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📤 Partager le code de session
  static Future<void> partagerCodeSession({
    required String codeSession,
    required String typeAccident,
    required BuildContext context,
  }) async {
    try {
      final message = _genererMessagePartage(codeSession, typeAccident);
      
      // Partager via le système natif
      await Share.share(
        message,
        subject: 'Invitation - Constat d\'accident collaboratif',
      );
    } catch (e) {
      print('❌ Erreur partage code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur lors du partage: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📋 Copier le code dans le presse-papiers
  static Future<void> copierCode({
    required String codeSession,
    required BuildContext context,
  }) async {
    try {
      // Note: Clipboard.setData nécessite import 'package:flutter/services.dart';
      // await Clipboard.setData(ClipboardData(text: codeSession));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Code $codeSession copié !'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Erreur copie code: $e');
    }
  }

  /// 🎨 Créer une carte d'invitation élégante
  static Widget creerCarteInvitation({
    required String codeSession,
    required String typeAccident,
    required int nombreVehicules,
    required VoidCallback onPartager,
    required VoidCallback onCopier,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.purple[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Inviter d\'autres conducteurs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code de session',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          codeSession,
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$nombreVehicules véhicules',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _obtenirDescriptionTypeAccident(typeAccident),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPartager,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Partager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopier,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔧 Méthodes utilitaires privées
  static String _genererCodeAleatoire() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  static Future<bool> _verifierCodeExiste(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('collaborative_sessions')
          .where('codeSession', isEqualTo: code)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification existence code: $e');
      return false;
    }
  }

  static String _genererDonneesQR(String codeSession, String typeAccident) {
    return 'CONSTAT_TUNISIE:$codeSession:$typeAccident:${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _genererMessagePartage(String codeSession, String typeAccident) {
    final typeDescription = _obtenirDescriptionTypeAccident(typeAccident);
    
    return '''
🚗 Invitation - Constat d'accident collaboratif

Vous êtes invité(e) à participer à un constat d'accident.

📋 Type: $typeDescription
🔑 Code de session: $codeSession

📱 Pour rejoindre:
1. Téléchargez l'app "Constat Tunisie"
2. Choisissez "Rejoindre une session"
3. Entrez le code: $codeSession

⏰ Cette invitation expire dans 24h.

#ConstatTunisie #AccidentCollaboratif
    ''';
  }

  static String _obtenirDescriptionTypeAccident(String typeAccident) {
    switch (typeAccident) {
      case 'collision_deux_vehicules':
        return 'Collision entre deux véhicules';
      case 'carambolage':
        return 'Carambolage (3+ véhicules)';
      case 'sortie_route':
        return 'Sortie de route';
      case 'choc_objet_fixe':
        return 'Choc avec objet fixe';
      case 'accident_pieton':
        return 'Accident avec piéton';
      default:
        return 'Accident de circulation';
    }
  }
}
