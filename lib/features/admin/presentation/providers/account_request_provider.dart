import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../models/account_request_model.dart';
import '../../services/account_request_service.dart';

/// 📋 État des demandes de comptes
class AccountRequestState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final String? message;
  final List<AccountRequestModel> requests;
  final List<AccountRequestModel> pendingRequests;
  final List<AccountRequestModel> processedRequests;

  const AccountRequestState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.message,
    this.requests = const [],
    this.pendingRequests = const [],
    this.processedRequests = const [],
  });

  AccountRequestState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    String? message,
    List<AccountRequestModel>? requests,
    List<AccountRequestModel>? pendingRequests,
    List<AccountRequestModel>? processedRequests,
  }) {
    return AccountRequestState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      message: message,
      requests: requests ?? this.requests,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      processedRequests: processedRequests ?? this.processedRequests,
    );
  }

  /// 📊 Statistiques
  int get totalRequests => requests.length;
  int get pendingCount => pendingRequests.length;
  int get approvedCount => processedRequests.where((r) => r.isApproved).length;
  int get rejectedCount => processedRequests.where((r) => r.isRejected).length;
}

/// 📋 Notifier pour les demandes de comptes
class AccountRequestNotifier extends StateNotifier<AccountRequestState> {
  final AccountRequestService _service;

  AccountRequestNotifier(this._service) : super(const AccountRequestState());

  /// 📤 Soumettre une nouvelle demande
  Future<void> submitRequest(AccountRequestModel request) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await _service.submitRequest(request);
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        message: 'Demande soumise avec succès',
      );
      
      debugPrint('[ACCOUNT_REQUEST] Demande soumise: ${request.email}');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST] Erreur lors de la soumission: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la soumission: $e',
      );
    }
  }

  /// 📋 Charger toutes les demandes (pour admin)
  Future<void> loadAllRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requests = await _service.getAllRequests();
      
      final pending = requests.where((r) => r.isPending).toList();
      final processed = requests.where((r) => !r.isPending).toList();
      
      state = state.copyWith(
        isLoading: false,
        requests: requests,
        pendingRequests: pending,
        processedRequests: processed,
      );
      
      debugPrint('[ACCOUNT_REQUEST] ${requests.length} demandes chargées');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST] Erreur lors du chargement: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// ✅ Approuver une demande
  Future<void> approveRequest(String requestId, String adminId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.approveRequest(requestId, adminId);
      
      // Recharger les demandes
      await loadAllRequests();
      
      state = state.copyWith(
        isLoading: false,
        message: 'Demande approuvée avec succès',
      );
      
      debugPrint('[ACCOUNT_REQUEST] Demande approuvée: $requestId');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST] Erreur lors de l\'approbation: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'approbation: $e',
      );
    }
  }

  /// ❌ Rejeter une demande
  Future<void> rejectRequest(String requestId, String adminId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.rejectRequest(requestId, adminId, reason);
      
      // Recharger les demandes
      await loadAllRequests();
      
      state = state.copyWith(
        isLoading: false,
        message: 'Demande rejetée',
      );
      
      debugPrint('[ACCOUNT_REQUEST] Demande rejetée: $requestId');
    } catch (e) {
      debugPrint('[ACCOUNT_REQUEST] Erreur lors du rejet: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du rejet: $e',
      );
    }
  }

  /// 🔍 Rechercher des demandes
  void searchRequests(String query) {
    if (query.isEmpty) {
      // Réinitialiser la liste
      final pending = state.requests.where((r) => r.isPending).toList();
      final processed = state.requests.where((r) => !r.isPending).toList();
      
      state = state.copyWith(
        pendingRequests: pending,
        processedRequests: processed,
      );
      return;
    }

    final filteredRequests = state.requests.where((request) {
      return request.fullName.toLowerCase().contains(query.toLowerCase()) ||
             request.email.toLowerCase().contains(query.toLowerCase()) ||
             request.accountType.displayName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    final pending = filteredRequests.where((r) => r.isPending).toList();
    final processed = filteredRequests.where((r) => !r.isPending).toList();

    state = state.copyWith(
      pendingRequests: pending,
      processedRequests: processed,
    );
  }

  /// 🔄 Filtrer par statut
  void filterByStatus(RequestStatus? status) {
    if (status == null) {
      // Afficher toutes les demandes
      final pending = state.requests.where((r) => r.isPending).toList();
      final processed = state.requests.where((r) => !r.isPending).toList();
      
      state = state.copyWith(
        pendingRequests: pending,
        processedRequests: processed,
      );
      return;
    }

    final filteredRequests = state.requests.where((r) => r.status == status).toList();
    
    if (status == RequestStatus.pending) {
      state = state.copyWith(
        pendingRequests: filteredRequests,
        processedRequests: [],
      );
    } else {
      state = state.copyWith(
        pendingRequests: [],
        processedRequests: filteredRequests,
      );
    }
  }

  /// 🔄 Filtrer par type de compte
  void filterByAccountType(ProfessionalAccountType? accountType) {
    if (accountType == null) {
      // Afficher toutes les demandes
      final pending = state.requests.where((r) => r.isPending).toList();
      final processed = state.requests.where((r) => !r.isPending).toList();
      
      state = state.copyWith(
        pendingRequests: pending,
        processedRequests: processed,
      );
      return;
    }

    final filteredRequests = state.requests.where((r) => r.accountType == accountType).toList();
    
    final pending = filteredRequests.where((r) => r.isPending).toList();
    final processed = filteredRequests.where((r) => !r.isPending).toList();

    state = state.copyWith(
      pendingRequests: pending,
      processedRequests: processed,
    );
  }

  /// 🧹 Effacer les messages
  void clearMessages() {
    state = state.copyWith(error: null, message: null, isSuccess: false);
  }

  /// 🔄 Réinitialiser l'état
  void reset() {
    state = const AccountRequestState();
  }
}

/// 📋 Provider principal pour les demandes de comptes
final accountRequestProvider = StateNotifierProvider<AccountRequestNotifier, AccountRequestState>((ref) {
  final service = ref.read(accountRequestServiceProvider);
  return AccountRequestNotifier(service);
});

/// 🔧 Provider pour le service
final accountRequestServiceProvider = Provider<AccountRequestService>((ref) {
  return AccountRequestService();
});

/// 📊 Provider pour les statistiques
final requestStatsProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(accountRequestProvider);
  return {
    'total': state.totalRequests,
    'pending': state.pendingCount,
    'approved': state.approvedCount,
    'rejected': state.rejectedCount,
  };
});

/// 📋 Provider pour les demandes en attente
final pendingRequestsProvider = Provider<List<AccountRequestModel>>((ref) {
  final state = ref.watch(accountRequestProvider);
  return state.pendingRequests;
});

/// 📋 Provider pour les demandes traitées
final processedRequestsProvider = Provider<List<AccountRequestModel>>((ref) {
  final state = ref.watch(accountRequestProvider);
  return state.processedRequests;
});

/// ⏳ Provider pour l'état de chargement
final isLoadingRequestsProvider = Provider<bool>((ref) {
  final state = ref.watch(accountRequestProvider);
  return state.isLoading;
});

/// ❌ Provider pour les erreurs
final requestErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(accountRequestProvider);
  return state.error;
});

/// 💬 Provider pour les messages
final requestMessageProvider = Provider<String?>((ref) {
  final state = ref.watch(accountRequestProvider);
  return state.message;
});
