import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'collaborative_session_provider.dart';

/// 🚀 Provider Riverpod pour les sessions collaboratives
/// 
/// Ce provider encapsule le CollaborativeSessionProvider pour
/// l'intégrer dans l'architecture Riverpod existante du projet.
final collaborativeSessionProvider = ChangeNotifierProvider((ref) {
  return CollaborativeSessionProvider();
});

/// 🎯 Provider pour l'état de session actuelle (optionnel)
/// 
/// Permet d'accéder rapidement à la session actuelle sans
/// avoir besoin d'écouter tout le provider.
final currentSessionProvider = Provider((ref) {
  final sessionProvider = ref.watch(collaborativeSessionProvider);
  return sessionProvider.currentSession;
});

/// 📊 Provider pour le statut de session (optionnel)
/// 
/// Permet d'afficher le statut de la session dans l'UI
/// sans avoir besoin d'écouter tout le provider.
final sessionStatusProvider = Provider((ref) {
  final sessionProvider = ref.watch(collaborativeSessionProvider);
  return sessionProvider.getSessionStatus();
});

/// 🔄 Provider pour l'état de chargement (optionnel)
/// 
/// Permet d'afficher un indicateur de chargement global
/// pour les opérations de session.
final sessionLoadingProvider = Provider((ref) {
  final sessionProvider = ref.watch(collaborativeSessionProvider);
  return sessionProvider.isLoading;
});

/// ❌ Provider pour les erreurs de session (optionnel)
/// 
/// Permet de gérer les erreurs de session de manière centralisée.
final sessionErrorProvider = Provider((ref) {
  final sessionProvider = ref.watch(collaborativeSessionProvider);
  return sessionProvider.error;
});

/// ✅ Provider pour les messages de succès (optionnel)
/// 
/// Permet d'afficher les messages de succès de manière centralisée.
final sessionSuccessProvider = Provider((ref) {
  final sessionProvider = ref.watch(collaborativeSessionProvider);
  return sessionProvider.successMessage;
});
