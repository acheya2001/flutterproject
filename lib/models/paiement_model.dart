import 'package:cloud_firestore/cloud_firestore.dart';

/// 💰 Modèle pour les paiements d'assurance
class PaiementModel {
  final String id;
  final String conducteurId;
  final String demandeId;
  final String numeroContrat;
  final double montant;
  final String frequencePaiement; // 'annuel', 'trimestriel', 'mensuel'
  final String modePaiement; // 'especes', 'carte_bancaire', 'cheque'
  final String statut; // 'en_attente', 'paye', 'en_retard', 'annule'
  final DateTime dateEcheance;
  final DateTime? datePaiement;
  final DateTime? dateRappel;
  final String? agentValidateur;
  final String? numeroRecu;
  final String? periodeCouverte; // 'Janvier - Mars 2025'
  final Map<String, dynamic>? metadonnees;
  final DateTime dateCreation;
  final DateTime dateModification;

  PaiementModel({
    required this.id,
    required this.conducteurId,
    required this.demandeId,
    required this.numeroContrat,
    required this.montant,
    required this.frequencePaiement,
    required this.modePaiement,
    required this.statut,
    required this.dateEcheance,
    this.datePaiement,
    this.dateRappel,
    this.agentValidateur,
    this.numeroRecu,
    this.periodeCouverte,
    this.metadonnees,
    required this.dateCreation,
    required this.dateModification,
  });

  /// 📄 Créer depuis Firestore
  factory PaiementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PaiementModel(
      id: doc.id,
      conducteurId: data['conducteurId'] ?? '',
      demandeId: data['demandeId'] ?? '',
      numeroContrat: data['numeroContrat'] ?? '',
      montant: (data['montant'] ?? 0.0).toDouble(),
      frequencePaiement: data['frequencePaiement'] ?? 'annuel',
      modePaiement: data['modePaiement'] ?? 'especes',
      statut: data['statut'] ?? 'en_attente',
      dateEcheance: (data['dateEcheance'] as Timestamp).toDate(),
      datePaiement: data['datePaiement'] != null 
          ? (data['datePaiement'] as Timestamp).toDate() 
          : null,
      dateRappel: data['dateRappel'] != null 
          ? (data['dateRappel'] as Timestamp).toDate() 
          : null,
      agentValidateur: data['agentValidateur'],
      numeroRecu: data['numeroRecu'],
      periodeCouverte: data['periodeCouverte'],
      metadonnees: data['metadonnees'],
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      dateModification: (data['dateModification'] as Timestamp).toDate(),
    );
  }

  /// 📤 Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'conducteurId': conducteurId,
      'demandeId': demandeId,
      'numeroContrat': numeroContrat,
      'montant': montant,
      'frequencePaiement': frequencePaiement,
      'modePaiement': modePaiement,
      'statut': statut,
      'dateEcheance': Timestamp.fromDate(dateEcheance),
      'datePaiement': datePaiement != null ? Timestamp.fromDate(datePaiement!) : null,
      'dateRappel': dateRappel != null ? Timestamp.fromDate(dateRappel!) : null,
      'agentValidateur': agentValidateur,
      'numeroRecu': numeroRecu,
      'periodeCouverte': periodeCouverte,
      'metadonnees': metadonnees,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': Timestamp.fromDate(dateModification),
    };
  }

  /// 📊 Calculer la prochaine échéance
  DateTime calculerProchaineEcheance() {
    switch (frequencePaiement) {
      case 'mensuel':
        return DateTime(dateEcheance.year, dateEcheance.month + 1, dateEcheance.day);
      case 'trimestriel':
        return DateTime(dateEcheance.year, dateEcheance.month + 3, dateEcheance.day);
      case 'annuel':
      default:
        return DateTime(dateEcheance.year + 1, dateEcheance.month, dateEcheance.day);
    }
  }

  /// 🔍 Vérifier si le paiement est en retard
  bool get estEnRetard {
    return DateTime.now().isAfter(dateEcheance) && statut == 'en_attente';
  }

  /// ⏰ Jours restants avant échéance
  int get joursRestants {
    return dateEcheance.difference(DateTime.now()).inDays;
  }

  /// 🎨 Couleur selon le statut
  String get couleurStatut {
    switch (statut) {
      case 'paye':
        return '#10B981'; // Vert
      case 'en_attente':
        return joursRestants <= 3 ? '#F59E0B' : '#3B82F6'; // Orange si urgent, bleu sinon
      case 'en_retard':
        return '#EF4444'; // Rouge
      case 'annule':
        return '#6B7280'; // Gris
      default:
        return '#6B7280';
    }
  }

  /// 📝 Libellé du statut
  String get libelleStatut {
    switch (statut) {
      case 'paye':
        return 'Payé';
      case 'en_attente':
        return joursRestants <= 0 ? 'Échu' : 'En attente';
      case 'en_retard':
        return 'En retard';
      case 'annule':
        return 'Annulé';
      default:
        return statut;
    }
  }

  /// 💰 Montant formaté
  String get montantFormate {
    return '${montant.toStringAsFixed(2)} DT';
  }

  /// 📅 Période couverte formatée
  String genererPeriodeCouverte() {
    final debut = dateEcheance;
    final fin = calculerProchaineEcheance();
    
    final moisDebut = _getNomMois(debut.month);
    final moisFin = _getNomMois(fin.month);
    
    if (debut.year == fin.year) {
      return '$moisDebut - $moisFin ${debut.year}';
    } else {
      return '$moisDebut ${debut.year} - $moisFin ${fin.year}';
    }
  }

  String _getNomMois(int mois) {
    const moisNoms = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return moisNoms[mois];
  }

  /// 🔄 Copier avec modifications
  PaiementModel copyWith({
    String? statut,
    DateTime? datePaiement,
    String? agentValidateur,
    String? numeroRecu,
    String? modePaiement,
    Map<String, dynamic>? metadonnees,
  }) {
    return PaiementModel(
      id: id,
      conducteurId: conducteurId,
      demandeId: demandeId,
      numeroContrat: numeroContrat,
      montant: montant,
      frequencePaiement: frequencePaiement,
      modePaiement: modePaiement ?? this.modePaiement,
      statut: statut ?? this.statut,
      dateEcheance: dateEcheance,
      datePaiement: datePaiement ?? this.datePaiement,
      dateRappel: dateRappel,
      agentValidateur: agentValidateur ?? this.agentValidateur,
      numeroRecu: numeroRecu ?? this.numeroRecu,
      periodeCouverte: periodeCouverte,
      metadonnees: metadonnees ?? this.metadonnees,
      dateCreation: dateCreation,
      dateModification: DateTime.now(),
    );
  }
}

/// 📊 Statistiques de paiement
class StatistiquesPaiement {
  final int totalPaiements;
  final int paiementsEnAttente;
  final int paiementsEnRetard;
  final int paiementsPayes;
  final double montantTotal;
  final double montantEnAttente;
  final double montantEnRetard;

  StatistiquesPaiement({
    required this.totalPaiements,
    required this.paiementsEnAttente,
    required this.paiementsEnRetard,
    required this.paiementsPayes,
    required this.montantTotal,
    required this.montantEnAttente,
    required this.montantEnRetard,
  });

  factory StatistiquesPaiement.fromPaiements(List<PaiementModel> paiements) {
    final enAttente = paiements.where((p) => p.statut == 'en_attente').toList();
    final enRetard = paiements.where((p) => p.estEnRetard).toList();
    final payes = paiements.where((p) => p.statut == 'paye').toList();

    return StatistiquesPaiement(
      totalPaiements: paiements.length,
      paiementsEnAttente: enAttente.length,
      paiementsEnRetard: enRetard.length,
      paiementsPayes: payes.length,
      montantTotal: paiements.fold(0.0, (sum, p) => sum + p.montant),
      montantEnAttente: enAttente.fold(0.0, (sum, p) => sum + p.montant),
      montantEnRetard: enRetard.fold(0.0, (sum, p) => sum + p.montant),
    );
  }
}
