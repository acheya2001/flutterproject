import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🧪 Service de test pour les notifications de documents manquants
class TestDocumentsManquantsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔔 Créer une notification de test pour documents manquants
  static Future<void> creerNotificationTestDocumentsManquants() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      print('🧪 Création notification test documents manquants...');

      // Créer une notification de documents manquants
      await _firestore.collection('notifications').add({
        'conducteurId': user.uid,
        'conducteurEmail': user.email,
        'type': 'documents_manquants',
        'titre': 'Documents manquants - TEST',
        'message': 'TEST: Votre demande nécessite des documents supplémentaires : CIN Recto, Permis Verso',
        'demandeId': 'test_demande_${DateTime.now().millisecondsSinceEpoch}',
        'documentsManquants': ['CIN Recto', 'Permis Verso'],
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      print('✅ Notification test documents manquants créée');

    } catch (e) {
      print('❌ Erreur création notification test: $e');
    }
  }

  /// 💳 Créer une notification de test pour paiement requis
  static Future<void> creerNotificationTestPaiementRequis() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      print('🧪 Création notification test paiement requis...');

      // Créer une notification de paiement requis
      await _firestore.collection('notifications').add({
        'conducteurId': user.uid,
        'conducteurEmail': user.email,
        'type': 'paiement_requis',
        'titre': 'Paiement requis - TEST',
        'message': 'TEST: Votre dossier est validé. Cliquez maintenant pour choisir votre fréquence de paiement et finaliser votre contrat.',
        'demandeId': 'test_demande_${DateTime.now().millisecondsSinceEpoch}',
        'numeroContrat': 'CTR_TEST_${DateTime.now().millisecondsSinceEpoch}',
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': 'haute',
      });

      print('✅ Notification test paiement requis créée');

    } catch (e) {
      print('❌ Erreur création notification test: $e');
    }
  }

  /// 🔍 Vérifier les notifications existantes
  static Future<void> verifierNotificationsExistantes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      print('🔍 Vérification notifications existantes...');

      final notifications = await _firestore
          .collection('notifications')
          .where('conducteurId', isEqualTo: user.uid)
          .orderBy('dateCreation', descending: true)
          .limit(10)
          .get();

      print('📊 Notifications trouvées: ${notifications.docs.length}');

      for (final doc in notifications.docs) {
        final data = doc.data();
        print('📧 ${doc.id}:');
        print('  - Type: ${data['type']}');
        print('  - Titre: ${data['titre']}');
        print('  - Message: ${data['message']}');
        print('  - Date: ${data['dateCreation']?.toDate()}');
        print('  - Lu: ${data['lu']}');
        print('  ---');
      }

    } catch (e) {
      print('❌ Erreur vérification notifications: $e');
    }
  }

  /// 🧹 Nettoyer les notifications de test
  static Future<void> nettoyerNotificationsTest() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      print('🧹 Nettoyage notifications de test...');

      final notifications = await _firestore
          .collection('notifications')
          .where('conducteurId', isEqualTo: user.uid)
          .where('titre', isGreaterThanOrEqualTo: 'TEST')
          .where('titre', isLessThan: 'TESU')
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ ${notifications.docs.length} notifications de test supprimées');

    } catch (e) {
      print('❌ Erreur nettoyage notifications test: $e');
    }
  }
}
