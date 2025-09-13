import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 Script de test pour le workflow de paiement
/// 
/// Ce script teste le processus complet :
/// 1. Agent valide les documents
/// 2. Notification envoyée au conducteur
/// 3. Conducteur peut accéder au choix de paiement
/// 4. Agent peut encaisser le paiement

void main() async {
  print('🧪 DÉBUT DU TEST WORKFLOW PAIEMENT');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;
    
    // 1. Créer une demande de test
    print('\n📋 1. Création d\'une demande de test...');
    final demandeId = await _creerDemandeTest(firestore);
    print('✅ Demande créée: $demandeId');
    
    // 2. Simuler la validation par l'agent
    print('\n👨‍💼 2. Simulation validation agent...');
    await _simulerValidationAgent(firestore, demandeId);
    print('✅ Documents validés par l\'agent');
    
    // 3. Vérifier la notification
    print('\n🔔 3. Vérification de la notification...');
    await _verifierNotification(firestore, demandeId);
    print('✅ Notification créée correctement');
    
    // 4. Simuler le choix de fréquence par le conducteur
    print('\n💰 4. Simulation choix fréquence...');
    await _simulerChoixFrequence(firestore, demandeId);
    print('✅ Fréquence choisie par le conducteur');
    
    // 5. Vérifier que l'agent peut encaisser
    print('\n💳 5. Vérification possibilité encaissement...');
    await _verifierEncaissement(firestore, demandeId);
    print('✅ Encaissement possible pour l\'agent');
    
    print('\n🎉 WORKFLOW TESTÉ AVEC SUCCÈS !');
    
  } catch (e) {
    print('\n❌ ERREUR DANS LE TEST: $e');
  }
}

/// Créer une demande de test
Future<String> _creerDemandeTest(FirebaseFirestore firestore) async {
  final demandeRef = firestore.collection('demandes_contrats').doc();
  
  await demandeRef.set({
    'numero': 'TEST${DateTime.now().millisecondsSinceEpoch}',
    'conducteurId': 'test_conducteur_123',
    'agentId': 'test_agent_456',
    'statut': 'affectee',
    'nom': 'Test',
    'prenom': 'Conducteur',
    'email': 'test@example.com',
    'telephone': '12345678',
    'vehicule': {
      'immatriculation': '123 TUN 456',
      'marque': 'Toyota',
      'modele': 'Corolla',
    },
    'dateCreation': FieldValue.serverTimestamp(),
  });
  
  return demandeRef.id;
}

/// Simuler la validation par l'agent
Future<void> _simulerValidationAgent(FirebaseFirestore firestore, String demandeId) async {
  // Mettre à jour le statut
  await firestore.collection('demandes_contrats').doc(demandeId).update({
    'statut': 'documents_completes',
    'dateDocumentsCompletes': FieldValue.serverTimestamp(),
    'agentDocuments': 'test_agent_456',
    'numeroContrat': 'CTR${DateTime.now().millisecondsSinceEpoch}',
  });
  
  // Créer la notification
  await firestore.collection('notifications').add({
    'conducteurId': 'test_conducteur_123',
    'type': 'paiement_requis',
    'titre': 'Dossier Validé - Paiement Requis',
    'message': 'Votre dossier est complet ! Merci de vous présenter à l\'agence pour choisir votre fréquence de paiement.',
    'demandeId': demandeId,
    'numeroContrat': 'CTR${DateTime.now().millisecondsSinceEpoch}',
    'dateCreation': FieldValue.serverTimestamp(),
    'lu': false,
    'priorite': 'haute',
  });
}

/// Vérifier que la notification a été créée
Future<void> _verifierNotification(FirebaseFirestore firestore, String demandeId) async {
  final notifications = await firestore
      .collection('notifications')
      .where('demandeId', isEqualTo: demandeId)
      .where('type', isEqualTo: 'paiement_requis')
      .get();
  
  if (notifications.docs.isEmpty) {
    throw Exception('Notification paiement_requis non trouvée');
  }
  
  final notifData = notifications.docs.first.data();
  print('   📧 Notification: ${notifData['titre']}');
  print('   📝 Message: ${notifData['message']}');
}

/// Simuler le choix de fréquence par le conducteur
Future<void> _simulerChoixFrequence(FirebaseFirestore firestore, String demandeId) async {
  // Mettre à jour avec la fréquence choisie
  await firestore.collection('demandes_contrats').doc(demandeId).update({
    'frequencePaiement': 'mensuel',
    'montantPaiement': 110.0,
    'dateChoixPaiement': FieldValue.serverTimestamp(),
    'statut': 'frequence_choisie',
  });
  
  // Créer le paiement
  await firestore.collection('paiements').add({
    'conducteurId': 'test_conducteur_123',
    'demandeId': demandeId,
    'numeroContrat': 'CTR${DateTime.now().millisecondsSinceEpoch}',
    'montant': 110.0,
    'frequencePaiement': 'mensuel',
    'statut': 'en_attente',
    'dateEcheance': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    'dateCreation': FieldValue.serverTimestamp(),
  });
}

/// Vérifier que l'agent peut encaisser
Future<void> _verifierEncaissement(FirebaseFirestore firestore, String demandeId) async {
  // Vérifier le statut de la demande
  final demandeDoc = await firestore.collection('demandes_contrats').doc(demandeId).get();
  final statut = demandeDoc.data()?['statut'];
  
  if (statut != 'frequence_choisie') {
    throw Exception('Statut incorrect pour encaissement: $statut');
  }
  
  // Vérifier qu'un paiement existe
  final paiements = await firestore
      .collection('paiements')
      .where('demandeId', isEqualTo: demandeId)
      .where('statut', isEqualTo: 'en_attente')
      .get();
  
  if (paiements.docs.isEmpty) {
    throw Exception('Aucun paiement en attente trouvé');
  }
  
  print('   💰 Paiement en attente: ${paiements.docs.first.data()['montant']} DT');
}
