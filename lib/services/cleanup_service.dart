import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🧹 Service pour nettoyer les données de test
class CleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🗑️ Supprimer tous les sinistres de test
  static Future<void> deleteAllTestSinistres() async {
    try {
      print('🧹 Début du nettoyage des sinistres...');

      // 1. Supprimer de la collection 'sinistres'
      await _deleteFromCollection('sinistres');

      // 2. Supprimer de la collection 'declarations_sinistres'
      await _deleteFromCollection('declarations_sinistres');

      // 3. Supprimer de la collection 'accident_sessions_complete'
      await _deleteFromCollection('accident_sessions_complete');

      // 4. Supprimer de la collection 'accident_sessions'
      await _deleteFromCollection('accident_sessions');

      // 5. Supprimer de la collection 'constats'
      await _deleteFromCollection('constats');

      print('✅ Nettoyage terminé avec succès !');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
      throw Exception('Erreur nettoyage: $e');
    }
  }

  /// 🗑️ Supprimer tous les documents d'une collection
  static Future<void> _deleteFromCollection(String collectionName) async {
    try {
      print('🔄 Nettoyage de la collection: $collectionName');
      
      final snapshot = await _firestore.collection(collectionName).get();
      print('📊 ${snapshot.docs.length} documents trouvés dans $collectionName');

      if (snapshot.docs.isEmpty) {
        print('✅ Collection $collectionName déjà vide');
        return;
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
          print('🔄 $count documents supprimés de $collectionName...');
        }
      }

      // Exécuter le batch final
      if (count % 500 != 0) {
        await batch.commit();
      }

      print('✅ $count documents supprimés de $collectionName');
    } catch (e) {
      print('❌ Erreur suppression $collectionName: $e');
      throw e;
    }
  }

  /// 🗑️ Supprimer seulement les sinistres avec isFakeData = true
  static Future<void> deleteOnlyFakeDataSinistres() async {
    try {
      print('🧹 Suppression des sinistres avec isFakeData = true...');

      final collections = [
        'sinistres',
        'declarations_sinistres', 
        'accident_sessions_complete',
        'accident_sessions',
        'constats'
      ];

      for (final collectionName in collections) {
        await _deleteFakeDataFromCollection(collectionName);
      }

      print('✅ Suppression des données de test terminée !');
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      throw Exception('Erreur suppression fake data: $e');
    }
  }

  /// 🗑️ Supprimer seulement les documents avec isFakeData = true
  static Future<void> _deleteFakeDataFromCollection(String collectionName) async {
    try {
      print('🔄 Suppression fake data de: $collectionName');
      
      final snapshot = await _firestore
          .collection(collectionName)
          .where('isFakeData', isEqualTo: true)
          .get();
      
      print('📊 ${snapshot.docs.length} documents fake trouvés dans $collectionName');

      if (snapshot.docs.isEmpty) {
        print('✅ Aucune fake data dans $collectionName');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ ${snapshot.docs.length} fake documents supprimés de $collectionName');
    } catch (e) {
      print('❌ Erreur suppression fake data $collectionName: $e');
    }
  }

  /// 🗑️ Supprimer les sinistres d'un utilisateur spécifique
  static Future<void> deleteUserSinistres(String userId) async {
    try {
      print('🧹 Suppression des sinistres pour utilisateur: $userId');

      // Collection sinistres
      await _deleteUserDataFromCollection('sinistres', 'conducteurDeclarantId', userId);
      await _deleteUserDataFromCollection('sinistres', 'conducteurId', userId);
      await _deleteUserDataFromCollection('sinistres', 'createdBy', userId);

      // Collection sessions
      await _deleteUserDataFromCollection('accident_sessions_complete', 'createurUserId', userId);
      await _deleteUserDataFromCollection('accident_sessions', 'createurUserId', userId);

      // Collection declarations
      await _deleteUserDataFromCollection('declarations_sinistres', 'conducteurId', userId);

      print('✅ Sinistres de l\'utilisateur $userId supprimés');
    } catch (e) {
      print('❌ Erreur suppression sinistres utilisateur: $e');
      throw e;
    }
  }

  /// 🗑️ Supprimer les données d'un utilisateur dans une collection
  static Future<void> _deleteUserDataFromCollection(
    String collectionName, 
    String fieldName, 
    String userId
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where(fieldName, isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ ${snapshot.docs.length} documents supprimés de $collectionName ($fieldName = $userId)');
    } catch (e) {
      print('❌ Erreur suppression $collectionName: $e');
    }
  }

  /// 📊 Compter les documents dans les collections de sinistres
  static Future<Map<String, int>> countSinistresDocuments() async {
    final counts = <String, int>{};

    final collections = [
      'sinistres',
      'declarations_sinistres',
      'accident_sessions_complete', 
      'accident_sessions',
      'constats'
    ];

    for (final collection in collections) {
      try {
        final snapshot = await _firestore.collection(collection).get();
        counts[collection] = snapshot.docs.length;
      } catch (e) {
        counts[collection] = -1; // Erreur
      }
    }

    return counts;
  }

  /// 🚨 DANGER: Supprimer TOUTES les données (à utiliser avec précaution)
  static Future<void> deleteAllData() async {
    if (!kDebugMode) {
      throw Exception('Cette fonction ne peut être utilisée qu\'en mode debug !');
    }

    print('🚨 ATTENTION: Suppression de TOUTES les données !');
    
    final collections = [
      'sinistres',
      'declarations_sinistres',
      'accident_sessions_complete',
      'accident_sessions', 
      'constats',
      'brouillons_constat',
      'sessions_collaboratives'
    ];

    for (final collection in collections) {
      await _deleteFromCollection(collection);
    }

    print('🚨 TOUTES les données ont été supprimées !');
  }
}
