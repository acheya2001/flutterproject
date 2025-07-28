import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 🏢 Service de gestion des agences pour Admin Compagnie
class AdminCompagnieAgenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🏢 Créer une nouvelle agence
  static Future<Map<String, dynamic>> createAgence({
    required String compagnieId,
    required String compagnieNom,
    required String nom,
    required String adresse,
    required String telephone,
    required String gouvernorat,
    required String emailContact,
    String? description,
    String? createdByEmail,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🏢 Création agence: $nom');

      // Générer un code unique pour l'agence
      final codeAgence = _generateAgenceCode(compagnieNom, nom);

      // Données de l'agence avec métadonnées de création
      final agenceData = {
        'nom': nom,
        'code': codeAgence,
        'adresse': adresse,
        'telephone': telephone,
        'gouvernorat': gouvernorat,
        'emailContact': emailContact,
        'description': description ?? '',
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'isActive': true,
        'hasAdminAgence': false,
        'nombreAgents': 0,
        'nombreConstats': 0,
        'dateCreation': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // 🔍 Métadonnées de création pour synchronisation Super Admin
        'origin': 'admin_compagnie',
        'createdBy': createdByEmail ?? 'admin_compagnie',
        'createdByRole': 'admin_compagnie',
        'createdByCompagnie': compagnieNom,
      };

      // Créer l'agence dans Firestore
      final agenceRef = await _firestore.collection('agences').add(agenceData);

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Agence créée: ${agenceRef.id}');

      return {
        'success': true,
        'agenceId': agenceRef.id,
        'code': codeAgence,
        'message': 'Agence créée avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur création agence: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'agence',
      };
    }
  }

  /// 👨‍💼 Créer un admin agence pour une agence
  static Future<Map<String, dynamic>> createAdminAgence({
    required String agenceId,
    required String agenceNom,
    required String compagnieId,
    required String compagnieNom,
    required String prenom,
    required String nom,
    required String telephone,
    String? email,
    String? createdByEmail,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 👨‍💼 Création admin agence pour: $agenceNom');

      // Vérifier si l'agence a déjà un admin
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        return {
          'success': false,
          'error': 'Agence non trouvée',
        };
      }

      final agenceData = agenceDoc.data()!;
      if (agenceData['hasAdminAgence'] == true) {
        return {
          'success': false,
          'error': 'Cette agence a déjà un admin agence',
        };
      }

      // Générer l'email si non fourni
      final finalEmail = email ?? _generateAdminAgenceEmail(prenom, nom, agenceNom);
      
      // Générer un mot de passe
      final password = _generatePassword();

      // Générer un UID unique
      final uid = _generateUID();

      // Données de l'admin agence avec métadonnées de création
      final adminData = {
        'uid': uid,
        'email': finalEmail,
        'password': password,
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'role': 'admin_agence',
        'agenceId': agenceId,
        'agenceNom': agenceNom,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'isActive': true,
        'status': 'actif',
        'firebaseAuthCreated': false,
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // 🔍 Métadonnées de création pour synchronisation Super Admin
        'origin': 'auto_creation',
        'createdBy': createdByEmail ?? 'admin_compagnie',
        'createdByRole': 'admin_compagnie',
        'createdByCompagnie': compagnieNom,
        'autoCreatedForAgence': agenceNom,
      };

      // Créer l'admin agence dans Firestore
      await _firestore.collection('users').doc(uid).set(adminData);

      // Mettre à jour l'agence pour indiquer qu'elle a un admin (statut occupé)
      await _firestore.collection('agences').doc(agenceId).update({
        'hasAdminAgence': true,
        'adminAgenceId': uid,
        'adminAgenceEmail': finalEmail,
        'statut': 'occupé',
        'dateAffectationAdmin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin agence créé: $finalEmail');

      return {
        'success': true,
        'email': finalEmail,
        'password': password,
        'adminId': uid,
        'displayName': '$prenom $nom',
        'message': 'Admin agence créé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur création admin agence: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'admin agence',
      };
    }
  }

  /// 📋 Récupérer les agences d'une compagnie
  static Future<List<Map<String, dynamic>>> getAgencesByCompagnie(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 📋 Récupération agences pour compagnie: $compagnieId');

      final agencesQuery = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      final agences = agencesQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ ${agences.length} agences récupérées');
      return agences;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur récupération agences: $e');
      return [];
    }
  }

  /// 👥 Récupérer les admins agence d'une compagnie
  static Future<List<Map<String, dynamic>>> getAdminsAgenceByCompagnie(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 👥 Récupération admins agence pour compagnie: $compagnieId');

      final adminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      final admins = adminsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ ${admins.length} admins agence récupérés');
      return admins;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur récupération admins agence: $e');
      return [];
    }
  }



  /// 🔄 Activer/Désactiver un admin agence
  static Future<Map<String, dynamic>> toggleAdminAgenceStatus(String adminId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(adminId).update({
        'isActive': isActive,
        'status': isActive ? 'actif' : 'inactif',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': isActive ? 'Admin agence activé' : 'Admin agence désactivé',
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur toggle admin agence: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Méthodes utilitaires privées
  static String _generateAgenceCode(String compagnieNom, String agenceNom) {
    final compagnieCode = compagnieNom.substring(0, 3).toUpperCase();
    final agenceCode = agenceNom.substring(0, 3).toUpperCase();
    final random = Random().nextInt(999).toString().padLeft(3, '0');
    return '$compagnieCode-$agenceCode-$random';
  }

  static String _generateAdminAgenceEmail(String prenom, String nom, String agenceNom) {
    final prenomClean = prenom.toLowerCase().replaceAll(' ', '');
    final nomClean = nom.toLowerCase().replaceAll(' ', '');
    final agenceClean = agenceNom.toLowerCase().replaceAll(' ', '').replaceAll('agence', '');
    return '$prenomClean.$nomClean.$agenceClean@assuretn.tn';
  }

  static String _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      12, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  static String _generateUID() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      20, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  /// 📋 Récupérer les agences avec leur statut d'affectation admin
  static Future<List<Map<String, dynamic>>> getAgencesWithAdminStatus(String compagnieId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 📋 Récupération agences avec statut admin pour compagnie: $compagnieId');

      final agencesQuery = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      List<Map<String, dynamic>> agences = [];

      for (var doc in agencesQuery.docs) {
        final agenceData = doc.data();
        agenceData['id'] = doc.id;

        // Vérifier s'il y a un admin agence associé
        final adminQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin_agence')
            .where('agenceId', isEqualTo: doc.id)
            .limit(1)
            .get();

        agenceData['hasAdminAgence'] = adminQuery.docs.isNotEmpty;
        if (adminQuery.docs.isNotEmpty) {
          final adminData = adminQuery.docs.first.data();
          agenceData['adminAgence'] = {
            'id': adminQuery.docs.first.id,
            'nom': adminData['nom'],
            'prenom': adminData['prenom'],
            'email': adminData['email'],
            'telephone': adminData['telephone'],
          };
        }

        agences.add(agenceData);
      }

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ ${agences.length} agences avec statut admin récupérées');
      return agences;

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur récupération agences avec statut: $e');
      return [];
    }
  }

  /// 🔄 Désactiver une agence et son admin
  static Future<Map<String, dynamic>> disableAgence(String agenceId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔄 Désactivation agence: $agenceId');

      // Récupérer l'agence pour trouver son admin
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        return {'success': false, 'message': 'Agence non trouvée'};
      }

      final agenceData = agenceDoc.data()!;
      final adminAgenceId = agenceData['adminAgenceId'];

      // Désactiver l'agence
      await _firestore.collection('agences').doc(agenceId).update({
        'isActive': false,
        'statut': 'désactivé',
        'dateDesactivation': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Désactiver l'admin agence s'il existe
      if (adminAgenceId != null) {
        await _firestore.collection('users').doc(adminAgenceId).update({
          'status': 'inactif',
          'isActive': false,
          'dateDesactivation': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin agence désactivé: $adminAgenceId');
      }

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Agence désactivée: $agenceId');
      return {'success': true, 'message': 'Agence et admin désactivés avec succès'};

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur désactivation agence: $e');
      return {'success': false, 'message': 'Erreur lors de la désactivation: $e'};
    }
  }

  /// ♻️ Réactiver une agence et son admin
  static Future<Map<String, dynamic>> enableAgence(String agenceId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ♻️ Réactivation agence: $agenceId');

      // Récupérer l'agence pour trouver son admin
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        return {'success': false, 'message': 'Agence non trouvée'};
      }

      final agenceData = agenceDoc.data()!;
      final adminAgenceId = agenceData['adminAgenceId'];

      // Réactiver l'agence
      await _firestore.collection('agences').doc(agenceId).update({
        'isActive': true,
        'statut': agenceData['hasAdminAgence'] == true ? 'occupé' : 'libre',
        'dateReactivation': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Réactiver l'admin agence s'il existe
      if (adminAgenceId != null) {
        await _firestore.collection('users').doc(adminAgenceId).update({
          'status': 'actif',
          'isActive': true,
          'dateReactivation': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin agence réactivé: $adminAgenceId');
      }

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Agence réactivée: $agenceId');
      return {'success': true, 'message': 'Agence et admin réactivés avec succès'};

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur réactivation agence: $e');
      return {'success': false, 'message': 'Erreur lors de la réactivation: $e'};
    }
  }

  /// 🗑️ Supprimer un admin agence et libérer l'agence
  static Future<Map<String, dynamic>> deleteAdminAgence(String adminId, String agenceId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🗑️ Suppression admin agence: $adminId');

      // Supprimer l'admin agence
      await _firestore.collection('users').doc(adminId).delete();

      // Libérer l'agence (retirer l'affectation)
      await _firestore.collection('agences').doc(agenceId).update({
        'hasAdminAgence': false,
        'adminAgenceId': FieldValue.delete(),
        'adminAgenceEmail': FieldValue.delete(),
        'statut': 'libre',
        'dateLiberation': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin supprimé et agence libérée');
      return {'success': true, 'message': 'Admin supprimé et agence libérée avec succès'};

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur suppression admin: $e');
      return {'success': false, 'message': 'Erreur lors de la suppression: $e'};
    }
  }

  /// 🔄 Affecter un admin existant à une agence libre
  static Future<Map<String, dynamic>> affectAdminToAgence(String adminId, String agenceId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔄 Affectation admin $adminId à agence $agenceId');

      // Vérifier que l'agence est libre
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        return {'success': false, 'message': 'Agence non trouvée'};
      }

      final agenceData = agenceDoc.data()!;
      if (agenceData['hasAdminAgence'] == true) {
        return {'success': false, 'message': 'Cette agence a déjà un admin affecté'};
      }

      // Récupérer les infos de l'admin
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      if (!adminDoc.exists) {
        return {'success': false, 'message': 'Admin non trouvé'};
      }

      final adminData = adminDoc.data()!;

      // Mettre à jour l'admin avec la nouvelle agence
      await _firestore.collection('users').doc(adminId).update({
        'agenceId': agenceId,
        'agenceNom': agenceData['nom'],
        'dateAffectation': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'agence avec l'admin
      await _firestore.collection('agences').doc(agenceId).update({
        'hasAdminAgence': true,
        'adminAgenceId': adminId,
        'adminAgenceEmail': adminData['email'],
        'statut': 'occupé',
        'dateAffectationAdmin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin affecté à l\'agence avec succès');
      return {'success': true, 'message': 'Admin affecté à l\'agence avec succès'};

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur affectation: $e');
      return {'success': false, 'message': 'Erreur lors de l\'affectation: $e'};
    }
  }

}
