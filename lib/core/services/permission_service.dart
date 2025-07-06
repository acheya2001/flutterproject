import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/app_enums.dart';
import '../constants/app_constants.dart';
import '../services/firebase_service.dart';
import '../../shared/models/user_model.dart';

/// 🔐 Service de gestion des permissions
class PermissionService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// 🎯 Permissions par défaut selon le rôle
  static const Map<UserRole, List<Permission>> defaultPermissions = {
    UserRole.superAdmin: [
      // Toutes les permissions
      Permission.createContract,
      Permission.editContract,
      Permission.deleteContract,
      Permission.viewAllContracts,
      Permission.manageAgents,
      Permission.manageClients,
      Permission.manageExperts,
      Permission.validateAccounts,
      Permission.processClaimsLevel1,
      Permission.processClaimsLevel2,
      Permission.assignExperts,
      Permission.generateReports,
      Permission.viewStatistics,
      Permission.exportData,
      Permission.manageCompanies,
      Permission.manageAgencies,
      Permission.systemConfiguration,
    ],
    UserRole.companyAdmin: [
      Permission.createContract,
      Permission.editContract,
      Permission.viewAllContracts,
      Permission.manageAgents,
      Permission.manageClients,
      Permission.manageExperts,
      Permission.validateAccounts,
      Permission.processClaimsLevel2,
      Permission.assignExperts,
      Permission.generateReports,
      Permission.viewStatistics,
      Permission.exportData,
      Permission.manageAgencies,
    ],
    UserRole.agencyAdmin: [
      Permission.createContract,
      Permission.editContract,
      Permission.viewAllContracts,
      Permission.manageAgents,
      Permission.manageClients,
      Permission.processClaimsLevel1,
      Permission.processClaimsLevel2,
      Permission.generateReports,
      Permission.viewStatistics,
    ],
    UserRole.agent: [
      Permission.createContract,
      Permission.editContract,
      Permission.manageClients,
      Permission.processClaimsLevel1,
    ],
    UserRole.driver: [],
    UserRole.expert: [
      Permission.processClaimsLevel1,
      Permission.processClaimsLevel2,
    ],
  };

  /// ✅ Vérifie si un utilisateur a une permission spécifique
  Future<bool> hasPermission(String userId, Permission permission) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final userRole = UserRole.fromString(userData['role']);
      final userPermissions = (userData['permissions'] as List<dynamic>?)
          ?.map((p) => Permission.fromString(p.toString()))
          .toList() ?? [];

      // Vérifier les permissions par défaut du rôle
      final rolePermissions = defaultPermissions[userRole] ?? [];
      if (rolePermissions.contains(permission)) return true;

      // Vérifier les permissions personnalisées
      return userPermissions.contains(permission);
    } catch (e) {
      return false;
    }
  }

  /// 📋 Récupère toutes les permissions d'un utilisateur
  Future<List<Permission>> getUserPermissions(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final userRole = UserRole.fromString(userData['role']);
      final userPermissions = (userData['permissions'] as List<dynamic>?)
          ?.map((p) => Permission.fromString(p.toString()))
          .toList() ?? [];

      // Combiner permissions par défaut et personnalisées
      final rolePermissions = defaultPermissions[userRole] ?? [];
      final allPermissions = <Permission>{...rolePermissions, ...userPermissions};

      return allPermissions.toList();
    } catch (e) {
      return [];
    }
  }

  /// ➕ Ajoute une permission à un utilisateur
  Future<bool> addPermission(
    String userId,
    Permission permission,
    String grantedBy,
  ) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentPermissions = (userData['permissions'] as List<dynamic>?)
          ?.map((p) => p.toString())
          .toList() ?? [];

      if (!currentPermissions.contains(permission.value)) {
        currentPermissions.add(permission.value);

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({
          'permissions': currentPermissions,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': grantedBy,
        });

        // Log de l'action
        await _logPermissionChange(
          userId,
          'add',
          permission,
          grantedBy,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ➖ Retire une permission d'un utilisateur
  Future<bool> removePermission(
    String userId,
    Permission permission,
    String removedBy,
  ) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final currentPermissions = (userData['permissions'] as List<dynamic>?)
          ?.map((p) => p.toString())
          .toList() ?? [];

      if (currentPermissions.contains(permission.value)) {
        currentPermissions.remove(permission.value);

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({
          'permissions': currentPermissions,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': removedBy,
        });

        // Log de l'action
        await _logPermissionChange(
          userId,
          'remove',
          permission,
          removedBy,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🔄 Met à jour toutes les permissions d'un utilisateur
  Future<bool> updateUserPermissions(
    String userId,
    List<Permission> permissions,
    String updatedBy,
  ) async {
    try {
      final permissionValues = permissions.map((p) => p.value).toList();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'permissions': permissionValues,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      });

      // Log de l'action
      await _logPermissionChange(
        userId,
        'update',
        null,
        updatedBy,
        metadata: {'newPermissions': permissionValues},
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🔍 Vérifie les permissions hiérarchiques
  Future<bool> canManageUser(String managerId, String targetUserId) async {
    try {
      final managerDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(managerId)
          .get();

      final targetDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(targetUserId)
          .get();

      if (!managerDoc.exists || !targetDoc.exists) return false;

      final managerRole = UserRole.fromString(managerDoc.data()!['role']);
      final targetRole = UserRole.fromString(targetDoc.data()!['role']);

      // Vérification hiérarchique
      return managerRole.hierarchyLevel <= targetRole.hierarchyLevel;
    } catch (e) {
      return false;
    }
  }

  /// 🏢 Vérifie les permissions dans le contexte d'une compagnie/agence
  Future<bool> hasContextualPermission(
    String userId,
    Permission permission,
    String? companyId,
    String? agencyId,
  ) async {
    try {
      // Vérifier d'abord la permission de base
      final hasBasePermission = await hasPermission(userId, permission);
      if (!hasBasePermission) return false;

      // Si pas de contexte spécifique, la permission de base suffit
      if (companyId == null && agencyId == null) return true;

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final userRole = UserRole.fromString(userData['role']);

      // Super admin a accès à tout
      if (userRole == UserRole.superAdmin) return true;

      // Vérifier le contexte selon le rôle
      switch (userRole) {
        case UserRole.companyAdmin:
          // Peut gérer sa compagnie
          return userData['companyId'] == companyId;
        case UserRole.agencyAdmin:
          // Peut gérer son agence
          return userData['agencyId'] == agencyId;
        case UserRole.agent:
          // Peut gérer dans son agence
          return userData['agencyId'] == agencyId;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 📝 Log des changements de permissions
  Future<void> _logPermissionChange(
    String userId,
    String action,
    Permission? permission,
    String changedBy, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('permission_logs').add({
        'userId': userId,
        'action': action,
        'permission': permission?.value,
        'changedBy': changedBy,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata,
      });
    } catch (e) {
      // Log silencieux en cas d'erreur
    }
  }

  /// 🎭 Vérifie si un utilisateur peut accéder à une route
  Future<bool> canAccessRoute(String userId, String route) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final userRole = UserRole.fromString(userData['role']);
      final accountStatus = AccountStatus.fromString(userData['status']);

      // Vérifier le statut du compte
      if (accountStatus != AccountStatus.active) return false;

      // Définir les routes accessibles par rôle
      final Map<UserRole, List<String>> roleRoutes = {
        UserRole.superAdmin: ['*'], // Accès à tout
        UserRole.companyAdmin: ['/company-admin', '/admin'],
        UserRole.agencyAdmin: ['/agency-admin', '/admin'],
        UserRole.agent: ['/agent'],
        UserRole.driver: ['/driver'],
        UserRole.expert: ['/expert'],
      };

      final allowedRoutes = roleRoutes[userRole] ?? [];
      
      // Super admin a accès à tout
      if (allowedRoutes.contains('*')) return true;

      // Vérifier si la route est autorisée
      return allowedRoutes.any((allowedRoute) => route.startsWith(allowedRoute));
    } catch (e) {
      return false;
    }
  }
}

/// 🔐 Provider pour PermissionService
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// 👤 Provider pour les permissions de l'utilisateur actuel
final currentUserPermissionsProvider = FutureProvider<List<Permission>>((ref) async {
  final currentUser = FirebaseService.currentUser;
  if (currentUser == null) return [];

  final permissionService = ref.read(permissionServiceProvider);
  return await permissionService.getUserPermissions(currentUser.uid);
});

/// ✅ Provider pour vérifier une permission spécifique
final hasPermissionProvider = FutureProvider.family<bool, Permission>((ref, permission) async {
  final currentUser = FirebaseService.currentUser;
  if (currentUser == null) return false;

  final permissionService = ref.read(permissionServiceProvider);
  return await permissionService.hasPermission(currentUser.uid, permission);
});
