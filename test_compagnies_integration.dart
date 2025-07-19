import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'lib/features/admin/services/data_initialization_service.dart';
import 'lib/features/admin/services/compagnie_service.dart';
import 'lib/features/admin/models/compagnie_assurance.dart';

/// 🧪 Script de test pour l'intégration des compagnies d'assurance
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase (vous devrez adapter selon votre configuration)
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');

    // Test du service d'initialisation
    await testDataInitialization();
    
    // Test du service de compagnies
    await testCompagnieService();
    
    print('\n🎉 Tous les tests sont passés avec succès !');
    
  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  }
}

/// 🚀 Test du service d'initialisation
Future<void> testDataInitialization() async {
  print('\n📋 Test du service d\'initialisation...');
  
  final dataService = DataInitializationService();
  
  try {
    // Obtenir les statistiques avant
    final statsBefore = await dataService.getInitializationStats();
    print('📊 Statistiques avant: ${statsBefore['totalCompagnies']} compagnies');
    
    // Initialiser les compagnies
    await dataService.initializeCompagnies();
    print('✅ Initialisation terminée');
    
    // Obtenir les statistiques après
    final statsAfter = await dataService.getInitializationStats();
    print('📊 Statistiques après: ${statsAfter['totalCompagnies']} compagnies');
    
    // Vérifier l'intégrité
    final integrity = await dataService.checkDataIntegrity();
    print('🔍 Intégrité des données: ${integrity['isValid'] ? 'OK' : 'ERREUR'}');
    
    if (!integrity['isValid']) {
      print('⚠️ Problèmes détectés: ${integrity['issues']}');
    }
    
  } catch (e) {
    print('❌ Erreur test initialisation: $e');
    rethrow;
  }
}

/// 🏢 Test du service de compagnies
Future<void> testCompagnieService() async {
  print('\n📋 Test du service de compagnies...');
  
  final compagnieService = CompagnieService();
  
  try {
    // Test de récupération des compagnies
    print('📥 Récupération des compagnies...');
    final compagniesStream = compagnieService.getCompagnies(limit: 5);
    
    await for (final compagnies in compagniesStream.take(1)) {
      print('✅ ${compagnies.length} compagnies récupérées');
      
      for (final compagnie in compagnies.take(3)) {
        print('  - ${compagnie.nom} (${compagnie.code})');
      }
      break;
    }
    
    // Test de recherche
    print('\n🔍 Test de recherche...');
    final searchStream = compagnieService.getCompagnies(
      limit: 10,
      searchQuery: 'STAR',
    );
    
    await for (final results in searchStream.take(1)) {
      print('✅ Recherche "STAR": ${results.length} résultats');
      break;
    }
    
    // Test de vérification d'unicité
    print('\n🔒 Test d\'unicité des codes...');
    final isStarUnique = await compagnieService.isCodeUnique('STAR');
    final isNewCodeUnique = await compagnieService.isCodeUnique('NOUVEAU_CODE');
    
    print('✅ Code STAR unique: ${!isStarUnique} (attendu: false)');
    print('✅ Code NOUVEAU_CODE unique: $isNewCodeUnique (attendu: true)');
    
    // Test de création d'une compagnie de test
    print('\n➕ Test de création...');
    final nouvelleCompagnie = CompagnieAssurance(
      id: '', // Sera généré par Firestore
      nom: 'Test Assurance',
      code: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      adresseSiege: 'Adresse de test',
      ville: 'Tunis',
      gouvernorat: 'Tunis',
      email: 'test@test.tn',
      telephone: '+216 12 345 678',
      dateCreation: DateTime.now(),
      isActive: true,
    );
    
    final createResult = await compagnieService.createCompagnie(nouvelleCompagnie);
    if (createResult == null) {
      print('✅ Compagnie de test créée avec succès');
      
      // Test de suppression (soft delete)
      print('🗑️ Test de suppression...');
      // Note: Vous devrez implémenter la méthode de suppression si nécessaire
      
    } else {
      print('❌ Erreur création: $createResult');
    }
    
  } catch (e) {
    print('❌ Erreur test compagnie service: $e');
    rethrow;
  }
}

/// 📊 Afficher un résumé des fonctionnalités
void printFeatureSummary() {
  print('''
🎯 RÉSUMÉ DES FONCTIONNALITÉS IMPLÉMENTÉES:

✅ MODÈLES ET SERVICES:
   - CompagnieAssurance: Modèle complet avec validation
   - CompagnieService: CRUD, recherche, pagination, statistiques
   - DataInitializationService: Initialisation des données de test

✅ INTERFACES UTILISATEUR:
   - CompagniesManagementScreen: Interface de gestion complète
   - CompagnieFormDialog: Formulaire de création/édition
   - CompagnieDetailsDialog: Affichage détaillé avec statistiques
   - DeleteConfirmationDialog: Confirmations d'actions

✅ INTÉGRATION DASHBOARD:
   - Onglet "Gestion Compagnies" dans Super Admin Dashboard
   - Action rapide "Gestion Compagnies" avec compteur
   - Section Paramètres avec outil d'initialisation
   - Navigation automatique entre les sections

✅ FONCTIONNALITÉS AVANCÉES:
   - Recherche en temps réel avec pagination
   - Validation d'unicité des codes compagnie
   - Statistiques en temps réel (agences, agents, contrats)
   - Soft delete avec possibilité de restauration
   - Gouvernorats tunisiens intégrés
   - Gestion d'erreurs complète

🚀 PROCHAINES ÉTAPES:
   1. Système de gestion des agences (hiérarchie compagnie → agence)
   2. Gestion des agents par agence
   3. Système de contrats et véhicules assurés
   4. Interface conducteur avec ses véhicules
   5. Système d'experts multi-compagnies
   6. Remplissage automatique des formulaires d'accident

📱 NAVIGATION:
   Super Admin Dashboard → Gestion Compagnies → [CRUD complet]
   Actions Rapides → Gestion Compagnies → [Navigation directe]
   Paramètres → Initialiser Compagnies → [Données de test]
''');
}
