import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🔍 Script de débogage pour vérifier les notifications de documents manquants
void main() async {
  await Firebase.initializeApp();
  
  print('🔍 === DÉBOGAGE NOTIFICATIONS DOCUMENTS MANQUANTS ===');
  
  await debugNotifications();
  await debugDemandesContrats();
}

/// 📧 Déboguer les notifications
Future<void> debugNotifications() async {
  try {
    print('\n📧 === NOTIFICATIONS ===');
    
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('dateCreation', descending: true)
        .limit(20)
        .get();
    
    print('📊 Total notifications récentes: ${notifications.docs.length}');
    
    for (final doc in notifications.docs) {
      final data = doc.data();
      final type = data['type'] ?? 'UNKNOWN';
      final titre = data['titre'] ?? 'SANS TITRE';
      final conducteurId = data['conducteurId'] ?? 'UNKNOWN';
      final dateCreation = data['dateCreation']?.toDate();
      
      print('📧 ${doc.id}:');
      print('  - Type: $type');
      print('  - Titre: $titre');
      print('  - ConducteurId: $conducteurId');
      print('  - Date: $dateCreation');
      
      if (type == 'documents_manquants') {
        print('  - Documents manquants: ${data['documentsManquants']}');
        print('  - DemandeId: ${data['demandeId']}');
      } else if (type == 'paiement_requis') {
        print('  - DemandeId: ${data['demandeId']}');
        print('  - NumeroContrat: ${data['numeroContrat']}');
      }
      print('  ---');
    }
  } catch (e) {
    print('❌ Erreur debug notifications: $e');
  }
}

/// 📋 Déboguer les demandes de contrats
Future<void> debugDemandesContrats() async {
  try {
    print('\n📋 === DEMANDES CONTRATS ===');
    
    final demandes = await FirebaseFirestore.instance
        .collection('demandes_contrats')
        .orderBy('dateCreation', descending: true)
        .limit(10)
        .get();
    
    print('📊 Total demandes récentes: ${demandes.docs.length}');
    
    for (final doc in demandes.docs) {
      final data = doc.data();
      final statut = data['statut'] ?? 'UNKNOWN';
      final numero = data['numero'] ?? 'SANS NUMERO';
      final conducteurId = data['conducteurId'] ?? 'UNKNOWN';
      final agentId = data['agentId'] ?? 'NON AFFECTE';
      
      print('📋 ${doc.id}:');
      print('  - Numéro: $numero');
      print('  - Statut: $statut');
      print('  - ConducteurId: $conducteurId');
      print('  - AgentId: $agentId');
      
      if (data['documentsManquants'] != null) {
        print('  - Documents manquants: ${data['documentsManquants']}');
        print('  - Date docs manquants: ${data['dateDocumentsManquants']?.toDate()}');
      }
      
      print('  ---');
    }
  } catch (e) {
    print('❌ Erreur debug demandes: $e');
  }
}

/// 🔍 Vérifier les notifications pour un conducteur spécifique
Future<void> debugNotificationsConducteur(String conducteurId) async {
  try {
    print('\n🔍 === NOTIFICATIONS POUR CONDUCTEUR: $conducteurId ===');
    
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('conducteurId', isEqualTo: conducteurId)
        .orderBy('dateCreation', descending: true)
        .get();
    
    print('📊 Notifications pour ce conducteur: ${notifications.docs.length}');
    
    for (final doc in notifications.docs) {
      final data = doc.data();
      print('📧 ${data['type']}: ${data['titre']}');
      print('   Message: ${data['message']}');
      print('   Date: ${data['dateCreation']?.toDate()}');
      print('   Lu: ${data['lu']}');
      print('   ---');
    }
  } catch (e) {
    print('❌ Erreur debug notifications conducteur: $e');
  }
}
