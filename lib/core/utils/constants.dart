class Constants {
  // App
  static const String appName = 'Constat Tunisie';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Application de gestion des constats d\'accidents';

  // Routes
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLanguage = '/language';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeConducteurHome = '/conducteur/home';
  static const String routeAssureurHome = '/assureur/home';
  static const String routeExpertHome = '/expert/home';
  static const String routeAddVehicule = '/vehicule/add';
  static const String routeVehiculeDetails = '/vehicule/details';
  static const String routeSelectVehicule = '/vehicule/select';
  static const String routeAccidentDeclaration = '/accident/declaration';
  static const String routeAccidentDetails = '/accident/details';

  // Titles
  static const String titleSplash = 'Bienvenue';
  static const String titleOnboarding = 'Découvrir';
  static const String titleLanguage = 'Langue';
  static const String titleLogin = 'Connexion';
  static const String titleRegister = 'Inscription';
  static const String titleForgotPassword = 'Mot de passe oublié';
  static const String titleConducteurHome = 'Tableau de bord';
  static const String titleAssureurHome = 'Gestion des dossiers';
  static const String titleExpertHome = 'Expertises';
  static const String titleAddVehicule = 'Ajouter un véhicule';
  static const String titleVehiculeDetails = 'Détails du véhicule';
  static const String titleSelectVehicule = 'Sélectionner un véhicule';
  static const String titleAccidentDeclaration = 'Déclarer un accident';
  static const String titleAccidentDetails = 'Détails de l\'accident';

  // Buttons
  static const String buttonNext = 'Suivant';
  static const String buttonPrevious = 'Précédent';
  static const String buttonFinish = 'Terminer';
  static const String buttonLogin = 'Se connecter';
  static const String buttonRegister = 'S\'inscrire';
  static const String buttonForgotPassword = 'Mot de passe oublié ?';
  static const String buttonResetPassword = 'Réinitialiser';
  static const String buttonSave = 'Enregistrer';
  static const String buttonCancel = 'Annuler';
  static const String buttonDelete = 'Supprimer';
  static const String buttonEdit = 'Modifier';
  static const String buttonAdd = 'Ajouter';
  static const String buttonSelect = 'Sélectionner';
  static const String buttonTakePhoto = 'Prendre une photo';
  static const String buttonChoosePhoto = 'Choisir une photo';
  static const String buttonSend = 'Envoyer';
  static const String buttonSubmit = 'Soumettre';
  static const String buttonContinue = 'Continuer';
  static const String buttonLogout = 'Déconnexion';

  // Placeholders
  static const String placeholderEmail = 'Email';
  static const String placeholderPassword = 'Mot de passe';
  static const String placeholderConfirmPassword = 'Confirmer le mot de passe';
  static const String placeholderName = 'Nom';
  static const String placeholderFirstName = 'Prénom';
  static const String placeholderPhone = 'Téléphone';
  static const String placeholderAddress = 'Adresse';
  static const String placeholderCIN = 'Numéro de CIN';
  static const String placeholderPermis = 'Numéro de permis';
  static const String placeholderCompagnie = 'Compagnie d\'assurance';
  static const String placeholderMatricule = 'Matricule';
  static const String placeholderVehiculeMarque = 'Marque';
  static const String placeholderVehiculeModele = 'Modèle';
  static const String placeholderVehiculeImmatriculation = 'Immatriculation';
  static const String placeholderVehiculeAnnee = 'Année';
  static const String placeholderVehiculeAssurance = 'Assurance';
  static const String placeholderVehiculePolice = 'Numéro de police';
  static const String placeholderAccidentDate = 'Date de l\'accident';
  static const String placeholderAccidentHeure = 'Heure de l\'accident';
  static const String placeholderAccidentLieu = 'Lieu de l\'accident';
  static const String placeholderAccidentDescription = 'Description de l\'accident';

  // Error messages
  static const String errorRequiredField = 'Ce champ est obligatoire';
  static const String errorInvalidEmail = 'Email invalide';
  static const String errorPasswordTooShort = 'Le mot de passe doit contenir au moins 6 caractères';
  static const String errorPasswordsDoNotMatch = 'Les mots de passe ne correspondent pas';
  static const String errorEmailInvalid = 'Format d\'email invalide';
  static const String errorPhoneInvalid = 'Format de téléphone invalide';
  static const String errorCINInvalid = 'Format de CIN invalide';
  static const String errorPermisInvalid = 'Format de permis invalide';
  static const String errorImmatriculationInvalid = 'Format d\'immatriculation invalide';
  static const String errorPoliceInvalid = 'Format de numéro de police invalide';
  static const String errorDateInvalid = 'Format de date invalide';
  static const String errorHeureInvalid = 'Format d\'heure invalide';
  static const String errorGeneric = 'Une erreur s\'est produite';
  static const String errorNoInternet = 'Pas de connexion Internet';
  static const String errorServerError = 'Erreur serveur';
  static const String errorUnauthorized = 'Non autorisé';
  static const String errorNotFound = 'Non trouvé';
  static const String errorTimeout = 'Délai d\'attente dépassé';
  static const String errorUnknown = 'Erreur inconnue';

  // Firestore collections
  static const String collectionUsers = 'users';
  static const String collectionConducteurs = 'conducteurs';
  static const String collectionAssureurs = 'assureurs';
  static const String collectionExperts = 'experts';
  static const String collectionVehicules = 'vehicules';
  static const String collectionAccidents = 'accidents';
  static const String collectionTemoins = 'temoins';
  static const String collectionPhotos = 'photos';
  static const String collectionDocuments = 'documents';
  static const String collectionMessages = 'messages';
  static const String collectionNotifications = 'notifications';

  // Shared preferences keys
  static const String prefUserId = 'userId';
  static const String prefUserType = 'userType';
  static const String prefLanguage = 'language';
  static const String prefTheme = 'theme';
  static const String prefOnboardingCompleted = 'onboardingCompleted';
  static const String prefLoggedIn = 'loggedIn';

  // Languages
  static const String langFrench = 'fr';
  static const String langArabic = 'ar';
  static const String langEnglish = 'en';

  // Themes
  static const String themeLight = 'light';
  static const String themeDark = 'dark';
  static const String themeSystem = 'system';

  // Misc
  static const int splashDuration = 2; // seconds
  static const int animationDuration = 300; // milliseconds
  static const double borderRadius = 12.0;
  static const double spacing = 16.0;
  static const double spacingSmall = 8.0;
  static const double spacingLarge = 24.0;
}
