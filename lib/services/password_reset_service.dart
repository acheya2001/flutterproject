import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 🔐 Service de réinitialisation de mot de passe pour les admins compagnie
class PasswordResetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔐 Générer un nouveau mot de passe sécurisé
  static String generateSecurePassword() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const String symbols = '@#!&*';
    final random = Random.secure();
    
    // Structure: @Assur + année + # + 5 chiffres + 2 lettres + !
    final year = DateTime.now().year;
    final numbers = List.generate(5, (_) => random.nextInt(10)).join();
    final letters = List.generate(2, (_) => chars[random.nextInt(chars.length)]).join();
    
    return '@Assur$year#$numbers$letters!';
  }

  /// 🔄 Réinitialiser le mot de passe d'un admin compagnie
  static Future<Map<String, dynamic>> resetAdminPassword({
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      debugPrint('[PASSWORD_RESET] 🔄 Début réinitialisation mot de passe');
      debugPrint('[PASSWORD_RESET] 👤 Admin ID: $adminId');
      debugPrint('[PASSWORD_RESET] 📧 Email: $adminEmail');

      // Vérifier que l'admin existe
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      
      if (!adminDoc.exists) {
        return {
          'success': false,
          'error': 'Admin non trouvé',
        };
      }

      final adminData = adminDoc.data()!;
      final role = adminData['role'] as String?;
      
      if (role != 'admin_compagnie') {
        return {
          'success': false,
          'error': 'Cet utilisateur n\'est pas un admin compagnie',
        };
      }

      // Générer un nouveau mot de passe
      final newPassword = generateSecurePassword();
      debugPrint('[PASSWORD_RESET] 🔐 Nouveau mot de passe généré');

      // Mettre à jour dans Firestore
      await _firestore.collection('users').doc(adminId).update({
        'password': newPassword,
        'temporaryPassword': newPassword,
        'requirePasswordChange': true,
        'passwordResetAt': FieldValue.serverTimestamp(),
        'passwordResetBy': 'super_admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[PASSWORD_RESET] ✅ Mot de passe mis à jour dans Firestore');

      // Optionnel: Mettre à jour dans Firebase Auth si l'utilisateur existe
      try {
        // Note: Cette partie nécessiterait des privilèges admin Firebase
        // Pour l'instant, on se contente de la mise à jour Firestore
        debugPrint('[PASSWORD_RESET] ℹ️ Mise à jour Firebase Auth non implémentée');
      } catch (e) {
        debugPrint('[PASSWORD_RESET] ⚠️ Erreur Firebase Auth: $e');
        // On continue car Firestore est mis à jour
      }

      return {
        'success': true,
        'newPassword': newPassword,
        'adminId': adminId,
        'adminEmail': adminEmail,
        'adminName': adminData['displayName'],
        'compagnieNom': adminData['compagnieNom'],
        'message': 'Mot de passe réinitialisé avec succès',
      };
    } catch (e) {
      debugPrint('[PASSWORD_RESET] ❌ Erreur réinitialisation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📊 Obtenir l'historique des réinitialisations
  static Future<List<Map<String, dynamic>>> getPasswordResetHistory({
    required String adminId,
  }) async {
    try {
      // Pour l'instant, on retourne juste les infos de base
      // On pourrait créer une collection séparée pour l'historique
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      
      if (!adminDoc.exists) return [];
      
      final data = adminDoc.data()!;
      final passwordResetAt = data['passwordResetAt'] as Timestamp?;
      final passwordResetBy = data['passwordResetBy'] as String?;
      
      if (passwordResetAt == null) return [];
      
      return [
        {
          'resetAt': passwordResetAt,
          'resetBy': passwordResetBy ?? 'Inconnu',
          'type': 'password_reset',
        }
      ];
    } catch (e) {
      debugPrint('[PASSWORD_RESET] ❌ Erreur historique: $e');
      return [];
    }
  }

  /// 🔍 Vérifier si un admin nécessite un changement de mot de passe
  static Future<bool> requiresPasswordChange(String adminId) async {
    try {
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      
      if (!adminDoc.exists) return false;
      
      final data = adminDoc.data()!;
      return data['requirePasswordChange'] == true;
    } catch (e) {
      debugPrint('[PASSWORD_RESET] ❌ Erreur vérification: $e');
      return false;
    }
  }

  /// 📧 Préparer les données pour l'envoi d'email
  static Map<String, dynamic> prepareEmailData({
    required String adminName,
    required String adminEmail,
    required String compagnieNom,
    required String newPassword,
  }) {
    return {
      'to': adminEmail,
      'subject': 'Réinitialisation de votre mot de passe - $compagnieNom',
      'htmlBody': '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Réinitialisation de mot de passe</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #059669, #047857); color: white; padding: 30px; border-radius: 10px; text-align: center;">
            <h1 style="margin: 0; font-size: 24px;">🔐 Réinitialisation de mot de passe</h1>
        </div>
        
        <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin: 20px 0;">
            <h2 style="color: #059669; margin-top: 0;">Bonjour $adminName,</h2>
            
            <p>Votre mot de passe pour l'accès à la plateforme <strong>$compagnieNom</strong> a été réinitialisé.</p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; border-left: 4px solid #059669; margin: 20px 0;">
                <h3 style="margin-top: 0; color: #059669;">🔑 Vos nouveaux identifiants :</h3>
                <p><strong>📧 Email :</strong> $adminEmail</p>
                <p><strong>🔐 Nouveau mot de passe :</strong> <code style="background: #f1f5f9; padding: 4px 8px; border-radius: 4px; font-family: monospace; font-size: 16px;">$newPassword</code></p>
            </div>
            
            <div style="background: #fef3c7; padding: 15px; border-radius: 8px; border-left: 4px solid #f59e0b; margin: 20px 0;">
                <h4 style="margin-top: 0; color: #92400e;">⚠️ Important :</h4>
                <ul style="margin: 0; color: #92400e;">
                    <li>Vous devrez changer ce mot de passe lors de votre première connexion</li>
                    <li>Conservez ces informations en lieu sûr</li>
                    <li>Ne partagez jamais vos identifiants</li>
                </ul>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="#" style="background: #059669; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; display: inline-block;">Se connecter</a>
            </div>
        </div>
        
        <div style="text-align: center; color: #6b7280; font-size: 12px;">
            <p>Cet email a été envoyé automatiquement. Ne pas répondre.</p>
            <p>© 2025 Constat Tunisie - Système de gestion des assurances</p>
        </div>
    </div>
</body>
</html>
      ''',
      'textBody': '''
Réinitialisation de mot de passe

Bonjour $adminName,

Votre mot de passe pour l'accès à la plateforme $compagnieNom a été réinitialisé.

Vos nouveaux identifiants :
Email : $adminEmail
Nouveau mot de passe : $newPassword

Important :
- Vous devrez changer ce mot de passe lors de votre première connexion
- Conservez ces informations en lieu sûr
- Ne partagez jamais vos identifiants

© 2025 Constat Tunisie
      ''',
    };
  }

  /// 📋 Obtenir la liste des admins compagnie pour réinitialisation
  static Future<List<Map<String, dynamic>>> getAdminsForPasswordReset() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();

      final admins = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': data['displayName'],
          'email': data['email'],
          'compagnieNom': data['compagnieNom'],
          'status': data['status'],
          'requirePasswordChange': data['requirePasswordChange'] ?? false,
          'lastPasswordReset': data['passwordResetAt'],
          'isActive': data['isActive'] ?? false,
        };
      }).toList();

      // Trier par nom en mémoire
      admins.sort((a, b) => (a['displayName'] ?? '').compareTo(b['displayName'] ?? ''));

      return admins;
    } catch (e) {
      debugPrint('[PASSWORD_RESET] ❌ Erreur liste admins: $e');
      return [];
    }
  }
}
