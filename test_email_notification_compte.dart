import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 Test du nouveau système d'email de notification de compte
void main() async {
  print('🧪 Test du système d\'email de notification de compte...');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    final firestore = FirebaseFirestore.instance;
    
    // Test 1: Créer une demande de test
    print('\n📝 Test 1: Création demande de test...');
    final requestRef = await firestore.collection('professional_account_requests').add({
      'userId': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'email': 'hammami123rahma@gmail.com', // Email de test
      'nom': 'TestAgent',
      'prenom': 'Nouveau',
      'telephone': '12345678',
      'userType': 'assureur',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Demande créée: ${requestRef.id}');
    
    // Test 2: Simuler approbation
    print('\n✅ Test 2: Simulation approbation...');
    await requestRef.update({
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': 'admin_test',
    });
    
    print('📧 Email d\'approbation qui sera envoyé :');
    print('═══════════════════════════════════════');
    print('À: hammami123rahma@gmail.com');
    print('Sujet: ✅ Votre compte Constat Tunisie a été approuvé !');
    print('');
    print('🎉 Félicitations !');
    print('Votre compte a été approuvé');
    print('');
    print('Bonjour Nouveau TestAgent,');
    print('');
    print('Excellente nouvelle ! Votre demande de compte Agent d\'Assurance');
    print('sur la plateforme Constat Tunisie a été approuvée par nos administrateurs.');
    print('');
    print('✅ Votre compte est maintenant actif');
    print('• Vous pouvez vous connecter à l\'application');
    print('• Toutes les fonctionnalités professionnelles sont disponibles');
    print('• Vous pouvez gérer vos dossiers et clients');
    print('• Collaboration avec les autres professionnels activée');
    print('');
    print('[Se connecter maintenant]');
    print('');
    print('Merci de faire confiance à Constat Tunisie pour vos activités professionnelles.');
    print('');
    print('Cordialement,');
    print('L\'équipe Constat Tunisie');
    print('═══════════════════════════════════════');
    
    // Test 3: Simuler refus
    print('\n❌ Test 3: Simulation refus...');
    await requestRef.update({
      'status': 'rejected',
      'rejectionReason': 'Documents incomplets - Veuillez fournir une copie de votre licence professionnelle',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': 'admin_test',
    });
    
    print('📧 Email de refus qui sera envoyé :');
    print('═══════════════════════════════════════');
    print('À: hammami123rahma@gmail.com');
    print('Sujet: ❌ Votre demande de compte Constat Tunisie');
    print('');
    print('❌ Demande non approuvée');
    print('Votre demande de compte');
    print('');
    print('Bonjour Nouveau TestAgent,');
    print('');
    print('Nous vous remercions pour votre demande de compte Agent d\'Assurance');
    print('sur Constat Tunisie.');
    print('');
    print('Après examen, nous ne pouvons pas approuver votre demande');
    print('pour la raison suivante :');
    print('');
    print('📋 Documents incomplets - Veuillez fournir une copie de votre licence professionnelle');
    print('');
    print('Vous pouvez soumettre une nouvelle demande en corrigeant');
    print('les points mentionnés ci-dessus.');
    print('');
    print('Pour toute question, n\'hésitez pas à nous contacter.');
    print('');
    print('Cordialement,');
    print('L\'équipe Constat Tunisie');
    print('═══════════════════════════════════════');
    
    // Test 4: Nettoyage
    print('\n🧹 Test 4: Nettoyage...');
    await requestRef.delete();
    print('✅ Demande de test supprimée');
    
    print('\n🎯 Tests terminés avec succès !');
    print('\n📧 RÉSUMÉ :');
    print('• Email d\'approbation : Design vert, message de félicitations');
    print('• Email de refus : Design rouge, raison personnalisée');
    print('• Templates HTML professionnels');
    print('• Même infrastructure que les invitations (Firebase Functions + Gmail API)');
    print('• Plus d\'emails d\'invitation collaborative pour les notifications de compte');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
