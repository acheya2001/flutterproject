import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestNotificationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🧪 Créer des notifications de test pour le conducteur connecté
  static Future<void> createTestNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      final conducteurId = user.uid;
      final conducteurEmail = user.email ?? 'test@example.com';

      // 1. Notification de documents manquants
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'conducteurEmail': conducteurEmail,
        'type': 'documents_manquants',
        'titre': 'Documents manquants',
        'message': 'Votre dossier est incomplet. Merci de fournir : CIN Recto, Permis Verso. Vous pouvez les ajouter directement depuis votre espace client.',
        'demandeId': 'test_demande_123',
        'documentsManquants': ['CIN Recto', 'Permis Verso'],
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // 2. Notification de paiement proposé
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'conducteurEmail': conducteurEmail,
        'type': 'paiement_propose',
        'titre': 'Paiement proposé',
        'message': 'Votre dossier est validé ! Vous pouvez maintenant choisir votre mode de paiement et finaliser votre contrat.',
        'demandeId': 'test_demande_456',
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // 3. Notification de paiement requis en agence
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'conducteurEmail': conducteurEmail,
        'type': 'paiement_requis',
        'titre': 'Paiement en agence requis',
        'message': 'Votre dossier est validé. Merci de vous présenter à l\'agence STAR Assurances - Tunis Centre pour finaliser le paiement de 250 DT.',
        'demandeId': 'test_demande_789',
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // 4. Notification de contrat activé
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'conducteurEmail': conducteurEmail,
        'type': 'contrat_actif',
        'titre': 'Contrat activé !',
        'message': 'Félicitations ! Votre contrat d\'assurance est maintenant actif. Vous pouvez télécharger votre attestation et carte verte.',
        'demandeId': 'test_demande_101',
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // 5. Notification d'échéance proche
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'echeance_rappel',
        'titre': 'Rappel d\'échéance',
        'message': 'Rappel: Votre échéance n°2 de 125 DT est due dans 3 jours. Merci de vous présenter à l\'agence.',
        'contratId': 'test_contrat_202',
        'echeanceId': 'test_echeance_303',
        'montant': 125.0,
        'joursRestants': 3,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // 6. Notification d'expiration proche
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'expiration_proche',
        'titre': 'Contrat expire bientôt',
        'message': 'Votre contrat CTR-1234567890 expire dans 15 jours. Pensez à le renouveler pour continuer à être couvert.',
        'contratId': 'test_contrat_404',
        'joursRestants': 15,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // 7. Notification de retard de paiement
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'echeance_retard',
        'titre': 'Échéance en retard',
        'message': 'Votre échéance n°3 de 125 DT est en retard de 5 jours. Merci de régulariser votre situation rapidement.',
        'contratId': 'test_contrat_505',
        'echeanceId': 'test_echeance_606',
        'montant': 125.0,
        'joursRetard': 5,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': 'haute',
      });

      // 8. Notification de contrat suspendu
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'contrat_suspendu',
        'titre': 'Contrat suspendu',
        'message': 'Votre contrat d\'assurance a été suspendu pour non-paiement. Contactez votre agence pour régulariser votre situation.',
        'contratId': 'test_contrat_707',
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': 'critique',
      });

      // 9. Notification de renouvellement programmé
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'renouvellement_programme',
        'titre': 'Renouvellement programmé',
        'message': 'Votre contrat CTR-9876543210 sera automatiquement renouvelé. Vous recevrez une confirmation prochainement.',
        'contratId': 'test_contrat_808',
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // 10. Notification de contrat expiré
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'contrat_expire',
        'titre': 'Contrat expiré',
        'message': 'Votre contrat CTR-1111222233 a expiré. Renouvelez-le pour continuer à être couvert.',
        'contratId': 'test_contrat_909',
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': 'haute',
      });

      print('✅ 10 notifications de test créées pour le conducteur $conducteurId');

    } catch (e) {
      print('❌ Erreur création notifications de test: $e');
      throw e;
    }
  }

  /// 🧹 Supprimer toutes les notifications de test
  static Future<void> clearTestNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      print('🧹 Suppression des notifications pour ${user.uid}...');

      final notifications = await _firestore
          .collection('notifications')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      if (notifications.docs.isEmpty) {
        print('ℹ️ Aucune notification à supprimer');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ ${notifications.docs.length} notifications supprimées');

    } catch (e) {
      print('❌ Erreur suppression notifications: $e');
      throw e;
    }
  }

  /// 🧹 Supprimer toutes les données de test (notifications + historique)
  static Future<void> clearAllTestData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      print('🧹 Suppression de toutes les données de test...');

      final batch = _firestore.batch();
      int totalDeleted = 0;

      // Supprimer les notifications
      final notifications = await _firestore
          .collection('notifications')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
        totalDeleted++;
      }

      // Supprimer les contrats de test
      final contrats = await _firestore
          .collection('contrats')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      for (final doc in contrats.docs) {
        final data = doc.data();
        // Supprimer seulement les contrats de test (qui contiennent "TEST" dans le numéro)
        if (data['numeroContrat']?.toString().contains('TEST') == true) {
          batch.delete(doc.reference);
          totalDeleted++;
        }
      }

      // Supprimer les échéances de test
      final echeances = await _firestore
          .collection('echeances')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      for (final doc in echeances.docs) {
        final data = doc.data();
        // Supprimer seulement les échéances liées aux contrats de test
        if (data['contratId']?.toString().contains('test') == true) {
          batch.delete(doc.reference);
          totalDeleted++;
        }
      }

      // Supprimer les sinistres de test
      final sinistres = await _firestore
          .collection('sinistres')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      for (final doc in sinistres.docs) {
        final data = doc.data();
        // Supprimer seulement les sinistres de test (qui contiennent "TEST" dans le numéro)
        if (data['numeroSinistre']?.toString().contains('TEST') == true) {
          batch.delete(doc.reference);
          totalDeleted++;
        }
      }

      await batch.commit();
      print('✅ $totalDeleted éléments de test supprimés');

    } catch (e) {
      print('❌ Erreur suppression données de test: $e');
      throw e;
    }
  }

  /// 📊 Créer des données de test pour l'historique
  static Future<void> createTestHistoryData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final conducteurId = user.uid;

      // Créer un contrat de test
      await _firestore.collection('contrats').add({
        'conducteurId': conducteurId,
        'numeroContrat': 'CTR-TEST-${DateTime.now().millisecondsSinceEpoch}',
        'vehicule': {
          'marque': 'Peugeot',
          'modele': '208',
          'immatriculation': '123 TUN 456',
          'annee': 2020,
        },
        'formuleAssurance': 'rc_vol_incendie',
        'formuleAssuranceLabel': 'RC + Vol + Incendie',
        'compagnieId': 'test_compagnie',
        'compagnieNom': 'STAR Assurances',
        'agenceId': 'test_agence',
        'agenceNom': 'Tunis Centre',
        'montantTotal': 450.0,
        'frequencePaiement': 'trimestriel',
        'dateDebut': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        'dateFin': Timestamp.fromDate(DateTime.now().add(const Duration(days: 335))),
        'statut': 'actif',
        'dateCreation': FieldValue.serverTimestamp(),
      });

      // Créer des échéances de test
      for (int i = 1; i <= 4; i++) {
        await _firestore.collection('echeances').add({
          'contratId': 'test_contrat_historique',
          'conducteurId': conducteurId,
          'numeroEcheance': i,
          'totalEcheances': 4,
          'montant': 112.5,
          'dateEcheance': Timestamp.fromDate(
            DateTime.now().add(Duration(days: (i - 1) * 90)),
          ),
          'statut': i <= 2 ? 'payee' : 'en_attente',
          'dateCreation': FieldValue.serverTimestamp(),
          'datePaiement': i <= 2 
              ? Timestamp.fromDate(DateTime.now().subtract(Duration(days: (3 - i) * 90)))
              : null,
        });
      }

      // Créer un sinistre de test
      await _firestore.collection('sinistres').add({
        'conducteurId': conducteurId,
        'numeroSinistre': 'SIN-TEST-${DateTime.now().millisecondsSinceEpoch}',
        'typeSinistre': 'Bris de glace',
        'statut': 'clos',
        'montantEstime': 150.0,
        'dateDeclaration': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
        'dateCreation': FieldValue.serverTimestamp(),
      });

      print('✅ Données de test créées pour l\'historique');

    } catch (e) {
      print('❌ Erreur création données historique: $e');
    }
  }

  /// 🎯 Créer toutes les données de test
  static Future<void> createAllTestData() async {
    await createTestNotifications();
    await createTestHistoryData();
    print('🎯 Toutes les données de test créées !');
  }
}
