import 'package:flutter/material.dart';

/// 🛡️ Mixin pour gérer les setState de manière sécurisée
/// 
/// Ce mixin fournit des méthodes pour éviter les erreurs de setState
/// pendant le build ou après que le widget soit démonté.
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  
  /// 🔄 Initialisation sécurisée pour éviter setState pendant build
  /// 
  /// Utilise addPostFrameCallback pour exécuter le callback après
  /// que le build soit terminé.
  void safeInit(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        callback();
      }
    });
  }
  
  /// 🔄 setState sécurisé qui vérifie si le widget est encore monté
  ///
  /// Évite les erreurs "setState called after dispose" en vérifiant
  /// l'état mounted avant d'appeler setState.
  void safeSetState(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }
  
  /// 🔄 Version asynchrone de safeSetState
  /// 
  /// Utile pour les opérations asynchrones qui doivent mettre à jour l'état.
  Future<void> safeSetStateAsync(VoidCallback callback) async {
    if (mounted) {
      setState(callback);
    }
  }
  
  /// 🔄 Exécution sécurisée d'un callback seulement si le widget est monté
  /// 
  /// Utile pour les callbacks qui ne nécessitent pas setState mais
  /// doivent vérifier l'état mounted.
  void safeExecute(VoidCallback callback) {
    if (mounted) {
      callback();
    }
  }
}

