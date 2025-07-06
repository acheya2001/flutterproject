import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../models/professional_request_model_final.dart';
import '../../services/professional_request_service.dart';
import '../../services/account_creation_email_service.dart';

/// 📝 Provider pour les demandes professionnelles
final professionalRequestsProvider = FutureProvider<List<ProfessionalRequestModel>>((ref) async {
  return await ProfessionalRequestService.getAllRequests();
});

/// 📝 Provider pour les demandes en attente
final pendingRequestsProvider = FutureProvider<List<ProfessionalRequestModel>>((ref) async {
  return await ProfessionalRequestService.getPendingRequests();
});

/// 📝 Stream provider pour les demandes en temps réel
final professionalRequestsStreamProvider = StreamProvider<List<ProfessionalRequestModel>>((ref) {
  return ProfessionalRequestService.getRequestsStream();
});

/// 📝 Stream provider pour les demandes en attente en temps réel
final pendingRequestsStreamProvider = StreamProvider<List<ProfessionalRequestModel>>((ref) {
  return ProfessionalRequestService.getPendingRequestsStream();
});

/// 📊 Provider pour les statistiques des demandes
final requestsStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await ProfessionalRequestService.getRequestsStats();
});

/// 🎯 Provider pour la recherche de demandes
final requestSearchProvider = StateProvider<String>((ref) => '');

/// 🎯 Provider pour le filtre par statut
final requestStatusFilterProvider = StateProvider<String>((ref) => 'tous');

/// 🎯 Provider pour le filtre par type
final requestTypeFilterProvider = StateProvider<String>((ref) => 'tous');

/// 📝 Provider pour les demandes filtrées
final filteredRequestsProvider = Provider<AsyncValue<List<ProfessionalRequestModel>>>((ref) {
  final requestsAsync = ref.watch(professionalRequestsStreamProvider);
  final searchTerm = ref.watch(requestSearchProvider);
  final statusFilter = ref.watch(requestStatusFilterProvider);
  final typeFilter = ref.watch(requestTypeFilterProvider);

  return requestsAsync.when(
    data: (requests) {
      var filteredRequests = requests;

      // Filtre par recherche
      if (searchTerm.isNotEmpty) {
        final searchLower = searchTerm.toLowerCase();
        filteredRequests = filteredRequests.where((request) {
          return request.nom.toLowerCase().contains(searchLower) ||
                 request.prenom.toLowerCase().contains(searchLower) ||
                 request.email.toLowerCase().contains(searchLower) ||
                 request.telephone.contains(searchTerm) ||
                 request.compagnieAssurance.toLowerCase().contains(searchLower) ||
                 request.agence.toLowerCase().contains(searchLower);
        }).toList();
      }

      // Filtre par statut
      if (statusFilter != 'tous') {
        filteredRequests = filteredRequests.where((request) {
          return request.statut == statusFilter;
        }).toList();
      }

      // Filtre par type
      if (typeFilter != 'tous') {
        filteredRequests = filteredRequests.where((request) {
          return request.typeCompte == typeFilter;
        }).toList();
      }

      return AsyncValue.data(filteredRequests);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// 🎯 Notifier pour les actions sur les demandes
class RequestActionsNotifier extends StateNotifier<AsyncValue<void>> {
  RequestActionsNotifier() : super(const AsyncValue.data(null));

  /// ✅ Approuver une demande
  Future<bool> approveRequest(
    String requestId,
    String adminId, {
    String? commentaire,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await ProfessionalRequestService.approveRequest(
        requestId,
        adminId,
        commentaire: commentaire,
      );

      if (success) {
        // Créer le compte utilisateur
        final request = await ProfessionalRequestService.getRequestById(requestId);
        if (request != null) {
          final accountResult = await ProfessionalRequestService.createUserAccount(request);

          if (accountResult['success'] == true) {
            // Compte créé avec succès
            debugPrint('[APPROVAL] ✅ Compte créé - UID: ${accountResult['uid']}');
            debugPrint('[APPROVAL] 🔐 Mot de passe temporaire: ${accountResult['temporaryPassword']}');

            // Envoyer les identifiants par email
            final emailSent = await AccountCreationEmailService.sendAccountCredentials(
              request: request,
              temporaryPassword: accountResult['temporaryPassword'],
              uid: accountResult['uid'],
            );

            if (emailSent) {
              debugPrint('[APPROVAL] ✅ Email avec identifiants envoyé');
            } else {
              debugPrint('[APPROVAL] ⚠️ Erreur envoi email - Compte créé mais email non envoyé');
            }
          } else {
            debugPrint('[APPROVAL] ❌ Erreur création compte: ${accountResult['error']}');
            // La demande est approuvée mais le compte n'a pas pu être créé
            // L'admin devra créer le compte manuellement
          }
        }

        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('Erreur lors de l\'approbation', StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// ❌ Rejeter une demande
  Future<bool> rejectRequest(
    String requestId,
    String adminId, {
    required String commentaire,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await ProfessionalRequestService.rejectRequest(
        requestId,
        adminId,
        commentaire: commentaire,
      );

      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('Erreur lors du rejet', StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// 🗑️ Supprimer une demande
  Future<bool> deleteRequest(String requestId) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await ProfessionalRequestService.deleteRequest(requestId);

      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('Erreur lors de la suppression', StackTrace.current);
        return false;
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// 🎯 Provider pour les actions sur les demandes
final requestActionsProvider = StateNotifierProvider<RequestActionsNotifier, AsyncValue<void>>((ref) {
  return RequestActionsNotifier();
});

/// 📊 Provider pour les statistiques calculées
final calculatedStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final requestsAsync = ref.watch(professionalRequestsStreamProvider);
  
  return requestsAsync.when(
    data: (requests) {
      final stats = <String, dynamic>{
        'total': requests.length,
        'en_attente': requests.where((r) => r.statut == 'en_attente').length,
        'approuvees': requests.where((r) => r.statut == 'approuvee').length,
        'rejetees': requests.where((r) => r.statut == 'rejetee').length,
        'agents': requests.where((r) => r.typeCompte == 'agent').length,
        'experts': requests.where((r) => r.typeCompte == 'expert').length,
      };

      // Calculer les pourcentages
      if (stats['total'] > 0) {
        stats['pourcentage_attente'] = ((stats['en_attente'] / stats['total']) * 100).round();
        stats['pourcentage_approuvees'] = ((stats['approuvees'] / stats['total']) * 100).round();
        stats['pourcentage_rejetees'] = ((stats['rejetees'] / stats['total']) * 100).round();
      } else {
        stats['pourcentage_attente'] = 0;
        stats['pourcentage_approuvees'] = 0;
        stats['pourcentage_rejetees'] = 0;
      }

      // Calculer les tendances (simulation basée sur les données récentes)
      final recentRequests = requests.where((r) {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        return r.envoyeLe.isAfter(weekAgo);
      }).length;

      stats['nouvelles_cette_semaine'] = recentRequests;
      stats['tendance'] = recentRequests > 0 ? 'hausse' : 'stable';

      return stats;
    },
    loading: () => <String, dynamic>{
      'total': 0,
      'en_attente': 0,
      'approuvees': 0,
      'rejetees': 0,
      'agents': 0,
      'experts': 0,
      'pourcentage_attente': 0,
      'pourcentage_approuvees': 0,
      'pourcentage_rejetees': 0,
      'nouvelles_cette_semaine': 0,
      'tendance': 'stable',
    },
    error: (_, __) => <String, dynamic>{
      'total': 0,
      'en_attente': 0,
      'approuvees': 0,
      'rejetees': 0,
      'agents': 0,
      'experts': 0,
      'pourcentage_attente': 0,
      'pourcentage_approuvees': 0,
      'pourcentage_rejetees': 0,
      'nouvelles_cette_semaine': 0,
      'tendance': 'erreur',
    },
  );
});

/// 🔍 Provider pour la recherche asynchrone
final asyncSearchProvider = FutureProvider.family<List<ProfessionalRequestModel>, String>((ref, query) async {
  if (query.isEmpty) {
    return await ProfessionalRequestService.getAllRequests();
  }
  return await ProfessionalRequestService.searchRequests(query);
});

/// 📝 Provider pour une demande spécifique
final requestByIdProvider = FutureProvider.family<ProfessionalRequestModel?, String>((ref, requestId) async {
  return await ProfessionalRequestService.getRequestById(requestId);
});
