import 'package:cloud_firestore/cloud_firestore.dart';

/// 📝 Modèle Firestore final pour les demandes de comptes professionnels
/// Collection: /demandes_professionnels/{demandeId}
class ProfessionalRequestModel {
  final String id;
  
  // 🔖 Champs communs à toutes les demandes
  final String nomComplet;
  final String email;
  final String tel;
  final String cin;
  final String roleDemande; // 'agent_agence', 'expert_auto', 'admin_compagnie', 'admin_agence'
  final String status; // 'en_attente', 'acceptee', 'rejetee'
  final DateTime envoyeLe;
  final String? commentaireAdmin;
  
  // 🔸 Champs de traitement
  final String? traiteParUid;
  final DateTime? traiteLe;
  
  // 🎯 Champs spécifiques selon le rôle
  // Agent d'agence
  final String? nomAgence;
  final String? compagnie;
  final String? adresseAgence;
  final String? matriculeInterne;
  
  // Expert auto
  final String? numAgrement;
  final String? zoneIntervention;
  final int? experienceAnnees;
  
  // Admin compagnie
  final String? nomCompagnie;
  final String? fonction;
  final String? adresseSiege;
  final String? numAutorisation;
  
  // Admin agence
  final String? ville;
  final String? telAgence;

  const ProfessionalRequestModel({
    required this.id,
    required this.nomComplet,
    required this.email,
    required this.tel,
    required this.cin,
    required this.roleDemande,
    required this.envoyeLe,
    this.status = 'en_attente',
    this.commentaireAdmin,
    this.traiteParUid,
    this.traiteLe,
    // Champs spécifiques
    this.nomAgence,
    this.compagnie,
    this.adresseAgence,
    this.matriculeInterne,
    this.numAgrement,
    this.zoneIntervention,
    this.experienceAnnees,
    this.nomCompagnie,
    this.fonction,
    this.adresseSiege,
    this.numAutorisation,
    this.ville,
    this.telAgence,
  });

  /// Créer depuis Firestore
  factory ProfessionalRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ProfessionalRequestModel(
      id: doc.id,
      nomComplet: data['nom_complet'] ?? '',
      email: data['email'] ?? '',
      tel: data['tel'] ?? '',
      cin: data['cin'] ?? '',
      roleDemande: data['role_demande'] ?? '',
      envoyeLe: (data['envoye_le'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'en_attente',
      commentaireAdmin: data['commentaire_admin'],
      traiteParUid: data['traite_par_uid'],
      traiteLe: (data['traite_le'] as Timestamp?)?.toDate(),
      // Champs spécifiques
      nomAgence: data['nom_agence'],
      compagnie: data['compagnie'],
      adresseAgence: data['adresse_agence'],
      matriculeInterne: data['matricule_interne'],
      numAgrement: data['num_agrement'],
      zoneIntervention: data['zone_intervention'],
      experienceAnnees: data['experience_annees'],
      nomCompagnie: data['nom_compagnie'],
      fonction: data['fonction'],
      adresseSiege: data['adresse_siege'],
      numAutorisation: data['num_autorisation'],
      ville: data['ville'],
      telAgence: data['tel_agence'],
    );
  }

  /// Convertir vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom_complet': nomComplet,
      'email': email,
      'tel': tel,
      'cin': cin,
      'role_demande': roleDemande,
      'envoye_le': Timestamp.fromDate(envoyeLe),
      'status': status,
      'commentaire_admin': commentaireAdmin,
      'traite_par_uid': traiteParUid,
      'traite_le': traiteLe != null ? Timestamp.fromDate(traiteLe!) : null,
      // Champs spécifiques
      'nom_agence': nomAgence,
      'compagnie': compagnie,
      'adresse_agence': adresseAgence,
      'matricule_interne': matriculeInterne,
      'num_agrement': numAgrement,
      'zone_intervention': zoneIntervention,
      'experience_annees': experienceAnnees,
      'nom_compagnie': nomCompagnie,
      'fonction': fonction,
      'adresse_siege': adresseSiege,
      'num_autorisation': numAutorisation,
      'ville': ville,
      'tel_agence': telAgence,
    };
  }

  /// Copier avec modifications
  ProfessionalRequestModel copyWith({
    String? id,
    String? nomComplet,
    String? email,
    String? tel,
    String? cin,
    String? roleDemande,
    DateTime? envoyeLe,
    String? status,
    String? commentaireAdmin,
    String? traiteParUid,
    DateTime? traiteLe,
    String? nomAgence,
    String? compagnie,
    String? adresseAgence,
    String? matriculeInterne,
    String? numAgrement,
    String? zoneIntervention,
    int? experienceAnnees,
    String? nomCompagnie,
    String? fonction,
    String? adresseSiege,
    String? numAutorisation,
    String? ville,
    String? telAgence,
  }) {
    return ProfessionalRequestModel(
      id: id ?? this.id,
      nomComplet: nomComplet ?? this.nomComplet,
      email: email ?? this.email,
      tel: tel ?? this.tel,
      cin: cin ?? this.cin,
      roleDemande: roleDemande ?? this.roleDemande,
      envoyeLe: envoyeLe ?? this.envoyeLe,
      status: status ?? this.status,
      commentaireAdmin: commentaireAdmin ?? this.commentaireAdmin,
      traiteParUid: traiteParUid ?? this.traiteParUid,
      traiteLe: traiteLe ?? this.traiteLe,
      nomAgence: nomAgence ?? this.nomAgence,
      compagnie: compagnie ?? this.compagnie,
      adresseAgence: adresseAgence ?? this.adresseAgence,
      matriculeInterne: matriculeInterne ?? this.matriculeInterne,
      numAgrement: numAgrement ?? this.numAgrement,
      zoneIntervention: zoneIntervention ?? this.zoneIntervention,
      experienceAnnees: experienceAnnees ?? this.experienceAnnees,
      nomCompagnie: nomCompagnie ?? this.nomCompagnie,
      fonction: fonction ?? this.fonction,
      adresseSiege: adresseSiege ?? this.adresseSiege,
      numAutorisation: numAutorisation ?? this.numAutorisation,
      ville: ville ?? this.ville,
      telAgence: telAgence ?? this.telAgence,
    );
  }

  /// Getters utilitaires
  String get statutFormate {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return status;
    }
  }

  String get roleFormate {
    switch (roleDemande) {
      case 'agent_agence':
        return 'Agent d\'agence';
      case 'expert_auto':
        return 'Expert automobile';
      case 'admin_compagnie':
        return 'Admin compagnie';
      case 'admin_agence':
        return 'Admin agence';
      default:
        return roleDemande;
    }
  }

  bool get estEnAttente => status == 'en_attente';
  bool get estAcceptee => status == 'acceptee';
  bool get estRejetee => status == 'rejetee';

  /// Getters de compatibilité pour les anciens noms
  String get nom => nomComplet.split(' ').first;
  String get prenom => nomComplet.split(' ').skip(1).join(' ');
  String get telephone => tel;
  String get statut => status;
  String get typeCompte => roleDemande;
  String get compagnieAssurance => compagnie ?? '';
  String get agence => nomAgence ?? '';

  /// Getter pour le nom complet formaté
  String get typeCompteFormate => roleFormate;

  @override
  String toString() {
    return 'ProfessionalRequestModel(id: $id, nomComplet: $nomComplet, roleDemande: $roleDemande, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfessionalRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 📊 Énumérations et constantes
class ProfessionalRequestConstants {
  // Types de rôles
  static const List<String> rolesDisponibles = [
    'agent_agence',
    'expert_auto', 
    'admin_compagnie',
    'admin_agence'
  ];

  // Statuts possibles
  static const List<String> statutsPossibles = [
    'en_attente',
    'acceptee',
    'rejetee'
  ];

  // Compagnies d'assurance en Tunisie
  static const List<String> compagniesAssurance = [
    'STAR Assurances',
    'Maghrebia Assurances',
    'Assurances Salim',
    'GAT Assurances',
    'Comar Assurances',
    'Lloyd Tunisien',
    'Zitouna Takaful',
    'Attijari Assurance',
  ];

  // Gouvernorats de Tunisie
  static const List<String> gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba',
    'Nabeul', 'Zaghouan', 'Bizerte',
    'Béja', 'Jendouba', 'Kef', 'Siliana',
    'Sousse', 'Monastir', 'Mahdia', 'Sfax',
    'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Medenine', 'Tataouine',
    'Gafsa', 'Tozeur', 'Kebili'
  ];

  /// 📋 Exemples de documents Firestore par type de demande

  /// 🧍‍💼 Exemple: Agent d'agence
  static Map<String, dynamic> exempleAgentAgence() {
    return {
      "nom_complet": "Karim Jlassi",
      "email": "karim@star.tn",
      "tel": "21699322144",
      "cin": "09345122",
      "role_demande": "agent_agence",
      "status": "en_attente",
      "envoye_le": Timestamp.now(),

      // Champs spécifiques agent
      "nom_agence": "Agence El Menzah 6",
      "compagnie": "STAR Assurances",
      "adresse_agence": "Av. Hédi Nouira, Tunis",
      "matricule_interne": "AG455"
    };
  }

  /// 🧑‍🔧 Exemple: Expert auto
  static Map<String, dynamic> exempleExpertAuto() {
    return {
      "nom_complet": "Ahmed Ben Salem",
      "email": "ahmed.expert@gmail.com",
      "tel": "21698765432",
      "cin": "08123456",
      "role_demande": "expert_auto",
      "status": "en_attente",
      "envoye_le": Timestamp.now(),

      // Champs spécifiques expert
      "num_agrement": "EXP2024001",
      "compagnie": "Maghrebia Assurances",
      "zone_intervention": "Tunis",
      "experience_annees": 8,
      "nom_agence": "Agence Lac 2" // Optionnel
    };
  }

  /// 🧑‍💼 Exemple: Admin compagnie
  static Map<String, dynamic> exempleAdminCompagnie() {
    return {
      "nom_complet": "Fatma Trabelsi",
      "email": "fatma@gat.tn",
      "tel": "21671234567",
      "cin": "07987654",
      "role_demande": "admin_compagnie",
      "status": "en_attente",
      "envoye_le": Timestamp.now(),

      // Champs spécifiques admin compagnie
      "nom_compagnie": "GAT Assurances",
      "fonction": "Directrice Régionale",
      "adresse_siege": "Avenue Habib Bourguiba, Tunis",
      "num_autorisation": "AUTH2024GAT" // Optionnel
    };
  }

  /// 🏢 Exemple: Admin agence
  static Map<String, dynamic> exempleAdminAgence() {
    return {
      "nom_complet": "Mohamed Bouazizi",
      "email": "mohamed@comar-sfax.tn",
      "tel": "21674555666",
      "cin": "06111222",
      "role_demande": "admin_agence",
      "status": "en_attente",
      "envoye_le": Timestamp.now(),

      // Champs spécifiques admin agence
      "nom_agence": "Agence Comar Sfax Centre",
      "compagnie": "Comar Assurances",
      "ville": "Sfax",
      "adresse_agence": "Rue Mongi Slim, Sfax",
      "tel_agence": "74123456" // Optionnel
    };
  }

  /// 📝 Exemple: Demande traitée (acceptée)
  static Map<String, dynamic> exempleDemandeAcceptee() {
    return {
      "nom_complet": "Sarra Mansouri",
      "email": "sarra@lloyd.tn",
      "tel": "21695123456",
      "cin": "05789123",
      "role_demande": "agent_agence",
      "status": "acceptee",
      "envoye_le": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      "traite_par_uid": "super_admin_uid",
      "traite_le": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      "commentaire_admin": "Dossier complet, compte créé avec succès",

      // Champs spécifiques
      "nom_agence": "Agence Lloyd Sousse",
      "compagnie": "Lloyd Tunisien",
      "adresse_agence": "Avenue Léopold Sédar Senghor, Sousse",
    };
  }

  /// ❌ Exemple: Demande rejetée
  static Map<String, dynamic> exempleDemandeRejetee() {
    return {
      "nom_complet": "Ali Rejeb",
      "email": "ali.rejeb@email.com",
      "tel": "21692999888",
      "cin": "04567890",
      "role_demande": "expert_auto",
      "status": "rejetee",
      "envoye_le": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      "traite_par_uid": "super_admin_uid",
      "traite_le": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      "commentaire_admin": "Numéro d'agrément invalide. Veuillez fournir un agrément valide.",

      // Champs spécifiques
      "num_agrement": "INVALID123",
      "compagnie": "STAR Assurances",
      "zone_intervention": "Bizerte",
    };
  }
}
