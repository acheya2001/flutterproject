import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'echeances_service.dart';

class AutomatedTasksService {
  static Timer? _timer;
  static bool _isRunning = false;

  /// 🚀 Démarrer les tâches automatiques
  static void startAutomatedTasks() {
    if (_isRunning) return;
    
    _isRunning = true;
    print('🚀 Démarrage des tâches automatiques...');
    
    // Exécuter immédiatement
    _runTasks();
    
    // Puis exécuter toutes les heures
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _runTasks();
    });
  }

  /// 🛑 Arrêter les tâches automatiques
  static void stopAutomatedTasks() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    print('🛑 Tâches automatiques arrêtées');
  }

  /// ⚙️ Exécuter toutes les tâches
  static Future<void> _runTasks() async {
    try {
      print('⚙️ Exécution des tâches automatiques...');
      
      // Vérifier les échéances
      await EcheancesService.checkAndSendReminders();
      
      // Vérifier les contrats expirants
      await EcheancesService.checkExpiringContracts();
      
      // Nettoyer les anciennes notifications
      await _cleanOldNotifications();
      
      // Mettre à jour les statuts des contrats expirés
      await _updateExpiredContracts();
      
      print('✅ Tâches automatiques terminées');
      
    } catch (e) {
      print('❌ Erreur dans les tâches automatiques: $e');
    }
  }

  /// 🧹 Nettoyer les anciennes notifications (plus de 30 jours)
  static Future<void> _cleanOldNotifications() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('dateCreation', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (oldNotifications.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        
        for (final doc in oldNotifications.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        print('🧹 ${oldNotifications.docs.length} anciennes notifications supprimées');
      }
      
    } catch (e) {
      print('❌ Erreur nettoyage notifications: $e');
    }
  }

  /// 📅 Mettre à jour les contrats expirés
  static Future<void> _updateExpiredContracts() async {
    try {
      final now = DateTime.now();
      
      final expiredContracts = await FirebaseFirestore.instance
          .collection('contrats')
          .where('statut', isEqualTo: 'actif')
          .where('dateFin', isLessThan: Timestamp.fromDate(now))
          .get();

      if (expiredContracts.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        
        for (final doc in expiredContracts.docs) {
          batch.update(doc.reference, {
            'statut': 'expire',
            'dateExpiration': FieldValue.serverTimestamp(),
          });
          
          // Créer notification d'expiration
          final data = doc.data();
          batch.set(
            FirebaseFirestore.instance.collection('notifications').doc(),
            {
              'conducteurId': data['conducteurId'],
              'type': 'contrat_expire',
              'titre': 'Contrat expiré',
              'message': 'Votre contrat ${data['numeroContrat']} a expiré. Renouvelez-le pour continuer à être couvert.',
              'contratId': doc.id,
              'dateCreation': FieldValue.serverTimestamp(),
              'lu': false,
              'priorite': 'haute',
            },
          );
        }
        
        await batch.commit();
        print('📅 ${expiredContracts.docs.length} contrats marqués comme expirés');
      }
      
    } catch (e) {
      print('❌ Erreur mise à jour contrats expirés: $e');
    }
  }

  /// 🔄 Traiter les renouvellements automatiques
  static Future<void> processAutoRenewals() async {
    try {
      final now = DateTime.now();
      final dans7Jours = now.add(const Duration(days: 7));
      
      // Trouver les contrats avec renouvellement automatique activé
      final autoRenewContracts = await FirebaseFirestore.instance
          .collection('contrats')
          .where('statut', isEqualTo: 'actif')
          .where('renouvellementAutomatique', isEqualTo: true)
          .where('dateFin', isLessThanOrEqualTo: Timestamp.fromDate(dans7Jours))
          .where('dateFin', isGreaterThan: Timestamp.fromDate(now))
          .get();

      for (final doc in autoRenewContracts.docs) {
        final data = doc.data();
        
        // Vérifier si le renouvellement n'a pas déjà été traité
        final existingRenewal = await FirebaseFirestore.instance
            .collection('demandes_renouvellement')
            .where('contratActuelId', isEqualTo: doc.id)
            .where('statut', whereIn: ['en_attente_validation', 'approuve'])
            .get();
        
        if (existingRenewal.docs.isEmpty) {
          // Créer une demande de renouvellement automatique
          await FirebaseFirestore.instance.collection('demandes_renouvellement').add({
            'contratActuelId': doc.id,
            'conducteurId': data['conducteurId'],
            'nouvelleFormule': data['formuleAssurance'], // Même formule
            'nouvelleFrequence': data['frequencePaiement'], // Même fréquence
            'renouvellementAutomatique': true,
            'typeRenouvellement': 'automatique',
            'statut': 'en_attente_validation',
            'dateCreation': FieldValue.serverTimestamp(),
          });
          
          // Notification à l'agent
          await FirebaseFirestore.instance.collection('notifications').add({
            'type': 'renouvellement_automatique',
            'titre': 'Renouvellement automatique',
            'message': 'Renouvellement automatique programmé pour le contrat ${data['numeroContrat']}',
            'contratId': doc.id,
            'dateCreation': FieldValue.serverTimestamp(),
            'lu': false,
          });
          
          // Notification au conducteur
          await FirebaseFirestore.instance.collection('notifications').add({
            'conducteurId': data['conducteurId'],
            'type': 'renouvellement_programme',
            'titre': 'Renouvellement programmé',
            'message': 'Votre contrat ${data['numeroContrat']} sera automatiquement renouvelé. Vous recevrez une confirmation prochainement.',
            'contratId': doc.id,
            'dateCreation': FieldValue.serverTimestamp(),
            'lu': false,
          });
          
          print('🔄 Renouvellement automatique programmé pour ${data['numeroContrat']}');
        }
      }
      
    } catch (e) {
      print('❌ Erreur renouvellements automatiques: $e');
    }
  }

  /// 📊 Générer des statistiques quotidiennes
  static Future<void> generateDailyStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Compter les nouvelles demandes
      final newRequests = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateCreation', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      
      // Compter les contrats activés
      final newContracts = await FirebaseFirestore.instance
          .collection('contrats')
          .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateCreation', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      
      // Compter les paiements
      final payments = await FirebaseFirestore.instance
          .collection('echeances')
          .where('datePaiement', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('datePaiement', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      
      // Calculer le montant total des paiements
      double totalPayments = 0;
      for (final doc in payments.docs) {
        final data = doc.data();
        totalPayments += (data['montant'] ?? 0.0);
      }
      
      // Sauvegarder les statistiques
      await FirebaseFirestore.instance.collection('statistiques_quotidiennes').add({
        'date': Timestamp.fromDate(startOfDay),
        'nouvellesDemandes': newRequests.docs.length,
        'nouveauxContrats': newContracts.docs.length,
        'nombrePaiements': payments.docs.length,
        'montantTotalPaiements': totalPayments,
        'dateCreation': FieldValue.serverTimestamp(),
      });
      
      print('📊 Statistiques quotidiennes générées: ${newRequests.docs.length} demandes, ${newContracts.docs.length} contrats, ${totalPayments.toStringAsFixed(0)} DT');
      
    } catch (e) {
      print('❌ Erreur génération statistiques: $e');
    }
  }

  /// 🔔 Envoyer des notifications push (à implémenter avec FCM)
  static Future<void> sendPushNotifications() async {
    try {
      // TODO: Implémenter l'envoi de notifications push avec Firebase Cloud Messaging
      // Pour les notifications critiques (contrat expiré, paiement en retard, etc.)
      
      final criticalNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('priorite', isEqualTo: 'critique')
          .where('pushEnvoye', isEqualTo: false)
          .limit(10)
          .get();
      
      for (final doc in criticalNotifications.docs) {
        // Ici on enverrait la notification push
        // await FCMService.sendNotification(doc.data());
        
        // Marquer comme envoyée
        await doc.reference.update({'pushEnvoye': true});
      }
      
      if (criticalNotifications.docs.isNotEmpty) {
        print('🔔 ${criticalNotifications.docs.length} notifications push critiques envoyées');
      }
      
    } catch (e) {
      print('❌ Erreur notifications push: $e');
    }
  }

  /// 🎯 Exécuter une tâche spécifique manuellement
  static Future<void> runSpecificTask(String taskName) async {
    try {
      switch (taskName) {
        case 'echeances':
          await EcheancesService.checkAndSendReminders();
          break;
        case 'expirations':
          await EcheancesService.checkExpiringContracts();
          break;
        case 'renouvellements':
          await processAutoRenewals();
          break;
        case 'nettoyage':
          await _cleanOldNotifications();
          break;
        case 'statistiques':
          await generateDailyStats();
          break;
        case 'push':
          await sendPushNotifications();
          break;
        default:
          print('❌ Tâche inconnue: $taskName');
      }
    } catch (e) {
      print('❌ Erreur tâche $taskName: $e');
    }
  }

  /// 📈 Obtenir le statut des tâches automatiques
  static Map<String, dynamic> getTasksStatus() {
    return {
      'isRunning': _isRunning,
      'lastRun': DateTime.now().toIso8601String(),
      'nextRun': _timer != null 
          ? DateTime.now().add(const Duration(hours: 1)).toIso8601String()
          : null,
    };
  }
}
