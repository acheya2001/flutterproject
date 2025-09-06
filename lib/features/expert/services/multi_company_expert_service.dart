import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔍 Service pour la gestion des experts multi-compagnies
/// S'intègre à votre système existant d'experts
class MultiCompanyExpertService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 👨‍💼 Obtenir les informations de l'expert avec ses compagnies partenaires
  static Future<Map<String, dynamic>?> getExpertWithCompanies({String? expertId}) async {
    try {
      final user = _auth.currentUser;
      final effectiveExpertId = expertId ?? user?.uid;
      
      if (effectiveExpertId == null) return null;

      // Récupérer les données de l'expert
      final expertDoc = await _firestore.collection('experts').doc(effectiveExpertId).get();
      if (!expertDoc.exists) return null;

      final expertData = expertDoc.data()!;
      
      // Récupérer les compagnies partenaires
      final compagniesPartenaires = List<String>.from(expertData['compagniesPartenaires'] ?? []);
      final companiesData = <Map<String, dynamic>>[];
      
      for (final companyId in compagniesPartenaires) {
        final companyDoc = await _firestore.collection('compagnies_assurance').doc(companyId).get();
        if (companyDoc.exists) {
          companiesData.add({
            'id': companyId,
            ...companyDoc.data()!,
          });
        }
      }

      return {
        'expert': expertData,
        'compagniesPartenaires': companiesData,
        'nombreCompagnies': companiesData.length,
      };
    } catch (e) {
      print('❌ Erreur récupération expert multi-compagnies: $e');
      return null;
    }
  }

  /// 🏢 Ajouter une compagnie partenaire à un expert
  static Future<bool> addPartnerCompany({
    required String expertId,
    required String companyId,
    Map<String, dynamic>? tarifs,
    Map<String, dynamic>? conditions,
  }) async {
    try {
      final expertRef = _firestore.collection('experts').doc(expertId);
      
      await expertRef.update({
        'compagniesPartenaires': FieldValue.arrayUnion([companyId]),
        'tarifsParCompagnie.$companyId': tarifs ?? {},
        'conditionsParCompagnie.$companyId': conditions ?? {},
        'missionsParCompagnie.$companyId': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Compagnie partenaire ajoutée avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur ajout compagnie partenaire: $e');
      return false;
    }
  }

  /// 🗑️ Retirer une compagnie partenaire d'un expert
  static Future<bool> removePartnerCompany({
    required String expertId,
    required String companyId,
  }) async {
    try {
      final expertRef = _firestore.collection('experts').doc(expertId);
      
      await expertRef.update({
        'compagniesPartenaires': FieldValue.arrayRemove([companyId]),
        'tarifsParCompagnie.$companyId': FieldValue.delete(),
        'conditionsParCompagnie.$companyId': FieldValue.delete(),
        'missionsParCompagnie.$companyId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Compagnie partenaire retirée avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur suppression compagnie partenaire: $e');
      return false;
    }
  }

  /// 📊 Obtenir les statistiques par compagnie pour un expert
  static Future<Map<String, dynamic>> getExpertStatsByCompany(String expertId) async {
    try {
      final expertDoc = await _firestore.collection('experts').doc(expertId).get();
      if (!expertDoc.exists) return {};

      final expertData = expertDoc.data()!;
      final compagniesPartenaires = List<String>.from(expertData['compagniesPartenaires'] ?? []);
      final missionsParCompagnie = Map<String, int>.from(expertData['missionsParCompagnie'] ?? {});
      
      final stats = <String, dynamic>{};
      
      for (final companyId in compagniesPartenaires) {
        // Récupérer les informations de la compagnie
        final companyDoc = await _firestore.collection('compagnies_assurance').doc(companyId).get();
        final companyName = companyDoc.exists ? companyDoc.data()!['nom'] : 'Compagnie inconnue';
        
        // Récupérer les missions pour cette compagnie
        final missionsSnapshot = await _firestore
            .collection('missions')
            .where('expertId', isEqualTo: expertId)
            .where('compagnieId', isEqualTo: companyId)
            .get();

        final missions = missionsSnapshot.docs.map((doc) => doc.data()).toList();
        final missionsEnCours = missions.where((m) => m['statut'] == 'en_cours').length;
        final missionsTerminees = missions.where((m) => m['statut'] == 'terminee').length;
        
        stats[companyId] = {
          'compagnieNom': companyName,
          'totalMissions': missions.length,
          'missionsEnCours': missionsEnCours,
          'missionsTerminees': missionsTerminees,
          'tarifs': expertData['tarifsParCompagnie']?[companyId] ?? {},
          'conditions': expertData['conditionsParCompagnie']?[companyId] ?? {},
        };
      }

      return stats;
    } catch (e) {
      print('❌ Erreur récupération statistiques expert: $e');
      return {};
    }
  }

  /// 🔍 Rechercher des experts disponibles pour une compagnie
  static Future<List<Map<String, dynamic>>> findAvailableExperts({
    required String companyId,
    String? gouvernorat,
    String? specialite,
    bool onlyAvailable = true,
  }) async {
    try {
      Query query = _firestore.collection('experts');
      
      // Filtrer par compagnie partenaire
      query = query.where('compagniesPartenaires', arrayContains: companyId);
      
      // Filtrer par disponibilité
      if (onlyAvailable) {
        query = query.where('isDisponible', isEqualTo: true);
      }
      
      // Filtrer par spécialité
      if (specialite != null) {
        query = query.where('specialite', isEqualTo: specialite);
      }
      
      final snapshot = await query.get();
      final experts = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final expertData = doc.data() as Map<String, dynamic>;
        
        // Filtrer par gouvernorat si spécifié
        if (gouvernorat != null) {
          final gouvernoratsIntervention = List<String>.from(expertData['gouvernoratsIntervention'] ?? []);
          if (!gouvernoratsIntervention.contains(gouvernorat)) continue;
        }
        
        experts.add({
          'id': doc.id,
          ...expertData,
          'tarifsCompagnie': expertData['tarifsParCompagnie']?[companyId] ?? {},
          'conditionsCompagnie': expertData['conditionsParCompagnie']?[companyId] ?? {},
        });
      }
      
      // Trier par note moyenne décroissante
      experts.sort((a, b) => (b['noteMoyenne'] ?? 0.0).compareTo(a['noteMoyenne'] ?? 0.0));
      
      return experts;
    } catch (e) {
      print('❌ Erreur recherche experts disponibles: $e');
      return [];
    }
  }

  /// 📝 Créer une mission pour un expert
  static Future<String?> createMission({
    required String expertId,
    required String compagnieId,
    required String sinisterId,
    required Map<String, dynamic> missionData,
  }) async {
    try {
      final missionRef = await _firestore.collection('missions').add({
        ...missionData,
        'expertId': expertId,
        'compagnieId': compagnieId,
        'sinisterId': sinisterId,
        'statut': 'en_attente',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour les compteurs de l'expert
      await _firestore.collection('experts').doc(expertId).update({
        'missionsEnCours': FieldValue.increment(1),
        'totalMissions': FieldValue.increment(1),
        'missionsParCompagnie.$compagnieId': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Mission créée avec succès: ${missionRef.id}');
      return missionRef.id;
    } catch (e) {
      print('❌ Erreur création mission: $e');
      return null;
    }
  }

  /// 📋 Obtenir les missions d'un expert par compagnie
  static Future<Map<String, List<Map<String, dynamic>>>> getExpertMissionsByCompany(String expertId) async {
    try {
      final snapshot = await _firestore
          .collection('missions')
          .where('expertId', isEqualTo: expertId)
          .orderBy('createdAt', descending: true)
          .get();

      final missionsByCompany = <String, List<Map<String, dynamic>>>{};
      
      for (final doc in snapshot.docs) {
        final missionData = doc.data();
        final compagnieId = missionData['compagnieId'] as String;
        
        if (!missionsByCompany.containsKey(compagnieId)) {
          missionsByCompany[compagnieId] = [];
        }
        
        missionsByCompany[compagnieId]!.add({
          'id': doc.id,
          ...missionData,
        });
      }

      return missionsByCompany;
    } catch (e) {
      print('❌ Erreur récupération missions par compagnie: $e');
      return {};
    }
  }

  /// 💰 Mettre à jour les tarifs d'un expert pour une compagnie
  static Future<bool> updateExpertTarifs({
    required String expertId,
    required String compagnieId,
    required Map<String, dynamic> tarifs,
  }) async {
    try {
      await _firestore.collection('experts').doc(expertId).update({
        'tarifsParCompagnie.$compagnieId': tarifs,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Tarifs mis à jour avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur mise à jour tarifs: $e');
      return false;
    }
  }

  /// 📄 Mettre à jour les conditions d'un expert pour une compagnie
  static Future<bool> updateExpertConditions({
    required String expertId,
    required String compagnieId,
    required Map<String, dynamic> conditions,
  }) async {
    try {
      await _firestore.collection('experts').doc(expertId).update({
        'conditionsParCompagnie.$compagnieId': conditions,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Conditions mises à jour avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur mise à jour conditions: $e');
      return false;
    }
  }

  /// 📊 Obtenir le tableau de bord multi-compagnies pour un expert
  static Future<Map<String, dynamic>> getExpertMultiCompanyDashboard(String expertId) async {
    try {
      final expertData = await getExpertWithCompanies(expertId: expertId);
      if (expertData == null) return {};

      final stats = await getExpertStatsByCompany(expertId);
      final missionsByCompany = await getExpertMissionsByCompany(expertId);

      return {
        'expert': expertData['expert'],
        'compagniesPartenaires': expertData['compagniesPartenaires'],
        'nombreCompagnies': expertData['nombreCompagnies'],
        'statistiques': stats,
        'missions': missionsByCompany,
        'summary': {
          'totalMissions': stats.values.fold(0, (sum, stat) => sum + (stat['totalMissions'] as int)),
          'missionsEnCours': stats.values.fold(0, (sum, stat) => sum + (stat['missionsEnCours'] as int)),
          'missionsTerminees': stats.values.fold(0, (sum, stat) => sum + (stat['missionsTerminees'] as int)),
        },
      };
    } catch (e) {
      print('❌ Erreur récupération dashboard multi-compagnies: $e');
      return {};
    }
  }
}
