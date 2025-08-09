import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔧 Service de diagnostic et réparation pour Admin Agence
/// Aide à diagnostiquer et corriger les problèmes de configuration
class AdminAgenceDiagnosticService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Diagnostiquer les problèmes d'un admin agence
  static Future<Map<String, dynamic>> diagnoseAdminAgence(String adminId) async {
    final diagnosis = <String, dynamic>{
      'adminExists': false,
      'adminData': null,
      'hasAgenceId': false,
      'agenceExists': false,
      'agenceData': null,
      'possibleAgences': [],
      'recommendations': [],
    };

    try {
      debugPrint('[DIAGNOSTIC] 🔍 Diagnostic pour admin: $adminId');

      // 1. Vérifier si l'admin existe
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      diagnosis['adminExists'] = adminDoc.exists;

      if (!adminDoc.exists) {
        diagnosis['recommendations'].add('L\'utilisateur admin n\'existe pas dans Firestore');
        return diagnosis;
      }

      final adminData = adminDoc.data()!;
      diagnosis['adminData'] = adminData;
      debugPrint('[DIAGNOSTIC] 👤 Admin trouvé: ${adminData['email']}');

      // 2. Vérifier si l'admin a un agenceId
      final agenceId = adminData['agenceId'];
      diagnosis['hasAgenceId'] = agenceId != null;

      if (agenceId != null) {
        // 3. Vérifier si l'agence existe
        final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
        diagnosis['agenceExists'] = agenceDoc.exists;

        if (agenceDoc.exists) {
          diagnosis['agenceData'] = agenceDoc.data();
          debugPrint('[DIAGNOSTIC] ✅ Agence trouvée: ${agenceDoc.data()!['nom']}');
        } else {
          diagnosis['recommendations'].add('L\'agence référencée (ID: $agenceId) n\'existe pas');
        }
      } else {
        diagnosis['recommendations'].add('L\'admin n\'a pas d\'agenceId assigné');
      }

      // 4. Chercher des agences possibles par email
      final email = adminData['email'];
      if (email != null) {
        final possibleAgences = await _findPossibleAgencesByEmail(email);
        diagnosis['possibleAgences'] = possibleAgences;

        if (possibleAgences.isNotEmpty) {
          diagnosis['recommendations'].add('${possibleAgences.length} agence(s) trouvée(s) avec cet email');
        }
      }

      // 5. Générer des recommandations
      if (!diagnosis['hasAgenceId'] && diagnosis['possibleAgences'].isEmpty) {
        diagnosis['recommendations'].add('Créer une nouvelle agence pour cet admin');
      }

      if (!diagnosis['hasAgenceId'] && diagnosis['possibleAgences'].isNotEmpty) {
        diagnosis['recommendations'].add('Assigner l\'admin à une agence existante');
      }

      return diagnosis;

    } catch (e) {
      debugPrint('[DIAGNOSTIC] ❌ Erreur diagnostic: $e');
      diagnosis['error'] = e.toString();
      return diagnosis;
    }
  }

  /// 🔍 Chercher des agences possibles par email
  static Future<List<Map<String, dynamic>>> _findPossibleAgencesByEmail(String email) async {
    final possibleAgences = <Map<String, dynamic>>[];

    try {
      final agencesQuery = await _firestore.collection('agences').get();

      for (final agenceDoc in agencesQuery.docs) {
        final agenceData = agenceDoc.data();
        agenceData['id'] = agenceDoc.id;

        // Vérifier différents champs d'email
        if (agenceData['adminEmail'] == email ||
            agenceData['email'] == email ||
            agenceData['contactEmail'] == email) {
          possibleAgences.add(agenceData);
        }
      }

      debugPrint('[DIAGNOSTIC] 🔍 ${possibleAgences.length} agences possibles trouvées');
      return possibleAgences;

    } catch (e) {
      debugPrint('[DIAGNOSTIC] ❌ Erreur recherche agences: $e');
      return [];
    }
  }

  /// 🔧 Réparer automatiquement la configuration d'un admin agence
  static Future<bool> repairAdminAgence(String adminId) async {
    try {
      debugPrint('[DIAGNOSTIC] 🔧 Tentative de réparation pour admin: $adminId');

      final diagnosis = await diagnoseAdminAgence(adminId);

      if (!diagnosis['adminExists']) {
        debugPrint('[DIAGNOSTIC] ❌ Impossible de réparer: admin inexistant');
        return false;
      }

      final adminData = diagnosis['adminData'] as Map<String, dynamic>;
      final possibleAgences = diagnosis['possibleAgences'] as List<Map<String, dynamic>>;

      // Si l'admin n'a pas d'agenceId mais qu'on a trouvé des agences possibles
      if (!diagnosis['hasAgenceId'] && possibleAgences.isNotEmpty) {
        final agenceToAssign = possibleAgences.first;
        
        // Assigner l'agence à l'admin
        await _firestore.collection('users').doc(adminId).update({
          'agenceId': agenceToAssign['id'],
          'agenceNom': agenceToAssign['nom'],
          'compagnieId': agenceToAssign['compagnieId'],
        });

        debugPrint('[DIAGNOSTIC] ✅ Admin assigné à l\'agence: ${agenceToAssign['nom']}');
        return true;
      }

      // Si aucune agence n'est trouvée, créer une agence par défaut
      if (!diagnosis['hasAgenceId'] && possibleAgences.isEmpty) {
        final newAgenceId = await _createDefaultAgence(adminData);
        if (newAgenceId != null) {
          await _firestore.collection('users').doc(adminId).update({
            'agenceId': newAgenceId,
          });
          debugPrint('[DIAGNOSTIC] ✅ Nouvelle agence créée et assignée');
          return true;
        }
      }

      debugPrint('[DIAGNOSTIC] ❌ Aucune réparation possible');
      return false;

    } catch (e) {
      debugPrint('[DIAGNOSTIC] ❌ Erreur réparation: $e');
      return false;
    }
  }

  /// 🏢 Créer une agence par défaut pour un admin
  static Future<String?> _createDefaultAgence(Map<String, dynamic> adminData) async {
    try {
      // Chercher une compagnie par défaut ou créer une
      final compagniesQuery = await _firestore.collection('compagnies_assurance').limit(1).get();
      String? compagnieId;

      if (compagniesQuery.docs.isNotEmpty) {
        compagnieId = compagniesQuery.docs.first.id;
      } else {
        // Créer une compagnie par défaut
        final compagnieRef = await _firestore.collection('compagnies_assurance').add({
          'nom': 'Compagnie par Défaut',
          'code': 'DEFAULT',
          'email': 'default@company.com',
          'telephone': '00000000',
          'adresse': 'Adresse par défaut',
          'dateCreation': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        compagnieId = compagnieRef.id;
      }

      // Créer l'agence
      final agenceRef = await _firestore.collection('agences').add({
        'nom': 'Agence ${adminData['prenom']} ${adminData['nom']}',
        'code': 'AG${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'compagnieId': compagnieId,
        'adminEmail': adminData['email'],
        'email': adminData['email'],
        'telephone': adminData['telephone'] ?? '00000000',
        'adresse': 'Adresse à définir',
        'ville': adminData['ville'] ?? 'Ville à définir',
        'dateCreation': FieldValue.serverTimestamp(),
        'isActive': true,
        'stats': {
          'totalAgents': 0,
          'activeAgents': 0,
          'totalContrats': 0,
          'totalSinistres': 0,
        },
      });

      debugPrint('[DIAGNOSTIC] ✅ Agence par défaut créée: ${agenceRef.id}');
      return agenceRef.id;

    } catch (e) {
      debugPrint('[DIAGNOSTIC] ❌ Erreur création agence: $e');
      return null;
    }
  }

  /// 📊 Obtenir un rapport de diagnostic complet
  static Future<String> getDiagnosticReport(String adminId) async {
    final diagnosis = await diagnoseAdminAgence(adminId);
    
    final report = StringBuffer();
    report.writeln('=== RAPPORT DE DIAGNOSTIC ADMIN AGENCE ===');
    report.writeln('Admin ID: $adminId');
    report.writeln('');
    
    if (diagnosis['adminExists']) {
      final adminData = diagnosis['adminData'] as Map<String, dynamic>;
      report.writeln('✅ Admin trouvé:');
      report.writeln('   Email: ${adminData['email']}');
      report.writeln('   Nom: ${adminData['prenom']} ${adminData['nom']}');
      report.writeln('   Rôle: ${adminData['role']}');
      report.writeln('');
    } else {
      report.writeln('❌ Admin non trouvé');
      return report.toString();
    }
    
    if (diagnosis['hasAgenceId']) {
      report.writeln('✅ AgenceId présent');
      if (diagnosis['agenceExists']) {
        final agenceData = diagnosis['agenceData'] as Map<String, dynamic>;
        report.writeln('✅ Agence trouvée: ${agenceData['nom']}');
      } else {
        report.writeln('❌ Agence référencée inexistante');
      }
    } else {
      report.writeln('❌ Aucun AgenceId assigné');
    }
    
    final possibleAgences = diagnosis['possibleAgences'] as List<Map<String, dynamic>>;
    if (possibleAgences.isNotEmpty) {
      report.writeln('');
      report.writeln('🔍 Agences possibles trouvées:');
      for (final agence in possibleAgences) {
        report.writeln('   - ${agence['nom']} (ID: ${agence['id']})');
      }
    }
    
    final recommendations = diagnosis['recommendations'] as List<dynamic>;
    if (recommendations.isNotEmpty) {
      report.writeln('');
      report.writeln('💡 Recommandations:');
      for (final rec in recommendations) {
        report.writeln('   - $rec');
      }
    }
    
    return report.toString();
  }
}
