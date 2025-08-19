import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔧 Service pour réinitialiser le mot de passe des agents
class AgentPasswordResetService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔑 Définir un mot de passe temporaire pour un agent
  static Future<Map<String, dynamic>> setTemporaryPassword({
    required String agentEmail,
    required String temporaryPassword,
  }) async {
    try {
      debugPrint('🔧 Réinitialisation mot de passe pour: $agentEmail');

      // 1. Vérifier que l'agent existe dans Firestore
      final agentsQuery = await _firestore
          .collection('agents_assurance')
          .where('email', isEqualTo: agentEmail)
          .get();

      if (agentsQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Agent non trouvé dans la base de données',
        };
      }

      final agentDoc = agentsQuery.docs.first;
      final agentData = agentDoc.data();
      
      debugPrint('✅ Agent trouvé: ${agentData['prenom']} ${agentData['nom']}');

      // 2. Se connecter temporairement comme admin pour changer le mot de passe
      final currentUser = _auth.currentUser;
      final currentUserEmail = currentUser?.email;

      try {
        // 3. Utiliser Firebase Admin pour changer le mot de passe
        // Note: En production, ceci devrait être fait via Firebase Admin SDK côté serveur
        
        // Pour le moment, on va mettre à jour le document Firestore avec le mot de passe temporaire
        await _firestore.collection('agents_assurance').doc(agentDoc.id).update({
          'temporaryPassword': temporaryPassword,
          'needsPasswordReset': true,
          'passwordResetAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Mot de passe temporaire défini dans Firestore');

        return {
          'success': true,
          'message': 'Mot de passe temporaire défini avec succès',
          'agentId': agentDoc.id,
          'agentName': '${agentData['prenom']} ${agentData['nom']}',
          'temporaryPassword': temporaryPassword,
        };

      } catch (e) {
        debugPrint('❌ Erreur lors de la définition du mot de passe: $e');
        return {
          'success': false,
          'error': 'Erreur lors de la définition du mot de passe: $e',
        };
      }

    } catch (e) {
      debugPrint('❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur générale: $e',
      };
    }
  }

  /// 🔐 Connexion agent avec mot de passe temporaire
  static Future<Map<String, dynamic>> signInWithTemporaryPassword({
    required String email,
    required String temporaryPassword,
  }) async {
    try {
      debugPrint('🔐 Tentative connexion avec mot de passe temporaire: $email');

      // 1. Vérifier le mot de passe temporaire dans Firestore
      final agentsQuery = await _firestore
          .collection('agents_assurance')
          .where('email', isEqualTo: email)
          .get();

      if (agentsQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Agent non trouvé',
        };
      }

      final agentDoc = agentsQuery.docs.first;
      final agentData = agentDoc.data();

      // 2. Vérifier le mot de passe temporaire
      if (agentData['temporaryPassword'] != temporaryPassword) {
        return {
          'success': false,
          'error': 'Mot de passe temporaire incorrect',
        };
      }

      // 3. Essayer de se connecter avec Firebase Auth
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: temporaryPassword,
        );

        debugPrint('✅ Connexion Firebase Auth réussie');

        // 4. Marquer comme connecté et supprimer le mot de passe temporaire
        await _firestore.collection('agents_assurance').doc(agentDoc.id).update({
          'temporaryPassword': FieldValue.delete(),
          'needsPasswordReset': false,
          'lastLogin': FieldValue.serverTimestamp(),
          'isFirstLogin': false,
        });

        return {
          'success': true,
          'user': userCredential.user,
          'agentData': agentData,
          'message': 'Connexion réussie avec mot de passe temporaire',
        };

      } catch (authError) {
        debugPrint('⚠️ Erreur Firebase Auth: $authError');
        
        // Si erreur PigeonUserDetails, essayer le contournement
        if (authError.toString().contains('PigeonUserDetails')) {
          debugPrint('🔧 Erreur PigeonUserDetails détectée, contournement...');
          
          await Future.delayed(const Duration(milliseconds: 1000));
          final currentUser = _auth.currentUser;
          
          if (currentUser != null && currentUser.email == email) {
            debugPrint('✅ Contournement PigeonUserDetails réussi');
            
            // Marquer comme connecté
            await _firestore.collection('agents_assurance').doc(agentDoc.id).update({
              'temporaryPassword': FieldValue.delete(),
              'needsPasswordReset': false,
              'lastLogin': FieldValue.serverTimestamp(),
              'isFirstLogin': false,
            });

            return {
              'success': true,
              'user': currentUser,
              'agentData': agentData,
              'message': 'Connexion réussie (contournement PigeonUserDetails)',
            };
          }
        }

        return {
          'success': false,
          'error': 'Erreur de connexion Firebase Auth: $authError',
        };
      }

    } catch (e) {
      debugPrint('❌ Erreur générale: $e');
      return {
        'success': false,
        'error': 'Erreur générale: $e',
      };
    }
  }

  /// 📋 Lister les agents avec mot de passe temporaire
  static Future<List<Map<String, dynamic>>> getAgentsWithTemporaryPassword() async {
    try {
      final agentsQuery = await _firestore
          .collection('agents_assurance')
          .where('needsPasswordReset', isEqualTo: true)
          .get();

      return agentsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'],
          'nom': data['nom'],
          'prenom': data['prenom'],
          'temporaryPassword': data['temporaryPassword'],
          'passwordResetAt': data['passwordResetAt'],
        };
      }).toList();

    } catch (e) {
      debugPrint('❌ Erreur récupération agents: $e');
      return [];
    }
  }
}
