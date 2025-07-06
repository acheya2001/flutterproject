import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../constants/app_constants.dart';
import '../enums/app_enums.dart';

/// 🔥 Service Firebase centralisé
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters pour les instances Firebase
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseAuth get auth => _auth;
  static FirebaseStorage get storage => _storage;

  /// 👤 Utilisateur actuel
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;

  /// 📊 Collections Firestore
  static CollectionReference get usersCollection => 
      _firestore.collection(AppConstants.usersCollection);
  
  static CollectionReference get companiesCollection => 
      _firestore.collection(AppConstants.companiesCollection);
  
  static CollectionReference get agenciesCollection => 
      _firestore.collection(AppConstants.agenciesCollection);
  
  static CollectionReference get agentsCollection => 
      _firestore.collection(AppConstants.agentsCollection);
  
  static CollectionReference get driversCollection => 
      _firestore.collection(AppConstants.driversCollection);
  
  static CollectionReference get expertsCollection => 
      _firestore.collection(AppConstants.expertsCollection);
  
  static CollectionReference get contractsCollection => 
      _firestore.collection(AppConstants.contractsCollection);
  
  static CollectionReference get vehiclesCollection => 
      _firestore.collection(AppConstants.vehiclesCollection);
  
  static CollectionReference get claimsCollection => 
      _firestore.collection(AppConstants.claimsCollection);
  
  static CollectionReference get documentsCollection => 
      _firestore.collection(AppConstants.documentsCollection);
  
  static CollectionReference get notificationsCollection => 
      _firestore.collection(AppConstants.notificationsCollection);
  
  static CollectionReference get messagesCollection => 
      _firestore.collection(AppConstants.messagesCollection);

  /// 🔐 Authentification
  static Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  static Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 📄 Opérations CRUD génériques
  static Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Erreur lors de l\'ajout du document: $e',
      );
    }
  }

  static Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Erreur lors de la sauvegarde du document: $e',
      );
    }
  }

  static Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .update(data);
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Erreur lors de la mise à jour du document: $e',
      );
    }
  }

  static Future<void> deleteDocument(
    String collection,
    String documentId,
  ) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .delete();
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Erreur lors de la suppression du document: $e',
      );
    }
  }

  static Future<DocumentSnapshot> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      return await _firestore
          .collection(collection)
          .doc(documentId)
          .get();
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Erreur lors de la récupération du document: $e',
      );
    }
  }

  static Stream<DocumentSnapshot> watchDocument(
    String collection,
    String documentId,
  ) {
    return _firestore
        .collection(collection)
        .doc(documentId)
        .snapshots();
  }

  static Future<QuerySnapshot> getCollection(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return await query.get();
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Erreur lors de la récupération de la collection: $e',
      );
    }
  }

  static Stream<QuerySnapshot> watchCollection(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) {
    Query query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  /// 🔍 Requêtes spécialisées
  static Future<QuerySnapshot> getUsersByRole(UserRole role) async {
    return await getCollection(
      AppConstants.usersCollection,
      queryBuilder: (query) => query.where('role', isEqualTo: role.value),
    );
  }

  static Future<QuerySnapshot> getAgenciesByCompany(String companyId) async {
    return await getCollection(
      AppConstants.agenciesCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    );
  }

  static Future<QuerySnapshot> getAgentsByAgency(String agencyId) async {
    return await getCollection(
      AppConstants.agentsCollection,
      queryBuilder: (query) => query.where('agencyId', isEqualTo: agencyId),
    );
  }

  static Future<QuerySnapshot> getContractsByDriver(String driverId) async {
    return await getCollection(
      AppConstants.contractsCollection,
      queryBuilder: (query) => query.where('driverId', isEqualTo: driverId),
    );
  }

  static Future<QuerySnapshot> getVehiclesByOwner(String ownerId) async {
    return await getCollection(
      AppConstants.vehiclesCollection,
      queryBuilder: (query) => query.where('ownerId', isEqualTo: ownerId),
    );
  }

  static Future<QuerySnapshot> getClaimsByDriver(String driverId) async {
    return await getCollection(
      AppConstants.claimsCollection,
      queryBuilder: (query) => query.where('driverId', isEqualTo: driverId),
    );
  }

  static Future<QuerySnapshot> getClaimsByExpert(String expertId) async {
    return await getCollection(
      AppConstants.claimsCollection,
      queryBuilder: (query) => query.where('expertId', isEqualTo: expertId),
    );
  }

  /// 📁 Stockage de fichiers
  static Future<String> uploadFile(
    String path,
    List<int> fileBytes, {
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': currentUserId ?? 'unknown',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putData(Uint8List.fromList(fileBytes), metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        message: 'Erreur lors de l\'upload du fichier: $e',
      );
    }
  }

  static Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        message: 'Erreur lors de la suppression du fichier: $e',
      );
    }
  }

  /// 🔐 Gestion des erreurs d'authentification
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée.';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }

  /// 🧹 Utilitaires
  static String generateId() {
    return _firestore.collection('temp').doc().id;
  }

  static Timestamp timestampFromDateTime(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  static DateTime dateTimeFromTimestamp(Timestamp timestamp) {
    return timestamp.toDate();
  }

  /// 🔄 Transactions et batches
  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    return await _firestore.runTransaction(updateFunction);
  }

  static WriteBatch batch() {
    return _firestore.batch();
  }

  static Future<void> commitBatch(WriteBatch batch) async {
    await batch.commit();
  }
}

/// 🔥 Provider pour FirebaseService
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// 📱 Provider pour l'état de connexion
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.auth.authStateChanges();
});

/// 👤 Provider pour l'utilisateur actuel
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
