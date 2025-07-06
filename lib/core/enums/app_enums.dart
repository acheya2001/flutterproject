/// 👥 Énumération des rôles utilisateurs
enum UserRole {
  superAdmin('super_admin', 'Super Administrateur', 0),
  companyAdmin('company_admin', 'Administrateur Compagnie', 1),
  agencyAdmin('agency_admin', 'Administrateur Agence', 2),
  agent('agent', 'Agent d\'Assurance', 3),
  driver('driver', 'Conducteur/Client', 4),
  expert('expert', 'Expert Automobile', 3);

  const UserRole(this.value, this.displayName, this.hierarchyLevel);

  final String value;
  final String displayName;
  final int hierarchyLevel;

  /// Vérifie si ce rôle est un administrateur
  bool get isAdmin => [superAdmin, companyAdmin, agencyAdmin].contains(this);

  /// Vérifie si ce rôle peut gérer d'autres utilisateurs
  bool get canManageUsers => hierarchyLevel <= 2;

  /// Vérifie si ce rôle peut créer des contrats
  bool get canCreateContracts => [agent, agencyAdmin, companyAdmin, superAdmin].contains(this);

  /// Obtient le rôle à partir de sa valeur string
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.driver,
    );
  }
}

/// 🏷️ Statuts des comptes utilisateurs
enum AccountStatus {
  pending('pending', 'En attente', '⏳'),
  active('active', 'Actif', '✅'),
  suspended('suspended', 'Suspendu', '⏸️'),
  rejected('rejected', 'Rejeté', '❌'),
  expired('expired', 'Expiré', '⌛');

  const AccountStatus(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static AccountStatus fromString(String value) {
    return AccountStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AccountStatus.pending,
    );
  }
}

/// 🚗 Types de véhicules
enum VehicleType {
  car('car', 'Voiture particulière', '🚗'),
  van('van', 'Camionnette', '🚐'),
  truck('truck', 'Camion', '🚛'),
  bus('bus', 'Autobus', '🚌'),
  motorcycle('motorcycle', 'Motocyclette', '🏍️'),
  moped('moped', 'Cyclomoteur', '🛵'),
  tractor('tractor', 'Tracteur', '🚜'),
  trailer('trailer', 'Remorque', '🚚');

  const VehicleType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => VehicleType.car,
    );
  }
}

/// 💰 Types de garanties d'assurance
enum GuaranteeType {
  liability('liability', 'Responsabilité Civile', true),
  comprehensive('comprehensive', 'Tous Risques', false),
  theftFire('theft_fire', 'Vol et Incendie', false),
  glassBreakage('glass_breakage', 'Bris de Glace', false),
  assistance('assistance', 'Assistance', false),
  legalProtection('legal_protection', 'Protection Juridique', false),
  driverProtection('driver_protection', 'Individuelle Conducteur', false);

  const GuaranteeType(this.value, this.displayName, this.isMandatory);

  final String value;
  final String displayName;
  final bool isMandatory;

  static GuaranteeType fromString(String value) {
    return GuaranteeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => GuaranteeType.liability,
    );
  }
}

/// 📋 Statuts des sinistres
enum ClaimStatus {
  draft('draft', 'Brouillon', '📝', false),
  submitted('submitted', 'Soumis', '📤', false),
  underReview('under_review', 'En cours d\'examen', '👀', false),
  expertiseRequired('expertise_required', 'Expertise requise', '🔍', false),
  expertiseInProgress('expertise_in_progress', 'Expertise en cours', '⚙️', false),
  approved('approved', 'Approuvé', '✅', true),
  rejected('rejected', 'Rejeté', '❌', true),
  closed('closed', 'Clôturé', '🔒', true);

  const ClaimStatus(this.value, this.displayName, this.icon, this.isFinal);

  final String value;
  final String displayName;
  final String icon;
  final bool isFinal;

  static ClaimStatus fromString(String value) {
    return ClaimStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ClaimStatus.draft,
    );
  }
}

/// 📄 Types de documents
enum DocumentType {
  contract('contract', 'Contrat d\'assurance', '📋'),
  attestation('attestation', 'Attestation d\'assurance', '📜'),
  expertReport('expert_report', 'Rapport d\'expertise', '📊'),
  claimDeclaration('claim_declaration', 'Déclaration de sinistre', '📝'),
  idCard('id_card', 'Carte d\'identité', '🆔'),
  drivingLicense('driving_license', 'Permis de conduire', '🪪'),
  vehicleRegistration('vehicle_registration', 'Carte grise', '📄'),
  invoice('invoice', 'Facture', '🧾'),
  photo('photo', 'Photo', '📸');

  const DocumentType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.photo,
    );
  }
}

/// 🔔 Types de notifications
enum NotificationType {
  claimCreated('claim_created', 'Sinistre créé', '📋'),
  claimUpdated('claim_updated', 'Sinistre mis à jour', '🔄'),
  contractExpiring('contract_expiring', 'Contrat expirant', '⚠️'),
  documentReady('document_ready', 'Document prêt', '📄'),
  expertAssigned('expert_assigned', 'Expert assigné', '👨‍🔧'),
  messageReceived('message_received', 'Message reçu', '💬'),
  accountValidated('account_validated', 'Compte validé', '✅'),
  accountRejected('account_rejected', 'Compte rejeté', '❌');

  const NotificationType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.messageReceived,
    );
  }
}

/// 🏛️ Types d'agences
enum AgencyType {
  headquarters('headquarters', 'Siège Social', '🏢'),
  regional('regional', 'Agence Régionale', '🏪'),
  local('local', 'Agence Locale', '🏬'),
  branch('branch', 'Succursale', '🏭');

  const AgencyType(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static AgencyType fromString(String value) {
    return AgencyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AgencyType.local,
    );
  }
}

/// 🔑 Permissions système
enum Permission {
  // Gestion des contrats
  createContract('create_contract', 'Créer des contrats'),
  editContract('edit_contract', 'Modifier des contrats'),
  deleteContract('delete_contract', 'Supprimer des contrats'),
  viewAllContracts('view_all_contracts', 'Voir tous les contrats'),
  
  // Gestion des utilisateurs
  manageAgents('manage_agents', 'Gérer les agents'),
  manageClients('manage_clients', 'Gérer les clients'),
  manageExperts('manage_experts', 'Gérer les experts'),
  validateAccounts('validate_accounts', 'Valider les comptes'),
  
  // Gestion des sinistres
  processClaimsLevel1('process_claims_level1', 'Traiter sinistres niveau 1'),
  processClaimsLevel2('process_claims_level2', 'Traiter sinistres niveau 2'),
  assignExperts('assign_experts', 'Assigner des experts'),
  
  // Rapports et statistiques
  generateReports('generate_reports', 'Générer des rapports'),
  viewStatistics('view_statistics', 'Voir les statistiques'),
  exportData('export_data', 'Exporter des données'),
  
  // Administration système
  manageCompanies('manage_companies', 'Gérer les compagnies'),
  manageAgencies('manage_agencies', 'Gérer les agences'),
  systemConfiguration('system_configuration', 'Configuration système');

  const Permission(this.value, this.description);

  final String value;
  final String description;

  static Permission fromString(String value) {
    return Permission.values.firstWhere(
      (permission) => permission.value == value,
      orElse: () => Permission.createContract,
    );
  }
}

/// 🌍 Gouvernorats de Tunisie
enum Governorate {
  tunis('tunis', 'Tunis', 'TN'),
  ariana('ariana', 'Ariana', 'AR'),
  benArous('ben_arous', 'Ben Arous', 'BA'),
  manouba('manouba', 'Manouba', 'MN'),
  nabeul('nabeul', 'Nabeul', 'NB'),
  zaghouan('zaghouan', 'Zaghouan', 'ZG'),
  bizerte('bizerte', 'Bizerte', 'BZ'),
  beja('beja', 'Béja', 'BJ'),
  jendouba('jendouba', 'Jendouba', 'JD'),
  kef('kef', 'Kef', 'KF'),
  siliana('siliana', 'Siliana', 'SL'),
  sousse('sousse', 'Sousse', 'SS'),
  monastir('monastir', 'Monastir', 'MS'),
  mahdia('mahdia', 'Mahdia', 'MH'),
  sfax('sfax', 'Sfax', 'SF'),
  kairouan('kairouan', 'Kairouan', 'KR'),
  kasserine('kasserine', 'Kasserine', 'KS'),
  sidiBouzid('sidi_bouzid', 'Sidi Bouzid', 'SB'),
  gabes('gabes', 'Gabès', 'GB'),
  medenine('medenine', 'Médenine', 'MD'),
  tataouine('tataouine', 'Tataouine', 'TT'),
  gafsa('gafsa', 'Gafsa', 'GF'),
  tozeur('tozeur', 'Tozeur', 'TZ'),
  kebili('kebili', 'Kébili', 'KB');

  const Governorate(this.value, this.displayName, this.code);

  final String value;
  final String displayName;
  final String code;

  static Governorate fromString(String value) {
    return Governorate.values.firstWhere(
      (gov) => gov.value == value,
      orElse: () => Governorate.tunis,
    );
  }
}
