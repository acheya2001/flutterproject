import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// 🔔 Service de notifications automatiques pour les échéances
class EcheanceNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🕐 Vérifier et envoyer les rappels d'échéance
  static Future<void> verifierEtEnvoyerRappels() async {
    try {
      print('🔔 Vérification des échéances...');
      
      final maintenant = DateTime.now();
      final dans15Jours = maintenant.add(const Duration(days: 15));
      final dans3Jours = maintenant.add(const Duration(days: 3));
      final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);

      // Récupérer tous les paiements en attente
      final paiementsEnAttente = await _firestore
          .collection('paiements')
          .where('statut', isEqualTo: 'en_attente')
          .get();

      for (final doc in paiementsEnAttente.docs) {
        final paiement = doc.data();
        final dateEcheance = (paiement['dateEcheance'] as Timestamp).toDate();
        final dateEcheanceOnly = DateTime(dateEcheance.year, dateEcheance.month, dateEcheance.day);
        final conducteurId = paiement['conducteurId'];
        final montant = paiement['montant'];
        final paiementId = doc.id;

        // Vérifier si une notification a déjà été envoyée
        final notificationExistante = await _firestore
            .collection('notifications')
            .where('conducteurId', isEqualTo: conducteurId)
            .where('paiementId', isEqualTo: paiementId)
            .where('type', whereIn: ['rappel_15j', 'rappel_3j', 'echeance_aujourd_hui'])
            .get();

        final typesEnvoyes = notificationExistante.docs
            .map((doc) => doc.data()['type'])
            .toList();

        // Rappel 15 jours avant
        if (dateEcheanceOnly.isAtSameMomentAs(dans15Jours.add(const Duration(days: 0))) &&
            !typesEnvoyes.contains('rappel_15j')) {
          await _envoyerRappel(
            conducteurId: conducteurId,
            paiementId: paiementId,
            type: 'rappel_15j',
            titre: 'Rappel de Paiement',
            message: 'Votre paiement d\'assurance de ${montant.toStringAsFixed(2)} DT est dû dans 15 jours (${_formatDate(dateEcheance)}). Pensez à vous présenter à l\'agence.',
            priorite: 'normale',
            dateEcheance: dateEcheance,
            montant: montant,
          );
        }

        // Rappel 3 jours avant
        if (dateEcheanceOnly.isAtSameMomentAs(dans3Jours) &&
            !typesEnvoyes.contains('rappel_3j')) {
          await _envoyerRappel(
            conducteurId: conducteurId,
            paiementId: paiementId,
            type: 'rappel_3j',
            titre: 'Paiement Urgent',
            message: 'URGENT: Votre paiement d\'assurance de ${montant.toStringAsFixed(2)} DT est dû dans 3 jours (${_formatDate(dateEcheance)}). Merci de vous présenter à l\'agence rapidement.',
            priorite: 'haute',
            dateEcheance: dateEcheance,
            montant: montant,
          );
        }

        // Le jour même
        if (dateEcheanceOnly.isAtSameMomentAs(aujourdhui) &&
            !typesEnvoyes.contains('echeance_aujourd_hui')) {
          await _envoyerRappel(
            conducteurId: conducteurId,
            paiementId: paiementId,
            type: 'echeance_aujourd_hui',
            titre: 'Paiement Dû Aujourd\'hui',
            message: 'Votre paiement d\'assurance de ${montant.toStringAsFixed(2)} DT est dû AUJOURD\'HUI. Présentez-vous à l\'agence avant la fermeture.',
            priorite: 'critique',
            dateEcheance: dateEcheance,
            montant: montant,
          );
        }

        // Paiement en retard
        if (dateEcheanceOnly.isBefore(aujourdhui) &&
            !typesEnvoyes.contains('paiement_en_retard')) {
          await _marquerEnRetard(paiementId, conducteurId, dateEcheance, montant);
        }
      }

      print('✅ Vérification des échéances terminée');
    } catch (e) {
      print('❌ Erreur vérification échéances: $e');
    }
  }

  /// 📤 Envoyer un rappel de paiement
  static Future<void> _envoyerRappel({
    required String conducteurId,
    required String paiementId,
    required String type,
    required String titre,
    required String message,
    required String priorite,
    required DateTime dateEcheance,
    required double montant,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'paiementId': paiementId,
        'type': type,
        'titre': titre,
        'message': message,
        'priorite': priorite,
        'dateEcheance': Timestamp.fromDate(dateEcheance),
        'montant': montant,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'actionRequise': true,
      });

      print('📤 Rappel $type envoyé au conducteur $conducteurId');
    } catch (e) {
      print('❌ Erreur envoi rappel: $e');
    }
  }

  /// ⚠️ Marquer un paiement en retard
  static Future<void> _marquerEnRetard(String paiementId, String conducteurId, DateTime dateEcheance, double montant) async {
    try {
      // Mettre à jour le statut du paiement
      await _firestore.collection('paiements').doc(paiementId).update({
        'statut': 'en_retard',
        'dateRetard': FieldValue.serverTimestamp(),
      });

      // Envoyer notification de retard
      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'paiementId': paiementId,
        'type': 'paiement_en_retard',
        'titre': 'Paiement en Retard',
        'message': 'Votre paiement d\'assurance de ${montant.toStringAsFixed(2)} DT était dû le ${_formatDate(dateEcheance)}. Merci de régulariser votre situation rapidement pour éviter la suspension de votre contrat.',
        'priorite': 'critique',
        'dateEcheance': Timestamp.fromDate(dateEcheance),
        'montant': montant,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'actionRequise': true,
      });

      // Notifier l'agent
      final paiementDoc = await _firestore.collection('paiements').doc(paiementId).get();
      if (paiementDoc.exists) {
        final demandeId = paiementDoc.data()!['demandeId'];
        final demandeDoc = await _firestore.collection('demandes_contrats').doc(demandeId).get();
        
        if (demandeDoc.exists) {
          final agentId = demandeDoc.data()!['agentId'];
          
          await _firestore.collection('notifications').add({
            'agentId': agentId,
            'conducteurId': conducteurId,
            'paiementId': paiementId,
            'demandeId': demandeId,
            'type': 'paiement_retard_agent',
            'titre': 'Paiement en Retard',
            'message': 'Le conducteur a un paiement en retard de ${montant.toStringAsFixed(2)} DT (échéance: ${_formatDate(dateEcheance)}). Action requise.',
            'priorite': 'haute',
            'dateCreation': FieldValue.serverTimestamp(),
            'lu': false,
          });
        }
      }

      print('⚠️ Paiement $paiementId marqué en retard');
    } catch (e) {
      print('❌ Erreur marquage retard: $e');
    }
  }

  /// 📊 Obtenir les statistiques d'échéances
  static Future<Map<String, int>> getStatistiquesEcheances() async {
    try {
      final maintenant = DateTime.now();
      final dans15Jours = maintenant.add(const Duration(days: 15));
      final dans3Jours = maintenant.add(const Duration(days: 3));

      final paiementsEnAttente = await _firestore
          .collection('paiements')
          .where('statut', isEqualTo: 'en_attente')
          .get();

      int echeances15j = 0;
      int echeances3j = 0;
      int echeancesAujourdhui = 0;
      int enRetard = 0;

      for (final doc in paiementsEnAttente.docs) {
        final dateEcheance = (doc.data()['dateEcheance'] as Timestamp).toDate();
        final dateEcheanceOnly = DateTime(dateEcheance.year, dateEcheance.month, dateEcheance.day);
        final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);

        if (dateEcheanceOnly.isBefore(aujourdhui)) {
          enRetard++;
        } else if (dateEcheanceOnly.isAtSameMomentAs(aujourdhui)) {
          echeancesAujourdhui++;
        } else if (dateEcheanceOnly.isBefore(dans3Jours.add(const Duration(days: 1)))) {
          echeances3j++;
        } else if (dateEcheanceOnly.isBefore(dans15Jours.add(const Duration(days: 1)))) {
          echeances15j++;
        }
      }

      return {
        'echeances_15j': echeances15j,
        'echeances_3j': echeances3j,
        'echeances_aujourd_hui': echeancesAujourdhui,
        'en_retard': enRetard,
      };
    } catch (e) {
      print('❌ Erreur statistiques échéances: $e');
      return {
        'echeances_15j': 0,
        'echeances_3j': 0,
        'echeances_aujourd_hui': 0,
        'en_retard': 0,
      };
    }
  }

  /// 🔄 Créer le prochain paiement après un paiement effectué
  static Future<void> creerProchainPaiement(String paiementId) async {
    try {
      final paiementDoc = await _firestore.collection('paiements').doc(paiementId).get();
      if (!paiementDoc.exists) return;

      final data = paiementDoc.data()!;
      final dateEcheanceActuelle = (data['dateEcheance'] as Timestamp).toDate();
      final frequence = data['frequencePaiement'];
      
      DateTime prochaineEcheance;
      switch (frequence) {
        case 'mensuel':
          prochaineEcheance = DateTime(
            dateEcheanceActuelle.year,
            dateEcheanceActuelle.month + 1,
            dateEcheanceActuelle.day,
          );
          break;
        case 'trimestriel':
          prochaineEcheance = DateTime(
            dateEcheanceActuelle.year,
            dateEcheanceActuelle.month + 3,
            dateEcheanceActuelle.day,
          );
          break;
        case 'annuel':
        default:
          prochaineEcheance = DateTime(
            dateEcheanceActuelle.year + 1,
            dateEcheanceActuelle.month,
            dateEcheanceActuelle.day,
          );
          break;
      }

      // Créer le nouveau paiement
      await _firestore.collection('paiements').add({
        'conducteurId': data['conducteurId'],
        'demandeId': data['demandeId'],
        'numeroContrat': data['numeroContrat'],
        'montant': data['montant'],
        'frequencePaiement': frequence,
        'modePaiement': 'especes',
        'statut': 'en_attente',
        'dateEcheance': Timestamp.fromDate(prochaineEcheance),
        'periodeCouverte': _genererPeriodeCouverte(prochaineEcheance, frequence),
        'dateCreation': FieldValue.serverTimestamp(),
        'dateModification': FieldValue.serverTimestamp(),
      });

      print('✅ Prochain paiement créé pour ${_formatDate(prochaineEcheance)}');
    } catch (e) {
      print('❌ Erreur création prochain paiement: $e');
    }
  }

  /// 📅 Générer la période couverte
  static String _genererPeriodeCouverte(DateTime dateDebut, String frequence) {
    DateTime dateFin;
    switch (frequence) {
      case 'mensuel':
        dateFin = DateTime(dateDebut.year, dateDebut.month + 1, dateDebut.day);
        break;
      case 'trimestriel':
        dateFin = DateTime(dateDebut.year, dateDebut.month + 3, dateDebut.day);
        break;
      case 'annuel':
      default:
        dateFin = DateTime(dateDebut.year + 1, dateDebut.month, dateDebut.day);
        break;
    }

    return '${_formatDate(dateDebut)} - ${_formatDate(dateFin)}';
  }

  /// 📅 Formater une date
  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// 🕐 Initialiser le service (à appeler au démarrage de l'app)
  static Future<void> initialiser() async {
    // Vérifier immédiatement
    await verifierEtEnvoyerRappels();
    
    // TODO: Programmer des vérifications périodiques
    // En production, utiliser un service de tâches en arrière-plan
    print('🔔 Service d\'échéances initialisé');
  }
}
