import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🔧 Test simple de synchronisation compagnie-admin
class TestSyncSimple {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔧 Synchroniser une compagnie et son admin
  static Future<Map<String, dynamic>> syncCompanyAndAdmin({
    required String compagnieId,
    required String adminEmail,
    required bool newStatus,
  }) async {
    debugPrint('');
    debugPrint('🔧 ========== TEST SYNC SIMPLE ==========');
    debugPrint('🔧 CompagnieId: $compagnieId');
    debugPrint('🔧 Admin Email: $adminEmail');
    debugPrint('🔧 Nouveau statut: ${newStatus ? "ACTIF" : "INACTIF"}');
    
    int adminsUpdated = 0;
    List<String> updatedAdmins = [];
    
    try {
      // 1. Mettre à jour la compagnie
      await _firestore.collection('compagnies').doc(compagnieId).update({
        'status': newStatus ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSimpleSync': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('🔧 ✅ Compagnie mise à jour');
      
      // 2. Chercher et mettre à jour l'admin par email
      if (adminEmail.isNotEmpty) {
        final adminQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: adminEmail)
            .where('role', isEqualTo: 'admin_compagnie')
            .get();
            
        debugPrint('🔧 📧 Admins trouvés par email: ${adminQuery.docs.length}');
        
        for (final adminDoc in adminQuery.docs) {
          final adminData = adminDoc.data();
          final currentStatus = adminData['isActive'] ?? false;
          final adminName = adminData['displayName'] ?? '${adminData['prenom']} ${adminData['nom']}';
          
          debugPrint('🔧 👤 Admin: $adminName');
          debugPrint('🔧 📊 Statut: $currentStatus → $newStatus');
          
          // Mettre à jour l'admin
          await _firestore.collection('users').doc(adminDoc.id).update({
            'isActive': newStatus,
            'status': newStatus ? 'actif' : 'inactif',
            'updatedAt': FieldValue.serverTimestamp(),
            'lastSimpleSync': DateTime.now().millisecondsSinceEpoch,
            'syncReason': newStatus 
                ? 'RÉACTIVATION automatique compagnie'
                : 'DÉSACTIVATION automatique compagnie',
          });
          
          adminsUpdated++;
          updatedAdmins.add('$adminName (${adminDoc.id})');
          debugPrint('🔧 ✅ Admin mis à jour: $adminName');
          
          // Vérification immédiate
          await Future.delayed(const Duration(milliseconds: 200));
          final verifyDoc = await _firestore.collection('users').doc(adminDoc.id).get();
          if (verifyDoc.exists) {
            final verifyData = verifyDoc.data()!;
            final verifiedStatus = verifyData['isActive'] ?? false;
            debugPrint('🔧 🔍 VÉRIFICATION: $verifiedStatus (attendu: $newStatus)');
            
            if (verifiedStatus == newStatus) {
              debugPrint('🔧 ✅ VÉRIFICATION RÉUSSIE !');
            } else {
              debugPrint('🔧 ❌ VÉRIFICATION ÉCHOUÉE !');
            }
          }
        }
      }
      
      debugPrint('🔧 📊 RÉSULTAT: $adminsUpdated admins mis à jour');
      debugPrint('🔧 ========== FIN TEST SYNC SIMPLE ==========');
      debugPrint('');
      
      return {
        'success': true,
        'adminsUpdated': adminsUpdated,
        'updatedAdmins': updatedAdmins,
        'message': 'Synchronisation simple réussie: $adminsUpdated admin(s) ${newStatus ? "activé(s)" : "désactivé(s)"}',
      };
      
    } catch (e) {
      debugPrint('🔧 ❌ ERREUR SYNC SIMPLE: $e');
      debugPrint('🔧 ========== FIN TEST SYNC SIMPLE (ERREUR) ==========');
      debugPrint('');
      
      return {
        'success': false,
        'adminsUpdated': 0,
        'updatedAdmins': [],
        'error': e.toString(),
        'message': 'Erreur synchronisation: $e',
      };
    }
  }
  
  /// 🧪 Tester avec une compagnie spécifique
  static Future<void> testWithCompany(String compagnieId, String adminEmail, bool newStatus) async {
    debugPrint('🧪 DÉBUT TEST AVEC COMPAGNIE SPÉCIFIQUE');
    
    final result = await syncCompanyAndAdmin(
      compagnieId: compagnieId,
      adminEmail: adminEmail,
      newStatus: newStatus,
    );
    
    debugPrint('🧪 RÉSULTAT TEST:');
    debugPrint('   Success: ${result['success']}');
    debugPrint('   Admins mis à jour: ${result['adminsUpdated']}');
    debugPrint('   Message: ${result['message']}');
    
    if (result['updatedAdmins'] != null) {
      final updatedAdmins = result['updatedAdmins'] as List<String>;
      for (final admin in updatedAdmins) {
        debugPrint('   - $admin');
      }
    }
    
    debugPrint('🧪 FIN TEST');
  }
}
