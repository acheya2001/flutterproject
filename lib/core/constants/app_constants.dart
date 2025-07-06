/// 🎯 Constantes globales de l'application d'assurance
class AppConstants {
  // 📱 Informations de l'application
  static const String appName = 'Constat Tunisie';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Application d\'assurance automobile digitalisée';
  
  // 🏢 Informations entreprise
  static const String companyName = 'Constat Tunisie';
  static const String companyEmail = 'constat.tunisie.app@gmail.com';
  static const String supportEmail = 'support@constat-tunisie.tn';
  
  // 🔐 Rôles utilisateurs
  static const String roleSuperAdmin = 'super_admin';
  static const String roleCompanyAdmin = 'company_admin';
  static const String roleAgencyAdmin = 'agency_admin';
  static const String roleAgent = 'agent';
  static const String roleDriver = 'driver';
  static const String roleExpert = 'expert';
  
  // 📊 Collections Firestore
  static const String usersCollection = 'users';
  static const String companiesCollection = 'companies';
  static const String agenciesCollection = 'agencies';
  static const String agentsCollection = 'agents';
  static const String driversCollection = 'drivers';
  static const String expertsCollection = 'experts';
  static const String contractsCollection = 'contracts';
  static const String vehiclesCollection = 'vehicles';
  static const String claimsCollection = 'claims';
  static const String documentsCollection = 'documents';
  static const String notificationsCollection = 'notifications';
  static const String messagesCollection = 'messages';
  static const String accountRequestsCollection = 'account_requests';
  
  // 🏛️ Compagnies d'assurance tunisiennes
  static const List<String> insuranceCompanies = [
    'STAR',
    'MAGHREBIA',
    'COMAR',
    'GAT',
    'LLOYD TUNISIEN',
    'ASTREE',
    'CTAMA',
    'ZITOUNA TAKAFUL',
    'SALIM',
    'CARTE',
  ];
  
  // 🗺️ Gouvernorats de Tunisie
  static const List<String> tunisianGovernorates = [
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
  
  // 📄 Types de documents
  static const String docTypeContract = 'contract';
  static const String docTypeAttestation = 'attestation';
  static const String docTypeExpertReport = 'expert_report';
  static const String docTypeClaimDeclaration = 'claim_declaration';
  static const String docTypeIdCard = 'id_card';
  static const String docTypeDrivingLicense = 'driving_license';
  static const String docTypeVehicleRegistration = 'vehicle_registration';
  
  // 🚗 Types de véhicules
  static const List<String> vehicleTypes = [
    'Voiture particulière',
    'Camionnette',
    'Camion',
    'Autobus',
    'Motocyclette',
    'Cyclomoteur',
    'Tracteur',
    'Remorque',
  ];
  
  // 💰 Types de garanties
  static const List<String> guaranteeTypes = [
    'Responsabilité Civile',
    'Tous Risques',
    'Vol et Incendie',
    'Bris de Glace',
    'Assistance',
    'Protection Juridique',
    'Individuelle Conducteur',
  ];
  
  // 📱 Paramètres de l'application
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx'];
  
  // ⏱️ Délais et timeouts
  static const int networkTimeout = 30; // secondes
  static const int cacheTimeout = 24; // heures
  static const int sessionTimeout = 60; // minutes
  
  // 🎨 Couleurs de l'application
  static const String primaryColorHex = '#1976D2';
  static const String secondaryColorHex = '#FFC107';
  static const String errorColorHex = '#F44336';
  static const String successColorHex = '#4CAF50';
  static const String warningColorHex = '#FF9800';
  
  // 📧 Configuration email
  static const String emailDomain = '@constat-tunisie.tn';
  static const String noReplyEmail = 'noreply@constat-tunisie.tn';
  
  // 🔔 Types de notifications
  static const String notifTypeClaimCreated = 'claim_created';
  static const String notifTypeClaimUpdated = 'claim_updated';
  static const String notifTypeContractExpiring = 'contract_expiring';
  static const String notifTypeDocumentReady = 'document_ready';
  static const String notifTypeExpertAssigned = 'expert_assigned';
  static const String notifTypeMessageReceived = 'message_received';
  
  // 🏷️ Statuts des sinistres
  static const String claimStatusDraft = 'draft';
  static const String claimStatusSubmitted = 'submitted';
  static const String claimStatusUnderReview = 'under_review';
  static const String claimStatusExpertiseRequired = 'expertise_required';
  static const String claimStatusExpertiseInProgress = 'expertise_in_progress';
  static const String claimStatusApproved = 'approved';
  static const String claimStatusRejected = 'rejected';
  static const String claimStatusClosed = 'closed';
  
  // 🏷️ Statuts des comptes
  static const String accountStatusPending = 'pending';
  static const String accountStatusActive = 'active';
  static const String accountStatusSuspended = 'suspended';
  static const String accountStatusRejected = 'rejected';
  
  // 🔑 Permissions
  static const String permissionCreateContract = 'create_contract';
  static const String permissionEditContract = 'edit_contract';
  static const String permissionDeleteContract = 'delete_contract';
  static const String permissionViewAllContracts = 'view_all_contracts';
  static const String permissionManageAgents = 'manage_agents';
  static const String permissionManageClients = 'manage_clients';
  static const String permissionGenerateReports = 'generate_reports';
  static const String permissionManageExperts = 'manage_experts';
  static const String permissionValidateAccounts = 'validate_accounts';
  
  // 🌐 URLs et liens
  static const String privacyPolicyUrl = 'https://constat-tunisie.tn/privacy';
  static const String termsOfServiceUrl = 'https://constat-tunisie.tn/terms';
  static const String helpUrl = 'https://constat-tunisie.tn/help';
  static const String contactUrl = 'https://constat-tunisie.tn/contact';
}

/// 🎨 Constantes de design
class DesignConstants {
  // Espacements
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Rayons de bordure
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  
  // Tailles d'icônes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  
  // Hauteurs d'éléments
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardHeight = 120.0;
  static const double appBarHeight = 56.0;
}

/// 📱 Constantes de validation
class ValidationConstants {
  // Longueurs
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int phoneLength = 8;
  static const int cinLength = 8;
  
  // Expressions régulières
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^[0-9]{8}$';
  static const String cinRegex = r'^[0-9]{8}$';
  static const String matriculeRegex = r'^[A-Z0-9]{6,12}$';
}
