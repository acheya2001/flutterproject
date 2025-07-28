import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔑 Service de récupération de mots de passe pour les admins
class PasswordRecoveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Récupérer le mot de passe d'un admin par email
  static Future<Map<String, dynamic>> getPasswordByEmail(String email) async {
    try {
      debugPrint('[PASSWORD_RECOVERY] 🔍 Recherche mot de passe pour: $email');

      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Aucun utilisateur trouvé avec cet email',
        };
      }

      final userData = userQuery.docs.first.data();
      
      // Chercher le mot de passe dans tous les champs possibles
      final password = userData['password'] ?? 
                      userData['temporaryPassword'] ?? 
                      userData['motDePasseTemporaire'] ?? 
                      userData['motDePasse'] ?? 
                      userData['temp_password'] ?? 
                      userData['generated_password'];

      if (password == null) {
        return {
          'success': false,
          'error': 'Mot de passe non trouvé pour cet utilisateur',
        };
      }

      debugPrint('[PASSWORD_RECOVERY] ✅ Mot de passe trouvé');

      return {
        'success': true,
        'email': email,
        'password': password,
        'nom': '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}',
        'role': userData['role'],
        'compagnie': userData['compagnieNom'],
        'status': userData['status'],
      };

    } catch (e) {
      debugPrint('[PASSWORD_RECOVERY] ❌ Erreur: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la récupération: $e',
      };
    }
  }

  /// 📋 Lister tous les admins compagnie avec leurs mots de passe
  static Future<List<Map<String, dynamic>>> getAllAdminPasswords() async {
    try {
      debugPrint('[PASSWORD_RECOVERY] 📋 Récupération de tous les admins...');

      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .orderBy('created_at', descending: true)
          .get();

      final admins = usersQuery.docs.map((doc) {
        final data = doc.data();
        final password = data['password'] ?? 
                        data['temporaryPassword'] ?? 
                        data['motDePasseTemporaire'] ?? 
                        data['motDePasse'] ?? 
                        data['temp_password'] ?? 
                        data['generated_password'] ?? 
                        'Mot de passe non trouvé';

        return {
          'id': doc.id,
          'email': data['email'] ?? 'Email non défini',
          'password': password,
          'nom': '${data['prenom'] ?? ''} ${data['nom'] ?? ''}',
          'compagnie': data['compagnieNom'] ?? 'Compagnie non définie',
          'status': data['status'] ?? 'Statut inconnu',
          'created_at': data['created_at'],
        };
      }).toList();

      debugPrint('[PASSWORD_RECOVERY] ✅ ${admins.length} admins trouvés');
      return admins;

    } catch (e) {
      debugPrint('[PASSWORD_RECOVERY] ❌ Erreur récupération admins: $e');
      return [];
    }
  }

  /// 🔧 Afficher les identifiants dans la console (pour debug)
  static Future<void> printAdminCredentials() async {
    try {
      final admins = await getAllAdminPasswords();
      
      debugPrint('');
      debugPrint('🔑 ========== IDENTIFIANTS ADMINS COMPAGNIE ==========');
      debugPrint('');
      
      for (final admin in admins) {
        debugPrint('👤 ${admin['nom']}');
        debugPrint('📧 Email: ${admin['email']}');
        debugPrint('🔑 Mot de passe: ${admin['password']}');
        debugPrint('🏢 Compagnie: ${admin['compagnie']}');
        debugPrint('📊 Statut: ${admin['status']}');
        debugPrint('---');
      }
      
      debugPrint('🔑 ================================================');
      debugPrint('');

    } catch (e) {
      debugPrint('[PASSWORD_RECOVERY] ❌ Erreur affichage: $e');
    }
  }
}
