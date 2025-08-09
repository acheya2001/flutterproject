import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'email_notification_service.dart';

/// 🔧 Service de gestion des admins agences
class AdminAgenceManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔄 Réinitialiser le mot de passe d'un admin agence
  static Future<Map<String, dynamic>> resetAdminPassword({
    required String adminId,
    required String adminEmail,
    required String adminName,
    required String agenceName,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] 🔄 Réinitialisation mot de passe: $adminEmail');

      // Générer un nouveau mot de passe
      final newPassword = _generatePassword();

      // Mettre à jour dans Firestore
      await _firestore.collection('users').doc(adminId).update({
        'password': newPassword,
        'mustChangePassword': true,
        'passwordResetAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Envoyer le nouveau mot de passe par email
      final emailResult = await EmailNotificationService.sendPasswordResetEmail(
        toEmail: adminEmail,
        adminName: adminName,
        newPassword: newPassword,
        agenceName: agenceName,
      );

      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ✅ Mot de passe réinitialisé: $newPassword');
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] 📧 Email envoyé: ${emailResult['success']}');

      return {
        'success': true,
        'newPassword': newPassword,
        'emailSent': emailResult['success'],
        'message': emailResult['success']
            ? 'Mot de passe réinitialisé et envoyé par email'
            : 'Mot de passe réinitialisé (erreur envoi email)',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ❌ Erreur réinitialisation: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la réinitialisation du mot de passe',
      };
    }
  }

  /// 🚫 Retirer un admin d'une agence (le désactiver)
  static Future<Map<String, dynamic>> removeAdminFromAgence({
    required String adminId,
    required String agenceId,
    required String reason,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] 🚫 Retrait admin: $adminId de agence: $agenceId');

      // Désactiver l'admin
      await _firestore.collection('users').doc(adminId).update({
        'isActive': false,
        'status': 'inactif',
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'agence pour indiquer qu'elle n'a plus d'admin
      await _firestore.collection('agences').doc(agenceId).update({
        'hasAdminAgence': false,
        'adminAgenceId': FieldValue.delete(),
        'adminAgenceEmail': FieldValue.delete(),
        'adminAgence': FieldValue.delete(), // Supprimer les données de l'admin
        'statut': 'libre',
        'dateRetraitAdmin': FieldValue.serverTimestamp(),
        'retraitAdminReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ✅ Admin retiré avec succès');

      return {
        'success': true,
        'message': 'Admin retiré de l\'agence avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ❌ Erreur retrait admin: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors du retrait de l\'admin',
      };
    }
  }

  /// ⚡ Activer/Désactiver un admin agence
  static Future<Map<String, dynamic>> toggleAdminStatus({
    required String adminId,
    required bool newStatus,
    String? reason,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ⚡ Changement statut admin: $adminId -> $newStatus');

      final updateData = {
        'isActive': newStatus,
        'status': newStatus ? 'actif' : 'inactif',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!newStatus) {
        updateData['deactivatedAt'] = FieldValue.serverTimestamp();
        updateData['deactivationReason'] = reason ?? 'Désactivé par admin';
      } else {
        updateData['reactivatedAt'] = FieldValue.serverTimestamp();
      }

      // 1. Récupérer les infos de l'admin pour trouver son agence
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      if (!adminDoc.exists) {
        return {
          'success': false,
          'message': 'Admin agence non trouvé',
        };
      }

      final adminData = adminDoc.data()!;
      final agenceId = adminData['agenceId'];

      // 2. Mettre à jour l'admin
      await _firestore.collection('users').doc(adminId).update(updateData);

      // 3. Mettre à jour l'agence selon le statut de l'admin
      if (agenceId != null) {
        final agenceUpdateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!newStatus) {
          // Admin désactivé → agence devient libre
          agenceUpdateData['hasAdminAgence'] = false;
          agenceUpdateData['statut'] = 'libre';
          agenceUpdateData['adminAgenceId'] = FieldValue.delete();
          agenceUpdateData['adminAgenceEmail'] = FieldValue.delete();
          agenceUpdateData['adminAgence'] = FieldValue.delete();
          agenceUpdateData['adminLibereAt'] = FieldValue.serverTimestamp();
          agenceUpdateData['adminLibereReason'] = reason ?? 'Admin agence désactivé';
        } else {
          // Admin réactivé → agence devient occupée
          agenceUpdateData['hasAdminAgence'] = true;
          agenceUpdateData['statut'] = 'occupé';
          agenceUpdateData['adminAgenceId'] = adminId;
          agenceUpdateData['adminReaffecteAt'] = FieldValue.serverTimestamp();
        }

        await _firestore.collection('agences').doc(agenceId).update(agenceUpdateData);

        debugPrint('[ADMIN_AGENCE_MANAGEMENT] ✅ Agence mise à jour: ${agenceUpdateData['statut']}');
      }

      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ✅ Statut admin modifié');

      return {
        'success': true,
        'message': newStatus
            ? 'Admin agence activé et agence réaffectée'
            : 'Admin agence désactivé et agence libérée',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ❌ Erreur changement statut: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors du changement de statut',
      };
    }
  }

  /// 🏪 Activer/Désactiver une agence (et son admin)
  static Future<Map<String, dynamic>> toggleAgenceStatus({
    required String agenceId,
    required bool newStatus,
    String? reason,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] 🏪 Changement statut agence: $agenceId -> $newStatus');

      // Mettre à jour l'agence
      final agenceUpdateData = {
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!newStatus) {
        agenceUpdateData['deactivatedAt'] = FieldValue.serverTimestamp();
        agenceUpdateData['deactivationReason'] = reason ?? 'Désactivée par admin';
      } else {
        agenceUpdateData['reactivatedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('agences').doc(agenceId).update(agenceUpdateData);

      // Si l'agence est désactivée, désactiver aussi son admin
      if (!newStatus) {
        final adminSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin_agence')
            .where('agenceId', isEqualTo: agenceId)
            .where('isActive', isEqualTo: true)
            .get();

        for (var adminDoc in adminSnapshot.docs) {
          await _firestore.collection('users').doc(adminDoc.id).update({
            'isActive': false,
            'status': 'inactif',
            'deactivatedAt': FieldValue.serverTimestamp(),
            'deactivationReason': 'Agence désactivée',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Désactiver aussi tous les agents de l'agence
        final agentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('agenceId', isEqualTo: agenceId)
            .where('isActive', isEqualTo: true)
            .get();

        for (var agentDoc in agentsSnapshot.docs) {
          await _firestore.collection('users').doc(agentDoc.id).update({
            'isActive': false,
            'status': 'inactif',
            'deactivatedAt': FieldValue.serverTimestamp(),
            'deactivationReason': 'Agence désactivée',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ✅ Statut agence modifié');

      return {
        'success': true,
        'message': newStatus 
            ? 'Agence activée avec succès' 
            : 'Agence et ses utilisateurs désactivés avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ❌ Erreur changement statut agence: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors du changement de statut de l\'agence',
      };
    }
  }

  /// 👥 Obtenir la liste des admins agences disponibles pour affectation
  static Future<List<Map<String, dynamic>>> getAvailableAdminsAgence({
    required String compagnieId,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] 👥 Recherche admins disponibles pour: $compagnieId');

      // Chercher les admins agences sans agence assignée ou inactifs
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      final availableAdmins = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Vérifier si l'admin n'est pas déjà assigné à une agence active
        final agenceId = data['agenceId'];
        if (agenceId != null) {
          final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
          if (agenceDoc.exists && agenceDoc.data()?['hasAdminAgence'] == true) {
            continue; // Admin déjà assigné
          }
        }

        availableAdmins.add(data);
      }

      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ✅ ${availableAdmins.length} admins disponibles trouvés');

      return availableAdmins;

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ❌ Erreur recherche admins: $e');
      return [];
    }
  }

  /// 🔗 Affecter un admin existant à une agence
  static Future<Map<String, dynamic>> assignAdminToAgence({
    required String adminId,
    required String agenceId,
    required String agenceNom,
  }) async {
    try {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] 🔗 Affectation admin: $adminId à agence: $agenceId');

      // Mettre à jour l'admin
      await _firestore.collection('users').doc(adminId).update({
        'agenceId': agenceId,
        'agenceNom': agenceNom,
        'isActive': true,
        'status': 'actif',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'agence
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      final adminData = adminDoc.data()!;

      await _firestore.collection('agences').doc(agenceId).update({
        'hasAdminAgence': true,
        'adminAgenceId': adminId,
        'adminAgenceEmail': adminData['email'],
        'statut': 'occupé',
        'dateAffectationAdmin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ✅ Admin affecté avec succès');

      return {
        'success': true,
        'message': 'Admin affecté à l\'agence avec succès',
      };

    } catch (e) {
      debugPrint('[ADMIN_AGENCE_MANAGEMENT] ❌ Erreur affectation: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de l\'affectation de l\'admin',
      };
    }
  }

  /// 🔐 Générer un mot de passe aléatoire
  static String _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      8, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }
}
