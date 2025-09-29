import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🔧 Script pour corriger l'affectation de la demande HE1TBOHykp9KnyWaVhee
void main() async {
  await Firebase.initializeApp();
  
  print('🔧 === CORRECTION AFFECTATION AGENT ===');
  
  try {
    // Corriger la demande HE1TBOHykp9KnyWaVhee
    await FirebaseFirestore.instance
        .collection('demandes_contrats')
        .doc('HE1TBOHykp9KnyWaVhee')
        .update({
      'agentId': 't1DwAgepD4W1p9lTJyQDnxcxyf72', // Bon ID de l'agent
      'agentNom': 'agent demo',
      'agentEmail': 'agentdemo@gmail.com',
      'dateAffectation': FieldValue.serverTimestamp(),
      'affectationMode': 'correction_manuelle',
    });
    
    print('✅ Demande HE1TBOHykp9KnyWaVhee corrigée');
    
    // Vérifier la correction
    final doc = await FirebaseFirestore.instance
        .collection('demandes_contrats')
        .doc('HE1TBOHykp9KnyWaVhee')
        .get();
    
    if (doc.exists) {
      final data = doc.data()!;
      print('📄 Demande après correction:');
      print('  - agentId: ${data['agentId']}');
      print('  - agentNom: ${data['agentNom']}');
      print('  - agentEmail: ${data['agentEmail']}');
      print('  - statut: ${data['statut']}');
      print('  - affectationMode: ${data['affectationMode']}');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
