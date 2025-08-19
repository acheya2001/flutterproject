import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 📧 Service d'envoi d'emails pour les agents
class AgentEmailService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Configuration Gmail OAuth2 (vos vraies clés)
  static const String _refreshToken = '1//04fqCR47aG8PuCgYIARAAGAQSNwF-L9IrbmVfT1Ip925nf40rYtGez0sw_fJH341WZM9UHDhdWnkShe5AONoFyep4P6lS2E1VsFw';
  static const String _clientId = '1059917372502-bcja6qd5feh9rpndg3klveh1pcihruj5.apps.googleusercontent.com';
  static const String _clientSecret = 'GOCSPX-your-client-secret'; // À remplacer par votre vraie clé
  static const String _senderEmail = 'constat.tunisie.app@gmail.com';

  /// 🔑 Générer un mot de passe sécurisé
  static String generateSecurePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 📧 Créer un agent avec la méthode alternative (comme les admins)
  static Future<Map<String, dynamic>> createAgentWithEmail({
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required String agenceId,
    required String compagnieId,
    required String adminAgenceId,
  }) async {
    try {
      debugPrint('🚀 Début création agent (méthode alternative): $email');

      // 1. Vérifier si l'email existe déjà
      final existingUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Email déjà utilisé',
          'message': 'Cette adresse email est déjà utilisée par un autre utilisateur',
        };
      }

      // 2. Générer mot de passe sécurisé
      final password = generateSecurePassword();
      debugPrint('🔑 Mot de passe généré');

      // 3. Générer un UID unique (comme pour les admins)
      final userId = _firestore.collection('users').doc().id;
      debugPrint('🆔 UID généré: $userId');

      // 4. Récupérer infos agence et compagnie
      debugPrint('📋 Récupération infos agence: $agenceId');
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();

      debugPrint('📋 Récupération infos compagnie: $compagnieId');
      final compagnieDoc = await _firestore.collection('compagnies').doc(compagnieId).get();

      final agenceNom = agenceDoc.exists ? agenceDoc.data()!['nom'] ?? 'Agence' : 'Agence';
      final compagnieNom = compagnieDoc.exists ? compagnieDoc.data()!['nom'] ?? 'Compagnie' : 'Compagnie';

      debugPrint('🏪 Agence trouvée: $agenceNom');
      debugPrint('🏢 Compagnie trouvée: $compagnieNom');

      // 5. Créer le profil agent directement dans Firestore (méthode alternative)
      try {
        debugPrint('📝 Création profil agent dans Firestore (méthode alternative)...');

        final userData = {
          'uid': userId,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'displayName': '$prenom $nom',
          'telephone': telephone,
          'role': 'agent',
          'agenceId': agenceId,
          'agenceNom': agenceNom,
          'compagnieId': compagnieId,
          'compagnieNom': compagnieNom,
          'isActive': true,
          'status': 'actif',
          'firebaseAuthCreated': false, // Sera créé lors de la première connexion
          'password': password, // Stocké pour référence (comme les admins)
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'origin': 'admin_agence_creation',
          'createdBy': 'admin_agence',
          'createdByRole': 'admin_agence',
          'creationMethod': 'alternative', // Marquer comme création alternative
          'lastLogin': null,
          'isFirstLogin': true,
          'nombreConstats': 0,
          'dernierConstAt': null,
        };

        await _firestore.collection('users').doc(userId).set(userData);
        debugPrint('✅ Profil agent créé dans Firestore (méthode alternative)');

      } catch (firestoreError) {
        debugPrint('❌ Erreur création profil Firestore: $firestoreError');
        return {
          'success': false,
          'error': 'Erreur création profil: $firestoreError',
          'message': 'Impossible de créer le profil agent dans Firestore',
        };
      }

      // 6. Mettre à jour le compteur d'agents dans l'agence
      try {
        await _firestore.collection('agences').doc(agenceId).update({
          'nombreAgents': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Compteur agence mis à jour');
      } catch (e) {
        debugPrint('⚠️ Erreur mise à jour compteur agence: $e');
      }

      // 7. Enregistrer dans les logs
      await _firestore.collection('email_logs').add({
        'destinataire': email,
        'type': 'creation_agent_alternative',
        'statut': 'cree_sans_email',
        'agentId': userId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'sentAt': FieldValue.serverTimestamp(),
        'message': 'Agent créé avec méthode alternative - Firebase Auth sera créé lors de la première connexion',
      });

      debugPrint('✅ Agent créé avec succès (méthode alternative)');

      return {
        'success': true,
        'agentId': userId,
        'email': email,
        'password': password,
        'emailSent': false,
        'message': 'Agent créé avec succès. Mot de passe: $password',
        'note': 'Le compte Firebase Auth sera créé automatiquement lors de la première connexion.',
        'creationMethod': 'alternative',
      };
    } catch (e) {
      debugPrint('❌ Erreur création agent: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'agent',
      };
    }
  }

  /// 📧 Envoyer email de bienvenue avec identifiants
  static Future<bool> _sendWelcomeEmail({
    required String email,
    required String nom,
    required String prenom,
    required String password,
    required String agenceNom,
    required String compagnieNom,
  }) async {
    try {
      // 1. Obtenir token d'accès
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ Impossible d\'obtenir le token d\'accès');
        return false;
      }

      // 2. Construire l'email HTML
      final htmlContent = _buildWelcomeEmailHTML(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
        agenceNom: agenceNom,
        compagnieNom: compagnieNom,
      );

      // 3. Préparer l'email
      final emailData = {
        'raw': base64Url.encode(utf8.encode(
          'To: $email\r\n'
          'From: $_senderEmail\r\n'
          'Subject: =?UTF-8?B?${base64.encode(utf8.encode('🎉 Bienvenue dans votre espace Agent - Constat Tunisie'))}?=\r\n'
          'Content-Type: text/html; charset=UTF-8\r\n'
          'Content-Transfer-Encoding: base64\r\n'
          '\r\n'
          '$htmlContent'
        ))
      };

      // 4. Envoyer via Gmail API
      final response = await http.post(
        Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages/send'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(emailData),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Email envoyé avec succès à $email');
        return true;
      } else {
        debugPrint('❌ Erreur envoi email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception envoi email: $e');
      return false;
    }
  }

  /// 🔑 Obtenir token d'accès OAuth2
  static Future<String?> _getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': _refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        debugPrint('❌ Erreur token: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception token: $e');
      return null;
    }
  }

  /// 🎨 Construire l'email HTML de bienvenue
  static String _buildWelcomeEmailHTML({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String agenceNom,
    required String compagnieNom,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue Agent - Constat Tunisie</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5;">
    <div style="max-width: 600px; margin: 0 auto; background-color: white; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
        
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #2563eb, #1e40af); padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 28px; font-weight: bold;">🎉 Bienvenue !</h1>
            <p style="color: #e0e7ff; margin: 10px 0 0 0; font-size: 16px;">Votre espace Agent est prêt</p>
        </div>

        <!-- Content -->
        <div style="padding: 40px 30px;">
            <h2 style="color: #1e293b; margin: 0 0 20px 0; font-size: 24px;">Bonjour $prenom $nom,</h2>
            
            <p style="color: #475569; line-height: 1.6; margin: 0 0 20px 0; font-size: 16px;">
                Félicitations ! Votre compte agent a été créé avec succès pour <strong>$agenceNom</strong> 
                de la compagnie <strong>$compagnieNom</strong>.
            </p>

            <p style="color: #475569; line-height: 1.6; margin: 0 0 30px 0; font-size: 16px;">
                Vous pouvez maintenant accéder à votre espace agent pour gérer les véhicules en attente 
                de contrat et créer des contrats d'assurance.
            </p>

            <!-- Credentials Box -->
            <div style="background-color: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 25px; margin: 30px 0;">
                <h3 style="color: #1e293b; margin: 0 0 20px 0; font-size: 18px; text-align: center;">🔐 Vos identifiants de connexion</h3>
                
                <div style="margin: 15px 0;">
                    <strong style="color: #374151; display: block; margin-bottom: 5px;">📧 Email :</strong>
                    <code style="background-color: #e5e7eb; padding: 8px 12px; border-radius: 6px; font-family: monospace; color: #1f2937; display: block;">$email</code>
                </div>
                
                <div style="margin: 15px 0;">
                    <strong style="color: #374151; display: block; margin-bottom: 5px;">🔑 Mot de passe :</strong>
                    <code style="background-color: #fef3c7; padding: 8px 12px; border-radius: 6px; font-family: monospace; color: #92400e; display: block; font-weight: bold;">$password</code>
                </div>
            </div>

            <!-- Security Notice -->
            <div style="background-color: #fef2f2; border-left: 4px solid #ef4444; padding: 15px; margin: 20px 0; border-radius: 6px;">
                <p style="color: #dc2626; margin: 0; font-size: 14px; font-weight: 500;">
                    🔒 <strong>Important :</strong> Changez votre mot de passe lors de votre première connexion pour sécuriser votre compte.
                </p>
            </div>

            <!-- Features -->
            <div style="margin: 30px 0;">
                <h3 style="color: #1e293b; margin: 0 0 15px 0; font-size: 18px;">🚀 Fonctionnalités disponibles :</h3>
                <ul style="color: #475569; line-height: 1.8; padding-left: 20px;">
                    <li>📋 Gestion des véhicules en attente de contrat</li>
                    <li>📝 Création de contrats d'assurance</li>
                    <li>🔔 Notifications en temps réel</li>
                    <li>📊 Tableau de bord des activités</li>
                    <li>👥 Gestion des clients conducteurs</li>
                </ul>
            </div>

            <!-- CTA Button -->
            <div style="text-align: center; margin: 40px 0;">
                <a href="https://votre-app.com/login" style="background: linear-gradient(135deg, #059669, #047857); color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; display: inline-block; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
                    🚀 Accéder à mon espace Agent
                </a>
            </div>
        </div>

        <!-- Footer -->
        <div style="background-color: #f8fafc; padding: 20px 30px; text-align: center; border-top: 1px solid #e2e8f0;">
            <p style="color: #64748b; margin: 0; font-size: 14px;">
                📱 <strong>Constat Tunisie</strong> - Application d'assurance moderne
            </p>
            <p style="color: #94a3b8; margin: 5px 0 0 0; font-size: 12px;">
                Cet email a été envoyé automatiquement. Ne pas répondre.
            </p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// 📧 Renvoyer email avec nouveau mot de passe
  static Future<Map<String, dynamic>> resendCredentials(String agentId) async {
    try {
      final agentDoc = await _firestore.collection('users').doc(agentId).get();
      if (!agentDoc.exists) {
        return {'success': false, 'message': 'Agent non trouvé'};
      }

      final agentData = agentDoc.data()!;
      final newPassword = generateSecurePassword();

      // Mettre à jour le mot de passe
      await _auth.currentUser?.updatePassword(newPassword);

      // Envoyer le nouvel email
      final emailSent = await _sendWelcomeEmail(
        email: agentData['email'],
        nom: agentData['nom'],
        prenom: agentData['prenom'],
        password: newPassword,
        agenceNom: agentData['agenceNom'] ?? 'Votre agence',
        compagnieNom: agentData['compagnieNom'] ?? 'Votre compagnie',
      );

      return {
        'success': emailSent,
        'password': newPassword,
        'message': emailSent ? 'Email renvoyé avec succès' : 'Échec envoi email',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
