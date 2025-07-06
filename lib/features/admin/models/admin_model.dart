import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';
import '../../../utils/user_type.dart';

/// 👨‍💼 Modèle pour un administrateur système
class AdminModel extends UserModel {
  final String niveauAcces; // super_admin, admin_regional
  final List<String> zoneResponsabilite; // Zones géographiques gérées
  final int nombreValidations; // Nombre de validations effectuées
  final DateTime? derniereConnexion;

  AdminModel({
    required super.uid,
    required super.email,
    required super.nom,
    required super.prenom,
    required super.telephone,
    super.adresse,
    required super.dateCreation,
    super.dateModification,
    super.permissions,
    required this.niveauAcces,
    required this.zoneResponsabilite,
    this.nombreValidations = 0,
    this.derniereConnexion,
  }) : super(userType: UserType.admin);

  /// Créer depuis Firestore
  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      adresse: data['adresse'],
      niveauAcces: data['niveau_acces'] ?? 'admin_regional',
      zoneResponsabilite: List<String>.from(data['zone_responsabilite'] ?? []),
      permissions: List<String>.from(data['permissions'] ?? []),
      nombreValidations: data['nombre_validations'] ?? 0,
      derniereConnexion: data['derniere_connexion'] != null
          ? (data['derniere_connexion'] as Timestamp).toDate()
          : null,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateModification: (data['dateModification'] as Timestamp?)?.toDate(),
    );
  }

  /// Créer depuis Map (pour compatibilité avec le service universel)
  factory AdminModel.fromMap(Map<String, dynamic> data) {
    return AdminModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      adresse: data['adresse'],
      niveauAcces: data['niveau_acces'] ?? data['niveauAcces'] ?? 'admin_regional',
      zoneResponsabilite: List<String>.from(data['zone_responsabilite'] ?? data['zoneResponsabilite'] ?? []),
      permissions: List<String>.from(data['permissions'] ?? []),
      nombreValidations: data['nombre_validations'] ?? data['nombreValidations'] ?? 0,
      derniereConnexion: data['derniere_connexion'] != null
          ? (data['derniere_connexion'] as Timestamp).toDate()
          : data['derniereConnexion'] != null
              ? (data['derniereConnexion'] is DateTime
                  ? data['derniereConnexion']
                  : DateTime.tryParse(data['derniereConnexion'].toString()))
              : null,
      dateCreation: data['dateCreation'] is Timestamp
          ? (data['dateCreation'] as Timestamp).toDate()
          : data['dateCreation'] is DateTime
              ? data['dateCreation']
              : DateTime.now(),
      dateModification: data['dateModification'] is Timestamp
          ? (data['dateModification'] as Timestamp).toDate()
          : data['dateModification'] is DateTime
              ? data['dateModification']
              : null,
    );
  }

  /// Convertir vers Firestore
  @override
  Map<String, dynamic> toFirestore() {
    final baseData = super.toFirestore();
    baseData.addAll({
      'niveau_acces': niveauAcces,
      'zone_responsabilite': zoneResponsabilite,
      'permissions': permissions,
      'nombre_validations': nombreValidations,
      'derniere_connexion': derniereConnexion != null
          ? Timestamp.fromDate(derniereConnexion!)
          : null,
    });
    return baseData;
  }

  /// Copier avec modifications
  @override
  AdminModel copyWith({
    String? uid,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    UserType? userType,
    String? adresse,
    DateTime? dateCreation,
    DateTime? dateModification,
    AccountStatus? accountStatus,
    String? rejectionReason,
    DateTime? approvalDate,
    String? approvedBy,
    String? compagnieId,
    String? agenceId,
    String? matricule,
    String? poste,
    String? niveauAcces,
    List<String>? zoneResponsabilite,
    List<String>? permissions,
    int? nombreValidations,
    DateTime? derniereConnexion,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      niveauAcces: niveauAcces ?? this.niveauAcces,
      zoneResponsabilite: zoneResponsabilite ?? this.zoneResponsabilite,
      permissions: permissions ?? this.permissions,
      nombreValidations: nombreValidations ?? this.nombreValidations,
      derniereConnexion: derniereConnexion ?? this.derniereConnexion,
    );
  }

  /// Vérifier si l'admin a une permission spécifique
  bool hasPermission(String permission) {
    return permissions.contains(permission) || niveauAcces == 'super_admin';
  }

  /// Vérifier si l'admin peut gérer une zone
  bool canManageZone(String zone) {
    return niveauAcces == 'super_admin' || zoneResponsabilite.contains(zone);
  }

  /// Obtenir le niveau d'accès en français
  String get niveauAccesFr {
    switch (niveauAcces) {
      case 'super_admin':
        return 'Super Administrateur';
      case 'admin_regional':
        return 'Administrateur Régional';
      default:
        return 'Administrateur';
    }
  }

  /// Vérifier si c'est un super admin
  bool get isSuperAdmin => niveauAcces == 'super_admin';

  /// Vérifier si c'est un admin régional
  bool get isRegionalAdmin => niveauAcces == 'admin_regional';

  @override
  String toString() {
    return 'AdminModel(id: $id, nom: $nom $prenom, niveau: $niveauAcces)';
  }
}

/// 📋 Permissions disponibles pour les admins
class AdminPermissions {
  static const String validateAgents = 'validate_agents';
  static const String manageCompanies = 'manage_companies';
  static const String viewStats = 'view_stats';
  static const String moderateUsers = 'moderate_users';
  static const String manageExperts = 'manage_experts';
  static const String systemSettings = 'system_settings';
  static const String auditLogs = 'audit_logs';
  static const String dataExport = 'data_export';

  /// Obtenir toutes les permissions
  static List<String> get allPermissions => [
    validateAgents,
    manageCompanies,
    viewStats,
    moderateUsers,
    manageExperts,
    systemSettings,
    auditLogs,
    dataExport,
  ];

  /// Obtenir les permissions par défaut pour un admin régional
  static List<String> get defaultRegionalPermissions => [
    validateAgents,
    viewStats,
    moderateUsers,
  ];

  /// Obtenir le nom français d'une permission
  static String getPermissionName(String permission) {
    switch (permission) {
      case validateAgents:
        return 'Valider les agents';
      case manageCompanies:
        return 'Gérer les compagnies';
      case viewStats:
        return 'Voir les statistiques';
      case moderateUsers:
        return 'Modérer les utilisateurs';
      case manageExperts:
        return 'Gérer les experts';
      case systemSettings:
        return 'Paramètres système';
      case auditLogs:
        return 'Logs d\'audit';
      case dataExport:
        return 'Export de données';
      default:
        return permission;
    }
  }
}

/// 🌍 Zones géographiques de Tunisie
class TunisianZones {
  static const List<String> gouvernorats = [
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Zaghouan',
    'Bizerte',
    'Béja',
    'Jendouba',
    'Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Sfax',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Gabès',
    'Médenine',
    'Tataouine',
    'Gafsa',
    'Tozeur',
    'Kébili',
  ];

  /// Obtenir les délégations par gouvernorat (exemple pour quelques gouvernorats)
  static Map<String, List<String>> get delegations => {
    'Tunis': [
      'Tunis Centre',
      'Bab Bhar',
      'Bab Souika',
      'Cité El Khadra',
      'Djebel Jelloud',
      'El Kabaria',
      'El Menzah',
      'El Omrane',
      'El Omrane Supérieur',
      'Ettahrir',
      'Ezzouhour',
      'Hraïria',
      'La Goulette',
      'La Marsa',
      'Le Bardo',
      'Médina',
      'Séjoumi',
      'Sidi Bou Said',
      'Sidi Hassine',
    ],
    'Ariana': [
      'Ariana Ville',
      'Ettadhamen',
      'Kalâat el-Andalous',
      'Raoued',
      'Sidi Thabet',
      'Soukra',
    ],
    'Sfax': [
      'Sfax Centre',
      'Sfax Nord',
      'Sfax Sud',
      'Sakiet Ezzit',
      'Sakiet Eddaïer',
      'El Hencha',
      'Menzel Chaker',
      'Ghraïba',
      'Bir Ali Ben Khalifa',
      'Skhira',
      'Mahares',
      'Kerkennah',
      'Agareb',
      'Jebiniana',
    ],
  };
}
