import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/assureur_model.dart';
import '../services/hierarchical_auth_service.dart';

/// 🏢 Provider pour la gestion de l'authentification hiérarchique des agents
class HierarchicalAuthProvider extends ChangeNotifier {
  final HierarchicalAuthService _authService = HierarchicalAuthService();

  AssureurModel? _currentAgent;
  Map<String, dynamic>? _agentHierarchy;
  List<AssureurModel> _agencyAgents = [];
  Map<String, int> _agencyStats = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  AssureurModel? get currentAgent => _currentAgent;
  Map<String, dynamic>? get agentHierarchy => _agentHierarchy;
  List<AssureurModel> get agencyAgents => _agencyAgents;
  Map<String, int> get agencyStats => _agencyStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentAgent != null;

  /// 🔐 Connexion d'un agent
  Future<bool> signInAgent({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final agent = await _authService.signInAgent(
        email: email,
        password: password,
      );

      if (agent != null) {
        _currentAgent = agent;
        await _loadAgentData();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 📊 Charger toutes les données de l'agent
  Future<void> _loadAgentData() async {
    if (_currentAgent == null) return;

    try {
      // Charger la hiérarchie
      _agentHierarchy = await _authService.getAgentHierarchy(_currentAgent!.id);

      // Charger les autres agents de l'agence
      _agencyAgents = await _authService.getAgentsInAgence(_currentAgent!.agenceId);

      // Charger les statistiques de l'agence
      _agencyStats = await _authService.getAgenceStats(_currentAgent!.agenceId);

      notifyListeners();
    } catch (e) {
      debugPrint('[HierarchicalAuthProvider] Erreur chargement données: $e');
    }
  }

  /// 🔄 Rafraîchir les données
  Future<void> refreshData() async {
    if (_currentAgent != null) {
      await _loadAgentData();
    }
  }

  /// 🏢 Récupérer les agences d'une compagnie dans un gouvernorat
  Future<List<Map<String, dynamic>>> getAgencesInGouvernorat(String compagnie, String gouvernorat) async {
    try {
      return await _authService.getAgencesInGouvernorat(compagnie, gouvernorat);
    } catch (e) {
      debugPrint('[HierarchicalAuthProvider] Erreur récupération agences: $e');
      return [];
    }
  }

  /// 🔍 Vérifier les permissions
  bool hasPermission(String permission) {
    if (_currentAgent == null) return false;
    return _authService.hasPermission(_currentAgent!, permission);
  }

  /// 📈 Obtenir les informations de l'agence actuelle
  Map<String, dynamic>? get currentAgencyInfo {
    if (_agentHierarchy == null) return null;
    return _agentHierarchy!['agence'] as Map<String, dynamic>?;
  }

  /// 🏢 Obtenir les informations de la compagnie actuelle
  Map<String, dynamic>? get currentCompanyInfo {
    if (_agentHierarchy == null) return null;
    return _agentHierarchy!['compagnie'] as Map<String, dynamic>?;
  }

  /// 👥 Obtenir le nombre d'agents dans l'agence
  int get agencyAgentsCount => _agencyAgents.length;

  /// 📊 Obtenir les statistiques formatées
  Map<String, String> get formattedStats {
    return {
      'agents': '${_agencyStats['agents'] ?? 0}',
      'contrats_total': '${_agencyStats['contrats_total'] ?? 0}',
      'contrats_actifs': '${_agencyStats['contrats_actifs'] ?? 0}',
      'taux_activation': _agencyStats['contrats_total'] != null && _agencyStats['contrats_total']! > 0
          ? '${((_agencyStats['contrats_actifs'] ?? 0) * 100 / _agencyStats['contrats_total']!).toStringAsFixed(1)}%'
          : '0%',
    };
  }

  /// 🚪 Déconnexion
  Future<void> signOut() async {
    _currentAgent = null;
    _agentHierarchy = null;
    _agencyAgents = [];
    _agencyStats = {};
    _clearError();
    notifyListeners();
  }

  /// 🔧 Méthodes utilitaires
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// 🎯 Obtenir le nom complet de l'agent
  String get agentFullName {
    if (_currentAgent == null) return '';
    return '${_currentAgent!.prenom} ${_currentAgent!.nom}';
  }

  /// 🏢 Obtenir le nom de l'agence
  String get agencyName {
    return _currentAgent?.agenceNom ?? '';
  }

  /// 🌍 Obtenir le gouvernorat
  String get gouvernorat {
    return _currentAgent?.gouvernorat ?? '';
  }

  /// 💼 Obtenir le poste
  String get poste {
    return _currentAgent?.poste ?? '';
  }

  /// 🏢 Obtenir la compagnie
  String get companyName {
    return _currentAgent?.compagnie ?? '';
  }

  /// 📋 Obtenir les permissions
  List<String> get permissions {
    return _currentAgent?.permissions ?? [];
  }

  /// ✅ Vérifier si l'agent est responsable
  bool get isResponsable {
    return _currentAgent?.poste == 'Responsable Agence' || 
           _currentAgent?.poste == 'Superviseur';
  }

  /// 📊 Obtenir un résumé de l'agent
  Map<String, dynamic> get agentSummary {
    if (_currentAgent == null) return {};
    
    return {
      'nom_complet': agentFullName,
      'email': _currentAgent!.email,
      'telephone': _currentAgent!.telephone,
      'matricule': _currentAgent!.matricule,
      'compagnie': companyName,
      'agence': agencyName,
      'gouvernorat': gouvernorat,
      'poste': poste,
      'statut': _currentAgent!.statut,
      'permissions': permissions,
      'date_embauche': _currentAgent!.dateEmbauche?.toIso8601String(),
      'derniere_connexion': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider global pour l'authentification hiérarchique
final hierarchicalAuthProvider = ChangeNotifierProvider<HierarchicalAuthProvider>((ref) {
  return HierarchicalAuthProvider();
});

/// Provider pour vérifier si un agent a une permission spécifique
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final authProvider = ref.watch(hierarchicalAuthProvider);
  return authProvider.hasPermission(permission);
});

/// Provider pour obtenir les statistiques de l'agence
final agencyStatsProvider = Provider<Map<String, String>>((ref) {
  final authProvider = ref.watch(hierarchicalAuthProvider);
  return authProvider.formattedStats;
});

/// Provider pour vérifier si l'agent est responsable
final isResponsableProvider = Provider<bool>((ref) {
  final authProvider = ref.watch(hierarchicalAuthProvider);
  return authProvider.isResponsable;
});
