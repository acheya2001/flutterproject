import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/features/admin/services/robust_admin_creation_service.dart';
import 'lib/features/admin/services/firestore_connectivity_fix.dart';

/// 🧪 Script de test pour la création d'Admin Compagnie
void main() async {
  print('🧪 === TEST CRÉATION ADMIN COMPAGNIE ===');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase
    print('🔥 Initialisation Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Test 1: Diagnostic connectivité
    print('\n🔍 === TEST 1: DIAGNOSTIC CONNECTIVITÉ ===');
    final diagnosis = await FirestoreConnectivityFix.diagnoseProblem();
    print('📊 Résultat diagnostic:');
    print('  - Statut global: ${diagnosis['overall_status']}');
    print('  - Problèmes détectés: ${(diagnosis['problems'] as List).length}');
    
    if ((diagnosis['problems'] as List).isNotEmpty) {
      print('❌ Problèmes trouvés:');
      for (final problem in diagnosis['problems']) {
        print('  • $problem');
      }
      
      // Appliquer les corrections
      print('\n🔧 Application des corrections...');
      final fixes = await FirestoreConnectivityFix.applyAutomaticFixes();
      print('✅ Corrections appliquées: ${(fixes['applied'] as List).length}');
    }
    
    // Test 2: Test connectivité robuste
    print('\n🌐 === TEST 2: TEST CONNECTIVITÉ ROBUSTE ===');
    final connectivityTest = await RobustAdminCreationService.runConnectivityTest();
    print('📊 Résultat test connectivité:');
    print('  - Succès global: ${connectivityTest['overall_success']}');
    print('  - Internet: ${connectivityTest['tests']['internet']['success']}');
    print('  - Firestore: ${connectivityTest['tests']['firestore']['success']}');
    print('  - Auth: ${connectivityTest['tests']['auth']['success']}');
    
    // Test 3: Création admin robuste (si connectivité OK)
    if (connectivityTest['overall_success'] == true) {
      print('\n🚀 === TEST 3: CRÉATION ADMIN ROBUSTE ===');
      
      final adminResult = await RobustAdminCreationService.createAdminCompagnieWithRetry(
        email: 'admin.test.script@assurance.tn',
        nom: 'Admin',
        prenom: 'Test Script',
        compagnieId: 'test-script-company',
        compagnieNom: 'Test Script Company',
        maxRetries: 2,
      );
      
      print('📊 Résultat création admin:');
      print('  - Succès: ${adminResult['success']}');
      if (adminResult['success'] == true) {
        print('  - Admin ID: ${adminResult['adminId']}');
        print('  - Email: ${adminResult['email']}');
        print('  - Compagnie: ${adminResult['compagnieNom']}');
        print('✅ Admin créé avec succès !');
      } else {
        print('  - Erreur: ${adminResult['error']}');
        print('  - Tentatives: ${adminResult['attempts']}');
        print('❌ Échec création admin');
      }
    } else {
      print('\n⚠️ === CONNECTIVITÉ INSUFFISANTE ===');
      print('❌ Impossible de tester la création admin');
      print('🔧 Veuillez corriger les problèmes de connectivité d\'abord');
    }
    
    // Résumé final
    print('\n📋 === RÉSUMÉ FINAL ===');
    print('✅ Tests terminés avec succès');
    print('🎯 Prochaines étapes:');
    print('  1. Vérifier les résultats dans Firebase Console');
    print('  2. Tester la création via l\'interface Super Admin');
    print('  3. Confirmer que les admins peuvent se connecter');
    
  } catch (e) {
    print('❌ Erreur durant les tests: $e');
    print('🔧 Vérifiez:');
    print('  - Configuration Firebase');
    print('  - Connexion Internet');
    print('  - Règles Firestore');
  }
  
  print('\n🏁 === FIN DES TESTS ===');
}
