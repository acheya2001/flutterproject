import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'constat_agent_notification_service.dart';

/// 👨‍💼 Service pour gérer les experts qui travaillent avec plusieurs compagnies
class ExpertMultiCompagnieService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Créer un profil d'expert
  static Future<Map<String, dynamic>> createExpert({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String adresse,
    required String numeroLicence,
    required List<String> specialites,
    required List<String> compagniesPartenaires,
    String? photo,
    Map<String, dynamic>? certifications,
  }) async {
    try {
      final expertId = _generateExpertId();

      final expertData = {
        'id': expertId,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'adresse': adresse,
        'numeroLicence': numeroLicence,
        'specialites': specialites,
        'compagniesPartenaires': compagniesPartenaires,
        'photo': photo,
        'certifications': certifications ?? {},
        'status': 'actif',
        'disponible': true,
        'dateCreation': FieldValue.serverTimestamp(),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
        'statistiques': {
          'nombreExpertises': 0,
          'nombreCompagnies': compagniesPartenaires.length,
          'notesMoyenne': 0.0,
          'tempsReponseMovenne': 0,
        },
      };

      await _firestore
          .collection('experts')
          .doc(expertId)
          .set(expertData);

      // Créer les relations avec les compagnies
      for (String compagnieId in compagniesPartenaires) {
        await _createExpertCompagnieRelation(expertId, compagnieId);
      }

      debugPrint('✅ Expert créé: $prenom $nom');
      return {
        'success': true,
        'expertId': expertId,
        'message': 'Expert créé avec succès',
      };
    } catch (e) {
      debugPrint('❌ Erreur création expert: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création de l\'expert',
      };
    }
  }

  /// 🤝 Créer une relation expert-compagnie
  static Future<void> _createExpertCompagnieRelation(String expertId, String compagnieId) async {
    try {
      final relationData = {
        'expertId': expertId,
        'compagnieId': compagnieId,
        'dateDebut': FieldValue.serverTimestamp(),
        'status': 'actif',
        'tarifHoraire': 0.0,
        'conditionsSpeciales': {},
        'statistiques': {
          'nombreMissions': 0,
          'noteMoyenne': 0.0,
          'tempsReponseMovenne': 0,
        },
      };

      await _firestore
          .collection('expert_compagnie_relations')
          .doc('${expertId}_$compagnieId')
          .set(relationData);
    } catch (e) {
      debugPrint('❌ Erreur création relation expert-compagnie: $e');
    }
  }

  /// 🔍 Trouver des experts disponibles pour une compagnie
  static Future<List<Map<String, dynamic>>> getExpertsDisponibles({
    required String compagnieId,
    List<String>? specialitesRequises,
    String? region,
  }) async {
    try {
      // Récupérer les experts partenaires de cette compagnie
      Query query = _firestore
          .collection('experts')
          .where('compagniesPartenaires', arrayContains: compagnieId)
          .where('status', isEqualTo: 'actif')
          .where('disponible', isEqualTo: true);

      if (specialitesRequises != null && specialitesRequises.isNotEmpty) {
        query = query.where('specialites', arrayContainsAny: specialitesRequises);
      }

      final snapshot = await query.get();
      final experts = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final expertData = doc.data() as Map<String, dynamic>;
        expertData['id'] = doc.id;

        // Récupérer les statistiques spécifiques à cette compagnie
        final relationDoc = await _firestore
            .collection('expert_compagnie_relations')
            .doc('${doc.id}_$compagnieId')
            .get();

        if (relationDoc.exists) {
          expertData['relationCompagnie'] = relationDoc.data();
        }

        experts.add(expertData);
      }

      // Trier par disponibilité et note
      experts.sort((a, b) {
        final noteA = a['statistiques']['notesMoyenne'] ?? 0.0;
        final noteB = b['statistiques']['notesMoyenne'] ?? 0.0;
        return noteB.compareTo(noteA);
      });

      debugPrint('✅ ${experts.length} experts trouvés pour $compagnieId');
      return experts;
    } catch (e) {
      debugPrint('❌ Erreur recherche experts: $e');
      return [];
    }
  }

  /// 📋 Assigner un expert à un sinistre
  static Future<Map<String, dynamic>> assignerExpertSinistre({
    required String expertId,
    required String sinistreId,
    required String compagnieId,
    DateTime? dateEcheance,
    String? instructions,
  }) async {
    try {
      final assignationId = _generateAssignationId();

      final assignationData = {
        'id': assignationId,
        'expertId': expertId,
        'sinistreId': sinistreId,
        'compagnieId': compagnieId,
        'dateAssignation': FieldValue.serverTimestamp(),
        'dateEcheance': dateEcheance != null ? Timestamp.fromDate(dateEcheance) : null,
        'instructions': instructions,
        'status': 'assigne',
        'progression': 0,
        'rapportFinal': null,
        'evaluation': null,
      };

      await _firestore
          .collection('expert_assignations')
          .doc(assignationId)
          .set(assignationData);

      // Mettre à jour le statut de l'expert
      await _firestore
          .collection('experts')
          .doc(expertId)
          .update({
        'disponible': false,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le sinistre
      final sinistreDoc = await _firestore.collection('sinistres').doc(sinistreId).get();
      final sinistreData = sinistreDoc.data();

      await _firestore
          .collection('sinistres')
          .doc(sinistreId)
          .update({
        'expertAssigne': {
          'expertId': expertId,
          'assignationId': assignationId,
          'dateAssignation': FieldValue.serverTimestamp(),
        },
        'status': 'en_expertise',
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le statut dans constats_finalises si sessionId existe
      final sessionId = sinistreData?['sessionId'];
      if (sessionId != null) {
        // Récupérer les données de l'expert
        final expertDoc = await _firestore.collection('experts').doc(expertId).get();
        final expertData = expertDoc.data();

        if (expertData != null) {
          await ConstatAgentNotificationService.mettreAJourStatutExpertAssigne(
            sessionId: sessionId,
            expertInfo: {
              'id': expertId,
              'nom': expertData['nom'] ?? '',
              'prenom': expertData['prenom'] ?? '',
              'codeExpert': expertData['codeExpert'] ?? '',
              'telephone': expertData['telephone'] ?? '',
              'email': expertData['email'] ?? '',
            },
            missionId: assignationId,
          );
        }
      }

      debugPrint('✅ Expert $expertId assigné au sinistre $sinistreId');
      return {
        'success': true,
        'assignationId': assignationId,
        'message': 'Expert assigné avec succès',
      };
    } catch (e) {
      debugPrint('❌ Erreur assignation expert: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de l\'assignation de l\'expert',
      };
    }
  }

  /// 📊 Obtenir les statistiques d'un expert
  static Future<Map<String, dynamic>> getExpertStatistiques(String expertId) async {
    try {
      // Statistiques générales
      final expertDoc = await _firestore
          .collection('experts')
          .doc(expertId)
          .get();

      if (!expertDoc.exists) {
        throw Exception('Expert non trouvé');
      }

      final expertData = expertDoc.data()!;

      // Statistiques par compagnie
      final relationsSnapshot = await _firestore
          .collection('expert_compagnie_relations')
          .where('expertId', isEqualTo: expertId)
          .get();

      final statistiquesParCompagnie = <String, Map<String, dynamic>>{};
      for (final doc in relationsSnapshot.docs) {
        final data = doc.data();
        statistiquesParCompagnie[data['compagnieId']] = data['statistiques'];
      }

      // Missions récentes
      final missionsSnapshot = await _firestore
          .collection('expert_assignations')
          .where('expertId', isEqualTo: expertId)
          .orderBy('dateAssignation', descending: true)
          .limit(10)
          .get();

      final missionsRecentes = missionsSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      return {
        'success': true,
        'expert': expertData,
        'statistiquesParCompagnie': statistiquesParCompagnie,
        'missionsRecentes': missionsRecentes,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques expert: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔄 Mettre à jour la disponibilité d'un expert
  static Future<void> updateExpertDisponibilite(String expertId, bool disponible) async {
    try {
      await _firestore
          .collection('experts')
          .doc(expertId)
          .update({
        'disponible': disponible,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Disponibilité expert $expertId mise à jour: $disponible');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour disponibilité: $e');
    }
  }

  /// 🏢 Ajouter une compagnie partenaire à un expert
  static Future<Map<String, dynamic>> ajouterCompagniePartenaire(String expertId, String compagnieId) async {
    try {
      // Vérifier que la relation n'existe pas déjà
      final relationDoc = await _firestore
          .collection('expert_compagnie_relations')
          .doc('${expertId}_$compagnieId')
          .get();

      if (relationDoc.exists) {
        return {
          'success': false,
          'message': 'Cette relation existe déjà',
        };
      }

      // Créer la nouvelle relation
      await _createExpertCompagnieRelation(expertId, compagnieId);

      // Mettre à jour la liste des compagnies partenaires
      await _firestore
          .collection('experts')
          .doc(expertId)
          .update({
        'compagniesPartenaires': FieldValue.arrayUnion([compagnieId]),
        'statistiques.nombreCompagnies': FieldValue.increment(1),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Compagnie $compagnieId ajoutée à l\'expert $expertId');
      return {
        'success': true,
        'message': 'Compagnie partenaire ajoutée avec succès',
      };
    } catch (e) {
      debugPrint('❌ Erreur ajout compagnie partenaire: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de l\'ajout de la compagnie partenaire',
      };
    }
  }

  // 🔧 MÉTHODES UTILITAIRES

  static String _generateExpertId() {
    return 'EXP_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateAssignationId() {
    return 'ASS_${DateTime.now().millisecondsSinceEpoch}';
  }
}
