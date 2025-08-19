import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// 🔢 Service de génération automatique des numéros de contrat
class ContractNumberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📋 Générer un numéro de contrat automatiquement
  /// Format: [COMP_CODE][AGENCE_CODE][YYYY][MM][NNNNNN]
  /// Exemple: STAR_TUN_2024_01_000001
  static Future<String> generateContractNumber({
    required String compagnieId,
    required String agenceId,
    String? typeContrat,
  }) async {
    try {
      print('🔢 [CONTRACT_NUMBER] Génération pour compagnie: $compagnieId, agence: $agenceId');

      // 1. Récupérer les codes de la compagnie et de l'agence
      final compagnieCode = await _getCompagnieCode(compagnieId);
      final agenceCode = await _getAgenceCode(agenceId);
      
      // 2. Générer les composants du numéro
      final year = DateTime.now().year.toString();
      final month = DateTime.now().month.toString().padLeft(2, '0');
      
      // 3. Générer le numéro séquentiel pour cette compagnie/agence/année/mois
      final sequentialNumber = await _getNextSequentialNumber(
        compagnieId: compagnieId,
        agenceId: agenceId,
        year: year,
        month: month,
      );
      
      // 4. Construire le numéro final
      final contractNumber = '${compagnieCode}_${agenceCode}_${year}_${month}_${sequentialNumber}';
      
      print('✅ [CONTRACT_NUMBER] Numéro généré: $contractNumber');
      return contractNumber;
      
    } catch (e) {
      print('❌ [CONTRACT_NUMBER] Erreur génération: $e');
      // Fallback avec timestamp
      return _generateFallbackNumber(typeContrat);
    }
  }

  /// 🏢 Récupérer le code de la compagnie
  static Future<String> _getCompagnieCode(String compagnieId) async {
    try {
      // Essayer plusieurs collections possibles
      final collections = ['compagnies_assurance', 'compagnies', 'companies'];
      
      for (String collection in collections) {
        try {
          final doc = await _firestore.collection(collection).doc(compagnieId).get();
          if (doc.exists) {
            final data = doc.data()!;
            
            // Chercher le code dans différents champs possibles
            String? code = data['code'] ?? data['codeCompagnie'] ?? data['abbreviation'];
            
            if (code != null && code.isNotEmpty) {
              return code.toUpperCase().substring(0, 4.clamp(0, code.length)).padRight(4, 'X');
            }
            
            // Générer un code à partir du nom
            String nom = data['nom'] ?? data['name'] ?? data['nomCompagnie'] ?? 'COMP';
            return _generateCodeFromName(nom, 4);
          }
        } catch (e) {
          print('⚠️ [CONTRACT_NUMBER] Erreur collection $collection: $e');
        }
      }
      
      // Fallback: utiliser l'ID
      return compagnieId.substring(0, 4.clamp(0, compagnieId.length)).toUpperCase().padRight(4, 'X');
      
    } catch (e) {
      print('❌ [CONTRACT_NUMBER] Erreur récupération code compagnie: $e');
      return 'COMP';
    }
  }

  /// 🏢 Récupérer le code de l'agence
  static Future<String> _getAgenceCode(String agenceId) async {
    try {
      // Essayer plusieurs collections possibles
      final collections = ['agences_assurance', 'agences', 'agencies'];
      
      for (String collection in collections) {
        try {
          final doc = await _firestore.collection(collection).doc(agenceId).get();
          if (doc.exists) {
            final data = doc.data()!;
            
            // Chercher le code dans différents champs possibles
            String? code = data['code'] ?? data['codeAgence'] ?? data['abbreviation'];
            
            if (code != null && code.isNotEmpty) {
              return code.toUpperCase().substring(0, 3.clamp(0, code.length)).padRight(3, 'X');
            }
            
            // Générer un code à partir du nom
            String nom = data['nom'] ?? data['name'] ?? data['nomAgence'] ?? 'AGE';
            return _generateCodeFromName(nom, 3);
          }
        } catch (e) {
          print('⚠️ [CONTRACT_NUMBER] Erreur collection $collection: $e');
        }
      }
      
      // Fallback: utiliser l'ID
      return agenceId.substring(0, 3.clamp(0, agenceId.length)).toUpperCase().padRight(3, 'X');
      
    } catch (e) {
      print('❌ [CONTRACT_NUMBER] Erreur récupération code agence: $e');
      return 'AGE';
    }
  }

  /// 🔢 Obtenir le prochain numéro séquentiel
  static Future<String> _getNextSequentialNumber({
    required String compagnieId,
    required String agenceId,
    required String year,
    required String month,
  }) async {
    try {
      // Créer un préfixe unique pour cette période
      final prefix = '${compagnieId}_${agenceId}_${year}_${month}';
      
      // Compter les contrats existants pour cette période
      final startOfMonth = DateTime(int.parse(year), int.parse(month), 1);
      final endOfMonth = DateTime(int.parse(year), int.parse(month) + 1, 0, 23, 59, 59);
      
      final existingContracts = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('agenceId', isEqualTo: agenceId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      final nextNumber = existingContracts.docs.length + 1;
      return nextNumber.toString().padLeft(6, '0');
      
    } catch (e) {
      print('❌ [CONTRACT_NUMBER] Erreur numéro séquentiel: $e');
      // Fallback avec timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return (timestamp % 1000000).toString().padLeft(6, '0');
    }
  }

  /// 🔤 Générer un code à partir d'un nom
  static String _generateCodeFromName(String name, int length) {
    // Nettoyer le nom
    String cleanName = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .replaceAll(' ', '');
    
    if (cleanName.isEmpty) {
      cleanName = 'CODE';
    }
    
    // Prendre les premières lettres ou compléter
    if (cleanName.length >= length) {
      return cleanName.substring(0, length);
    } else {
      return cleanName.padRight(length, 'X');
    }
  }

  /// 🆘 Générer un numéro de fallback
  static String _generateFallbackNumber(String? typeContrat) {
    final typeCode = typeContrat?.substring(0, 2.clamp(0, typeContrat.length)).toUpperCase() ?? 'CT';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final year = DateTime.now().year;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    
    return '${typeCode}_${year}_${timestamp.toString().substring(timestamp.toString().length - 6)}_$random';
  }

  /// 🔍 Vérifier l'unicité d'un numéro de contrat
  static Future<bool> isContractNumberUnique(String numeroContrat) async {
    try {
      final existingContract = await _firestore
          .collection('contrats')
          .where('numeroContrat', isEqualTo: numeroContrat)
          .limit(1)
          .get();
      
      return existingContract.docs.isEmpty;
    } catch (e) {
      print('❌ [CONTRACT_NUMBER] Erreur vérification unicité: $e');
      return false;
    }
  }

  /// 🔄 Générer un numéro unique (avec retry si collision)
  static Future<String> generateUniqueContractNumber({
    required String compagnieId,
    required String agenceId,
    String? typeContrat,
    int maxRetries = 5,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final numeroContrat = await generateContractNumber(
          compagnieId: compagnieId,
          agenceId: agenceId,
          typeContrat: typeContrat,
        );
        
        final isUnique = await isContractNumberUnique(numeroContrat);
        
        if (isUnique) {
          print('✅ [CONTRACT_NUMBER] Numéro unique généré (tentative $attempt): $numeroContrat');
          return numeroContrat;
        } else {
          print('⚠️ [CONTRACT_NUMBER] Collision détectée (tentative $attempt): $numeroContrat');
        }
      } catch (e) {
        print('❌ [CONTRACT_NUMBER] Erreur tentative $attempt: $e');
      }
    }
    
    // Dernier recours: timestamp + random
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    final fallback = 'CTR_${timestamp}_$random';
    
    print('🆘 [CONTRACT_NUMBER] Utilisation fallback: $fallback');
    return fallback;
  }

  /// 📊 Obtenir des statistiques sur les numéros de contrat
  static Future<Map<String, dynamic>> getContractNumberStats({
    required String compagnieId,
    required String agenceId,
  }) async {
    try {
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime.now().month;
      
      // Contrats ce mois-ci
      final thisMonthStart = DateTime(currentYear, currentMonth, 1);
      final thisMonthEnd = DateTime(currentYear, currentMonth + 1, 0, 23, 59, 59);
      
      final thisMonthContracts = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('agenceId', isEqualTo: agenceId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(thisMonthEnd))
          .get();
      
      // Contrats cette année
      final thisYearStart = DateTime(currentYear, 1, 1);
      final thisYearEnd = DateTime(currentYear, 12, 31, 23, 59, 59);
      
      final thisYearContracts = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('agenceId', isEqualTo: agenceId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thisYearStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(thisYearEnd))
          .get();
      
      return {
        'contratsThisMonth': thisMonthContracts.docs.length,
        'contratsThisYear': thisYearContracts.docs.length,
        'nextMonthlyNumber': thisMonthContracts.docs.length + 1,
        'nextYearlyNumber': thisYearContracts.docs.length + 1,
      };
    } catch (e) {
      print('❌ [CONTRACT_NUMBER] Erreur statistiques: $e');
      return {
        'contratsThisMonth': 0,
        'contratsThisYear': 0,
        'nextMonthlyNumber': 1,
        'nextYearlyNumber': 1,
      };
    }
  }
}
