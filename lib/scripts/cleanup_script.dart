import 'package:firebase_core/firebase_core.dart';
import '../services/cleanup_service.dart';
import '../firebase_options.dart';

/// 🧹 Script pour nettoyer les données de test
/// 
/// Usage:
/// ```bash
/// flutter run lib/scripts/cleanup_script.dart
/// ```
void main() async {
  print('🧹 Script de nettoyage des données de test');
  print('=====================================');

  try {
    // Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé');

    // Afficher les compteurs actuels
    print('\n📊 Comptage des documents avant nettoyage:');
    final countsBefore = await CleanupService.countSinistresDocuments();
    for (final entry in countsBefore.entries) {
      print('   ${entry.key}: ${entry.value} documents');
    }

    // Demander confirmation
    print('\n🚨 ATTENTION: Cette action va supprimer TOUS les sinistres !');
    print('Voulez-vous continuer ? (y/N)');
    
    // Note: En mode script, on peut automatiser ou demander confirmation
    // Pour l'instant, on procède automatiquement en mode debug
    
    print('\n🔄 Début du nettoyage...');
    
    // Supprimer tous les sinistres de test
    await CleanupService.deleteAllTestSinistres();
    
    // Afficher les compteurs après nettoyage
    print('\n📊 Comptage des documents après nettoyage:');
    final countsAfter = await CleanupService.countSinistresDocuments();
    for (final entry in countsAfter.entries) {
      print('   ${entry.key}: ${entry.value} documents');
    }

    print('\n✅ Nettoyage terminé avec succès !');
    
  } catch (e) {
    print('❌ Erreur lors du nettoyage: $e');
  }
}

/// 🧹 Fonction pour nettoyer seulement les données de test
Future<void> cleanupOnlyFakeData() async {
  print('🧹 Nettoyage des données avec isFakeData = true');
  print('===============================================');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('📊 Comptage avant nettoyage:');
    final countsBefore = await CleanupService.countSinistresDocuments();
    for (final entry in countsBefore.entries) {
      print('   ${entry.key}: ${entry.value} documents');
    }

    await CleanupService.deleteOnlyFakeDataSinistres();

    print('📊 Comptage après nettoyage:');
    final countsAfter = await CleanupService.countSinistresDocuments();
    for (final entry in countsAfter.entries) {
      print('   ${entry.key}: ${entry.value} documents');
    }

    print('✅ Nettoyage des données de test terminé !');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// 📊 Fonction pour afficher seulement les compteurs
Future<void> showCounts() async {
  print('📊 Comptage des documents');
  print('========================');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final counts = await CleanupService.countSinistresDocuments();
    for (final entry in counts.entries) {
      print('   ${entry.key}: ${entry.value} documents');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
