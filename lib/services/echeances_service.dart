import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EcheancesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 📅 Créer l'échéancier pour un contrat
  static Future<void> createEcheancier(String contratId, Map<String, dynamic> contratData) async {
    try {
      final frequencePaiement = contratData['frequencePaiement'] ?? 'annuel';
      final montantTotal = contratData['montantTotal'] ?? 0.0;
      final dateDebut = contratData['dateDebut']?.toDate() ?? DateTime.now();
      
      int nombreEcheances;
      int intervalleEnMois;
      
      switch (frequencePaiement) {
        case 'annuel':
          nombreEcheances = 1;
          intervalleEnMois = 12;
          break;
        case 'semestriel':
          nombreEcheances = 2;
          intervalleEnMois = 6;
          break;
        case 'trimestriel':
          nombreEcheances = 4;
          intervalleEnMois = 3;
          break;
        default:
          nombreEcheances = 1;
          intervalleEnMois = 12;
      }
      
      final montantParEcheance = montantTotal / nombreEcheances;
      
      // Créer les échéances
      for (int i = 0; i < nombreEcheances; i++) {
        final dateEcheance = DateTime(
          dateDebut.year,
          dateDebut.month + (i * intervalleEnMois),
          dateDebut.day,
        );
        
        await _firestore.collection('echeances').add({
          'contratId': contratId,
          'conducteurId': contratData['conducteurId'],
          'numeroEcheance': i + 1,
          'totalEcheances': nombreEcheances,
          'montant': montantParEcheance,
          'dateEcheance': Timestamp.fromDate(dateEcheance),
          'statut': i == 0 ? 'payee' : 'en_attente', // Première échéance déjà payée
          'dateCreation': FieldValue.serverTimestamp(),
          'rappelEnvoye': false,
        });
      }
      
      print('✅ Échéancier créé pour le contrat $contratId: $nombreEcheances échéances');
      
    } catch (e) {
      print('❌ Erreur création échéancier: $e');
      throw e;
    }
  }

  /// 🔔 Vérifier et envoyer les rappels d'échéances
  static Future<void> checkAndSendReminders() async {
    try {
      final now = DateTime.now();
      final dans7Jours = now.add(const Duration(days: 7));
      final aujourdhui = DateTime(now.year, now.month, now.day);
      
      // Récupérer les échéances à venir (dans 7 jours)
      final echeancesProches = await _firestore
          .collection('echeances')
          .where('statut', isEqualTo: 'en_attente')
          .where('rappelEnvoye', isEqualTo: false)
          .where('dateEcheance', isLessThanOrEqualTo: Timestamp.fromDate(dans7Jours))
          .get();

      for (final doc in echeancesProches.docs) {
        final data = doc.data();
        final dateEcheance = data['dateEcheance'].toDate();
        final joursRestants = dateEcheance.difference(aujourdhui).inDays;
        
        if (joursRestants <= 7) {
          await _sendEcheanceReminder(doc.id, data, joursRestants);
        }
      }
      
      // Vérifier les échéances en retard
      final echeancesEnRetard = await _firestore
          .collection('echeances')
          .where('statut', isEqualTo: 'en_attente')
          .where('dateEcheance', isLessThan: Timestamp.fromDate(aujourdhui))
          .get();

      for (final doc in echeancesEnRetard.docs) {
        final data = doc.data();
        await _sendRetardNotification(doc.id, data);
      }
      
    } catch (e) {
      print('❌ Erreur vérification échéances: $e');
    }
  }

  /// 📧 Envoyer un rappel d'échéance
  static Future<void> _sendEcheanceReminder(String echeanceId, Map<String, dynamic> data, int joursRestants) async {
    try {
      final contratId = data['contratId'];
      final conducteurId = data['conducteurId'];
      final montant = data['montant'];
      final numeroEcheance = data['numeroEcheance'];
      
      String message;
      if (joursRestants == 0) {
        message = 'Votre échéance n°$numeroEcheance de ${montant.toStringAsFixed(0)} DT est due aujourd\'hui. Merci de vous présenter à l\'agence pour effectuer le paiement.';
      } else {
        message = 'Rappel: Votre échéance n°$numeroEcheance de ${montant.toStringAsFixed(0)} DT est due dans $joursRestants jour${joursRestants > 1 ? 's' : ''}. Merci de vous présenter à l\'agence.';
      }
      
      // Créer la notification
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'echeance_rappel',
        'titre': 'Rappel d\'échéance',
        'message': message,
        'contratId': contratId,
        'echeanceId': echeanceId,
        'montant': montant,
        'joursRestants': joursRestants,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });
      
      // Marquer le rappel comme envoyé
      await _firestore.collection('echeances').doc(echeanceId).update({
        'rappelEnvoye': true,
        'dateRappel': FieldValue.serverTimestamp(),
      });
      
      print('📧 Rappel d\'échéance envoyé pour l\'échéance $echeanceId');
      
    } catch (e) {
      print('❌ Erreur envoi rappel: $e');
    }
  }

  /// ⚠️ Envoyer une notification de retard
  static Future<void> _sendRetardNotification(String echeanceId, Map<String, dynamic> data) async {
    try {
      final contratId = data['contratId'];
      final conducteurId = data['conducteurId'];
      final montant = data['montant'];
      final numeroEcheance = data['numeroEcheance'];
      final dateEcheance = data['dateEcheance'].toDate();
      final joursRetard = DateTime.now().difference(dateEcheance).inDays;
      
      // Mettre à jour le statut de l'échéance
      await _firestore.collection('echeances').doc(echeanceId).update({
        'statut': 'en_retard',
        'joursRetard': joursRetard,
      });
      
      // Créer la notification de retard
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'echeance_retard',
        'titre': 'Échéance en retard',
        'message': 'Votre échéance n°$numeroEcheance de ${montant.toStringAsFixed(0)} DT est en retard de $joursRetard jour${joursRetard > 1 ? 's' : ''}. Merci de régulariser votre situation rapidement.',
        'contratId': contratId,
        'echeanceId': echeanceId,
        'montant': montant,
        'joursRetard': joursRetard,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': 'haute',
      });
      
      // Si retard > 30 jours, suspendre le contrat
      if (joursRetard > 30) {
        await _suspendContract(contratId, conducteurId);
      }
      
      print('⚠️ Notification de retard envoyée pour l\'échéance $echeanceId ($joursRetard jours)');
      
    } catch (e) {
      print('❌ Erreur notification retard: $e');
    }
  }

  /// 🚫 Suspendre un contrat pour non-paiement
  static Future<void> _suspendContract(String contratId, String conducteurId) async {
    try {
      // Mettre à jour le statut du contrat
      await _firestore.collection('contrats').doc(contratId).update({
        'statut': 'suspendu',
        'motifSuspension': 'non_paiement',
        'dateSuspension': FieldValue.serverTimestamp(),
      });
      
      // Notification de suspension
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'contrat_suspendu',
        'titre': 'Contrat suspendu',
        'message': 'Votre contrat d\'assurance a été suspendu pour non-paiement. Contactez votre agence pour régulariser votre situation.',
        'contratId': contratId,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': 'critique',
      });
      
      print('🚫 Contrat $contratId suspendu pour non-paiement');
      
    } catch (e) {
      print('❌ Erreur suspension contrat: $e');
    }
  }

  /// 💳 Marquer une échéance comme payée
  static Future<void> markEcheanceAsPaid(String echeanceId, String agentId) async {
    try {
      await _firestore.collection('echeances').doc(echeanceId).update({
        'statut': 'payee',
        'datePaiement': FieldValue.serverTimestamp(),
        'agentId': agentId,
      });
      
      // Vérifier si c'était la dernière échéance en retard
      final echeanceData = await _firestore.collection('echeances').doc(echeanceId).get();
      final contratId = echeanceData.data()?['contratId'];
      
      if (contratId != null) {
        final echeancesEnRetard = await _firestore
            .collection('echeances')
            .where('contratId', isEqualTo: contratId)
            .where('statut', whereIn: ['en_retard', 'en_attente'])
            .get();
        
        // Si plus d'échéances en retard, réactiver le contrat
        if (echeancesEnRetard.docs.isEmpty) {
          await _firestore.collection('contrats').doc(contratId).update({
            'statut': 'actif',
            'motifSuspension': FieldValue.delete(),
            'dateSuspension': FieldValue.delete(),
            'dateReactivation': FieldValue.serverTimestamp(),
          });
          
          print('✅ Contrat $contratId réactivé');
        }
      }
      
      print('💳 Échéance $echeanceId marquée comme payée');
      
    } catch (e) {
      print('❌ Erreur paiement échéance: $e');
      throw e;
    }
  }

  /// 📊 Obtenir les échéances d'un contrat
  static Future<List<Map<String, dynamic>>> getEcheancesContrat(String contratId) async {
    try {
      final snapshot = await _firestore
          .collection('echeances')
          .where('contratId', isEqualTo: contratId)
          .orderBy('numeroEcheance')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      print('❌ Erreur récupération échéances: $e');
      return [];
    }
  }

  /// 🔄 Vérifier les contrats proches de l'expiration
  static Future<void> checkExpiringContracts() async {
    try {
      final now = DateTime.now();
      final dans30Jours = now.add(const Duration(days: 30));
      
      final contratsExpirants = await _firestore
          .collection('contrats')
          .where('statut', isEqualTo: 'actif')
          .where('dateFin', isLessThanOrEqualTo: Timestamp.fromDate(dans30Jours))
          .where('dateFin', isGreaterThan: Timestamp.fromDate(now))
          .get();

      for (final doc in contratsExpirants.docs) {
        final data = doc.data();
        final dateFin = data['dateFin'].toDate();
        final joursRestants = dateFin.difference(now).inDays;
        
        await _sendExpirationReminder(doc.id, data, joursRestants);
      }
      
    } catch (e) {
      print('❌ Erreur vérification expirations: $e');
    }
  }

  /// 📅 Envoyer un rappel d'expiration
  static Future<void> _sendExpirationReminder(String contratId, Map<String, dynamic> data, int joursRestants) async {
    try {
      final conducteurId = data['conducteurId'];
      final numeroContrat = data['numeroContrat'];
      
      // Vérifier si le rappel n'a pas déjà été envoyé
      final existingNotification = await _firestore
          .collection('notifications')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('contratId', isEqualTo: contratId)
          .where('type', isEqualTo: 'expiration_proche')
          .get();
      
      if (existingNotification.docs.isNotEmpty) return;
      
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'expiration_proche',
        'titre': 'Contrat expire bientôt',
        'message': 'Votre contrat $numeroContrat expire dans $joursRestants jour${joursRestants > 1 ? 's' : ''}. Pensez à le renouveler pour continuer à être couvert.',
        'contratId': contratId,
        'joursRestants': joursRestants,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });
      
      print('📅 Rappel d\'expiration envoyé pour le contrat $contratId ($joursRestants jours)');
      
    } catch (e) {
      print('❌ Erreur rappel expiration: $e');
    }
  }
}
