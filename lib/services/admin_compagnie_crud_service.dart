import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'company_management_service.dart';

/// 🔧 Service CRUD complet pour les Admins Compagnie
class AdminCompagnieCrudService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// 📋 Obtenir tous les admins compagnie avec détails
  static Future<List<Map<String, dynamic>>> getAllAdminCompagnie() async {
    try {
      // Récupérer sans tri pour éviter l'index composite
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'admin_compagnie')
          .get();

      final admins = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Enrichir avec les données de la compagnie
        String? companyName;
        Map<String, dynamic>? companyData;
        
        if (data['compagnieId'] != null) {
          final company = await CompanyManagementService.findCompanyById(data['compagnieId']);
          if (company != null) {
            companyName = company.nom;
            companyData = {
              'id': company.id,
              'nom': company.nom,
              'code': company.code,
              'type': company.type,
            };
          }
        }

        admins.add({
          'id': doc.id,
          'uid': data['uid'],
          'email': data['email'],
          'prenom': data['prenom'],
          'nom': data['nom'],
          'displayName': data['displayName'],
          'telephone': data['telephone'],
          'status': data['status'] ?? 'actif',
          'isActive': data['isActive'] ?? true,
          'compagnieId': data['compagnieId'],
          'compagnieNom': companyName ?? data['compagnieNom'],
          'companyData': companyData,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
          'lastLoginAt': data['lastLoginAt'],
          'loginCount': data['loginCount'] ?? 0,
          'requirePasswordChange': data['requirePasswordChange'] ?? false,
          'twoFactorEnabled': data['twoFactorEnabled'] ?? false,
          'permissions': data['permissions'] ?? [],
        });
      }

      // Trier côté client par date de création (plus récent en premier)
      admins.sort((a, b) {
        final aCreated = a['createdAt'] as Timestamp?;
        final bCreated = b['createdAt'] as Timestamp?;

        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;

        return bCreated.compareTo(aCreated); // Plus récent en premier
      });

      return admins;
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Erreur récupération admins: $e');
      return [];
    }
  }

  /// 🔍 Obtenir un admin compagnie par ID
  static Future<Map<String, dynamic>?> getAdminCompagnieById(String adminId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(adminId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      
      if (data['role'] != 'admin_compagnie') {
        debugPrint('[ADMIN_COMPAGNIE_CRUD] ⚠️ Utilisateur $adminId n\'est pas un admin compagnie');
        return null;
      }

      // Enrichir avec les données de la compagnie
      String? companyName;
      Map<String, dynamic>? companyData;
      
      if (data['compagnieId'] != null) {
        final company = await CompanyManagementService.findCompanyById(data['compagnieId']);
        if (company != null) {
          companyName = company.nom;
          companyData = {
            'id': company.id,
            'nom': company.nom,
            'code': company.code,
            'type': company.type,
            'adresse': company.adresse,
            'telephone': company.telephone,
            'email': company.email,
          };
        }
      }

      return {
        'id': doc.id,
        'uid': data['uid'],
        'email': data['email'],
        'prenom': data['prenom'],
        'nom': data['nom'],
        'displayName': data['displayName'],
        'telephone': data['telephone'],
        'status': data['status'] ?? 'actif',
        'isActive': data['isActive'] ?? true,
        'compagnieId': data['compagnieId'],
        'compagnieNom': companyName ?? data['compagnieNom'],
        'companyData': companyData,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
        'lastLoginAt': data['lastLoginAt'],
        'loginCount': data['loginCount'] ?? 0,
        'requirePasswordChange': data['requirePasswordChange'] ?? false,
        'twoFactorEnabled': data['twoFactorEnabled'] ?? false,
        'permissions': data['permissions'] ?? [],
        'createdBy': data['createdBy'],
        'source': data['source'],
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Erreur récupération admin $adminId: $e');
      return null;
    }
  }

  /// ✏️ Modifier un admin compagnie
  static Future<bool> updateAdminCompagnie({
    required String adminId,
    String? prenom,
    String? nom,
    String? telephone,
    String? email,
    String? status,
    bool? isActive,
    bool? requirePasswordChange,
    bool? twoFactorEnabled,
    List<String>? permissions,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (prenom != null) {
        updateData['prenom'] = prenom;
        // Mettre à jour displayName si prenom ou nom change
        final currentData = await _firestore.collection(_usersCollection).doc(adminId).get();
        if (currentData.exists) {
          final currentNom = nom ?? currentData.data()!['nom'];
          updateData['displayName'] = '$prenom $currentNom';
        }
      }
      
      if (nom != null) {
        updateData['nom'] = nom;
        // Mettre à jour displayName si prenom ou nom change
        final currentData = await _firestore.collection(_usersCollection).doc(adminId).get();
        if (currentData.exists) {
          final currentPrenom = prenom ?? currentData.data()!['prenom'];
          updateData['displayName'] = '$currentPrenom $nom';
        }
      }
      
      if (telephone != null) updateData['telephone'] = telephone;
      if (email != null) updateData['email'] = email;
      if (status != null) updateData['status'] = status;
      if (isActive != null) updateData['isActive'] = isActive;
      if (requirePasswordChange != null) updateData['requirePasswordChange'] = requirePasswordChange;
      if (twoFactorEnabled != null) updateData['twoFactorEnabled'] = twoFactorEnabled;
      if (permissions != null) updateData['permissions'] = permissions;

      await _firestore.collection(_usersCollection).doc(adminId).update(updateData);

      debugPrint('[ADMIN_COMPAGNIE_CRUD] ✅ Admin $adminId mis à jour');
      return true;
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Erreur mise à jour admin $adminId: $e');
      return false;
    }
  }

  /// 🗑️ Supprimer un admin compagnie
  static Future<bool> deleteAdminCompagnie(String adminId) async {
    try {
      // Récupérer les données avant suppression
      final adminData = await getAdminCompagnieById(adminId);
      if (adminData == null) {
        debugPrint('[ADMIN_COMPAGNIE_CRUD] ⚠️ Admin $adminId non trouvé');
        return false;
      }

      // Supprimer l'admin de la compagnie
      if (adminData['compagnieId'] != null) {
        await CompanyManagementService.removeCompanyAdmin(adminData['compagnieId']);
      }

      // Supprimer le document utilisateur
      await _firestore.collection(_usersCollection).doc(adminId).delete();

      // Log de sécurité
      await _logSecurityEvent(
        action: 'admin_compagnie_deleted',
        targetUserId: adminId,
        targetEmail: adminData['email'],
        details: {
          'prenom': adminData['prenom'],
          'nom': adminData['nom'],
          'compagnieId': adminData['compagnieId'],
          'compagnieNom': adminData['compagnieNom'],
        },
      );

      debugPrint('[ADMIN_COMPAGNIE_CRUD] ✅ Admin $adminId supprimé');
      return true;
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Erreur suppression admin $adminId: $e');
      return false;
    }
  }

  /// 🔒 Désactiver un admin compagnie et libérer la compagnie
  static Future<bool> deactivateAdminCompagnie(String adminId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] 🔒 Désactivation admin: $adminId');

      // 1. Récupérer les données de l'admin pour connaître sa compagnie
      final adminDoc = await _firestore.collection(_usersCollection).doc(adminId).get();

      if (!adminDoc.exists) {
        debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Admin non trouvé: $adminId');
        return false;
      }

      final adminData = adminDoc.data()!;
      final compagnieId = adminData['compagnieId'] as String?;

      // 2. Désactiver l'admin
      await _firestore.collection(_usersCollection).doc(adminId).update({
        'status': 'inactif',
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. 🎯 LIBÉRER LA COMPAGNIE si elle était assignée
      if (compagnieId != null && compagnieId.isNotEmpty) {
        await _firestore.collection('compagnies').doc(compagnieId).update({
          'adminCompagnieId': FieldValue.delete(),
          'adminCompagnieNom': FieldValue.delete(),
          'adminCompagnieEmail': FieldValue.delete(),
          'adminAssignedAt': FieldValue.delete(),
          'adminDeactivatedAt': FieldValue.serverTimestamp(),
          'isAvailable': true, // Marquer comme disponible
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('[ADMIN_COMPAGNIE_CRUD] ✅ Compagnie $compagnieId libérée');
      }

      debugPrint('[ADMIN_COMPAGNIE_CRUD] ✅ Admin $adminId désactivé et compagnie libérée');
      return true;
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Erreur désactivation admin $adminId: $e');
      return false;
    }
  }

  /// 🔓 Réactiver un admin compagnie et réassigner la compagnie
  static Future<bool> reactivateAdminCompagnie(String adminId) async {
    try {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] 🔓 Réactivation admin: $adminId');

      // 1. Récupérer les données de l'admin
      final adminDoc = await _firestore.collection(_usersCollection).doc(adminId).get();

      if (!adminDoc.exists) {
        debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Admin non trouvé: $adminId');
        return false;
      }

      final adminData = adminDoc.data()!;
      final compagnieId = adminData['compagnieId'] as String?;

      // 2. Vérifier si la compagnie est toujours disponible
      if (compagnieId != null && compagnieId.isNotEmpty) {
        final compagnieDoc = await _firestore.collection('compagnies').doc(compagnieId).get();

        if (compagnieDoc.exists) {
          final compagnieData = compagnieDoc.data()!;
          final currentAdminId = compagnieData['adminCompagnieId'] as String?;

          // Si la compagnie a déjà un autre admin actif, on ne peut pas réactiver
          if (currentAdminId != null && currentAdminId != adminId) {
            debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Compagnie déjà occupée par un autre admin');
            return false;
          }
        }
      }

      // 3. Réactiver l'admin
      await _firestore.collection(_usersCollection).doc(adminId).update({
        'status': 'actif',
        'isActive': true,
        'reactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. 🎯 RÉASSIGNER LA COMPAGNIE
      if (compagnieId != null && compagnieId.isNotEmpty) {
        final adminDisplayName = adminData['displayName'] ?? '${adminData['prenom']} ${adminData['nom']}';

        await _firestore.collection('compagnies').doc(compagnieId).update({
          'adminCompagnieId': adminId,
          'adminCompagnieNom': adminDisplayName,
          'adminCompagnieEmail': adminData['email'],
          'adminAssignedAt': FieldValue.serverTimestamp(),
          'adminDeactivatedAt': FieldValue.delete(),
          'isAvailable': false, // Marquer comme occupée
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('[ADMIN_COMPAGNIE_CRUD] ✅ Compagnie $compagnieId réassignée');
      }

      debugPrint('[ADMIN_COMPAGNIE_CRUD] ✅ Admin $adminId réactivé et compagnie réassignée');
      return true;
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Erreur réactivation admin $adminId: $e');
      return false;
    }
  }

  /// 🔄 Changer la compagnie d'un admin
  static Future<bool> changeAdminCompany({
    required String adminId,
    required String newCompanyId,
  }) async {
    try {
      // Récupérer les données actuelles
      final adminData = await getAdminCompagnieById(adminId);
      if (adminData == null) return false;

      // Supprimer l'admin de l'ancienne compagnie
      if (adminData['compagnieId'] != null) {
        await CompanyManagementService.removeCompanyAdmin(adminData['compagnieId']);
      }

      // Récupérer les données de la nouvelle compagnie
      final newCompany = await CompanyManagementService.findCompanyById(newCompanyId);
      if (newCompany == null) {
        debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Nouvelle compagnie $newCompanyId non trouvée');
        return false;
      }

      // Mettre à jour l'admin
      await _firestore.collection(_usersCollection).doc(adminId).update({
        'compagnieId': newCompanyId,
        'compagnieNom': newCompany.nom,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Assigner l'admin à la nouvelle compagnie
      await CompanyManagementService.updateCompanyAdmin(
        companyId: newCompanyId,
        adminId: adminId,
        adminNom: adminData['displayName'],
        adminEmail: adminData['email'],
      );

      debugPrint('[ADMIN_COMPAGNIE_CRUD] ✅ Admin $adminId transféré vers ${newCompany.nom}');
      return true;
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Erreur changement compagnie: $e');
      return false;
    }
  }

  /// 📊 Obtenir les statistiques des admins compagnie
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final admins = await getAllAdminCompagnie();
      
      final totalAdmins = admins.length;
      final activeAdmins = admins.where((a) => a['isActive'] == true).length;
      final inactiveAdmins = totalAdmins - activeAdmins;
      final adminsWithLogin = admins.where((a) => (a['loginCount'] ?? 0) > 0).length;

      return {
        'totalAdmins': totalAdmins,
        'activeAdmins': activeAdmins,
        'inactiveAdmins': inactiveAdmins,
        'adminsWithLogin': adminsWithLogin,
        'loginRate': totalAdmins > 0 ? (adminsWithLogin / totalAdmins * 100).round() : 0,
      };
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ❌ Erreur statistiques: $e');
      return {
        'totalAdmins': 0,
        'activeAdmins': 0,
        'inactiveAdmins': 0,
        'adminsWithLogin': 0,
        'loginRate': 0,
      };
    }
  }

  /// 📝 Log de sécurité
  static Future<void> _logSecurityEvent({
    required String action,
    required String targetUserId,
    required String targetEmail,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('security_logs').add({
        'action': action,
        'targetUserId': targetUserId,
        'targetEmail': targetEmail,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'admin_compagnie_crud_service',
      });
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CRUD] ⚠️ Erreur log sécurité: $e');
    }
  }
}
