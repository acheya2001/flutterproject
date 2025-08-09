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
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🚀 DÉBUT création admin agence');
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] 📋 Paramètres reçus:');
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] - agenceId: $agenceId');
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] - agenceNom: $agenceNom');
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] - compagnieId: $compagnieId');
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] - compagnieNom: $compagnieNom');
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] - prenom: $prenom');
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] - nom: $nom');
    debugPrint('[ADMIN_COMPAGNIE_AGENCE] - telephone: $telephone');

    try {
      // Validation des paramètres d'entrée
      if (agenceId.isEmpty || agenceNom.isEmpty || compagnieId.isEmpty ||
          compagnieNom.isEmpty || prenom.isEmpty || nom.isEmpty) {
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Paramètres manquants détectés');
        throw Exception('Paramètres manquants pour la création de l\'admin agence');
      }

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Validation paramètres OK');

      // Vérifier si l'agence a déjà un admin (vérification robuste)
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔍 Vérification agence existante...');
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Agence non trouvée: $agenceId');
        return {
          'success': false,
          'error': 'Agence non trouvée',
          'message': 'L\'agence spécifiée n\'existe pas',
        };
      }

      final agenceData = agenceDoc.data()!;
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 📋 Données agence: hasAdminAgence=${agenceData['hasAdminAgence']}');

      // Vérification robuste : vérifier s'il y a vraiment un admin actif pour cette agence
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔍 Vérification admin réel dans la collection users...');
      final existingAdminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('agenceId', isEqualTo: agenceId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      final hasRealAdmin = existingAdminQuery.docs.isNotEmpty;
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 📋 Admin réel trouvé: $hasRealAdmin');

      if (hasRealAdmin) {
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Agence a déjà un admin actif');
        return {
          'success': false,
          'error': 'Cette agence a déjà un admin agence actif',
          'message': 'Cette agence a déjà un admin agence actif assigné',
        };
      }

      // Si le flag hasAdminAgence est true mais qu'il n'y a pas d'admin réel, corriger les données
      if (agenceData['hasAdminAgence'] == true && !hasRealAdmin) {
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔧 Correction des données incohérentes de l\'agence...');
        await _firestore.collection('agences').doc(agenceId).update({
          'hasAdminAgence': false,
          'adminAgenceId': FieldValue.delete(),
          'adminAgenceEmail': FieldValue.delete(),
          'adminAgence': FieldValue.delete(),
          'statut': 'libre',
          'correctedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Données agence corrigées');
      }

      // Générer l'email si non fourni
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 📧 Génération email...');
      final finalEmail = email ?? _generateAdminAgenceEmail(prenom, nom, agenceNom);
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Email généré: $finalEmail');

      // Générer un mot de passe
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔑 Génération mot de passe...');
      final password = _generatePassword();
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Mot de passe généré');

      // Créer une référence de document pour auto-générer l'ID
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🆔 Génération référence document...');
      final docRef = _firestore.collection('users').doc();
      final uid = docRef.id;
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ UID généré: $uid');

      // Données de l'admin agence avec métadonnées de création
      final adminData = {
        'uid': uid,
        'email': finalEmail,
        'password': password,
        'prenom': prenom,
        'nom': nom,
        'displayName': '$prenom $nom',
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
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 💾 Création document admin dans Firestore...');
      await docRef.set(adminData);
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Document admin créé avec succès');

      // Mettre à jour l'agence pour indiquer qu'elle a un admin (statut occupé)
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔄 Mise à jour agence...');
      await _firestore.collection('agences').doc(agenceId).update({
        'hasAdminAgence': true,
        'adminAgenceId': uid,
        'adminAgenceEmail': finalEmail,
        'statut': 'occupé',
        'dateAffectationAdmin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Agence mise à jour avec succès');

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin agence créé: $finalEmail');

      return {
        'success': true,
        'email': finalEmail,
        'password': password,
        'adminId': uid,
        'displayName': '$prenom $nom',
        'message': 'Admin agence créé avec succès',
      };

    } catch (e, stackTrace) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur création admin agence: $e');
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 📍 Stack trace: $stackTrace');

      // Analyser le type d'erreur pour donner un message plus précis
      String errorMessage = 'Erreur lors de la création de l\'admin agence';
      if (e.toString().contains('permission')) {
        errorMessage = 'Permissions insuffisantes pour créer l\'admin agence';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet';
      } else if (e.toString().contains('email')) {
        errorMessage = 'Erreur avec l\'adresse email générée';
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': errorMessage,
        'details': 'Erreur technique: ${e.toString()}',
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
    try {
      final prenomClean = prenom.toLowerCase()
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), ''); // Supprimer caractères spéciaux
      final nomClean = nom.toLowerCase()
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), ''); // Supprimer caractères spéciaux
      final agenceClean = agenceNom.toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('agence', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '') // Supprimer caractères spéciaux
          .trim();

      // S'assurer qu'aucun champ n'est vide
      final prenomFinal = prenomClean.isEmpty ? 'admin' : prenomClean;
      final nomFinal = nomClean.isEmpty ? 'user' : nomClean;
      final agenceFinal = agenceClean.isEmpty ? 'agence' : agenceClean;

      return '$prenomFinal.$nomFinal.$agenceFinal@assuretn.tn';
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur génération email: $e');
      // Email de fallback
      return 'admin.${DateTime.now().millisecondsSinceEpoch}@assuretn.tn';
    }
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

        // Vérifier s'il y a un admin agence associé ET ACTIF
        final adminQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin_agence')
            .where('agenceId', isEqualTo: doc.id)
            .where('isActive', isEqualTo: true) // Seulement les admins actifs
            .limit(1)
            .get();

        final hasActiveAdmin = adminQuery.docs.isNotEmpty;
        agenceData['hasAdminAgence'] = hasActiveAdmin;

        if (hasActiveAdmin) {
          final adminData = adminQuery.docs.first.data();
          agenceData['adminAgence'] = {
            'id': adminQuery.docs.first.id,
            'nom': adminData['nom'],
            'prenom': adminData['prenom'],
            'email': adminData['email'],
            'telephone': adminData['telephone'],
            'cin': adminData['cin'],
            'isActive': adminData['isActive'],
          };
          agenceData['adminAgenceId'] = adminQuery.docs.first.id;
          agenceData['adminAgenceEmail'] = adminData['email'];
        } else {
          // S'assurer que les champs admin sont supprimés si pas d'admin actif
          agenceData['adminAgence'] = null;
          agenceData['adminAgenceId'] = null;
          agenceData['adminAgenceEmail'] = null;
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

  /// 🗑️ Retirer un admin d'une agence (sans supprimer le compte)
  static Future<Map<String, dynamic>> deleteAdminAgence(String adminId, String agenceId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🗑️ Retrait admin de l\'agence: $adminId');

      // Retirer l'assignation à l'agence (garder l'admin dans la liste)
      await _firestore.collection('users').doc(adminId).update({
        'agenceId': null,
        'agenceNom': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin retiré de l\'agence avec succès');
      return {
        'success': true,
        'message': 'Administrateur retiré de l\'agence avec succès'
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur retrait admin agence: $e');
      return {
        'success': false,
        'error': 'Erreur lors du retrait: $e'
      };
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

  /// 🗑️ Supprimer une agence et tous ses éléments associés
  static Future<Map<String, dynamic>> deleteAgence(String agenceId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🗑️ Suppression agence: $agenceId');

      // Récupérer l'agence pour vérifier son existence
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        return {'success': false, 'message': 'Agence non trouvée'};
      }

      final agenceData = agenceDoc.data()!;
      final agenceNom = agenceData['nom'] ?? 'Agence inconnue';

      // 1. Supprimer tous les admins agence de cette agence
      final adminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      for (var adminDoc in adminsQuery.docs) {
        await adminDoc.reference.delete();
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin agence supprimé: ${adminDoc.id}');
      }

      // 2. Supprimer tous les agents de cette agence
      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      for (var agentDoc in agentsQuery.docs) {
        await agentDoc.reference.delete();
        debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Agent supprimé: ${agentDoc.id}');
      }

      // 3. Supprimer l'agence elle-même
      await _firestore.collection('agences').doc(agenceId).delete();

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Agence "$agenceNom" supprimée avec succès');
      return {
        'success': true,
        'message': 'Agence "$agenceNom" et tous ses éléments associés supprimés avec succès'
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur suppression agence: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la suppression de l\'agence: $e'
      };
    }
  }

  /// ✏️ Modifier une agence
  static Future<Map<String, dynamic>> updateAgence({
    required String agenceId,
    required String nom,
    required String adresse,
    required String telephone,
    required String gouvernorat,
    required String emailContact,
    String? description,
  }) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✏️ Modification agence: $agenceId');

      // Vérifier que l'agence existe
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        return {'success': false, 'message': 'Agence non trouvée'};
      }

      // Données à mettre à jour
      final updateData = {
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'gouvernorat': gouvernorat,
        'emailContact': emailContact,
        'description': description ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Mettre à jour l'agence
      await _firestore.collection('agences').doc(agenceId).update(updateData);

      // Mettre à jour le nom de l'agence dans tous les utilisateurs associés
      final usersQuery = await _firestore
          .collection('users')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      for (var userDoc in usersQuery.docs) {
        await userDoc.reference.update({
          'agenceNom': nom,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Agence modifiée avec succès');
      return {
        'success': true,
        'message': 'Agence modifiée avec succès'
      };

    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur modification agence: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la modification: $e'
      };
    }
  }

  /// 🔄 Changer le statut d'une agence
  static Future<Map<String, dynamic>> toggleAgenceStatus(
    String agenceId,
    bool isActive,
  ) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔄 Changement statut agence: $agenceId -> $isActive');

      // Vérifier que l'agence existe
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        return {'success': false, 'message': 'Agence non trouvée'};
      }

      // Mettre à jour le statut
      await _firestore.collection('agences').doc(agenceId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Statut agence modifié avec succès');
      return {
        'success': true,
        'message': isActive
            ? 'Agence réactivée avec succès'
            : 'Agence désactivée avec succès'
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur changement statut agence: $e');
      return {
        'success': false,
        'message': 'Erreur lors du changement de statut: $e'
      };
    }
  }

  /// 🔗 Assigner un admin existant à une agence
  static Future<Map<String, dynamic>> assignAdminToAgence(
    String adminId,
    String agenceId,
  ) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔗 Assignation admin: $adminId -> agence: $agenceId');

      // Vérifier que l'admin existe et n'est pas déjà assigné
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      if (!adminDoc.exists) {
        return {'success': false, 'error': 'Administrateur non trouvé'};
      }

      final adminData = adminDoc.data()!;
      if (adminData['agenceId'] != null && adminData['agenceId'].isNotEmpty) {
        return {'success': false, 'error': 'Cet administrateur est déjà assigné à une agence'};
      }

      // Vérifier que l'agence existe
      final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
      if (!agenceDoc.exists) {
        return {'success': false, 'error': 'Agence non trouvée'};
      }

      final agenceData = agenceDoc.data()!;

      // Mettre à jour l'admin avec l'agenceId
      await _firestore.collection('users').doc(adminId).update({
        'agenceId': agenceId,
        'agenceNom': agenceData['nom'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Admin assigné avec succès');
      return {
        'success': true,
        'message': 'Administrateur assigné avec succès à l\'agence'
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur assignation admin: $e');
      return {
        'success': false,
        'error': 'Erreur lors de l\'assignation: $e'
      };
    }
  }

  /// 🔐 Réinitialiser le mot de passe d'un admin agence
  static Future<Map<String, dynamic>> resetAdminPassword(String adminId, String newPassword) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 🔐 Réinitialisation mot de passe admin: $adminId');

      // Mettre à jour le mot de passe dans Firestore
      await _firestore.collection('users').doc(adminId).update({
        'password': newPassword,
        'mustChangePassword': true, // Forcer le changement à la prochaine connexion
        'passwordResetAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Mot de passe réinitialisé avec succès');
      return {
        'success': true,
        'message': 'Mot de passe réinitialisé avec succès'
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur réinitialisation mot de passe: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la réinitialisation du mot de passe: $e'
      };
    }
  }

  /// 📧 Envoyer un email
  static Future<Map<String, dynamic>> sendEmail(Map<String, dynamic> emailData) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] 📧 Envoi email à: ${emailData['to']}');

      // Ajouter l'email à la collection pour traitement par Cloud Function
      await _firestore.collection('mail').add({
        'to': emailData['to'],
        'message': {
          'subject': emailData['subject'],
          'html': emailData['html'],
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ✅ Email ajouté à la queue d\'envoi');
      return {
        'success': true,
        'message': 'Email envoyé avec succès'
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_AGENCE] ❌ Erreur envoi email: $e');
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi de l\'email: $e'
      };
    }
  }

}
