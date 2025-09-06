import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/paiement_model.dart';

/// 💰 Service de gestion des paiements d'assurance
class PaiementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'paiements';

  /// 📅 Créer le premier paiement après validation du dossier
  static Future<String?> creerPremierPaiement({
    required String conducteurId,
    required String demandeId,
    required String numeroContrat,
    required double montant,
    required String frequencePaiement,
  }) async {
    try {
      print('💰 Création premier paiement pour $conducteurId');

      final maintenant = DateTime.now();
      final premierePaiement = PaiementModel(
        id: '',
        conducteurId: conducteurId,
        demandeId: demandeId,
        numeroContrat: numeroContrat,
        montant: montant,
        frequencePaiement: frequencePaiement,
        modePaiement: 'especes', // Par défaut
        statut: 'en_attente',
        dateEcheance: maintenant.add(const Duration(days: 7)), // 7 jours pour payer
        periodeCouverte: _genererPeriodeCouverte(maintenant, frequencePaiement),
        dateCreation: maintenant,
        dateModification: maintenant,
      );

      final docRef = await _firestore.collection(_collection).add(premierePaiement.toFirestore());
      
      print('✅ Premier paiement créé: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur création premier paiement: $e');
      return null;
    }
  }

  /// 💳 Valider un paiement (par l'agent)
  static Future<bool> validerPaiement({
    required String paiementId,
    required String agentId,
    required String modePaiement,
    required double montantRecu,
  }) async {
    try {
      print('💳 Validation paiement $paiementId par agent $agentId');

      final maintenant = DateTime.now();
      final numeroRecu = _genererNumeroRecu();

      await _firestore.collection(_collection).doc(paiementId).update({
        'statut': 'paye',
        'datePaiement': Timestamp.fromDate(maintenant),
        'agentValidateur': agentId,
        'modePaiement': modePaiement,
        'numeroRecu': numeroRecu,
        'montant': montantRecu, // Au cas où le montant diffère
        'dateModification': Timestamp.fromDate(maintenant),
      });

      // Créer le prochain paiement automatiquement
      await _creerProchainPaiement(paiementId);

      print('✅ Paiement validé avec reçu $numeroRecu');
      return true;
    } catch (e) {
      print('❌ Erreur validation paiement: $e');
      return false;
    }
  }

  /// 🔄 Créer le prochain paiement automatiquement
  static Future<void> _creerProchainPaiement(String paiementActuelId) async {
    try {
      final paiementActuel = await _firestore.collection(_collection).doc(paiementActuelId).get();
      if (!paiementActuel.exists) return;

      final data = paiementActuel.data()!;
      final dateEcheanceActuelle = (data['dateEcheance'] as Timestamp).toDate();
      
      DateTime prochaineEcheance;
      switch (data['frequencePaiement']) {
        case 'mensuel':
          prochaineEcheance = DateTime(dateEcheanceActuelle.year, dateEcheanceActuelle.month + 1, dateEcheanceActuelle.day);
          break;
        case 'trimestriel':
          prochaineEcheance = DateTime(dateEcheanceActuelle.year, dateEcheanceActuelle.month + 3, dateEcheanceActuelle.day);
          break;
        case 'annuel':
        default:
          prochaineEcheance = DateTime(dateEcheanceActuelle.year + 1, dateEcheanceActuelle.month, dateEcheanceActuelle.day);
          break;
      }

      final nouveauPaiement = PaiementModel(
        id: '',
        conducteurId: data['conducteurId'],
        demandeId: data['demandeId'],
        numeroContrat: data['numeroContrat'],
        montant: data['montant'].toDouble(),
        frequencePaiement: data['frequencePaiement'],
        modePaiement: 'especes',
        statut: 'en_attente',
        dateEcheance: prochaineEcheance,
        periodeCouverte: _genererPeriodeCouverte(prochaineEcheance, data['frequencePaiement']),
        dateCreation: DateTime.now(),
        dateModification: DateTime.now(),
      );

      await _firestore.collection(_collection).add(nouveauPaiement.toFirestore());
      print('✅ Prochain paiement créé pour ${prochaineEcheance.toString()}');
    } catch (e) {
      print('❌ Erreur création prochain paiement: $e');
    }
  }

  /// 📋 Récupérer les paiements d'un conducteur
  static Stream<List<PaiementModel>> getPaiementsConducteur(String conducteurId) {
    return _firestore
        .collection(_collection)
        .where('conducteurId', isEqualTo: conducteurId)
        .orderBy('dateEcheance', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PaiementModel.fromFirestore(doc)).toList());
  }

  /// 📊 Récupérer les paiements en attente pour un agent
  static Stream<List<PaiementModel>> getPaiementsEnAttente(String? agenceId) {
    Query query = _firestore
        .collection(_collection)
        .where('statut', isEqualTo: 'en_attente')
        .orderBy('dateEcheance', descending: false);

    return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => PaiementModel.fromFirestore(doc)).toList());
  }

  /// ⚠️ Récupérer les paiements en retard
  static Stream<List<PaiementModel>> getPaiementsEnRetard() {
    final maintenant = Timestamp.fromDate(DateTime.now());
    
    return _firestore
        .collection(_collection)
        .where('statut', isEqualTo: 'en_attente')
        .where('dateEcheance', isLessThan: maintenant)
        .orderBy('dateEcheance', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PaiementModel.fromFirestore(doc)).toList());
  }

  /// 🔔 Envoyer des rappels automatiques
  static Future<void> envoyerRappelsAutomatiques() async {
    try {
      final maintenant = DateTime.now();
      final dans15Jours = maintenant.add(const Duration(days: 15));
      final dans3Jours = maintenant.add(const Duration(days: 3));

      // Rappels 15 jours avant
      final rappels15j = await _firestore
          .collection(_collection)
          .where('statut', isEqualTo: 'en_attente')
          .where('dateEcheance', isGreaterThanOrEqualTo: Timestamp.fromDate(maintenant))
          .where('dateEcheance', isLessThanOrEqualTo: Timestamp.fromDate(dans15Jours))
          .where('dateRappel', isNull: true)
          .get();

      for (final doc in rappels15j.docs) {
        await _envoyerNotificationRappel(doc.id, doc.data(), 'rappel_15j');
      }

      // Rappels 3 jours avant
      final rappels3j = await _firestore
          .collection(_collection)
          .where('statut', isEqualTo: 'en_attente')
          .where('dateEcheance', isGreaterThanOrEqualTo: Timestamp.fromDate(maintenant))
          .where('dateEcheance', isLessThanOrEqualTo: Timestamp.fromDate(dans3Jours))
          .get();

      for (final doc in rappels3j.docs) {
        await _envoyerNotificationRappel(doc.id, doc.data(), 'rappel_3j');
      }

      print('✅ Rappels automatiques envoyés');
    } catch (e) {
      print('❌ Erreur envoi rappels: $e');
    }
  }

  /// 🔔 Envoyer une notification de rappel
  static Future<void> _envoyerNotificationRappel(String paiementId, Map<String, dynamic> paiementData, String typeRappel) async {
    try {
      final conducteurId = paiementData['conducteurId'];
      final montant = paiementData['montant'];
      final dateEcheance = (paiementData['dateEcheance'] as Timestamp).toDate();
      
      String titre, message;
      switch (typeRappel) {
        case 'rappel_15j':
          titre = 'Rappel de Paiement';
          message = 'Votre paiement d\'assurance de ${montant.toStringAsFixed(2)} DT est dû dans 15 jours (${_formatDate(dateEcheance)}).';
          break;
        case 'rappel_3j':
          titre = 'Paiement Urgent';
          message = 'Votre paiement d\'assurance de ${montant.toStringAsFixed(2)} DT est dû dans 3 jours (${_formatDate(dateEcheance)}). Merci de vous présenter à l\'agence.';
          break;
        default:
          return;
      }

      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': typeRappel,
        'titre': titre,
        'message': message,
        'paiementId': paiementId,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': typeRappel == 'rappel_3j' ? 'haute' : 'normale',
      });

      // Marquer le rappel comme envoyé
      await _firestore.collection(_collection).doc(paiementId).update({
        'dateRappel': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('❌ Erreur envoi notification rappel: $e');
    }
  }

  /// 🔢 Générer un numéro de reçu unique
  static String _genererNumeroRecu() {
    final maintenant = DateTime.now();
    final timestamp = maintenant.millisecondsSinceEpoch;
    return 'REC${maintenant.year}${maintenant.month.toString().padLeft(2, '0')}${maintenant.day.toString().padLeft(2, '0')}_$timestamp';
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// 📊 Obtenir les statistiques de paiement
  static Future<StatistiquesPaiement> getStatistiquesPaiement({String? agenceId}) async {
    try {
      Query query = _firestore.collection(_collection);
      
      final snapshot = await query.get();
      final paiements = snapshot.docs.map((doc) => PaiementModel.fromFirestore(doc)).toList();
      
      return StatistiquesPaiement.fromPaiements(paiements);
    } catch (e) {
      print('❌ Erreur récupération statistiques: $e');
      return StatistiquesPaiement(
        totalPaiements: 0,
        paiementsEnAttente: 0,
        paiementsEnRetard: 0,
        paiementsPayes: 0,
        montantTotal: 0.0,
        montantEnAttente: 0.0,
        montantEnRetard: 0.0,
      );
    }
  }
}
