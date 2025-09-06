import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 💰 Types de paiement disponibles en Tunisie
enum TypePaiement {
    especes('Espèces'),
    carteBancaire('Carte Bancaire'),
    virement('Virement Bancaire'),
    cheque('Chèque'),
    mobile('Paiement Mobile'); // Ooredoo Money, Orange Money

    const TypePaiement(this.label);
    final String label;
  }

/// 📅 Fréquences de paiement
enum FrequencePaiement {
  annuel('Annuel', 1, 0.0),
  semestriel('Semestriel', 2, 0.02),
  trimestriel('Trimestriel', 4, 0.05),
  mensuel('Mensuel', 12, 0.08);

  const FrequencePaiement(this.label, this.nbPaiements, this.frais);
  final String label;
  final int nbPaiements;
  final double frais; // Frais supplémentaires en pourcentage
}

/// 🧾 Modèle de paiement
class PaiementAssurance {
    final String id;
    final String contratId;
    final String numeroRecu;
    final double montant;
    final TypePaiement typePaiement;
    final FrequencePaiement frequence;
    final DateTime datePaiement;
    final String agentId;
    final String agenceId;
    final String statut; // en_attente, valide, refuse, annule
    final Map<String, dynamic> details;
    final DateTime dateCreation;

    PaiementAssurance({
      required this.id,
      required this.contratId,
      required this.numeroRecu,
      required this.montant,
      required this.typePaiement,
      required this.frequence,
      required this.datePaiement,
      required this.agentId,
      required this.agenceId,
      required this.statut,
      required this.details,
      required this.dateCreation,
    });

    factory PaiementAssurance.fromMap(Map<String, dynamic> map) {
      return PaiementAssurance(
        id: map['id'] ?? '',
        contratId: map['contratId'] ?? '',
        numeroRecu: map['numeroRecu'] ?? '',
        montant: (map['montant'] ?? 0).toDouble(),
        typePaiement: TypePaiement.values.firstWhere(
          (e) => e.name == map['typePaiement'],
          orElse: () => TypePaiement.especes,
        ),
        frequence: FrequencePaiement.values.firstWhere(
          (e) => e.name == map['frequence'],
          orElse: () => FrequencePaiement.annuel,
        ),
        datePaiement: (map['datePaiement'] as Timestamp).toDate(),
        agentId: map['agentId'] ?? '',
        agenceId: map['agenceId'] ?? '',
        statut: map['statut'] ?? '',
        details: Map<String, dynamic>.from(map['details'] ?? {}),
        dateCreation: (map['dateCreation'] as Timestamp).toDate(),
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'id': id,
        'contratId': contratId,
        'numeroRecu': numeroRecu,
        'montant': montant,
        'typePaiement': typePaiement.name,
        'frequence': frequence.name,
        'datePaiement': Timestamp.fromDate(datePaiement),
        'agentId': agentId,
        'agenceId': agenceId,
        'statut': statut,
        'details': details,
        'dateCreation': Timestamp.fromDate(dateCreation),
      };
    }
  }

/// 💳 Service de paiement pour l'assurance tunisienne
class TunisianPaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 💳 Traiter un paiement d'assurance
  static Future<Map<String, dynamic>> traiterPaiement({
    required String contratId,
    required double montantTotal,
    required TypePaiement typePaiement,
    required FrequencePaiement frequence,
    required String agentId,
    required String agenceId,
    Map<String, dynamic>? detailsPaiement,
  }) async {
    try {
      debugPrint('[PAYMENT] 💳 Traitement paiement: $montantTotal TND');

      // 1. Calculer le montant avec frais
      double fraisFrequence = montantTotal * frequence.frais;
      double montantAvecFrais = montantTotal + fraisFrequence;

      // 2. Générer numéro de reçu unique
      String numeroRecu = await _genererNumeroRecu(agenceId);

      // 3. Valider le paiement selon le type
      Map<String, dynamic> validationResult = await _validerPaiement(
        typePaiement: typePaiement,
        montant: montantAvecFrais,
        details: detailsPaiement ?? {},
      );

      if (!validationResult['success']) {
        return {
          'success': false,
          'error': validationResult['error'],
        };
      }

      // 4. Créer l'enregistrement de paiement
      final paiementData = PaiementAssurance(
        id: '',
        contratId: contratId,
        numeroRecu: numeroRecu,
        montant: montantAvecFrais,
        typePaiement: typePaiement,
        frequence: frequence,
        datePaiement: DateTime.now(),
        agentId: agentId,
        agenceId: agenceId,
        statut: 'valide',
        details: {
          ...detailsPaiement ?? {},
          'montantBase': montantTotal,
          'fraisFrequence': fraisFrequence,
          'validationDetails': validationResult['details'],
        },
        dateCreation: DateTime.now(),
      );

      // 5. Sauvegarder dans Firestore
      final docRef = await _firestore.collection('paiements_assurance').add(paiementData.toMap());
      
      // 6. Mettre à jour le contrat
      await _firestore.collection('contrats_assurance').doc(contratId).update({
        'statutPaiement': 'paye',
        'dernierPaiement': Timestamp.fromDate(DateTime.now()),
        'prochainPaiement': _calculerProchainPaiement(frequence),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 7. Générer la quittance
      Map<String, dynamic> quittance = await _genererQuittance(
        paiementId: docRef.id,
        paiement: paiementData,
      );

      debugPrint('[PAYMENT] ✅ Paiement traité avec succès: $numeroRecu');

      return {
        'success': true,
        'paiementId': docRef.id,
        'numeroRecu': numeroRecu,
        'montantPaye': montantAvecFrais,
        'quittance': quittance,
        'prochainPaiement': _calculerProchainPaiement(frequence),
      };

    } catch (e) {
      debugPrint('[PAYMENT] ❌ Erreur traitement paiement: $e');
      return {
        'success': false,
        'error': 'Erreur lors du traitement du paiement: $e',
      };
    }
  }

  /// 🔢 Générer un numéro de reçu unique
  static Future<String> _genererNumeroRecu(String agenceId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999);
    return 'REC-${agenceId.substring(0, 3).toUpperCase()}-$timestamp-$random';
  }

  /// ✅ Valider un paiement selon le type
  static Future<Map<String, dynamic>> _validerPaiement({
    required TypePaiement typePaiement,
    required double montant,
    required Map<String, dynamic> details,
  }) async {
    switch (typePaiement) {
      case TypePaiement.especes:
        return _validerPaiementEspeces(montant, details);
      
      case TypePaiement.carteBancaire:
        return _validerPaiementCarte(montant, details);
      
      case TypePaiement.virement:
        return _validerPaiementVirement(montant, details);
      
      case TypePaiement.cheque:
        return _validerPaiementCheque(montant, details);
      
      case TypePaiement.mobile:
        return _validerPaiementMobile(montant, details);
      
      default:
        return {
          'success': false,
          'error': 'Type de paiement non supporté',
        };
    }
  }

  /// 💵 Valider paiement en espèces
  static Future<Map<String, dynamic>> _validerPaiementEspeces(
    double montant, 
    Map<String, dynamic> details
  ) async {
    // Simulation de validation (en réalité, l'agent confirme la réception)
    return {
      'success': true,
      'details': {
        'methode': 'especes',
        'montantRecu': montant,
        'dateReception': DateTime.now().toIso8601String(),
      },
    };
  }

  /// 💳 Valider paiement par carte bancaire
  static Future<Map<String, dynamic>> _validerPaiementCarte(
    double montant, 
    Map<String, dynamic> details
  ) async {
    // Simulation TPE (Terminal de Paiement Électronique)
    String numeroTransaction = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'success': true,
      'details': {
        'methode': 'carte_bancaire',
        'numeroTransaction': numeroTransaction,
        'numeroAutorisation': 'AUTH${Random().nextInt(999999)}',
        'typeCarte': details['typeCarte'] ?? 'VISA',
        'dernierChiffres': details['dernierChiffres'] ?? '****',
      },
    };
  }

  /// 🏦 Valider paiement par virement
  static Future<Map<String, dynamic>> _validerPaiementVirement(
    double montant, 
    Map<String, dynamic> details
  ) async {
    return {
      'success': true,
      'details': {
        'methode': 'virement',
        'numeroReference': details['numeroReference'] ?? '',
        'banqueEmettrice': details['banqueEmettrice'] ?? '',
        'dateVirement': details['dateVirement'] ?? DateTime.now().toIso8601String(),
      },
    };
  }

  /// 📝 Valider paiement par chèque
  static Future<Map<String, dynamic>> _validerPaiementCheque(
    double montant, 
    Map<String, dynamic> details
  ) async {
    return {
      'success': true,
      'details': {
        'methode': 'cheque',
        'numeroCheque': details['numeroCheque'] ?? '',
        'banque': details['banque'] ?? '',
        'dateEmission': details['dateEmission'] ?? DateTime.now().toIso8601String(),
        'statut': 'en_attente_encaissement',
      },
    };
  }

  /// 📱 Valider paiement mobile
  static Future<Map<String, dynamic>> _validerPaiementMobile(
    double montant, 
    Map<String, dynamic> details
  ) async {
    return {
      'success': true,
      'details': {
        'methode': 'paiement_mobile',
        'operateur': details['operateur'] ?? 'Ooredoo Money',
        'numeroTransaction': 'MOB${DateTime.now().millisecondsSinceEpoch}',
        'numeroTelephone': details['numeroTelephone'] ?? '',
      },
    };
  }

  /// 📅 Calculer la prochaine échéance de paiement
  static Timestamp _calculerProchainPaiement(FrequencePaiement frequence) {
    DateTime maintenant = DateTime.now();
    DateTime prochainPaiement;

    switch (frequence) {
      case FrequencePaiement.mensuel:
        prochainPaiement = DateTime(maintenant.year, maintenant.month + 1, maintenant.day);
        break;
      case FrequencePaiement.trimestriel:
        prochainPaiement = DateTime(maintenant.year, maintenant.month + 3, maintenant.day);
        break;
      case FrequencePaiement.semestriel:
        prochainPaiement = DateTime(maintenant.year, maintenant.month + 6, maintenant.day);
        break;
      case FrequencePaiement.annuel:
        prochainPaiement = DateTime(maintenant.year + 1, maintenant.month, maintenant.day);
        break;
    }

    return Timestamp.fromDate(prochainPaiement);
  }

  /// 🧾 Générer une quittance de paiement
  static Future<Map<String, dynamic>> _genererQuittance({
    required String paiementId,
    required PaiementAssurance paiement,
  }) async {
    return {
      'id': paiementId,
      'numeroQuittance': 'QUI-${paiement.numeroRecu}',
      'numeroRecu': paiement.numeroRecu,
      'montant': paiement.montant,
      'typePaiement': paiement.typePaiement.label,
      'datePaiement': paiement.datePaiement.toIso8601String(),
      'agentId': paiement.agentId,
      'agenceId': paiement.agenceId,
      'contratId': paiement.contratId,
      'details': paiement.details,
      'dateGeneration': DateTime.now().toIso8601String(),
    };
  }

  /// 📊 Obtenir l'historique des paiements d'un contrat
  static Future<List<PaiementAssurance>> getHistoriquePaiements(String contratId) async {
    try {
      final querySnapshot = await _firestore
          .collection('paiements_assurance')
          .where('contratId', isEqualTo: contratId)
          .orderBy('datePaiement', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaiementAssurance.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('[PAYMENT] ❌ Erreur récupération historique: $e');
      return [];
    }
  }

  /// 💰 Calculer le montant avec frais selon la fréquence
  static Map<String, dynamic> calculerMontantAvecFrais({
    required double montantBase,
    required FrequencePaiement frequence,
  }) {
    double frais = montantBase * frequence.frais;
    double montantTotal = montantBase + frais;
    double montantParPaiement = montantTotal / frequence.nbPaiements;

    return {
      'montantBase': montantBase,
      'frais': frais,
      'montantTotal': montantTotal,
      'montantParPaiement': montantParPaiement,
      'nbPaiements': frequence.nbPaiements,
      'frequence': frequence.label,
    };
  }
}

/// 🔄 Service de renouvellement automatique des contrats
class TunisianRenewalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📅 Vérifier les contrats à renouveler
  static Future<List<Map<String, dynamic>>> getContratsARenouveler({
    int joursAvance = 30,
    String? agenceId,
    String? compagnieId,
  }) async {
    try {
      DateTime dateLimit = DateTime.now().add(Duration(days: joursAvance));

      Query query = _firestore
          .collection('contrats_assurance')
          .where('statut', isEqualTo: 'actif')
          .where('dateEcheance', isLessThanOrEqualTo: Timestamp.fromDate(dateLimit));

      if (agenceId != null) {
        query = query.where('agenceId', isEqualTo: agenceId);
      }

      if (compagnieId != null) {
        query = query.where('compagnieId', isEqualTo: compagnieId);
      }

      final querySnapshot = await query.get();

      List<Map<String, dynamic>> contratsARenouveler = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> contratData = doc.data() as Map<String, dynamic>;
        contratData['id'] = doc.id;

        // Calculer les jours restants
        DateTime echeance = (contratData['dateEcheance'] as Timestamp).toDate();
        int joursRestants = echeance.difference(DateTime.now()).inDays;
        contratData['joursRestants'] = joursRestants;

        // Déterminer l'urgence
        if (joursRestants <= 7) {
          contratData['urgence'] = 'critique';
        } else if (joursRestants <= 15) {
          contratData['urgence'] = 'elevee';
        } else {
          contratData['urgence'] = 'normale';
        }

        contratsARenouveler.add(contratData);
      }

      // Trier par urgence et date d'échéance
      contratsARenouveler.sort((a, b) {
        int urgenceA = _getUrgenceValue(a['urgence']);
        int urgenceB = _getUrgenceValue(b['urgence']);

        if (urgenceA != urgenceB) {
          return urgenceB.compareTo(urgenceA); // Plus urgent en premier
        }

        return a['joursRestants'].compareTo(b['joursRestants']);
      });

      return contratsARenouveler;

    } catch (e) {
      debugPrint('[RENEWAL] ❌ Erreur récupération contrats à renouveler: $e');
      return [];
    }
  }

  static int _getUrgenceValue(String urgence) {
    switch (urgence) {
      case 'critique': return 3;
      case 'elevee': return 2;
      case 'normale': return 1;
      default: return 0;
    }
  }

  /// 📧 Envoyer notifications de renouvellement
  static Future<void> envoyerNotificationsRenouvellement() async {
    try {
      List<Map<String, dynamic>> contrats = await getContratsARenouveler(joursAvance: 30);

      for (var contrat in contrats) {
        await _envoyerNotificationRenouvellement(contrat);
      }

      debugPrint('[RENEWAL] ✅ ${contrats.length} notifications envoyées');

    } catch (e) {
      debugPrint('[RENEWAL] ❌ Erreur envoi notifications: $e');
    }
  }

  static Future<void> _envoyerNotificationRenouvellement(Map<String, dynamic> contrat) async {
    try {
      // Créer la notification dans Firestore
      await _firestore.collection('notifications_renouvellement').add({
        'contratId': contrat['id'],
        'conducteurId': contrat['conducteurId'],
        'agentId': contrat['agentId'],
        'agenceId': contrat['agenceId'],
        'compagnieId': contrat['compagnieId'],
        'numeroContrat': contrat['numeroContrat'],
        'dateEcheance': contrat['dateEcheance'],
        'joursRestants': contrat['joursRestants'],
        'urgence': contrat['urgence'],
        'statut': 'envoye',
        'dateEnvoi': FieldValue.serverTimestamp(),
        'type': 'renouvellement',
        'message': _genererMessageRenouvellement(contrat),
      });

      // TODO: Envoyer SMS/Email au conducteur
      // TODO: Notifier l'agent

    } catch (e) {
      debugPrint('[RENEWAL] ❌ Erreur envoi notification pour ${contrat['numeroContrat']}: $e');
    }
  }

  static String _genererMessageRenouvellement(Map<String, dynamic> contrat) {
    int jours = contrat['joursRestants'];
    String numeroContrat = contrat['numeroContrat'];

    if (jours <= 0) {
      return 'URGENT: Votre contrat d\'assurance $numeroContrat a expiré. Renouvelez immédiatement pour éviter l\'interruption de couverture.';
    } else if (jours <= 7) {
      return 'URGENT: Votre contrat d\'assurance $numeroContrat expire dans $jours jour(s). Contactez votre agent pour le renouvellement.';
    } else if (jours <= 15) {
      return 'RAPPEL: Votre contrat d\'assurance $numeroContrat expire dans $jours jours. Pensez à le renouveler.';
    } else {
      return 'INFO: Votre contrat d\'assurance $numeroContrat expire dans $jours jours. Préparez votre renouvellement.';
    }
  }

  /// 🔄 Renouveler un contrat
  static Future<Map<String, dynamic>> renouvellerContrat({
    required String contratId,
    required String agentId,
    Map<String, dynamic>? nouvellesConditions,
  }) async {
    try {
      debugPrint('[RENEWAL] 🔄 Renouvellement contrat: $contratId');

      // 1. Récupérer le contrat actuel
      final contratDoc = await _firestore.collection('contrats_assurance').doc(contratId).get();
      if (!contratDoc.exists) {
        throw Exception('Contrat non trouvé');
      }

      Map<String, dynamic> contratActuel = contratDoc.data()!;

      // 2. Calculer les nouvelles dates
      DateTime ancienneDateFin = (contratActuel['dateFin'] as Timestamp).toDate();
      DateTime nouvelleDateDebut = ancienneDateFin.add(const Duration(days: 1));
      DateTime nouvelleDateFin = DateTime(nouvelleDateDebut.year + 1, nouvelleDateDebut.month, nouvelleDateDebut.day);
      DateTime nouvelleEcheance = nouvelleDateFin.subtract(const Duration(days: 30));

      // 3. Recalculer la prime si nécessaire
      double nouvellePrime = contratActuel['primeAnnuelle'];
      if (nouvellesConditions != null && nouvellesConditions.containsKey('primeAnnuelle')) {
        nouvellePrime = nouvellesConditions['primeAnnuelle'];
      }

      // 4. Créer le nouveau contrat
      String nouveauNumeroContrat = await _genererNouveauNumeroContrat(contratActuel['numeroContrat']);

      Map<String, dynamic> nouveauContrat = {
        ...contratActuel,
        'numeroContrat': nouveauNumeroContrat,
        'dateDebut': Timestamp.fromDate(nouvelleDateDebut),
        'dateFin': Timestamp.fromDate(nouvelleDateFin),
        'dateEcheance': Timestamp.fromDate(nouvelleEcheance),
        'primeAnnuelle': nouvellePrime,
        'statut': 'en_attente_paiement',
        'contratPrecedent': contratId,
        'typeRenouvellement': 'automatique',
        'agentRenouvellement': agentId,
        'dateCreation': FieldValue.serverTimestamp(),
        'dateRenouvellement': FieldValue.serverTimestamp(),
      };

      // Appliquer les nouvelles conditions si fournies
      if (nouvellesConditions != null) {
        nouveauContrat.addAll(nouvellesConditions);
      }

      // 5. Sauvegarder le nouveau contrat
      final nouveauContratRef = await _firestore.collection('contrats_assurance').add(nouveauContrat);

      // 6. Marquer l'ancien contrat comme renouvelé
      await _firestore.collection('contrats_assurance').doc(contratId).update({
        'statut': 'renouvele',
        'contratSuivant': nouveauContratRef.id,
        'dateRenouvellement': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 7. Créer l'historique de renouvellement
      await _firestore.collection('historique_renouvellements').add({
        'contratPrecedent': contratId,
        'contratNouveau': nouveauContratRef.id,
        'agentId': agentId,
        'dateRenouvellement': FieldValue.serverTimestamp(),
        'typeRenouvellement': 'automatique',
        'modifications': nouvellesConditions ?? {},
        'anciennePrime': contratActuel['primeAnnuelle'],
        'nouvellePrime': nouvellePrime,
      });

      debugPrint('[RENEWAL] ✅ Contrat renouvelé: $nouveauNumeroContrat');

      return {
        'success': true,
        'nouveauContratId': nouveauContratRef.id,
        'nouveauNumeroContrat': nouveauNumeroContrat,
        'nouvellePrime': nouvellePrime,
        'nouvelleDateDebut': nouvelleDateDebut.toIso8601String(),
        'nouvelleDateFin': nouvelleDateFin.toIso8601String(),
      };

    } catch (e) {
      debugPrint('[RENEWAL] ❌ Erreur renouvellement: $e');
      return {
        'success': false,
        'error': 'Erreur lors du renouvellement: $e',
      };
    }
  }

  static Future<String> _genererNouveauNumeroContrat(String ancienNumero) async {
    // Extraire l'année et incrémenter
    final maintenant = DateTime.now();
    final annee = maintenant.year.toString();

    // Si l'ancien numéro contient l'année, la remplacer
    if (ancienNumero.contains(RegExp(r'20\d{2}'))) {
      return ancienNumero.replaceAll(RegExp(r'20\d{2}'), annee);
    }

    // Sinon, ajouter un suffixe
    return '$ancienNumero-R$annee';
  }

  /// 📊 Statistiques de renouvellement
  static Future<Map<String, dynamic>> getStatistiquesRenouvellement({
    String? agenceId,
    String? compagnieId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      Query query = _firestore.collection('contrats_assurance');

      if (agenceId != null) {
        query = query.where('agenceId', isEqualTo: agenceId);
      }

      if (compagnieId != null) {
        query = query.where('compagnieId', isEqualTo: compagnieId);
      }

      final querySnapshot = await query.get();

      int totalContrats = 0;
      int contratsActifs = 0;
      int contratsExpires = 0;
      int contratsRenouveles = 0;
      int contratsARenouveler = 0;
      double chiffreAffaires = 0;

      DateTime maintenant = DateTime.now();
      DateTime dans30Jours = maintenant.add(const Duration(days: 30));

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> contrat = doc.data() as Map<String, dynamic>;
        totalContrats++;

        String statut = contrat['statut'] ?? '';
        DateTime? dateFin = contrat['dateFin'] != null
            ? (contrat['dateFin'] as Timestamp).toDate()
            : null;

        switch (statut) {
          case 'actif':
            contratsActifs++;
            if (dateFin != null && dateFin.isBefore(dans30Jours)) {
              contratsARenouveler++;
            }
            break;
          case 'expire':
            contratsExpires++;
            break;
          case 'renouvele':
            contratsRenouveles++;
            break;
        }

        if (contrat['primeAnnuelle'] != null) {
          chiffreAffaires += contrat['primeAnnuelle'];
        }
      }

      double tauxRenouvellement = totalContrats > 0
          ? (contratsRenouveles / totalContrats) * 100
          : 0;

      return {
        'totalContrats': totalContrats,
        'contratsActifs': contratsActifs,
        'contratsExpires': contratsExpires,
        'contratsRenouveles': contratsRenouveles,
        'contratsARenouveler': contratsARenouveler,
        'tauxRenouvellement': tauxRenouvellement.round(),
        'chiffreAffaires': chiffreAffaires.round(),
        'dateCalcul': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('[RENEWAL] ❌ Erreur calcul statistiques: $e');
      return {};
    }
  }
}
