import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 🔧 Service de gestion des experts pour Admin Agence
class AdminAgenceExpertService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 👨‍🔧 Créer un nouvel expert
  static Future<Map<String, dynamic>> createExpert({
    required String agenceId,
    required String agenceNom,
    required String compagnieId,
    required String compagnieNom,
    required String prenom,
    required String nom,
    required String telephone,
    required String cin,
    required List<String> specialites,
    required List<String> gouvernoratsIntervention,
    String? email,
    String? adresse,
    String? numeroLicence,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_EXPERT] 👨‍🔧 Création expert: $prenom $nom');

      // Vérifier si le CIN existe déjà
      final existingCinQuery = await _firestore
          .collection('users')
          .where('cin', isEqualTo: cin)
          .where('role', isEqualTo: 'expert')
          .get();

      if (existingCinQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Un expert avec ce CIN existe déjà',
        };
      }

      // Générer un email automatiquement si non fourni
      String finalEmail = email ?? _generateExpertEmail(prenom, nom, agenceNom);

      // Vérifier si l'email existe déjà
      final existingEmailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: finalEmail)
          .get();

      if (existingEmailQuery.docs.isNotEmpty) {
        // Générer un email alternatif
        finalEmail = _generateAlternativeEmail(prenom, nom, agenceNom);
      }

      // Générer un mot de passe
      final password = _generatePassword();

      // Générer un UID unique
      final uid = _generateUID();

      // Générer un code expert
      final codeExpert = _generateExpertCode(agenceNom, prenom, nom);

      // Générer un numéro de licence si non fourni
      final finalNumeroLicence = numeroLicence ?? _generateLicenceNumber();

      // Données de l'expert
      final expertData = {
        'uid': uid,
        'email': finalEmail,
        'password': password,
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'cin': cin,
        'adresse': adresse ?? '',
        'codeExpert': codeExpert,
        'numeroLicence': finalNumeroLicence,
        'role': 'expert',
        'agenceId': agenceId,
        'agenceNom': agenceNom,
        'compagnieId': compagnieId,
        'compagnieNom': compagnieNom,
        'specialites': specialites,
        'gouvernoratsIntervention': gouvernoratsIntervention,
        'isActive': true,
        'status': 'actif',
        'isDisponible': true,
        'firebaseAuthCreated': false,
        'nombreExpertises': 0,
        'expertisesEnCours': 0,
        'noteMoyenne': 0.0,
        'derniereMission': null,
        'created_at': FieldValue.serverTimestamp(),
        'createdBy': 'admin_agence',
        'origin': 'admin_agence_creation',
        'compagniesPartenaires': [compagnieId], // Expert associé à cette compagnie
        'tarifsParCompagnie': {
          compagnieId: {
            'tarifHoraire': 0.0,
            'tarifDeplacement': 0.0,
            'tarifRapport': 0.0,
          }
        },
        'conditionsParCompagnie': {
          compagnieId: {
            'delaiIntervention': 24, // heures
            'delaiRapport': 48, // heures
            'typeContrat': 'partenaire',
          }
        },
      };

      // Créer l'expert dans Firestore
      await _firestore.collection('users').doc(uid).set(expertData);

      // Créer aussi dans la collection experts pour compatibilité
      await _firestore.collection('experts').doc(uid).set({
        ...expertData,
        'id': uid,
      });

      // Mettre à jour le compteur d'experts dans l'agence
      await _firestore.collection('agences').doc(agenceId).update({
        'nombreExperts': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_AGENCE_EXPERT] ✅ Expert créé: $finalEmail');

      return {
        'success': true,
        'email': finalEmail,
        'password': password,
        'expertId': uid,
        'codeExpert': codeExpert,
        'numeroLicence': finalNumeroLicence,
        'displayName': '$prenom $nom',
        'message': 'Expert créé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_EXPERT] ❌ Erreur création expert: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'expert',
      };
    }
  }

  /// 📋 Récupérer les experts d'une agence
  static Future<List<Map<String, dynamic>>> getAgenceExperts(String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE_EXPERT] 📋 Récupération experts agence: $agenceId');

      // Première requête : récupérer tous les experts de l'agence
      final expertsQuery = await _firestore
          .collection('users')
          .where('agenceId', isEqualTo: agenceId)
          .where('role', isEqualTo: 'expert')
          .get();

      List<Map<String, dynamic>> experts = [];
      for (var doc in expertsQuery.docs) {
        final expertData = doc.data();
        expertData['id'] = doc.id;
        experts.add(expertData);
      }

      // Trier par date de création côté client
      experts.sort((a, b) {
        final aDate = a['created_at'] as Timestamp?;
        final bDate = b['created_at'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate); // Ordre décroissant
      });

      debugPrint('[ADMIN_AGENCE_EXPERT] ✅ ${experts.length} experts récupérés');
      return experts;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_EXPERT] ❌ Erreur récupération experts: $e');
      return [];
    }
  }

  /// 🔄 Mettre à jour un expert
  static Future<Map<String, dynamic>> updateExpert({
    required String expertId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_EXPERT] 🔄 Mise à jour expert: $expertId');

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Mettre à jour dans users
      await _firestore.collection('users').doc(expertId).update(updateData);

      // Mettre à jour dans experts aussi
      await _firestore.collection('experts').doc(expertId).update(updateData);

      return {
        'success': true,
        'message': 'Expert mis à jour avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_EXPERT] ❌ Erreur mise à jour expert: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🗑️ Supprimer un expert
  static Future<Map<String, dynamic>> deleteExpert(String expertId, String agenceId) async {
    try {
      debugPrint('[ADMIN_AGENCE_EXPERT] 🗑️ Suppression expert: $expertId');

      // Marquer comme inactif au lieu de supprimer
      await _firestore.collection('users').doc(expertId).update({
        'isActive': false,
        'status': 'supprime',
        'deletedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('experts').doc(expertId).update({
        'isActive': false,
        'status': 'supprime',
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Décrémenter le compteur
      await _firestore.collection('agences').doc(agenceId).update({
        'nombreExperts': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Expert supprimé avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_EXPERT] ❌ Erreur suppression expert: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📧 Générer un email pour l'expert
  static String _generateExpertEmail(String prenom, String nom, String agenceNom) {
    final prenomClean = prenom.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final nomClean = nom.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final agenceClean = agenceNom.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    
    return '${prenomClean}.${nomClean}.expert@${agenceClean}.tn';
  }

  /// 📧 Générer un email alternatif
  static String _generateAlternativeEmail(String prenom, String nom, String agenceNom) {
    final prenomClean = prenom.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final nomClean = nom.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final agenceClean = agenceNom.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    return '${prenomClean}.${nomClean}.expert${timestamp}@${agenceClean}.tn';
  }

  /// 🔑 Générer un mot de passe
  static String _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// 🆔 Générer un UID unique
  static String _generateUID() {
    return 'expert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  /// 🏷️ Générer un code expert
  static String _generateExpertCode(String agenceNom, String prenom, String nom) {
    final agenceCode = agenceNom.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '').substring(0, 3.clamp(0, agenceNom.length));
    final prenomCode = prenom.toUpperCase().substring(0, 1);
    final nomCode = nom.toUpperCase().substring(0, 2.clamp(0, nom.length));
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    return 'EXP-${agenceCode}${prenomCode}${nomCode}${timestamp}';
  }

  /// 📜 Générer un numéro de licence
  static String _generateLicenceNumber() {
    final year = DateTime.now().year;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'LIC-$year-$random';
  }

  /// 📊 Obtenir les statistiques des experts d'une agence
  static Future<Map<String, dynamic>> getAgenceExpertsStats(String agenceId) async {
    try {
      final experts = await getAgenceExperts(agenceId);
      
      final totalExperts = experts.length;
      final expertsActifs = experts.where((e) => e['isActive'] == true).length;
      final expertsDisponibles = experts.where((e) => e['isDisponible'] == true).length;
      final totalExpertises = experts.fold<int>(0, (sum, e) => sum + (e['nombreExpertises'] as int? ?? 0));
      final expertisesEnCours = experts.fold<int>(0, (sum, e) => sum + (e['expertisesEnCours'] as int? ?? 0));

      return {
        'totalExperts': totalExperts,
        'expertsActifs': expertsActifs,
        'expertsDisponibles': expertsDisponibles,
        'totalExpertises': totalExpertises,
        'expertisesEnCours': expertisesEnCours,
        'tauxDisponibilite': expertsActifs > 0 ? (expertsDisponibles / expertsActifs * 100).round() : 0,
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_EXPERT] ❌ Erreur stats experts: $e');
      return {
        'totalExperts': 0,
        'expertsActifs': 0,
        'expertsDisponibles': 0,
        'totalExpertises': 0,
        'expertisesEnCours': 0,
        'tauxDisponibilite': 0,
      };
    }
  }
}
