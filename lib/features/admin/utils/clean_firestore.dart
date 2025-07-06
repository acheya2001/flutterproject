import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/constants/app_constants.dart';

/// 🧹 Utilitaire pour nettoyer complètement Firestore
class CleanFirestore {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final FirebaseAuth _auth = FirebaseService.auth;

  /// 🗑️ Supprimer toutes les collections
  static Future<void> deleteAllCollections() async {
    try {
      debugPrint('[CLEAN_FIRESTORE] 🧹 Nettoyage complet de Firestore...');

      // Liste de toutes les collections à supprimer
      final collections = [
        AppConstants.usersCollection,
        AppConstants.driversCollection,
        AppConstants.agentsCollection,
        AppConstants.expertsCollection,
        AppConstants.companiesCollection,
        AppConstants.agenciesCollection,
        AppConstants.contractsCollection,
        AppConstants.vehiclesCollection,
        AppConstants.claimsCollection,
        AppConstants.documentsCollection,
        AppConstants.notificationsCollection,
        AppConstants.messagesCollection,
        AppConstants.accountRequestsCollection,
        // Ajoutez d'autres collections si nécessaire
        'test_data',
        'temp_data',
        'admin_logs',
      ];

      int totalDeleted = 0;

      for (final collectionName in collections) {
        try {
          final deleted = await _deleteCollection(collectionName);
          totalDeleted += deleted;
          debugPrint('[CLEAN_FIRESTORE] ✅ Collection "$collectionName": $deleted documents supprimés');
        } catch (e) {
          debugPrint('[CLEAN_FIRESTORE] ❌ Erreur pour "$collectionName": $e');
        }
      }

      debugPrint('[CLEAN_FIRESTORE] 🎉 Nettoyage terminé ! Total: $totalDeleted documents supprimés');

    } catch (e) {
      debugPrint('[CLEAN_FIRESTORE] ❌ Erreur générale: $e');
      rethrow;
    }
  }

  /// 🗑️ Supprimer une collection spécifique
  static Future<int> _deleteCollection(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      
      if (snapshot.docs.isEmpty) {
        return 0;
      }

      // Supprimer par batch pour éviter les timeouts
      final batch = _firestore.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        
        // Exécuter le batch tous les 500 documents
        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      // Exécuter le batch final
      if (count % 500 != 0) {
        await batch.commit();
      }

      return count;
    } catch (e) {
      debugPrint('[CLEAN_FIRESTORE] Erreur lors de la suppression de $collectionName: $e');
      return 0;
    }
  }

  /// 🔥 Supprimer tous les utilisateurs Firebase Auth
  static Future<void> deleteAllAuthUsers() async {
    try {
      debugPrint('[CLEAN_FIRESTORE] 🔥 Suppression des utilisateurs Auth...');
      
      // Note: Cette opération nécessite des privilèges admin
      // En production, utilisez Firebase Admin SDK côté serveur
      
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
        debugPrint('[CLEAN_FIRESTORE] ✅ Utilisateur actuel supprimé');
      }

      await _auth.signOut();
      debugPrint('[CLEAN_FIRESTORE] ✅ Déconnexion effectuée');

    } catch (e) {
      debugPrint('[CLEAN_FIRESTORE] ❌ Erreur suppression Auth: $e');
    }
  }

  /// 🆕 Créer le Super Admin après nettoyage
  static Future<void> createFreshSuperAdmin() async {
    try {
      debugPrint('[CLEAN_FIRESTORE] 🆕 Création du Super Admin...');

      const email = 'constat.tunisie.app@gmail.com';
      const password = 'Acheya123';

      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Créer le document Firestore avec structure simple
      await _firestore.collection(AppConstants.usersCollection).doc(userId).set({
        'id': userId,
        'email': email,
        'firstName': 'Super',
        'lastName': 'Admin',
        'phone': '+216 70 000 000',
        'role': 'super_admin',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'SYSTEM',
        'cin': 'SUPER_ADMIN',
        'address': 'Tunis, Tunisie',
      });

      // Mettre à jour le profil
      await userCredential.user!.updateDisplayName('Super Admin');

      debugPrint('[CLEAN_FIRESTORE] ✅ Super Admin créé avec succès !');
      debugPrint('[CLEAN_FIRESTORE] 🆔 UID: $userId');
      debugPrint('[CLEAN_FIRESTORE] 📧 Email: $email');
      debugPrint('[CLEAN_FIRESTORE] 🔑 Mot de passe: $password');

      // Se déconnecter
      await _auth.signOut();

    } catch (e) {
      debugPrint('[CLEAN_FIRESTORE] ❌ Erreur création Super Admin: $e');
      rethrow;
    }
  }

  /// 🔄 Nettoyage complet et recréation
  static Future<void> fullReset() async {
    try {
      debugPrint('[CLEAN_FIRESTORE] 🔄 RESET COMPLET EN COURS...');

      // 1. Supprimer toutes les collections
      await deleteAllCollections();

      // 2. Supprimer les utilisateurs Auth (optionnel)
      // await deleteAllAuthUsers();

      // 3. Créer un nouveau Super Admin
      await createFreshSuperAdmin();

      debugPrint('[CLEAN_FIRESTORE] 🎉 RESET COMPLET TERMINÉ !');

    } catch (e) {
      debugPrint('[CLEAN_FIRESTORE] ❌ Erreur lors du reset: $e');
      rethrow;
    }
  }

  /// 📊 Compter les documents dans toutes les collections
  static Future<void> countAllDocuments() async {
    try {
      debugPrint('[CLEAN_FIRESTORE] 📊 Comptage des documents...');

      final collections = [
        AppConstants.usersCollection,
        AppConstants.accountRequestsCollection,
        AppConstants.driversCollection,
        AppConstants.agentsCollection,
        AppConstants.expertsCollection,
        AppConstants.companiesCollection,
        AppConstants.agenciesCollection,
      ];

      int total = 0;

      for (final collectionName in collections) {
        try {
          final snapshot = await _firestore.collection(collectionName).get();
          final count = snapshot.docs.length;
          total += count;
          debugPrint('[CLEAN_FIRESTORE] 📋 $collectionName: $count documents');
        } catch (e) {
          debugPrint('[CLEAN_FIRESTORE] ❌ Erreur pour $collectionName: $e');
        }
      }

      debugPrint('[CLEAN_FIRESTORE] 📊 TOTAL: $total documents');

    } catch (e) {
      debugPrint('[CLEAN_FIRESTORE] ❌ Erreur comptage: $e');
    }
  }
}

/// 🧹 Widget pour interface de nettoyage
class CleanFirestoreWidget extends StatefulWidget {
  const CleanFirestoreWidget({Key? key}) : super(key: key);

  @override
  State<CleanFirestoreWidget> createState() => _CleanFirestoreWidgetState();
}

class _CleanFirestoreWidgetState extends State<CleanFirestoreWidget> {
  bool _isLoading = false;
  String _status = 'Prêt pour le nettoyage';

  Future<void> _executeAction(String action, Future<void> Function() function) async {
    setState(() {
      _isLoading = true;
      _status = '$action en cours...';
    });

    try {
      await function();
      setState(() {
        _status = '$action terminé avec succès !';
      });
    } catch (e) {
      setState(() {
        _status = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧹 Nettoyage Firestore'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statut
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Statut: $_status',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _executeAction(
                'Comptage',
                CleanFirestore.countAllDocuments,
              ),
              icon: const Icon(Icons.analytics),
              label: const Text('Compter les Documents'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _executeAction(
                'Suppression des collections',
                CleanFirestore.deleteAllCollections,
              ),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Supprimer Toutes les Collections'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _executeAction(
                'Reset complet',
                CleanFirestore.fullReset,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('RESET COMPLET'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Avertissement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: const Column(
                children: [
                  Text(
                    '⚠️ ATTENTION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ces actions suppriment DÉFINITIVEMENT toutes les données. '
                    'Utilisez uniquement en développement !',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
