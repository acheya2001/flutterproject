import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 Script de test des permissions Firestore
void main() async {
  print('🧪 Test des permissions Firestore...');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    print('✅ Firebase initialisé');
    
    // Test 1: Créer une demande de compte professionnel sans authentification
    print('\n📝 Test 1: Création demande sans auth...');
    try {
      await firestore.collection('professional_account_requests').add({
        'userId': 'test_user_id',
        'email': 'test@example.com',
        'nom': 'Test',
        'prenom': 'User',
        'telephone': '12345678',
        'userType': 'assureur',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Création réussie sans auth');
    } catch (e) {
      print('❌ Erreur création sans auth: $e');
    }
    
    // Test 2: Se connecter en tant qu'admin et tester les statistiques
    print('\n🔐 Test 2: Connexion admin...');
    try {
      await auth.signInWithEmailAndPassword(
        email: 'constat.tunisie.app@gmail.com',
        password: 'Acheya123',
      );
      print('✅ Connexion admin réussie');
      
      // Test lecture des collections pour statistiques
      print('\n📊 Test 3: Lecture statistiques...');
      
      final users = await firestore.collection('users').count().get();
      print('✅ Users count: ${users.count}');
      
      final requests = await firestore
          .collection('professional_account_requests')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      print('✅ Pending requests: ${requests.count}');
      
      final contracts = await firestore.collection('contracts').count().get();
      print('✅ Contracts count: ${contracts.count}');
      
      final constats = await firestore.collection('constats').count().get();
      print('✅ Constats count: ${constats.count}');
      
    } catch (e) {
      print('❌ Erreur test admin: $e');
    }
    
    print('\n🎯 Tests terminés');
    
  } catch (e) {
    print('❌ Erreur générale: $e');
  }
}
