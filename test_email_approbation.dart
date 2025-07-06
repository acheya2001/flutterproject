import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 Test du système d'email d'approbation
void main() async {
  print('🧪 Test du système d\'email d\'approbation...');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Se connecter en tant qu'admin
    print('\n🔐 Connexion admin...');
    await auth.signInWithEmailAndPassword(
      email: 'constat.tunisie.app@gmail.com',
      password: 'Acheya123',
    );
    print('✅ Connexion admin réussie');
    
    // Test 1: Créer une demande de test
    print('\n📝 Test 1: Création demande de test...');
    final requestRef = await firestore.collection('professional_account_requests').add({
      'userId': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'email': 'hammami123rahma@gmail.com', // Email de test
      'nom': 'Test',
      'prenom': 'Agent',
      'telephone': '12345678',
      'userType': 'assureur',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Demande créée: ${requestRef.id}');
    
    // Test 2: Approuver la demande
    print('\n✅ Test 2: Approbation de la demande...');
    await requestRef.update({
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': 'admin_test',
    });
    print('✅ Demande approuvée');
    
    // Test 3: Simuler l'envoi d'email
    print('\n📧 Test 3: Simulation envoi email...');
    
    // Récupérer les données de la demande
    final requestDoc = await requestRef.get();
    if (requestDoc.exists) {
      final data = requestDoc.data()!;
      final email = data['email'] as String;
      final nom = data['nom'] as String;
      final prenom = data['prenom'] as String;
      final userType = data['userType'] as String;
      
      print('📧 Email destinataire: $email');
      print('👤 Nom complet: $prenom $nom');
      print('🏢 Type: $userType');
      
      // Ici on simule l'envoi d'email
      print('📧 Simulation envoi email d\'approbation...');
      print('✅ Email simulé envoyé avec succès !');
      
      // Template email
      final subject = '✅ Votre compte Constat Tunisie a été approuvé !';
      final message = '''
Félicitations $prenom $nom !

Votre demande de compte ${userType == 'assureur' ? 'Agent d\'Assurance' : 'Expert'} 
sur Constat Tunisie a été approuvée.

Vous pouvez maintenant vous connecter et accéder à toutes les 
fonctionnalités professionnelles.

Cordialement,
L'équipe Constat Tunisie
      ''';
      
      print('\n📧 === CONTENU EMAIL ===');
      print('Sujet: $subject');
      print('Message: $message');
      print('======================');
    }
    
    // Test 4: Nettoyage
    print('\n🧹 Test 4: Nettoyage...');
    await requestRef.delete();
    print('✅ Demande de test supprimée');
    
    print('\n🎯 Tests terminés avec succès !');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
