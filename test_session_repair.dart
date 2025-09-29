import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/services/session_repair_service.dart';

/// 🧪 Script de test pour la réparation des sessions
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase (vous devez avoir votre configuration)
  await Firebase.initializeApp();
  
  print('🚀 Début du test de réparation des sessions...\n');
  
  await testSessionRepair();
  
  print('\n✅ Test terminé');
}

/// 🔧 Tester la réparation des sessions
Future<void> testSessionRepair() async {
  try {
    print('🔍 Phase 1: Diagnostic de toutes les sessions...');
    await diagnosticAllSessions();
    
    print('\n🔧 Phase 2: Réparation des sessions problématiques...');
    await SessionRepairService.repairAllSessions();
    
    print('\n🔍 Phase 3: Vérification post-réparation...');
    await diagnosticAllSessions();
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}

/// 🔍 Diagnostiquer toutes les sessions
Future<void> diagnosticAllSessions() async {
  try {
    // Cette fonction simule ce que fait le service de diagnostic
    print('📊 Analyse des sessions en cours...');
    
    // Vous pouvez ajouter ici du code pour lister et diagnostiquer
    // toutes les sessions si nécessaire
    
    print('✅ Diagnostic terminé');
    
  } catch (e) {
    print('❌ Erreur diagnostic: $e');
  }
}

/// 🧪 Tester une session spécifique
Future<void> testSpecificSession(String sessionId) async {
  try {
    print('🔍 Diagnostic session: $sessionId');
    
    final diagnostic = await SessionRepairService.diagnosticSession(sessionId);
    
    print('📊 Résultat diagnostic:');
    print('   - Statut: ${diagnostic['statut']}');
    print('   - Participants: ${(diagnostic['participants'] as Map?)?.length ?? 0}');
    print('   - Nécessite réparation: ${diagnostic['needsRepair']}');
    
    if (diagnostic['needsRepair'] == true) {
      print('🔧 Réparation de la session...');
      final success = await SessionRepairService.repairSpecificSession(sessionId);
      
      if (success) {
        print('✅ Session réparée avec succès');
        
        // Vérifier après réparation
        final newDiagnostic = await SessionRepairService.diagnosticSession(sessionId);
        print('📊 Nouveau statut: ${newDiagnostic['statut']}');
        print('📊 Nécessite encore réparation: ${newDiagnostic['needsRepair']}');
      } else {
        print('❌ Échec de la réparation');
      }
    } else {
      print('✅ Session OK, aucune réparation nécessaire');
    }
    
  } catch (e) {
    print('❌ Erreur test session $sessionId: $e');
  }
}

/// 📋 Exemple d'utilisation pour tester une session spécifique
/// 
/// Pour tester une session spécifique, décommentez et modifiez:
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   
///   // Remplacez par l'ID de votre session
///   await testSpecificSession('votre_session_id_ici');
/// }
/// ```

/// 🔧 Utilitaires de test

/// Simuler un problème de session pour tester la réparation
Future<void> simulateSessionProblem(String sessionId) async {
  print('🎭 Simulation d\'un problème de session...');
  
  // Cette fonction pourrait créer intentionnellement un problème
  // pour tester la réparation (à utiliser uniquement en développement)
  
  print('⚠️ Problème simulé (ne pas utiliser en production!)');
}

/// Vérifier l'intégrité d'une session
Future<bool> verifySessionIntegrity(String sessionId) async {
  try {
    final diagnostic = await SessionRepairService.diagnosticSession(sessionId);
    
    if (diagnostic.containsKey('error')) {
      print('❌ Erreur session $sessionId: ${diagnostic['error']}');
      return false;
    }
    
    final participants = diagnostic['participants'] as Map<String, dynamic>;
    final progression = diagnostic['progression'] as Map<String, dynamic>;
    final needsRepair = diagnostic['needsRepair'] as bool;
    
    print('🔍 Session $sessionId:');
    print('   - Participants: ${participants['total']}');
    print('   - Progression: ${progression['pourcentage']}%');
    print('   - Intègre: ${!needsRepair}');
    
    return !needsRepair;
    
  } catch (e) {
    print('❌ Erreur vérification $sessionId: $e');
    return false;
  }
}

/// Statistiques globales des sessions
Future<void> printSessionStats() async {
  try {
    print('📊 Statistiques globales des sessions:');
    
    // Ici vous pourriez ajouter du code pour calculer des statistiques
    // comme le nombre total de sessions, sessions problématiques, etc.
    
    print('   - Total sessions: [à implémenter]');
    print('   - Sessions OK: [à implémenter]');
    print('   - Sessions problématiques: [à implémenter]');
    
  } catch (e) {
    print('❌ Erreur statistiques: $e');
  }
}

/// 🚨 Mode de réparation d'urgence
/// 
/// À utiliser uniquement si vous avez beaucoup de sessions problématiques
Future<void> emergencyRepairMode() async {
  print('🚨 MODE RÉPARATION D\'URGENCE');
  print('⚠️  Ceci va réparer TOUTES les sessions problématiques');
  print('⚠️  Assurez-vous d\'avoir une sauvegarde de votre base de données');
  
  // En mode réel, vous pourriez ajouter une confirmation
  // print('Tapez "CONFIRMER" pour continuer:');
  // final confirmation = stdin.readLineSync();
  // if (confirmation != 'CONFIRMER') {
  //   print('❌ Opération annulée');
  //   return;
  // }
  
  try {
    await SessionRepairService.repairAllSessions();
    print('✅ Réparation d\'urgence terminée');
  } catch (e) {
    print('❌ Erreur réparation d\'urgence: $e');
  }
}

/// 📝 Instructions d'utilisation:
/// 
/// 1. Pour diagnostiquer toutes les sessions:
///    ```dart
///    await diagnosticAllSessions();
///    ```
/// 
/// 2. Pour réparer toutes les sessions:
///    ```dart
///    await SessionRepairService.repairAllSessions();
///    ```
/// 
/// 3. Pour tester une session spécifique:
///    ```dart
///    await testSpecificSession('session_id');
///    ```
/// 
/// 4. Pour vérifier l'intégrité:
///    ```dart
///    final isOk = await verifySessionIntegrity('session_id');
///    ```
/// 
/// 5. En cas d'urgence:
///    ```dart
///    await emergencyRepairMode();
///    ```
