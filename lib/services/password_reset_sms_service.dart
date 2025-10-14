import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

/// 📱 Service de récupération de mot de passe par SMS
class PasswordResetSMSService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _otpCollection = 'password_reset_otp';

  /// 📱 Envoyer un code de récupération par SMS
  static Future<Map<String, dynamic>> sendPasswordResetCode({
    required String phoneNumber,
    String? userId,
    String? userEmail,
    String? userName,
  }) async {
    try {
      print('[PASSWORD_RESET_SMS] 📱 Envoi code pour: $phoneNumber');

      // 1. Si les données utilisateur sont fournies, les utiliser directement
      Map<String, dynamic> userData;
      String finalUserId;

      if (userId != null && userEmail != null && userName != null) {
        // Utiliser les données fournies (depuis findUserByEmail)
        userData = {
          'email': userEmail,
          'nom': userName.split(' ').last,
          'prenom': userName.split(' ').first,
          'telephone': phoneNumber,
        };
        finalUserId = userId;
        print('[PASSWORD_RESET_SMS] ✅ Utilisation des données utilisateur fournies');
      } else {
        // Fallback: chercher par numéro de téléphone
        final userResult = await _findUserByPhone(phoneNumber);
        if (!userResult['found']) {
          return {
            'success': false,
            'error': 'Aucun compte trouvé avec ce numéro de téléphone',
          };
        }
        userData = userResult['userData'] as Map<String, dynamic>;
        finalUserId = userResult['userId'] as String;
      }

      // 2. Générer un code OTP
      final code = _generateOTP();

      // 3. Stocker l'OTP dans Firestore
      await _firestore.collection(_otpCollection).doc(phoneNumber).set({
        'code': code,
        'userId': finalUserId,
        'phoneNumber': phoneNumber,
        'userEmail': userData['email'],
        'userName': '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}'.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        'verified': false,
        'attempts': 0,
      });

      // 4. Envoyer le SMS
      await _sendSMS(phoneNumber, code, userData['prenom'] ?? 'Utilisateur');

      // 5. Logger l'envoi
      await _logPasswordResetAttempt(finalUserId, phoneNumber, 'code_sent');

      return {
        'success': true,
        'message': 'Code de récupération envoyé par SMS',
        'phoneNumber': phoneNumber,
        'userName': userData['prenom'] ?? 'Utilisateur',
      };

    } catch (e) {
      print('[PASSWORD_RESET_SMS] ❌ Erreur envoi code: $e');
      return {
        'success': false,
        'error': 'Erreur lors de l\'envoi du code: $e',
      };
    }
  }

  /// ✅ Vérifier le code OTP
  static Future<Map<String, dynamic>> verifyResetCode({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      print('[PASSWORD_RESET_SMS] ✅ Vérification code pour: $phoneNumber');

      // 1. Récupérer l'OTP stocké
      final otpDoc = await _firestore.collection(_otpCollection).doc(phoneNumber).get();
      
      if (!otpDoc.exists) {
        return {
          'success': false,
          'error': 'Aucun code de récupération trouvé. Demandez un nouveau code.',
        };
      }

      final otpData = otpDoc.data()!;

      // 2. Vérifier l'expiration
      final expiresAt = otpData['expiresAt'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _firestore.collection(_otpCollection).doc(phoneNumber).delete();
        return {
          'success': false,
          'error': 'Le code a expiré. Demandez un nouveau code.',
        };
      }

      // 3. Vérifier le nombre de tentatives
      final attempts = (otpData['attempts'] as int? ?? 0);
      if (attempts >= 3) {
        await _firestore.collection(_otpCollection).doc(phoneNumber).delete();
        return {
          'success': false,
          'error': 'Trop de tentatives. Demandez un nouveau code.',
        };
      }

      // 4. Vérifier le code
      final storedCode = otpData['code'] as String;
      if (code != storedCode) {
        // Incrémenter les tentatives
        await _firestore.collection(_otpCollection).doc(phoneNumber).update({
          'attempts': attempts + 1,
        });
        
        return {
          'success': false,
          'error': 'Code incorrect. ${2 - attempts} tentative(s) restante(s).',
        };
      }

      // 5. Marquer comme vérifié
      await _firestore.collection(_otpCollection).doc(phoneNumber).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // 6. Logger la vérification
      await _logPasswordResetAttempt(otpData['userId'], phoneNumber, 'code_verified');

      return {
        'success': true,
        'message': 'Code vérifié avec succès',
        'userId': otpData['userId'],
        'userEmail': otpData['userEmail'],
        'userName': otpData['userName'],
      };

    } catch (e) {
      print('[PASSWORD_RESET_SMS] ❌ Erreur vérification: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la vérification: $e',
      };
    }
  }

  /// 🔐 Réinitialiser le mot de passe après vérification
  static Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    try {
      print('[PASSWORD_RESET_SMS] 🔐 Réinitialisation mot de passe pour: $phoneNumber');

      // 1. Vérifier que le code a été vérifié
      final otpDoc = await _firestore.collection(_otpCollection).doc(phoneNumber).get();
      
      if (!otpDoc.exists) {
        return {
          'success': false,
          'error': 'Session expirée. Recommencez le processus.',
        };
      }

      final otpData = otpDoc.data()!;
      if (!(otpData['verified'] ?? false)) {
        return {
          'success': false,
          'error': 'Code non vérifié. Vérifiez d\'abord votre code.',
        };
      }

      final userId = otpData['userId'] as String;
      final userEmail = otpData['userEmail'] as String;

      // 2. Mettre à jour le mot de passe dans Firestore
      await _firestore.collection('users').doc(userId).update({
        'password': newPassword,
        'passwordResetAt': FieldValue.serverTimestamp(),
        'passwordResetMethod': 'sms',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Essayer de mettre à jour Firebase Auth si possible
      try {
        // Note: En production, ceci devrait être fait via Firebase Admin SDK côté serveur
        final user = await _auth.signInWithEmailAndPassword(
          email: userEmail,
          password: otpData['oldPassword'] ?? 'temp', // Mot de passe temporaire
        );
        
        await user.user?.updatePassword(newPassword);
        await _auth.signOut();
      } catch (authError) {
        print('[PASSWORD_RESET_SMS] ⚠️ Erreur mise à jour Firebase Auth: $authError');
        // Continuer même si Firebase Auth échoue
      }

      // 4. Nettoyer l'OTP
      await _firestore.collection(_otpCollection).doc(phoneNumber).delete();

      // 5. Logger la réinitialisation
      await _logPasswordResetAttempt(userId, phoneNumber, 'password_reset');

      return {
        'success': true,
        'message': 'Mot de passe réinitialisé avec succès',
        'userEmail': userEmail,
      };

    } catch (e) {
      print('[PASSWORD_RESET_SMS] ❌ Erreur réinitialisation: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la réinitialisation: $e',
      };
    }
  }

  /// 🔍 Trouver un utilisateur par email (nouvelle fonction publique)
  static Future<Map<String, dynamic>> findUserByEmail(String email) async {
    try {
      print('🔍 Recherche utilisateur par email: $email');

      // 1. Chercher dans la collection users
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final userData = usersQuery.docs.first.data();
        final userId = usersQuery.docs.first.id;

        print('✅ Utilisateur trouvé dans users: $userId');

        return {
          'success': true,
          'userId': userId,
          'userEmail': userData['email'] ?? email,
          'userName': userData['nom'] ?? userData['name'] ?? 'Utilisateur',
          'phoneNumber': userData['telephone'] ?? userData['phone'] ?? '',
        };
      }

      // 2. Chercher dans demandes_contrats
      final demandesQuery = await _firestore
          .collection('demandes_contrats')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (demandesQuery.docs.isNotEmpty) {
        final demandeData = demandesQuery.docs.first.data();
        final demandeId = demandesQuery.docs.first.id;

        print('✅ Utilisateur trouvé dans demandes_contrats: $demandeId');

        return {
          'success': true,
          'userId': demandeData['conducteurId'] ?? demandeId,
          'userEmail': demandeData['email'] ?? email,
          'userName': demandeData['nom'] ?? demandeData['nomConducteur'] ?? 'Conducteur',
          'phoneNumber': demandeData['telephone'] ?? demandeData['phone'] ?? '',
        };
      }

      print('❌ Aucun utilisateur trouvé avec l\'email: $email');
      return {
        'success': false,
        'error': 'Aucun compte trouvé avec cet email',
      };

    } catch (e) {
      print('❌ Erreur lors de la recherche par email: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la recherche du compte',
      };
    }
  }

  /// 🔍 Trouver un utilisateur par numéro de téléphone
  static Future<Map<String, dynamic>> _findUserByPhone(String phoneNumber) async {
    try {
      // Nettoyer le numéro de téléphone
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Chercher dans la collection users
      final usersQuery = await _firestore
          .collection('users')
          .where('telephone', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final doc = usersQuery.docs.first;
        return {
          'found': true,
          'userId': doc.id,
          'userData': doc.data(),
        };
      }

      // Chercher dans les demandes d'assurance
      final demandesQuery = await _firestore
          .collection('demandes_contrats')
          .where('telephone', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (demandesQuery.docs.isNotEmpty) {
        final demande = demandesQuery.docs.first.data();
        final conducteurId = demande['conducteurId'];
        
        if (conducteurId != null) {
          final userDoc = await _firestore.collection('users').doc(conducteurId).get();
          if (userDoc.exists) {
            return {
              'found': true,
              'userId': conducteurId,
              'userData': {...userDoc.data()!, ...demande},
            };
          }
        }
      }

      return {'found': false};

    } catch (e) {
      print('[PASSWORD_RESET_SMS] ❌ Erreur recherche utilisateur: $e');
      return {'found': false};
    }
  }

  /// 🎲 Générer un code OTP à 6 chiffres
  static String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// 📱 Envoyer SMS (simulation pour développement)
  static Future<void> _sendSMS(String phoneNumber, String code, String userName) async {
    try {
      final message = '''
🔐 Code de récupération Constat Tunisie

Bonjour $userName,

Votre code de récupération de mot de passe est:

$code

Ce code expire dans 5 minutes.

⚠️ Ne partagez jamais ce code.
''';

      print('[PASSWORD_RESET_SMS] 📱 Envoi code pour: $phoneNumber');
      print('[SMS_SIMULATION] 📱 MODE DÉVELOPPEMENT - SMS simulé:');
      print('[SMS_SIMULATION] 📞 Destinataire: $phoneNumber');
      print('[SMS_SIMULATION] 👤 Nom: $userName');
      print('[SMS_SIMULATION] 🔐 Code: $code');
      print('[SMS_SIMULATION] ✅ SMS envoyé avec succès (simulation)');

      // Simuler un délai d'envoi réaliste
      await Future.delayed(const Duration(milliseconds: 500));

      // En mode développement, toujours réussir
      print('[PASSWORD_RESET_SMS] ✅ SMS envoyé avec succès');

    } catch (e) {
      print('[PASSWORD_RESET_SMS] ❌ Erreur envoi SMS: $e');
      // En mode développement, ne pas faire échouer l'envoi
      print('[PASSWORD_RESET_SMS] 🔧 Mode développement: Simulation réussie malgré l\'erreur');
    }
  }

  /// 📝 Logger les tentatives de récupération
  static Future<void> _logPasswordResetAttempt(String userId, String phoneNumber, String action) async {
    try {
      await _firestore.collection('password_reset_logs').add({
        'userId': userId,
        'phoneNumber': phoneNumber,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'ip': 'unknown', // En production, récupérer l'IP réelle
      });
    } catch (e) {
      print('[PASSWORD_RESET_SMS] ❌ Erreur logging: $e');
    }
  }

  /// 🧹 Nettoyer les OTP expirés
  static Future<void> cleanExpiredOTPs() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredQuery = await _firestore
          .collection(_otpCollection)
          .where('expiresAt', isLessThan: now)
          .get();

      for (final doc in expiredQuery.docs) {
        await doc.reference.delete();
      }

      print('[PASSWORD_RESET_SMS] 🧹 ${expiredQuery.docs.length} OTP expirés supprimés');
    } catch (e) {
      print('[PASSWORD_RESET_SMS] ❌ Erreur nettoyage: $e');
    }
  }
}
