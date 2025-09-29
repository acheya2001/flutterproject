import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de test pour vérifier les nouveaux messages de notification
Future<void> testNotificationMessage() async {
  print('🧪 Test des nouveaux messages de notification...');
  
  final firestore = FirebaseFirestore.instance;
  
  try {
    // Créer une notification de test avec le nouveau message
    await firestore.collection('notifications').add({
      'conducteurId': 'test_conducteur_123',
      'conducteurEmail': 'test@example.com',
      'type': 'paiement_requis',
      'titre': 'Dossier Validé - Paiement Requis',
      'message': 'Votre dossier est complet ! Cliquez maintenant pour choisir votre fréquence de paiement et finaliser votre contrat.',
      'demandeId': 'test_demande_${DateTime.now().millisecondsSinceEpoch}',
      'numeroContrat': 'CTR_TEST_${DateTime.now().millisecondsSinceEpoch}',
      'dateCreation': FieldValue.serverTimestamp(),
      'lu': false,
      'priorite': 'haute',
    });
    
    print('✅ Notification de test créée avec le nouveau message');
    print('📝 Nouveau message: "Votre dossier est complet ! Cliquez maintenant pour choisir votre fréquence de paiement et finaliser votre contrat."');
    
    // Vérifier que la notification a été créée
    final notifications = await firestore
        .collection('notifications')
        .where('type', isEqualTo: 'paiement_requis')
        .orderBy('dateCreation', descending: true)
        .limit(1)
        .get();
    
    if (notifications.docs.isNotEmpty) {
      final notifData = notifications.docs.first.data();
      print('🔍 Notification vérifiée:');
      print('   📧 Titre: ${notifData['titre']}');
      print('   📝 Message: ${notifData['message']}');
      print('   🎯 Type: ${notifData['type']}');
    }
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}

/// Fonction principale pour exécuter le test
void main() async {
  await testNotificationMessage();
}
