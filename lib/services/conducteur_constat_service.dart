import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🚗 Service pour la gestion des constats du conducteur
class ConducteurConstatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📋 Récupérer les constats d'un conducteur
  static Future<List<Map<String, dynamic>>> getConstatsForConducteur({
    required String conducteurId,
    String? numeroContrat,
    String? numeroPolice,
  }) async {
    try {
      debugPrint('[CONDUCTEUR_CONSTAT] 🔍 Recherche constats pour conducteur: $conducteurId');

      Query query = _firestore
          .collection('constats_finalises')
          .where('conducteurId', isEqualTo: conducteurId)
          .orderBy('dateCreation', descending: true);

      // Filtrer par numéro de contrat si fourni
      if (numeroContrat != null && numeroContrat.isNotEmpty) {
        query = query.where('numeroContrat', isEqualTo: numeroContrat);
      }

      // Filtrer par numéro de police si fourni
      if (numeroPolice != null && numeroPolice.isNotEmpty) {
        query = query.where('numeroPolice', isEqualTo: numeroPolice);
      }

      final querySnapshot = await query.get();
      
      List<Map<String, dynamic>> constats = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        constats.add(data);
      }

      debugPrint('[CONDUCTEUR_CONSTAT] ✅ ${constats.length} constats trouvés');
      return constats;

    } catch (e) {
      debugPrint('[CONDUCTEUR_CONSTAT] ❌ Erreur récupération constats: $e');
      return [];
    }
  }

  /// 📊 Obtenir les statistiques des constats du conducteur
  static Future<Map<String, dynamic>> getConstatStats({
    required String conducteurId,
  }) async {
    try {
      final constats = await getConstatsForConducteur(conducteurId: conducteurId);
      
      int total = constats.length;
      int enAttente = constats.where((c) => c['statut'] == 'finalise').length;
      int expertAssigne = constats.where((c) => c['statut'] == 'expert_assigne').length;
      int enExpertise = constats.where((c) => c['statut'] == 'en_expertise').length;
      int termine = constats.where((c) => c['statut'] == 'expertise_terminee').length;

      return {
        'total': total,
        'en_attente': enAttente,
        'expert_assigne': expertAssigne,
        'en_expertise': enExpertise,
        'termine': termine,
      };

    } catch (e) {
      debugPrint('[CONDUCTEUR_CONSTAT] ❌ Erreur calcul statistiques: $e');
      return {
        'total': 0,
        'en_attente': 0,
        'expert_assigne': 0,
        'en_expertise': 0,
        'termine': 0,
      };
    }
  }

  /// 🔍 Rechercher un constat par code
  static Future<Map<String, dynamic>?> getConstatByCode({
    required String codeConstat,
    String? conducteurId,
  }) async {
    try {
      debugPrint('[CONDUCTEUR_CONSTAT] 🔍 Recherche constat par code: $codeConstat');

      Query query = _firestore
          .collection('constats_finalises')
          .where('codeConstat', isEqualTo: codeConstat);

      // Filtrer par conducteur si fourni (pour sécurité)
      if (conducteurId != null) {
        query = query.where('conducteurId', isEqualTo: conducteurId);
      }

      final querySnapshot = await query.get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        debugPrint('[CONDUCTEUR_CONSTAT] ✅ Constat trouvé: ${data['codeConstat']}');
        return data;
      }

      debugPrint('[CONDUCTEUR_CONSTAT] ❌ Constat non trouvé: $codeConstat');
      return null;

    } catch (e) {
      debugPrint('[CONDUCTEUR_CONSTAT] ❌ Erreur recherche constat: $e');
      return null;
    }
  }

  /// 📱 Obtenir les détails de l'expert assigné
  static Future<Map<String, dynamic>?> getExpertDetails({
    required String expertId,
  }) async {
    try {
      final expertDoc = await _firestore
          .collection('users')
          .doc(expertId)
          .get();

      if (expertDoc.exists) {
        final data = expertDoc.data()!;
        return {
          'nom': '${data['prenom'] ?? ''} ${data['nom'] ?? ''}',
          'codeExpert': data['codeExpert'] ?? '',
          'telephone': data['telephone'] ?? '',
          'email': data['email'] ?? '',
          'specialites': data['specialites'] ?? [],
          'noteMoyenne': data['noteMoyenne'] ?? 0.0,
        };
      }

      return null;

    } catch (e) {
      debugPrint('[CONDUCTEUR_CONSTAT] ❌ Erreur récupération expert: $e');
      return null;
    }
  }

  /// 🔄 Obtenir le statut formaté du constat
  static String getStatutFormate(String statut) {
    switch (statut) {
      case 'finalise':
        return 'En attente d\'assignation';
      case 'expert_assigne':
        return 'Expert assigné';
      case 'en_expertise':
        return 'Expertise en cours';
      case 'expertise_terminee':
        return 'Expertise terminée';
      case 'cloture':
        return 'Dossier clôturé';
      default:
        return 'Statut inconnu';
    }
  }

  /// 🎨 Obtenir la couleur du statut
  static String getStatutColor(String statut) {
    switch (statut) {
      case 'finalise':
        return 'orange';
      case 'expert_assigne':
        return 'blue';
      case 'en_expertise':
        return 'purple';
      case 'expertise_terminee':
        return 'green';
      case 'cloture':
        return 'grey';
      default:
        return 'grey';
    }
  }

  /// 📅 Formater une date
  static String formatDate(dynamic date) {
    if (date == null) return 'Non définie';
    
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.tryParse(date) ?? DateTime.now();
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Non définie';
      }
      
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Format invalide';
    }
  }
}
