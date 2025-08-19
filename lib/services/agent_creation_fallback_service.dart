import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔧 Service de création d'agent alternatif (sans Firebase Auth)
/// Utilisé en cas de problème avec Firebase Auth
class AgentCreationFallbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔑 Générer un mot de passe sécurisé
  static String generateSecurePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 📧 Créer un agent sans Firebase Auth (pour test)
  static Future<Map<String, dynamic>> createAgentWithoutAuth({
    required String email,
    required String nom,
    required String prenom,
    required String telephone,
    required String agenceId,
    required String compagnieId,
    required String adminAgenceId,
  }) async {
    try {
      debugPrint('🚀 Début création agent (mode fallback): $email');

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

      // 3. Générer un UID unique (sans Firebase Auth)
      final uid = _generateUID();
      debugPrint('🆔 UID généré: $uid');

      // 4. Récupérer infos agence et compagnie
      debugPrint('📋 Récupération infos agence: $agenceId');
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      
      debugPrint('📋 Récupération infos compagnie: $compagnieId');
      final compagnieDoc = await _firestore.collection('compagnies').doc(compagnieId).get();

      final agenceNom = agenceDoc.exists ? agenceDoc.data()!['nom'] ?? 'Agence' : 'Agence';
      final compagnieNom = compagnieDoc.exists ? compagnieDoc.data()!['nom'] ?? 'Compagnie' : 'Compagnie';
      
      debugPrint('🏪 Agence trouvée: $agenceNom');
      debugPrint('🏢 Compagnie trouvée: $compagnieNom');

      // 5. Créer le profil agent dans la collection 'users'
      try {
        debugPrint('📝 Création profil agent dans Firestore...');
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'password': password, // Stocké temporairement pour l'admin
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
          'firebaseAuthCreated': false, // Sera créé plus tard
          'needsFirebaseAuthCreation': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'origin': 'admin_agence_creation_fallback',
          'createdBy': 'admin_agence',
          'createdByRole': 'admin_agence',
          'lastLogin': null,
          'isFirstLogin': true,
          'nombreConstats': 0,
          'dernierConstAt': null,
        });

        debugPrint('✅ Profil agent créé dans Firestore');
        
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
        'type': 'creation_agent_fallback',
        'statut': 'en_attente',
        'agentId': uid,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'sentAt': FieldValue.serverTimestamp(),
        'message': 'Agent créé en mode fallback - Firebase Auth à créer manuellement',
      });

      return {
        'success': true,
        'agentId': uid,
        'email': email,
        'password': password,
        'emailSent': false,
        'message': 'Agent créé avec succès (mode fallback). Mot de passe: $password',
        'note': 'Le compte Firebase Auth devra être créé manuellement.',
      };

    } catch (e) {
      debugPrint('❌ Erreur création agent (fallback): $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'agent (mode fallback)',
      };
    }
  }

  /// 🆔 Générer un UID unique
  static String _generateUID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(28, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
