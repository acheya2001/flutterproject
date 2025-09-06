import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/accident_session_complete.dart';
import '../../services/auto_fill_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/sinistre_tracking_service.dart';
import '../../widgets/elegant_form_widgets.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// 📋 Formulaire de constat d'accident COMPLET selon les standards officiels
class ConstatCompletScreen extends StatefulWidget {
  final AccidentSessionComplete? session;
  final Map<String, dynamic>? vehiculeSelectionne;
  final String? sinistreId;
  final bool isCollaborative;
  final String? accidentType;
  final int? vehicleCount;
  final String? conducteurLetter;
  final Map<String, dynamic>? sessionData;

  const ConstatCompletScreen({
    Key? key,
    this.session,
    this.vehiculeSelectionne,
    this.sinistreId,
    this.isCollaborative = false,
    this.accidentType,
    this.vehicleCount,
    this.conducteurLetter,
    this.sessionData,
  }) : super(key: key);

  @override
  State<ConstatCompletScreen> createState() => _ConstatCompletScreenState();
}

class _ConstatCompletScreenState extends State<ConstatCompletScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isPreFilled = false;
  Map<String, dynamic> _formData = {};
  List<String> _photos = [];

  // Controllers pour tous les champs
  final Map<String, TextEditingController> _controllers = {};

  // Sections du constat (dynamiques selon le nombre de conducteurs)
  late List<String> _sections;

  @override
  void initState() {
    super.initState();

    // 1. Initialiser les sections d'abord
    _initializeSections();

    // 2. Créer le TabController avec le bon nombre de sections
    _tabController = TabController(length: _sections.length, vsync: this);

    // 3. Initialiser les controllers
    _initializeControllers();

    // 4. Pré-remplissage automatique SEULEMENT pour conducteur inscrit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserTypeAndLoadData();
    });
  }

  /// 📋 Initialiser les sections selon le contexte
  void _initializeSections() {
    final myLetter = widget.conducteurLetter ?? 'A';

    // CHAQUE CONDUCTEUR A UNIQUEMENT SA PROPRE SECTION
    _sections = [
      'Informations générales', // Date, lieu, heure (partagées)
      'Mes informations', // MES informations personnelles uniquement
      'Mon véhicule', // MON véhicule uniquement
      'Mon assurance', // MON assurance uniquement
      'Circonstances', // Ce que j'ai vu
      'Dégâts sur mon véhicule', // MES dégâts
      'Photos', // MES photos
      'Croquis', // Ma version du croquis
      'Validation', // Ma signature
    ];
  }

  /// 🔧 Initialiser tous les controllers
  void _initializeControllers() {
    final fields = [
      // Section 1: Informations générales
      'date', 'heure', 'lieu', 'ville', 'codePostal', 'pays',

      // Section 2: Mes informations personnelles COMPLÈTES
      'nom', 'prenom', 'cin', 'dateNaissance', 'lieuNaissance',
      'adresse', 'ville', 'codePostal', 'telephone', 'email',
      'profession', 'nationalite', 'situationFamiliale',

      // Permis de conduire COMPLET
      'numeroPermis', 'categoriePermis', 'dateDelivrancePermis',
      'lieuDelivrancePermis', 'dateValiditePermis',

      // Section 3: Mon véhicule COMPLET
      'marque', 'modele', 'immatriculation', 'couleur', 'annee',
      'numeroSerie', 'puissanceFiscale', 'nombrePlaces', 'usage',
      'datePremiereImmatriculation', 'kilometrage', 'carburant',
      'typeVehicule', 'poids', 'longueur', 'largeur',

      // Section 4: Mon assurance COMPLÈTE avec validité
      'compagnieAssurance', 'numeroPolice', 'agenceAssurance',
      'dateDebutContrat', 'dateFinContrat', 'montantFranchise',
      'typeContrat', 'typeCouverture', 'primeAnnuelle',
      'garanties', 'plafondGarantie',

      // Section 5: Circonstances
      'descriptionAccident',

      // Section 8: Témoins
      'temoin1_nom', 'temoin1_telephone', 'temoin1_adresse',
      'temoin2_nom', 'temoin2_telephone', 'temoin2_adresse',

      // Anciens champs pour compatibilité (à supprimer progressivement)
      'conducteurA_nom', 'conducteurA_prenom', 'conducteurA_dateNaissance',
      'conducteurA_adresse', 'conducteurA_telephone', 'conducteurA_email',
      'conducteurA_numeroPermis', 'conducteurA_categoriePermis',
      'conducteurB_nom', 'conducteurB_prenom', 'conducteurB_dateNaissance',
      'conducteurB_adresse', 'conducteurB_telephone', 'conducteurB_email',
      'conducteurB_numeroPermis', 'conducteurB_categoriePermis',
      'assuranceA_compagnie', 'assuranceA_numeroPolice', 'assuranceA_agence',
      'assuranceA_validiteDebut', 'assuranceA_validiteFin',
      'assuranceB_compagnie', 'assuranceB_numeroPolice', 'assuranceB_agence',
      'assuranceB_validiteDebut', 'assuranceB_validiteFin',

      // Observations
      'observations',
    ];

    for (String field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  /// 🔄 Charger les données pré-remplies
  Future<void> _loadPreFilledData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Charger les données automatiques (date, heure, lieu)
      final preFilledData = await AutoFillService.getCompletePreFilledData();

      if (preFilledData['isPreFilled'] == true) {
        _applyPreFilledData(preFilledData);
      }

      // 2. Pré-remplir avec les données du véhicule sélectionné
      if (widget.vehiculeSelectionne != null) {
        _applyVehicleData(widget.vehiculeSelectionne!);
      }

      // 3. Pré-remplir avec les données du conducteur connecté
      await _loadConducteurData();

      // 4. Appliquer les informations de l'accident
      _applyAccidentInfo();

      setState(() => _isPreFilled = true);
    } catch (e) {
      print('❌ Erreur pré-remplissage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📝 Appliquer les données pré-remplies automatiques
  void _applyPreFilledData(Map<String, dynamic> data) {
    final dateTime = data['dateTime'] ?? {};
    final location = data['location'] ?? {};

    // Date et heure automatiques
    _controllers['date']?.text = dateTime['dateFormatted'] ?? '';
    _controllers['heure']?.text = dateTime['heure'] ?? '';

    // Localisation automatique
    _controllers['lieu']?.text = location['adresse'] ?? '';
    _controllers['ville']?.text = location['ville'] ?? '';
    _controllers['codePostal']?.text = location['codePostal'] ?? '';
    _controllers['pays']?.text = 'Tunisie';
  }

  /// 🚗 Appliquer les données du véhicule sélectionné
  void _applyVehicleData(Map<String, dynamic> vehicule) {
    final letter = widget.conducteurLetter ?? 'A';

    // Véhicule du conducteur connecté
    _controllers['vehicule${letter}_marque']?.text = vehicule['marque'] ?? '';
    _controllers['vehicule${letter}_modele']?.text = vehicule['modele'] ?? '';
    _controllers['vehicule${letter}_immatriculation']?.text = vehicule['immatriculation'] ?? '';
    _controllers['vehicule${letter}_couleur']?.text = vehicule['couleur'] ?? '';

    // Assurance du véhicule
    _controllers['assurance${letter}_compagnie']?.text = vehicule['compagnieAssurance'] ?? '';
    _controllers['assurance${letter}_numeroPolice']?.text = vehicule['numeroPolice'] ?? '';
    _controllers['assurance${letter}_agence']?.text = vehicule['agenceAssurance'] ?? '';
  }

  /// 🔍 Vérifier le type d'utilisateur et charger les données appropriées
  Future<void> _checkUserTypeAndLoadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      print('🔍 === DIAGNOSTIC TYPE UTILISATEUR ===');
      print('🔍 Utilisateur connecté: ${user?.email ?? "NON"}');
      print('🔍 Véhicule sélectionné: ${widget.vehiculeSelectionne != null ? "OUI" : "NULL"}');
      print('🔍 Mode collaboratif: ${widget.isCollaborative}');
      print('🔍 Conducteur letter: ${widget.conducteurLetter}');

      if (user == null) {
        print('👤 Utilisateur NON CONNECTÉ - Formulaire vide pour invité');
        _showUserTypeMessage('Invité', 'Formulaire vide à remplir manuellement');
        return;
      }

      // Vérifier si l'utilisateur est inscrit dans le système
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      print('🔍 Document utilisateur existe: ${userDoc.exists}');
      if (userDoc.exists) {
        print('🔍 Données utilisateur: ${userDoc.data()}');
      }

      if (!userDoc.exists) {
        print('⚠️ Document utilisateur manquant, vérification des contrats...');

        // Vérifier si l'utilisateur a des contrats (donc il est inscrit mais document manquant)
        final contractSnapshot = await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .where('conducteurId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (contractSnapshot.docs.isNotEmpty) {
          print('✅ Utilisateur a des contrats - Création du document utilisateur...');

          final contractData = contractSnapshot.docs.first.data();

          // Créer le document utilisateur à partir des données du contrat
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'email': user.email,
            'nom': contractData['nom'] ?? '',
            'prenom': contractData['prenom'] ?? '',
            'telephone': contractData['telephone'] ?? '',
            'adresse': contractData['adresse'] ?? '',
            'ville': contractData['ville'] ?? '',
            'codePostal': contractData['codePostal'] ?? '',
            'dateNaissance': contractData['dateNaissance'] ?? '',
            'profession': contractData['profession'] ?? '',
            'nationalite': contractData['nationalite'] ?? 'Tunisienne',
            'numeroPermis': contractData['numeroPermis'] ?? '',
            'categoriePermis': contractData['categoriePermis'] ?? '',
            'role': 'conducteur',
            'statut': 'actif',
            'dateCreation': FieldValue.serverTimestamp(),
            'source': 'auto_creation_from_contract',
          });

          print('✅ Document utilisateur créé automatiquement !');

          // Recharger le document utilisateur après création
          final newUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (newUserDoc.exists) {
            final userData = newUserDoc.data()!;
            final role = userData['role'] ?? 'conducteur';

            print('👤 Utilisateur INSCRIT (créé automatiquement) - Rôle: $role');
            print('✅ PRÉ-REMPLISSAGE AUTOMATIQUE activé');

            _showUserTypeMessage('Inscrit ($role)', 'Document créé - Pré-remplissage automatique');

            // TOUJOURS charger les données pour les utilisateurs inscrits
            await _loadPreFilledData();
            await _loadConducteurData();
          }

          return;
        } else {
          print('👤 Utilisateur NON INSCRIT - Aucun contrat trouvé');
          _showUserTypeMessage('Non inscrit', 'Formulaire vide à remplir manuellement');
          return;
        }
      }

      final userData = userDoc.data()!;
      final role = userData['role'] ?? 'inconnu';

      print('👤 Utilisateur INSCRIT détecté - Rôle: $role');
      print('✅ PRÉ-REMPLISSAGE AUTOMATIQUE activé');

      _showUserTypeMessage('Inscrit ($role)', 'Pré-remplissage automatique des données');

      // TOUJOURS charger les données pour les utilisateurs inscrits
      await _loadPreFilledData();
      await _loadConducteurData();

    } catch (e) {
      print('❌ Erreur vérification type utilisateur: $e');
      _showUserTypeMessage('Erreur', 'Impossible de déterminer le type d\'utilisateur');
    }
  }

  /// 💬 Afficher un message sur le type d'utilisateur
  void _showUserTypeMessage(String userType, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                userType.contains('Inscrit') ? Icons.verified_user : Icons.person_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$userType: $message',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: userType.contains('Inscrit') ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 👤 Charger les données du conducteur connecté
  Future<void> _loadConducteurData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ Aucun utilisateur connecté - formulaire vide pour non-inscrit');
        return;
      }

      print('🔄 Chargement des données du conducteur inscrit...');

      // SEULEMENT pour les conducteurs INSCRITS
      // Vérifier si l'utilisateur est vraiment inscrit dans le système
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print('⚠️ Utilisateur non inscrit dans le système - formulaire vide');
        return;
      }

      print('✅ Utilisateur inscrit détecté - pré-remplissage automatique');

      // 1. Charger les données du contrat actif (contient TOUTES les infos)
      await _loadContractCompleteData(user.uid);

      // 2. Si pas de contrat, charger les données utilisateur de base
      if (_controllers['nom']?.text.isEmpty ?? true) {
        await _loadUserBasicData(user);
      }

      // 3. PRÉ-REMPLISSAGE AUTOMATIQUE - Véhicule et assurance
      if (widget.vehiculeSelectionne != null) {
        await _loadVehicleAndInsuranceData();
      }

    } catch (e) {
      print('❌ Erreur chargement conducteur: $e');
    }
  }

  /// 📄 Charger les données complètes du contrat actif
  Future<void> _loadContractCompleteData(String userId) async {
    try {
      print('🔍 Recherche du contrat actif...');

      // Chercher le contrat actif dans demandes_contrats
      final contractSnapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: userId)
          .where('statut', whereIn: ['contrat_actif', 'contrat_valide', 'affectee'])
          .limit(1)
          .get();

      if (contractSnapshot.docs.isNotEmpty) {
        final contractData = contractSnapshot.docs.first.data();
        print('✅ Contrat trouvé: ${contractData['numero']} - ${contractData['nom']} ${contractData['prenom']}');

        // PRÉ-REMPLISSAGE COMPLET - Informations personnelles
        _controllers['nom']?.text = contractData['nom'] ?? '';
        _controllers['prenom']?.text = contractData['prenom'] ?? '';
        _controllers['telephone']?.text = contractData['telephone'] ?? '';
        _controllers['email']?.text = contractData['email'] ?? '';
        _controllers['adresse']?.text = contractData['adresse'] ?? '';
        _controllers['ville']?.text = contractData['ville'] ?? '';
        _controllers['codePostal']?.text = contractData['codePostal'] ?? '';
        _controllers['dateNaissance']?.text = contractData['dateNaissance'] ?? '';
        _controllers['lieuNaissance']?.text = contractData['lieuNaissance'] ?? '';
        _controllers['profession']?.text = contractData['profession'] ?? '';
        _controllers['nationalite']?.text = contractData['nationalite'] ?? 'Tunisienne';

        // PRÉ-REMPLISSAGE COMPLET - Permis de conduire
        _controllers['numeroPermis']?.text = contractData['numeroPermis'] ?? '';
        _controllers['categoriePermis']?.text = contractData['categoriePermis'] ?? '';
        _controllers['dateDelivrancePermis']?.text = contractData['dateDelivrancePermis'] ?? '';
        _controllers['lieuDelivrancePermis']?.text = contractData['lieuDelivrancePermis'] ?? '';
        _controllers['dateValiditePermis']?.text = contractData['dateValiditePermis'] ?? '';

        // PRÉ-REMPLISSAGE COMPLET - Véhicule
        _controllers['marque']?.text = contractData['marque'] ?? '';
        _controllers['modele']?.text = contractData['modele'] ?? '';
        _controllers['immatriculation']?.text = contractData['immatriculation'] ?? '';
        _controllers['couleur']?.text = contractData['couleur'] ?? '';
        _controllers['annee']?.text = contractData['annee']?.toString() ?? '';
        _controllers['numeroSerie']?.text = contractData['numeroSerie'] ?? '';
        _controllers['puissanceFiscale']?.text = contractData['puissanceFiscale']?.toString() ?? '';
        _controllers['nombrePlaces']?.text = contractData['nombrePlaces']?.toString() ?? '';
        _controllers['usage']?.text = contractData['usage'] ?? 'Personnel';
        _controllers['datePremiereImmatriculation']?.text = contractData['datePremiereImmatriculation'] ?? '';

        // PRÉ-REMPLISSAGE COMPLET - Assurance avec validité
        _controllers['compagnieAssurance']?.text = contractData['compagnieAssuranceNom'] ?? contractData['compagnieAssurance'] ?? '';
        _controllers['numeroPolice']?.text = contractData['numero'] ?? contractData['numeroPolice'] ?? '';
        _controllers['agenceAssurance']?.text = contractData['agenceAssuranceNom'] ?? contractData['agenceAssurance'] ?? '';

        // VALIDITÉ DU CONTRAT (très important pour les constats)
        _controllers['dateDebutContrat']?.text = contractData['dateDebutContrat'] ?? '';
        _controllers['dateFinContrat']?.text = contractData['dateFinContrat'] ?? '';
        _controllers['montantFranchise']?.text = contractData['franchise']?.toString() ?? contractData['montantFranchise']?.toString() ?? '';
        _controllers['typeContrat']?.text = contractData['typeCouverture'] ?? contractData['typeContrat'] ?? 'Tous risques';

        print('✅ TOUTES les données pré-remplies depuis le contrat !');
      } else {
        print('⚠️ Aucun contrat actif trouvé');
      }
    } catch (e) {
      print('❌ Erreur chargement contrat: $e');
    }
  }

  /// 👤 Charger les données utilisateur de base (fallback)
  Future<void> _loadUserBasicData(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        print('✅ Données utilisateur de base: ${userData['nom']} ${userData['prenom']}');

        // Remplir uniquement si pas déjà rempli par le contrat
        if (_controllers['nom']?.text.isEmpty ?? true) {
          _controllers['nom']?.text = userData['nom'] ?? '';
          _controllers['prenom']?.text = userData['prenom'] ?? '';
          _controllers['telephone']?.text = userData['telephone'] ?? '';
          _controllers['email']?.text = userData['email'] ?? user.email ?? '';
        }
      }
    } catch (e) {
      print('❌ Erreur chargement données utilisateur: $e');
    }
  }

  /// 🚗 Charger les données du véhicule et de l'assurance
  Future<void> _loadVehicleAndInsuranceData() async {
    try {
      final vehicule = widget.vehiculeSelectionne!;
      print('🔄 Pré-remplissage véhicule: ${vehicule['marque']} ${vehicule['modele']}');

      // PRÉ-REMPLISSAGE AUTOMATIQUE - Véhicule
      _controllers['marque']?.text = vehicule['marque'] ?? '';
      _controllers['modele']?.text = vehicule['modele'] ?? '';
      _controllers['immatriculation']?.text = vehicule['immatriculation'] ?? '';
      _controllers['couleur']?.text = vehicule['couleur'] ?? '';
      _controllers['annee']?.text = vehicule['annee']?.toString() ?? '';
      _controllers['numeroSerie']?.text = vehicule['numeroSerie'] ?? '';
      _controllers['puissanceFiscale']?.text = vehicule['puissanceFiscale']?.toString() ?? '';
      _controllers['nombrePlaces']?.text = vehicule['nombrePlaces']?.toString() ?? '';
      _controllers['usage']?.text = vehicule['usage'] ?? 'Personnel';
      _controllers['datePremiereImmatriculation']?.text = vehicule['datePremiereImmatriculation'] ?? '';

      // PRÉ-REMPLISSAGE AUTOMATIQUE - Assurance
      _controllers['compagnieAssurance']?.text = vehicule['compagnieAssurance'] ?? '';
      _controllers['numeroPolice']?.text = vehicule['numeroPolice'] ?? '';
      _controllers['agenceAssurance']?.text = vehicule['agenceAssurance'] ?? '';
      _controllers['dateDebutContrat']?.text = vehicule['dateDebutContrat'] ?? '';
      _controllers['dateFinContrat']?.text = vehicule['dateFinContrat'] ?? '';
      _controllers['montantFranchise']?.text = vehicule['montantFranchise']?.toString() ?? '';
      _controllers['typeContrat']?.text = vehicule['typeContrat'] ?? 'Tous risques';

      print('✅ Véhicule et assurance pré-remplis: ${vehicule['compagnieAssurance']} - ${vehicule['numeroPolice']}');
    } catch (e) {
      print('❌ Erreur pré-remplissage véhicule: $e');
    }
  }

  /// 🚨 Appliquer les informations de l'accident
  void _applyAccidentInfo() {
    // Marquer le type d'accident dans les circonstances
    if (widget.accidentType != null) {
      switch (widget.accidentType) {
        case 'collision_deux_vehicules':
          // Marquer les circonstances appropriées
          break;
        case 'carambolage':
          // Marquer carambolage
          break;
        case 'sortie_route':
          // Marquer sortie de route
          break;
        case 'collision_objet_fixe':
          // Marquer collision objet fixe
          break;
        case 'accident_pieton_cycliste':
          // Marquer accident piéton/cycliste
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Constat d\'Accident Complet'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _sections.map((section) => Tab(text: section)).toList(),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _sauvegarderBrouillon,
            icon: const Icon(Icons.save),
            tooltip: 'Sauvegarder brouillon',
          ),
          IconButton(
            onPressed: _isLoading ? null : _finaliserConstat,
            icon: const Icon(Icons.send),
            tooltip: 'Finaliser constat',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Indicateur de pré-remplissage
                if (_isPreFilled)
                  ElegantFormWidgets.buildPreFilledIndicator(
                    isPreFilled: _isPreFilled,
                    message: 'Constat pré-rempli avec vos informations',
                  ),
                
                // Contenu des onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInformationsGeneralesTab(), // Informations générales
                      _buildMesInformationsTab(),       // Mes informations
                      _buildMonVehiculeTab(),           // Mon véhicule
                      _buildMonAssuranceTab(),          // Mon assurance
                      _buildCirconstancesTab(),         // Circonstances
                      _buildDegatsTab(),                // Dégâts sur mon véhicule
                      _buildPhotosTab(),                // Photos
                      _buildCroquisTab(),               // Croquis
                      _buildValidationTab(),            // Validation
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// 📍 Section 1: Informations générales (partagées)
  Widget _buildInformationsGeneralesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ElegantFormWidgets.buildFormSection(
              title: 'Date et Heure de l\'Accident',
              icon: Icons.access_time,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElegantFormWidgets.buildDatePicker(
                        label: 'Date',
                        controller: _controllers['date']!,
                        context: context,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElegantFormWidgets.buildTimePicker(
                        label: 'Heure',
                        controller: _controllers['heure']!,
                        context: context,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            ElegantFormWidgets.buildFormSection(
              title: 'Lieu de l\'Accident',
              icon: Icons.location_on,
              children: [
                ElegantFormWidgets.buildElegantTextField(
                  label: 'Adresse précise',
                  controller: _controllers['lieu']!,
                  hint: 'Rue, avenue, route...',
                  isRequired: true,
                  validator: (value) => value?.isEmpty == true ? 'Lieu requis' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElegantFormWidgets.buildElegantTextField(
                        label: 'Ville',
                        controller: _controllers['ville']!,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElegantFormWidgets.buildElegantTextField(
                        label: 'Code postal',
                        controller: _controllers['codePostal']!,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElegantFormWidgets.buildElegantTextField(
                  label: 'Pays',
                  controller: _controllers['pays']!,
                  preFilledValue: 'Tunisie',
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _obtenirPositionGPS,
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Obtenir position GPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            ElegantFormWidgets.buildFormSection(
              title: 'Questions Générales',
              icon: Icons.help_outline,
              children: [
                _buildYesNoQuestion('Y a-t-il des blessés ?', 'blesses'),
                const SizedBox(height: 16),
                _buildYesNoQuestion('Y a-t-il des dégâts matériels autres qu\'aux véhicules ?', 'degatsAutres'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 👤 Section 2: Mes informations personnelles
  Widget _buildMesInformationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElegantFormWidgets.buildFormSection(
            title: 'Mes Informations Personnelles',
            icon: Icons.person,
            iconColor: Colors.blue[600],
            children: [
              _buildMesInformationsForm(),
            ],
          ),
        ],
      ),
    );
  }

  /// 🚗 Section 3: Mon véhicule
  Widget _buildMonVehiculeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElegantFormWidgets.buildFormSection(
            title: 'Mon Véhicule',
            icon: Icons.directions_car,
            iconColor: Colors.blue[600],
            children: [
              _buildMonVehiculeForm(),
            ],
          ),
        ],
      ),
    );
  }

  /// 🛡️ Section 4: Mon assurance
  Widget _buildMonAssuranceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElegantFormWidgets.buildFormSection(
            title: 'Mon Assurance',
            icon: Icons.security,
            iconColor: Colors.blue[600],
            children: [
              _buildMonAssuranceForm(),
            ],
          ),
        ],
      ),
    );
  }

  /// 📸 Section 6: Photos
  Widget _buildPhotosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElegantFormWidgets.buildFormSection(
            title: 'Photos des Dégâts',
            icon: Icons.camera_alt,
            children: [
              _buildPhotosSection(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _ajouterPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera),
                      label: const Text('Prendre photo'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _ajouterPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Section 9: Validation
  Widget _buildValidationTab() {
    return const Center(
      child: Text('Validation - À implémenter'),
    );
  }

  /// ⚠️ Section 5: Circonstances
  Widget _buildCirconstancesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElegantFormWidgets.buildFormSection(
            title: 'Circonstances de l\'Accident',
            icon: Icons.warning,
            children: [
              const Text(
                'Cochez les cases correspondant aux circonstances de l\'accident:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildCirconstancesCheckboxes(),
            ],
          ),

          ElegantFormWidgets.buildFormSection(
            title: 'Description Libre',
            icon: Icons.description,
            children: [
              ElegantFormWidgets.buildElegantTextField(
                label: 'Description de l\'accident',
                controller: _controllers['descriptionAccident']!,
                hint: 'Décrivez ce qui s\'est passé avec vos propres mots...',
                maxLines: 5,
                isRequired: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔧 Section 6: Dégâts
  Widget _buildDegatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElegantFormWidgets.buildFormSection(
            title: 'Photos des Dégâts',
            icon: Icons.camera_alt,
            children: [
              _buildPhotosSection(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _ajouterPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera),
                      label: const Text('Prendre photo'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _ajouterPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎨 Section 7: Croquis
  Widget _buildCroquisTab() {
    return const Center(
      child: Text('Croquis - À implémenter'),
    );
  }

  /// 👥 Section 8: Témoins
  Widget _buildTemoinsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElegantFormWidgets.buildFormSection(
            title: 'Témoins de l\'Accident',
            icon: Icons.people,
            children: [
              _buildTemoinForm(1),
              const SizedBox(height: 16),
              _buildTemoinForm(2),
            ],
          ),
        ],
      ),
    );
  }

  /// ✍️ Section 9: Signatures
  Widget _buildSignaturesTab() {
    return const Center(
      child: Text('Signatures - À implémenter'),
    );
  }

  /// 👤 Formulaire pour mes informations personnelles (adapté inscrit/non-inscrit)
  Widget _buildMesInformationsForm() {
    return Column(
      children: [
        // Nom et Prénom
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Nom *',
                controller: _controllers['nom']!,
                isRequired: true,
                hint: 'Votre nom de famille',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Prénom *',
                controller: _controllers['prenom']!,
                isRequired: true,
                hint: 'Votre prénom',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date de naissance et CIN
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Date de naissance',
                controller: _controllers['dateNaissance']!,
                hint: 'JJ/MM/AAAA',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'CIN',
                controller: _controllers['cin']!,
                hint: 'Numéro CIN',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Adresse complète
        ElegantFormWidgets.buildElegantTextField(
          label: 'Adresse complète *',
          controller: _controllers['adresse']!,
          maxLines: 2,
          isRequired: true,
          hint: 'Rue, ville, code postal...',
        ),
        const SizedBox(height: 16),

        // Téléphone et Email
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Téléphone *',
                controller: _controllers['telephone']!,
                keyboardType: TextInputType.phone,
                isRequired: true,
                hint: '+216 XX XXX XXX',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Email',
                controller: _controllers['email']!,
                keyboardType: TextInputType.emailAddress,
                hint: 'votre@email.com',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section Permis de conduire
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Permis de conduire',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElegantFormWidgets.buildElegantTextField(
                      label: 'N° Permis *',
                      controller: _controllers['numeroPermis']!,
                      isRequired: true,
                      hint: 'Numéro du permis',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElegantFormWidgets.buildElegantTextField(
                      label: 'Catégorie *',
                      controller: _controllers['categoriePermis']!,
                      hint: 'B, A, C...',
                      isRequired: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🚗 Formulaire pour mon véhicule (adapté inscrit/non-inscrit)
  Widget _buildMonVehiculeForm() {
    return Column(
      children: [
        // Marque et Modèle
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Marque *',
                controller: _controllers['marque']!,
                isRequired: true,
                hint: 'Ex: Peugeot, Renault...',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Modèle *',
                controller: _controllers['modele']!,
                isRequired: true,
                hint: 'Ex: 208, Clio...',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Immatriculation
        ElegantFormWidgets.buildElegantTextField(
          label: 'Immatriculation *',
          controller: _controllers['immatriculation']!,
          isRequired: true,
          hint: 'Ex: 123 TUN 456',
        ),
        const SizedBox(height: 16),

        // Couleur et Année
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Couleur',
                controller: _controllers['couleur']!,
                hint: 'Ex: Blanc, Rouge...',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Année *',
                controller: _controllers['annee']!,
                keyboardType: TextInputType.number,
                isRequired: true,
                hint: 'Ex: 2020',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Numéro de série (optionnel pour non-inscrits)
        ElegantFormWidgets.buildElegantTextField(
          label: 'Numéro de série (châssis)',
          controller: _controllers['numeroSerie']!,
          hint: 'Optionnel - Numéro de châssis',
        ),
      ],
    );
  }

  /// 🛡️ Formulaire pour mon assurance (adapté inscrit/non-inscrit)
  Widget _buildMonAssuranceForm() {
    return Column(
      children: [
        // Compagnie d'assurance et Numéro de police
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Compagnie d\'assurance *',
                controller: _controllers['compagnieAssurance']!,
                isRequired: true,
                hint: 'Ex: STAR, AMI, COMAR...',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'N° Police *',
                controller: _controllers['numeroPolice']!,
                isRequired: true,
                hint: 'Numéro de police',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Agence d'assurance
        ElegantFormWidgets.buildElegantTextField(
          label: 'Agence d\'assurance',
          controller: _controllers['agenceAssurance']!,
          hint: 'Nom de l\'agence (optionnel)',
        ),
        const SizedBox(height: 16),

        // Période de validité du contrat (TRÈS IMPORTANT)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[300]!, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Validité du contrat d\'assurance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElegantFormWidgets.buildDatePicker(
                      label: 'Validité du *',
                      controller: _controllers['dateDebutContrat']!,
                      context: context,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElegantFormWidgets.buildDatePicker(
                      label: 'Validité au *',
                      controller: _controllers['dateFinContrat']!,
                      context: context,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Type de couverture
        ElegantFormWidgets.buildElegantTextField(
          label: 'Type de couverture',
          controller: _controllers['typeContrat']!,
          hint: 'Ex: Tous risques, Responsabilité civile...',
        ),
      ],
    );
  }

  /// 👤 Formulaire pour un conducteur (ancien - à supprimer)
  Widget _buildConducteurForm(String conducteur) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Nom',
                controller: _controllers['conducteur${conducteur}_nom']!,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Prénom',
                controller: _controllers['conducteur${conducteur}_prenom']!,
                isRequired: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElegantFormWidgets.buildDatePicker(
          label: 'Date de naissance',
          controller: _controllers['conducteur${conducteur}_dateNaissance']!,
          context: context,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        ElegantFormWidgets.buildElegantTextField(
          label: 'Adresse complète',
          controller: _controllers['conducteur${conducteur}_adresse']!,
          maxLines: 2,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Téléphone',
                controller: _controllers['conducteur${conducteur}_telephone']!,
                keyboardType: TextInputType.phone,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Email',
                controller: _controllers['conducteur${conducteur}_email']!,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'N° Permis de conduire',
                controller: _controllers['conducteur${conducteur}_numeroPermis']!,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildElegantTextField(
                label: 'Catégorie',
                controller: _controllers['conducteur${conducteur}_categoriePermis']!,
                hint: 'B, A, C...',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🛡️ Formulaire pour une assurance
  Widget _buildAssuranceForm(String vehicule) {
    return Column(
      children: [
        ElegantFormWidgets.buildElegantTextField(
          label: 'Compagnie d\'assurance',
          controller: _controllers['assurance${vehicule}_compagnie']!,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        ElegantFormWidgets.buildElegantTextField(
          label: 'Numéro de police',
          controller: _controllers['assurance${vehicule}_numeroPolice']!,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        ElegantFormWidgets.buildElegantTextField(
          label: 'Agence',
          controller: _controllers['assurance${vehicule}_agence']!,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElegantFormWidgets.buildDatePicker(
                label: 'Validité du',
                controller: _controllers['assurance${vehicule}_validiteDebut']!,
                context: context,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElegantFormWidgets.buildDatePicker(
                label: 'Validité au',
                controller: _controllers['assurance${vehicule}_validiteFin']!,
                context: context,
                isRequired: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 👥 Formulaire pour un témoin
  Widget _buildTemoinForm(int numero) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Témoin $numero',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ElegantFormWidgets.buildElegantTextField(
          label: 'Nom et prénom',
          controller: _controllers['temoin${numero}_nom']!,
        ),
        const SizedBox(height: 12),
        ElegantFormWidgets.buildElegantTextField(
          label: 'Téléphone',
          controller: _controllers['temoin${numero}_telephone']!,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        ElegantFormWidgets.buildElegantTextField(
          label: 'Adresse',
          controller: _controllers['temoin${numero}_adresse']!,
          maxLines: 2,
        ),
      ],
    );
  }

  /// ❓ Widget pour question Oui/Non
  Widget _buildYesNoQuestion(String question, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Oui'),
                value: true,
                groupValue: _formData[key],
                onChanged: (value) {
                  setState(() {
                    _formData[key] = value;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Non'),
                value: false,
                groupValue: _formData[key],
                onChanged: (value) {
                  setState(() {
                    _formData[key] = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ⚠️ Checkboxes pour les circonstances
  Widget _buildCirconstancesCheckboxes() {
    final circonstances = [
      'Stationnait',
      'Quittait un stationnement',
      'Prenait un stationnement',
      'Sortait d\'un parking, d\'un lieu privé',
      'S\'engageait dans un parking, un lieu privé',
      'Sortait d\'un rond-point',
      'S\'engageait dans un rond-point',
      'Heurtait par l\'arrière',
      'Roulait dans le même sens et sur la même file',
      'Changeait de file',
      'Doublait',
      'Virait à droite',
      'Virait à gauche',
      'Reculait',
      'Empiétait sur une voie réservée à la circulation en sens inverse',
      'Venait de droite (dans un carrefour)',
      'N\'avait pas observé un signal de priorité ou un feu de signalisation',
    ];

    return Column(
      children: circonstances.map((circonstance) {
        return CheckboxListTile(
          title: Text(circonstance),
          value: _formData['circonstance_$circonstance'] ?? false,
          onChanged: (value) {
            setState(() {
              _formData['circonstance_$circonstance'] = value ?? false;
            });
          },
        );
      }).toList(),
    );
  }

  /// 📸 Section photos
  Widget _buildPhotosSection() {
    return Column(
      children: [
        if (_photos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return _buildPhotoCard(_photos[index], index);
            },
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '${_photos.length}/10 photos ajoutées',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 🖼️ Carte de photo
  Widget _buildPhotoCard(String photoUrl, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Image.network(
              photoUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                );
              },
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _supprimerPhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📸 Ajouter une photo
  Future<void> _ajouterPhoto(ImageSource source) async {
    if (_photos.length >= 10) {
      _showErrorMessage('Maximum 10 photos autorisées');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        final photoUrl = await CloudinaryService.uploadImage(
          File(image.path),
          'constats',
        );

        if (photoUrl != null) {
          setState(() {
            _photos.add(photoUrl);
            _isLoading = false;
          });
          _showSuccessMessage('Photo ajoutée avec succès !');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Erreur lors de l\'ajout: $e');
    }
  }

  /// 🗑️ Supprimer une photo
  void _supprimerPhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    _showSuccessMessage('Photo supprimée');
  }

  /// 📍 Obtenir position GPS
  Future<void> _obtenirPositionGPS() async {
    try {
      setState(() => _isLoading = true);

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _formData['latitude'] = position.latitude;
        _formData['longitude'] = position.longitude;
        _isLoading = false;
      });

      _showSuccessMessage('Position GPS obtenue !');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Erreur GPS: $e');
    }
  }

  /// 💾 Sauvegarder brouillon
  Future<void> _sauvegarderBrouillon() async {
    try {
      setState(() => _isLoading = true);

      // Collecter toutes les données du formulaire
      final data = _collectFormData();
      data['statut'] = 'brouillon';
      data['photos'] = _photos;

      // TODO: Sauvegarder en base de données
      await Future.delayed(const Duration(seconds: 1)); // Simulation

      _showSuccessMessage('Brouillon sauvegardé !');
    } catch (e) {
      _showErrorMessage('Erreur sauvegarde: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📤 Finaliser constat
  Future<void> _finaliserConstat() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Collecter toutes les données du formulaire
      final data = _collectFormData();
      data['statut'] = 'termine';
      data['photos'] = _photos;
      data['dateFinalisation'] = DateTime.now().toIso8601String();
      data['accidentType'] = widget.accidentType;
      data['vehicleCount'] = widget.vehicleCount;
      data['isCollaborative'] = widget.isCollaborative;
      data['conducteurLetter'] = widget.conducteurLetter;

      // 1. Enregistrer le sinistre dans Firestore
      await _enregistrerSinistre(data);

      // 2. Envoyer à l'agence d'assurance
      await _envoyerAAgence(data);

      // 3. Mettre à jour le statut du sinistre de suivi
      if (widget.sinistreId != null) {
        await SinistreTrackingService.updateStatut(
          sinistreId: widget.sinistreId!,
          newStatut: 'envoye_agence',
          description: 'Constat finalisé et envoyé à l\'agence',
          additionalData: {
            'dateFinalisation': DateTime.now().toIso8601String(),
            'nombreVehicules': widget.vehicleCount ?? 1,
            'typeAccident': widget.accidentType ?? 'non_specifie',
          },
        );
      }
      await Future.delayed(const Duration(seconds: 2)); // Simulation

      _showSuccessMessage('Constat finalisé et envoyé !');
      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage('Erreur finalisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 💾 Enregistrer le sinistre dans Firestore
  Future<void> _enregistrerSinistre(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    // Préparer les données du sinistre
    final sinistreData = {
      'conducteurId': user.uid,
      'sinistreId': widget.sinistreId,
      'typeAccident': widget.accidentType ?? 'non_specifie',
      'nombreVehicules': widget.vehicleCount ?? 1,
      'isCollaborative': widget.isCollaborative,
      'conducteurLetter': widget.conducteurLetter ?? 'A',
      'statut': 'termine',
      'dateCreation': DateTime.now(),
      'dateFinalisation': DateTime.now(),
      'lieu': data['lieu'] ?? '',
      'ville': data['ville'] ?? '',
      'dateAccident': data['date'] ?? '',
      'heureAccident': data['heure'] ?? '',
      'vehiculeSelectionne': widget.vehiculeSelectionne,
      'formulaireData': data,
      'photos': _photos,
      'source': 'constat_complet',
    };

    // Enregistrer dans la collection sinistres
    await FirebaseFirestore.instance
        .collection('sinistres')
        .add(sinistreData);

    print('✅ Sinistre enregistré avec succès');
  }

  /// 📧 Envoyer le constat à l'agence d'assurance
  Future<void> _envoyerAAgence(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.vehiculeSelectionne == null) return;

      final agenceAssurance = widget.vehiculeSelectionne!['agenceAssurance'];
      final compagnieAssurance = widget.vehiculeSelectionne!['compagnieAssurance'];

      if (agenceAssurance == null || compagnieAssurance == null) {
        print('⚠️ Informations d\'agence manquantes');
        return;
      }

      // Préparer les données pour l'agence
      final agenceData = {
        'conducteurId': user.uid,
        'sinistreId': widget.sinistreId,
        'agenceAssurance': agenceAssurance,
        'compagnieAssurance': compagnieAssurance,
        'typeAccident': widget.accidentType,
        'dateEnvoi': DateTime.now(),
        'statut': 'recu_agence',
        'constatData': data,
        'vehiculeInfo': widget.vehiculeSelectionne,
        'source': 'constat_mobile',
      };

      // Enregistrer dans la collection pour l'agence
      await FirebaseFirestore.instance
          .collection('sinistres_agence')
          .add(agenceData);

      print('✅ Constat envoyé à l\'agence: $agenceAssurance');
    } catch (e) {
      print('❌ Erreur envoi agence: $e');
      // Ne pas bloquer la finalisation si l'envoi échoue
    }
  }

  /// 📋 Collecter toutes les données du formulaire
  Map<String, dynamic> _collectFormData() {
    final data = <String, dynamic>{};

    // Collecter toutes les valeurs des controllers
    _controllers.forEach((key, controller) {
      data[key] = controller.text;
    });

    // Ajouter les données des checkboxes et radio buttons
    data.addAll(_formData);

    return data;
  }

  /// ✅ Message de succès
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ❌ Message d'erreur
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
