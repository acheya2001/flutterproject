import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 Test direct des permissions Firestore
void main() async {
  print('🧪 Test direct des permissions Firestore...');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Test 1: Connexion anonyme
    print('\n🔐 Test 1: Connexion anonyme...');
    try {
      final userCredential = await auth.signInAnonymously();
      print('✅ Connexion anonyme réussie: ${userCredential.user?.uid}');
    } catch (e) {
      print('❌ Erreur connexion anonyme: $e');
    }
    
    // Test 2: Écriture directe dans professional_account_requests
    print('\n📝 Test 2: Écriture directe...');
    try {
      final docRef = await firestore.collection('professional_account_requests').add({
        'userId': 'test_${DateTime.now().millisecondsSinceEpoch}',
        'email': 'test@example.com',
        'nom': 'Test',
        'prenom': 'User',
        'telephone': '12345678',
        'userType': 'assureur',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Document créé avec succès: ${docRef.id}');
      
      // Test 3: Lecture du document créé
      print('\n📖 Test 3: Lecture du document...');
      final doc = await docRef.get();
      if (doc.exists) {
        print('✅ Document lu avec succès: ${doc.data()}');
      } else {
        print('❌ Document non trouvé');
      }
      
      // Test 4: Suppression du document de test
      print('\n🗑️ Test 4: Suppression du document...');
      await docRef.delete();
      print('✅ Document supprimé avec succès');
      
    } catch (e) {
      print('❌ Erreur lors des opérations Firestore: $e');
      print('❌ Type d\'erreur: ${e.runtimeType}');
    }
    
    // Test 5: Vérifier l'état d'authentification
    print('\n🔍 Test 5: État d\'authentification...');
    final currentUser = auth.currentUser;
    print('Utilisateur actuel: ${currentUser?.uid ?? 'null'}');
    print('Email: ${currentUser?.email ?? 'null'}');
    print('Anonyme: ${currentUser?.isAnonymous ?? false}');
    print('Authentifié: ${currentUser != null}');
    
    print('\n🎯 Tests terminés avec succès !');
    
  } catch (e) {
    print('❌ Erreur générale: $e');
    print('❌ Type d\'erreur: ${e.runtimeType}');
  }
}
