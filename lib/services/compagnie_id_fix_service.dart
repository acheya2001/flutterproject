import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 🔧 Service pour corriger les problèmes de compagnieId
class CompagnieIdFixService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔍 Analyser et proposer des corrections de compagnieId
  static Future<Map<String, dynamic>> analyzeAndSuggestFix() async {
    try {
      debugPrint('[COMPAGNIE_ID_FIX] 🔍 Analyse des problèmes de compagnieId...');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'error': 'Utilisateur non connecté'};
      }

      // 1. Récupérer les données de l'utilisateur actuel
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return {'error': 'Données utilisateur non trouvées'};
      }

      final userData = userDoc.data()!;
      final currentCompagnieId = userData['compagnieId'] as String?;
      
      debugPrint('[COMPAGNIE_ID_FIX] 👤 Utilisateur actuel: ${userData['email']}');
      debugPrint('[COMPAGNIE_ID_FIX] 🏢 CompagnieId actuel: $currentCompagnieId');

      // 2. Analyser toutes les compagnies disponibles
      final compagniesSnapshot = await _firestore.collection('compagnies').get();
      final compagnies = compagniesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      debugPrint('[COMPAGNIE_ID_FIX] 🏢 Compagnies disponibles: ${compagnies.length}');

      // 3. Analyser les agences et leurs compagnieId
      final agencesSnapshot = await _firestore.collection('agences').get();
      final agencesByCompany = <String, List<Map<String, dynamic>>>{};
      
      for (final doc in agencesSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final compagnieId = data['compagnieId'] as String?;
        
        if (compagnieId != null && compagnieId.isNotEmpty) {
          agencesByCompany[compagnieId] ??= [];
          agencesByCompany[compagnieId]!.add(data);
        }
      }

      debugPrint('[COMPAGNIE_ID_FIX] 🏪 Agences par compagnie:');
      for (final entry in agencesByCompany.entries) {
        debugPrint('[COMPAGNIE_ID_FIX] 🏪 ${entry.key}: ${entry.value.length} agences');
      }

      // 4. Analyser les agents et leurs compagnieId
      final agentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .get();
      
      final agentsByCompany = <String, List<Map<String, dynamic>>>{};
      
      for (final doc in agentsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final compagnieId = data['compagnieId'] as String?;
        
        if (compagnieId != null && compagnieId.isNotEmpty) {
          agentsByCompany[compagnieId] ??= [];
          agentsByCompany[compagnieId]!.add(data);
        }
      }

      debugPrint('[COMPAGNIE_ID_FIX] 👥 Agents par compagnie:');
      for (final entry in agentsByCompany.entries) {
        debugPrint('[COMPAGNIE_ID_FIX] 👥 ${entry.key}: ${entry.value.length} agents');
      }

      // 5. Proposer des corrections
      final suggestions = <Map<String, dynamic>>[];
      
      for (final compagnieId in agencesByCompany.keys) {
        final agencesCount = agencesByCompany[compagnieId]?.length ?? 0;
        final agentsCount = agentsByCompany[compagnieId]?.length ?? 0;
        
        // Trouver le nom de la compagnie
        final compagnie = compagnies.firstWhere(
          (c) => c['id'] == compagnieId,
          orElse: () => {'nom': 'Compagnie inconnue'},
        );

        suggestions.add({
          'compagnieId': compagnieId,
          'compagnieNom': compagnie['nom'],
          'agencesCount': agencesCount,
          'agentsCount': agentsCount,
          'totalData': agencesCount + agentsCount,
        });
      }

      // Trier par quantité de données (plus de données = plus probable)
      suggestions.sort((a, b) => (b['totalData'] as int).compareTo(a['totalData'] as int));

      return {
        'currentUser': userData,
        'currentCompagnieId': currentCompagnieId,
        'suggestions': suggestions,
        'compagnies': compagnies,
        'agencesByCompany': agencesByCompany,
        'agentsByCompany': agentsByCompany,
      };

    } catch (e) {
      debugPrint('[COMPAGNIE_ID_FIX] ❌ Erreur analyse: $e');
      return {'error': e.toString()};
    }
  }

  /// 🔧 Corriger le compagnieId de l'utilisateur actuel
  static Future<Map<String, dynamic>> fixUserCompagnieId(String newCompagnieId, String compagnieNom) async {
    try {
      debugPrint('[COMPAGNIE_ID_FIX] 🔧 Correction compagnieId vers: $newCompagnieId');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Utilisateur non connecté'};
      }

      // Mettre à jour l'utilisateur
      await _firestore.collection('users').doc(currentUser.uid).update({
        'compagnieId': newCompagnieId,
        'compagnieNom': compagnieNom,
        'compagnieIdFixedAt': FieldValue.serverTimestamp(),
        'compagnieIdFixedBy': 'auto_fix_service',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[COMPAGNIE_ID_FIX] ✅ CompagnieId mis à jour avec succès');

      return {
        'success': true,
        'message': 'CompagnieId mis à jour avec succès',
        'newCompagnieId': newCompagnieId,
        'compagnieNom': compagnieNom,
      };

    } catch (e) {
      debugPrint('[COMPAGNIE_ID_FIX] ❌ Erreur correction: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔧 Correction automatique (choisir la compagnie avec le plus de données)
  static Future<Map<String, dynamic>> autoFix() async {
    try {
      final analysis = await analyzeAndSuggestFix();
      
      if (analysis.containsKey('error')) {
        return analysis;
      }

      final suggestions = analysis['suggestions'] as List<Map<String, dynamic>>;
      
      if (suggestions.isEmpty) {
        return {
          'success': false,
          'error': 'Aucune compagnie avec des données trouvée',
        };
      }

      // Prendre la suggestion avec le plus de données
      final bestSuggestion = suggestions.first;
      final compagnieId = bestSuggestion['compagnieId'] as String;
      final compagnieNom = bestSuggestion['compagnieNom'] as String;

      debugPrint('[COMPAGNIE_ID_FIX] 🎯 Correction automatique vers: $compagnieNom ($compagnieId)');

      return await fixUserCompagnieId(compagnieId, compagnieNom);

    } catch (e) {
      debugPrint('[COMPAGNIE_ID_FIX] ❌ Erreur correction automatique: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
