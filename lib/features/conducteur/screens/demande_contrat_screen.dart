import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../../services/conducteur_auth_service.dart';
import '../../../services/debug_service.dart';
import '../../../services/cloudinary_storage_service.dart';

/// 📝 Formulaire de Demande de Contrat d'Assurance
/// 3 onglets : Infos personnelles, Véhicule, Compagnie/Agence
class DemandeContratScreen extends StatefulWidget {
  const DemandeContratScreen({super.key});

  @override
  State<DemandeContratScreen> createState() => _DemandeContratScreenState();
}

class _DemandeContratScreenState extends State<DemandeContratScreen>with TickerProviderStateMixin  {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour les infos personnelles
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _cinController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Controllers pour le véhicule
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _anneeController = TextEditingController();
  final _puissanceController = TextEditingController();
  
  // Variables de sélection
  String? _selectedTypeVehicule;
  String? _selectedCarburant;
  String? _selectedUsage;
  String? _selectedCompagnie;
  String? _selectedAgence;
  String? _selectedFormuleAssurance;

  // Formules d'assurance tunisiennes
  final List<Map<String, String>> _formulesAssurance = [
    {
      'value': 'rc',
      'label': 'Responsabilité Civile (RC)',
      'description': 'Couverture minimale obligatoire - Dommages causés aux tiers',
      'prix': '250 DT/an'
    },
    {
      'value': 'rc_vol_incendie',
      'label': 'RC + Vol + Incendie',
      'description': 'RC + Protection contre vol et incendie du véhicule',
      'prix': '450 DT/an'
    },
    {
      'value': 'tous_risques',
      'label': 'Tous Risques',
      'description': 'Couverture complète - Tous dommages matériels',
      'prix': '750 DT/an'
    },
  ];
  
  // Images
  File? _cinRectoImage;
  File? _cinVersoImage;
  File? _permisRectoImage;
  File? _permisVersoImage;
  File? _carteGriseRectoImage;
  File? _carteGriseVersoImage;
  
  // Données
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _agences = [];

  bool _isLoading = false;
  bool _isLoadingCompagnies = true;
  bool _isLoadingAgences = false;

  // Debug
  String _debugMessage = 'Initialisation...';
  bool _hasError = false;

  // Types de véhicules tunisiens
  final List<Map<String, String>> _typesVehicules = [
    {'value': 'VP', 'label': 'VP - Véhicule Particulier'},
    {'value': 'VU', 'label': 'VU - Véhicule Utilitaire'},
    {'value': 'PL', 'label': 'PL - Poids Lourds'},
    {'value': 'MOTO', 'label': 'MOTO - Motos, scooters'},
    {'value': 'TAXI', 'label': 'TAXI - Taxi individuel/collectif'},
    {'value': 'LOUEUR', 'label': 'LOUEUR - Véhicule de location'},
    {'value': 'BUS', 'label': 'BUS/MINIBUS - Transport personnes'},
    {'value': 'AMBULANCE', 'label': 'AMBULANCE - Véhicule médicalisé'},
    {'value': 'TRACTEUR', 'label': 'TRACTEUR - Routier/agricole'},
    {'value': 'ENGIN_SPECIAL', 'label': 'ENGIN SPÉCIAL - Chantier'},
    {'value': 'REMORQUE', 'label': 'REMORQUE/SEMI-REMORQUE'},
    {'value': 'AUTO_ECOLE', 'label': 'AUTO-ÉCOLE - Apprentissage'},
    {'value': 'DIPLOMATIQUE', 'label': 'VOITURE DIPLOMATIQUE'},
    {'value': 'ADMINISTRATIF', 'label': 'VÉHICULE ADMINISTRATIF'},
  ];

  final List<String> _carburants = [
    'Essence',
    'Diesel',
    'GPL',
    'Électrique',
    'Hybride',
    'Autre'
  ];

  final List<String> _usages = [
    'Personnel',
    'Professionnel',
    'Taxi',
    'Location',
    'Transport',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    print('🚀 Démarrage du chargement des compagnies...');
    _loadCompagnies();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _cinController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _emailController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeController.dispose();
    _puissanceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    // Si pas d'utilisateur Firebase, essayer les données locales
    if (user == null) {
      print('⚠️ Pas d\'utilisateur Firebase, recherche données locales...');
      await _loadDataFromLocal();
      return;
    }

    // Toujours remplir l'email en premier
    if (mounted) setState(() {
      _emailController.text = user.email ?? '';
    });

    try {
      print('🔄 Chargement données: ${user.email} (${user.uid})');
      print('🔄 DisplayName: ${user.displayName}');

      // 1. Collection 'users' (création par agent)
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('✅ Trouvé dans users: $data');
        _remplirChamps(data);
        return;
      }

      // 2. Collection 'conducteurs' par UID
      doc = await FirebaseFirestore.instance
          .collection('conducteurs')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('✅ Trouvé dans conducteurs (UID): $data');
        _remplirChamps(data);
        return;
      }

      // 3. Collection 'conducteurs' par email
      final query = await FirebaseFirestore.instance
          .collection('conducteurs')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        print('✅ Trouvé dans conducteurs (email): $data');
        _remplirChamps(data);
        return;
      }

      // 4. Vérifier SharedPreferences (système workaround)
      final prefs = await SharedPreferences.getInstance();
      print('🔍 Clés SharedPreferences: ${prefs.getKeys().where((k) => k.contains('conducteur')).toList()}');

      // 4. Chercher UNIQUEMENT les données de l'utilisateur actuel
      final userKey = 'conducteur_${user.uid}';
      String? savedData = prefs.getString(userKey);
      if (savedData != null) {
        final userData = json.decode(savedData) as Map<String, dynamic>;
        // Vérifier que l'email correspond pour éviter les données croisées
        if (userData['email'] == user.email) {
          print('✅ Trouvé dans SharedPreferences pour utilisateur actuel: $userData');
          _remplirChamps(userData);
          return;
        } else {
          print('⚠️ Email ne correspond pas - suppression données obsolètes');
          await prefs.remove(userKey);
        }
      }

      // Essayer avec l'ancienne clé
      savedData = prefs.getString('conducteur_data_${user.uid}');
      if (savedData != null) {
        final data = json.decode(savedData);
        print('✅ Trouvé dans SharedPreferences (ancienne clé): $data');
        _remplirChamps(data);
        return;
      }

      // 6. Essayer de récupérer depuis le service d'authentification
      try {
        final conducteurData = await ConducteurAuthService.getConducteurData(user.uid);
        if (conducteurData != null) {
          print('✅ Trouvé via ConducteurAuthService: $conducteurData');
          _remplirChamps(conducteurData);
          return;
        }
      } catch (e) {
        print('⚠️ Erreur ConducteurAuthService: $e');
      }

      // 7. Si rien trouvé, au moins remplir avec les infos Firebase Auth
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final parts = user.displayName!.trim().split(' ');
        setState(() {
          if (parts.isNotEmpty) {
            _prenomController.text = parts.first;
            print('🔧 Prénom depuis Firebase Auth: ${parts.first}');
          }
          if (parts.length > 1) {
            _nomController.text = parts.sublist(1).join(' ');
            print('🔧 Nom depuis Firebase Auth: ${parts.sublist(1).join(' ')}');
          }
        });
        print('✅ Auto-remplissage depuis Firebase Auth displayName: ${user.displayName}');
      }

      print('⚠️ Données limitées pour ${user.email}');

    } catch (e) {
      print('❌ Erreur chargement données: $e');
      // En cas d'erreur, au moins garder l'email
      if (mounted) setState(() {
        _emailController.text = user.email ?? '';
      });
    }

    // Toujours compléter les données manquantes à la fin
    Future.delayed(const Duration(milliseconds: 100), () {
      _completerDonneesManquantes();
    });
  }

  /// 🔧 Compléter les données manquantes UNIQUEMENT si elles sont vides
  void _completerDonneesManquantes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      // S'assurer que l'email est rempli avec l'email de l'utilisateur connecté
      if (_emailController.text.isEmpty && user.email != null) {
        _emailController.text = user.email!;
      }

      // NE PAS remplir automatiquement les autres champs avec des données statiques
      // L'utilisateur doit saisir ses vraies informations

      // Seulement suggérer le format téléphone si complètement vide
      if (_telephoneController.text.isEmpty) {
        _telephoneController.text = '+216 ';
      }
    });

    print('🔧 Email auto-rempli: "${_emailController.text}"');
    print('🔧 Autres champs laissés vides pour saisie utilisateur');
  }

  void _remplirChamps(Map<String, dynamic> data) {
    setState(() {
      // Gérer le cas où le nom complet est dans le champ prenom
      String nom = data['nom'] ?? data['lastName'] ?? '';
      String prenom = data['prenom'] ?? data['firstName'] ?? '';

      // Si nom est vide mais prenom contient plusieurs mots, séparer
      if (nom.isEmpty && prenom.isNotEmpty && prenom.contains(' ')) {
        final parts = prenom.split(' ');
        prenom = parts.first;
        nom = parts.sublist(1).join(' ');
        print('🔧 Séparation nom/prénom: "$prenom" / "$nom"');
      }

      _nomController.text = nom;
      _prenomController.text = prenom;
      _cinController.text = data['cin'] ?? '';
      _telephoneController.text = data['telephone'] ?? data['phone'] ?? '';

      // Gérer l'adresse (string ou objet)
      String adresse = '';
      if (data['adresse'] != null) {
        adresse = data['adresse'];
      } else if (data['address'] != null) {
        final addr = data['address'];
        if (addr is String) {
          adresse = addr;
        } else if (addr is Map) {
          final parts = [
            addr['street'] ?? '',
            addr['city'] ?? '',
            addr['postalCode'] ?? '',
            addr['governorate'] ?? ''
          ].where((s) => s.isNotEmpty).join(', ');
          adresse = parts;
        }
      }
      _adresseController.text = adresse;
    });

    print('✅ Auto-remplissage complet:');
    print('  - Nom: "${_nomController.text}"');
    print('  - Prénom: "${_prenomController.text}"');
    print('  - Email: "${_emailController.text}"');
    print('  - Téléphone: "${_telephoneController.text}"');
    print('  - CIN: "${_cinController.text}"');
    print('  - Adresse: "${_adresseController.text}"');

    // Compléter automatiquement les champs vides
    _completerDonneesManquantes();
  }

  Future<void> _loadDataFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('conducteur_')).toList();

      print('🔍 Recherche données locales: ${keys.length} clés trouvées');

      for (String key in keys) {
        final dataString = prefs.getString(key);
        if (dataString != null) {
          final userData = json.decode(dataString) as Map<String, dynamic>;
          print('📊 Données trouvées dans $key: $userData');

          // Utiliser les premières données trouvées
          _remplirChamps(userData);
          _emailController.text = userData['email'] ?? '';
          print('✅ Auto-remplissage depuis données locales');

          // Compléter les données manquantes
          Future.delayed(const Duration(milliseconds: 100), () {
            _completerDonneesManquantes();
          });
          return;
        }
      }

      print('⚠️ Aucune donnée locale trouvée');

      // Même sans données locales, essayer de compléter avec les infos disponibles
      Future.delayed(const Duration(milliseconds: 100), () {
        _completerDonneesManquantes();
      });
    } catch (e) {
      print('❌ Erreur chargement données locales: $e');

      // En cas d'erreur, essayer quand même de compléter
      Future.delayed(const Duration(milliseconds: 100), () {
        _completerDonneesManquantes();
      });
    }
  }

  Future<void> _debugUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Aucun utilisateur connecté');
      return;
    }

    print('=== DEBUG DONNÉES UTILISATEUR ===');
    print('UID: ${user.uid}');
    print('Email: ${user.email}');
    print('DisplayName: ${user.displayName}');

    // Vérifier Firebase
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      print('Firebase users: ${userDoc.exists ? userDoc.data() : 'NON TROUVÉ'}');

      final conducteurDoc = await FirebaseFirestore.instance.collection('conducteurs').doc(user.uid).get();
      print('Firebase conducteurs: ${conducteurDoc.exists ? conducteurDoc.data() : 'NON TROUVÉ'}');
    } catch (e) {
      print('Erreur Firebase: $e');
    }

    // Vérifier SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.contains('conducteur')).toList();
      print('Clés SharedPreferences: $keys');

      for (String key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          final userData = json.decode(data);
          print('$key: $userData');
        }
      }
    } catch (e) {
      print('Erreur SharedPreferences: $e');
    }

    print('=== FIN DEBUG ===');
  }

  Future<void> _loadCompagnies() async {
    if (mounted) setState(() {
      _debugMessage = 'Connexion à Firebase...';
      _hasError = false;
    });

    try {
      // Test simple : charger toutes les compagnies
      if (mounted) setState(() {
        _debugMessage = 'Chargement collection compagnies...';
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('compagnies')
          .get();

      setState(() {
        _debugMessage = 'Trouvé ${snapshot.docs.length} compagnies';
      });

      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() {
          _debugMessage = 'AUCUNE compagnie trouvée dans Firebase!';
          _hasError = true;
          _isLoadingCompagnies = false;
        });
        return;
      }

      // Mapper les données
      final compagniesData = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList();

      setState(() {
        _compagnies = compagniesData;
        _isLoadingCompagnies = false;
        _debugMessage = 'SUCCESS: ${_compagnies.length} compagnies chargées!';
      });

      // Afficher les compagnies dans la console
      print('🏢 COMPAGNIES CHARGÉES:');
      for (var comp in _compagnies) {
        print('🏢 ${comp['nom']} (${comp['id']})');
      }

    } catch (e) {
      if (mounted) setState(() {
        _debugMessage = 'ERREUR: $e';
        _hasError = true;
        _isLoadingCompagnies = false;
      });
      print('❌ Erreur: $e');
    }
  }

  Future<void> _loadAgences(String compagnieId) async {
    if (mounted) setState(() {
      _isLoadingAgences = true;
    });

    try {
      print('🔄 Chargement des agences pour compagnie: $compagnieId');

      // Test 1: Essayer avec compagnieId
      final snapshot = await FirebaseFirestore.instance
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      print('📊 Avec compagnieId: ${snapshot.docs.length} agences trouvées');

      // Test 2: Si aucune, essayer avec statut
      final finalSnapshot = snapshot.docs.isNotEmpty
          ? snapshot
          : await FirebaseFirestore.instance
              .collection('agences')
              .where('statut', isEqualTo: 'actif')
              .get();

      print('📊 Final: ${finalSnapshot.docs.length} agences chargées');

      setState(() {
        _agences = finalSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return <String, dynamic>{
            'id': doc.id,
            ...data,
          };
        }).toList();
        _selectedAgence = null; // Reset agence selection
        _isLoadingAgences = false;
      });

      // Debug: afficher les agences chargées
      for (var agence in _agences) {
        print('🏪 Agence: ${agence['nom']} - ${agence['ville'] ?? 'N/A'} (ID: ${agence['id']})');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des agences: $e');
      if (mounted) setState(() {
        _isLoadingAgences = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Demande de Contrat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [

          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              print('🔄 Rechargement forcé des données');
              _loadUserData();
              _loadCompagnies();
            },
            tooltip: 'Recharger',
          ),

        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.person),
              text: 'Infos Personnelles',
            ),
            Tab(
              icon: Icon(Icons.directions_car),
              text: 'Véhicule',
            ),
            Tab(
              icon: Icon(Icons.business),
              text: 'Compagnie',
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInfosPersonnellesTab(),
            _buildVehiculeTab(),
            _buildCompagnieTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_tabController.index > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _tabController.animateTo(_tabController.index - 1);
                  },
                  child: const Text('Précédent'),
                ),
              ),
            if (_tabController.index > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleNextOrSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_tabController.index == 2 ? 'Envoyer Demande' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfosPersonnellesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 Informations Personnelles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Nom et Prénom
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _nomController,
                  label: 'Nom *',
                  icon: Icons.person,
                  hintText: 'Ex: Ben Ahmed',
                  validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _prenomController,
                  label: 'Prénom *',
                  icon: Icons.person_outline,
                  hintText: 'Ex: Mohamed',
                  validator: (value) => value?.isEmpty == true ? 'Prénom requis' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CIN
          _buildTextField(
            controller: _cinController,
            label: 'Numéro CIN *',
            icon: Icons.credit_card,
            hintText: 'Ex: 12345678',
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty == true ? 'CIN requis' : null,
          ),

          const SizedBox(height: 16),

          // Téléphone et Email
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _telephoneController,
                  label: 'Téléphone *',
                  icon: Icons.phone,
                  hintText: 'Ex: +216 20 123 456',
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty == true ? 'Téléphone requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _emailController,
                  label: 'Email *',
                  icon: Icons.email,
                  hintText: 'Ex: mohamed@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value?.isEmpty == true ? 'Email requis' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Adresse
          _buildTextField(
            controller: _adresseController,
            label: 'Adresse *',
            icon: Icons.location_on,
            hintText: 'Ex: 15 Rue de la République, Tunis',
            maxLines: 2,
            validator: (value) => value?.isEmpty == true ? 'Adresse requise' : null,
          ),

          const SizedBox(height: 24),

          // Upload CIN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '📄 Documents CIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageUpload(
                        title: 'CIN Recto *',
                        image: _cinRectoImage,
                        onTap: () => _pickImage('cin_recto'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageUpload(
                        title: 'CIN Verso *',
                        image: _cinVersoImage,
                        onTap: () => _pickImage('cin_verso'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Upload Permis
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[50]!, Colors.green[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.drive_eta, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '🚗 Permis de Conduire',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageUpload(
                        title: 'Permis Recto *',
                        image: _permisRectoImage,
                        onTap: () => _pickImage('permis_recto'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageUpload(
                        title: 'Permis Verso *',
                        image: _permisVersoImage,
                        onTap: () => _pickImage('permis_verso'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚗 Informations Véhicule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Immatriculation
          _buildTextField(
            controller: _immatriculationController,
            label: 'Immatriculation *',
            icon: Icons.confirmation_number,
            hintText: 'Ex: 175 TU 5687',
            validator: (value) => value?.isEmpty == true ? 'Immatriculation requise' : null,
          ),

          const SizedBox(height: 16),

          // Marque et Modèle
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _marqueController,
                  label: 'Marque *',
                  icon: Icons.branding_watermark,
                  hintText: 'Ex: Renault',
                  validator: (value) => value?.isEmpty == true ? 'Marque requise' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _modeleController,
                  label: 'Modèle *',
                  icon: Icons.model_training,
                  hintText: 'Ex: Clio 4',
                  validator: (value) => value?.isEmpty == true ? 'Modèle requis' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Année et Puissance
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _anneeController,
                  label: 'Année *',
                  icon: Icons.calendar_today,
                  hintText: 'Ex: 2021',
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Année requise' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _puissanceController,
                  label: 'Puissance (CV) *',
                  icon: Icons.speed,
                  hintText: 'Ex: 5',
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Puissance requise' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Type de véhicule
          _buildDropdownField(
            label: 'Type de véhicule *',
            icon: Icons.category,
            hintText: 'Sélectionnez le type',
            value: _selectedTypeVehicule,
            items: _typesVehicules.map((type) => DropdownMenuItem<String>(
              value: type['value'],
              child: Text(type['label']!),
            )).toList(),
            onChanged: (value) => setState(() => _selectedTypeVehicule = value),
          ),

          const SizedBox(height: 16),

          // Carburant et Usage
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Carburant *',
                  icon: Icons.local_gas_station,
                  hintText: 'Type de carburant',
                  value: _selectedCarburant,
                  items: _carburants.map((carburant) => DropdownMenuItem<String>(
                    value: carburant,
                    child: Text(carburant),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedCarburant = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  label: 'Usage *',
                  icon: Icons.work,
                  hintText: 'Usage du véhicule',
                  value: _selectedUsage,
                  items: _usages.map((usage) => DropdownMenuItem<String>(
                    value: usage,
                    child: Text(usage),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedUsage = value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Documents véhicule
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[50]!, Colors.orange[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '📄 Carte Grise du Véhicule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageUpload(
                        title: 'Carte Grise Recto *',
                        image: _carteGriseRectoImage,
                        onTap: () => _pickImage('carte_grise_recto'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageUpload(
                        title: 'Carte Grise Verso *',
                        image: _carteGriseVersoImage,
                        onTap: () => _pickImage('carte_grise_verso'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompagnieTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏢 Sélection Compagnie et Agence',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Widget de Debug
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hasError ? Colors.red[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasError ? Colors.red[300]! : Colors.blue[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔍 DEBUG INFO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _hasError ? Colors.red[700] : Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: $_debugMessage',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Loading: $_isLoadingCompagnies',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Compagnies: ${_compagnies.length}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (_compagnies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Première compagnie:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_compagnies.first['nom']} (${_compagnies.first['id']})'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Compagnie
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.purple[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: Colors.purple[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '🏢 Sélection Compagnie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoadingCompagnies
                    ? Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[100],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Chargement des compagnies...'),
                            ],
                          ),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          print('🎨 DROPDOWN COMPAGNIES - Rendu du dropdown');
                          print('🎨 _compagnies.length = ${_compagnies.length}');
                          print('🎨 _isLoadingCompagnies = $_isLoadingCompagnies');
                          print('🎨 _selectedCompagnie = $_selectedCompagnie');

                          return _buildDropdownField(
                            label: 'Compagnie d\'assurance *',
                            icon: Icons.business,
                            hintText: _compagnies.isEmpty
                                ? 'Aucune compagnie disponible (${_compagnies.length})'
                                : 'Choisissez votre compagnie (${_compagnies.length} disponibles)',
                            value: _selectedCompagnie,
                            items: _compagnies.map((compagnie) {
                              print('🎨 Création item: ${compagnie['nom']} (${compagnie['id']})');
                              return DropdownMenuItem<String>(
                                value: compagnie['id'] as String,
                                child: Text(
                                  compagnie['nom'] ?? 'Compagnie',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              print('🎨 Compagnie sélectionnée: $value');
                              if (mounted) setState(() {
                                _selectedCompagnie = value;
                                _selectedAgence = null;
                                _agences.clear();
                              });
                              if (value != null) {
                                _loadAgences(value);
                              }
                            },
                          );
                        },
                      ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Agence
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[50]!, Colors.teal[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.teal[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_city, color: Colors.teal[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '🏪 Sélection Agence',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoadingAgences
                    ? Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[100],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Chargement des agences...'),
                            ],
                          ),
                        ),
                      )
                    : _buildDropdownField(
                        label: 'Agence *',
                        icon: Icons.location_city,
                        hintText: _selectedCompagnie == null
                            ? 'Sélectionnez d\'abord une compagnie'
                            : _agences.isEmpty
                                ? 'Aucune agence disponible'
                                : 'Choisissez votre agence',
                        value: _selectedAgence,
                        items: _agences.map((agence) => DropdownMenuItem<String>(
                          value: agence['id'] as String,
                          child: Text(
                            '${agence['nom']} - ${agence['ville'] ?? ''}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          if (_selectedCompagnie != null) {
                            setState(() => _selectedAgence = value);
                          }
                        },
                      ),
                if (_selectedCompagnie == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Veuillez d\'abord sélectionner une compagnie',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Formule d'assurance
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.purple[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.purple[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '🛡️ Formule d\'Assurance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Liste des formules
                ..._formulesAssurance.map((formule) {
                  final isSelected = _selectedFormuleAssurance == formule['value'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        if (mounted) setState(() {
                          _selectedFormuleAssurance = formule['value'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.purple[100] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.purple[400]! : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? Colors.purple[700] : Colors.grey[400],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formule['label']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isSelected ? Colors.purple[700] : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formule['description']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.purple[700] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                formule['prix']!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Résumé de la demande
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[50]!, Colors.indigo[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.indigo[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo[700],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.summarize,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '📋 Résumé de votre demande',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildSummaryRow(
                  icon: Icons.person,
                  label: 'Conducteur',
                  value: '${_prenomController.text} ${_nomController.text}',
                  color: Colors.blue,
                ),
                _buildSummaryRow(
                  icon: Icons.directions_car,
                  label: 'Véhicule',
                  value: '${_marqueController.text} ${_modeleController.text}',
                  color: Colors.green,
                ),
                _buildSummaryRow(
                  icon: Icons.category,
                  label: 'Type',
                  value: _selectedTypeVehicule ?? 'Non sélectionné',
                  color: Colors.orange,
                ),
                _buildSummaryRow(
                  icon: Icons.confirmation_number,
                  label: 'Immatriculation',
                  value: _immatriculationController.text.isNotEmpty
                      ? _immatriculationController.text
                      : 'Non renseignée',
                  color: Colors.purple,
                ),
                if (_selectedCompagnie != null && _compagnies.isNotEmpty)
                  _buildSummaryRow(
                    icon: Icons.business,
                    label: 'Compagnie',
                    value: _compagnies.firstWhere(
                      (c) => c['id'] == _selectedCompagnie,
                      orElse: () => {'nom': 'Inconnue'}
                    )['nom'],
                    color: Colors.indigo,
                  ),
                if (_selectedAgence != null && _agences.isNotEmpty)
                  _buildSummaryRow(
                    icon: Icons.location_city,
                    label: 'Agence',
                    value: _agences.firstWhere(
                      (a) => a['id'] == _selectedAgence,
                      orElse: () => {'nom': 'Inconnue'}
                    )['nom'],
                    color: Colors.teal,
                  ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre demande sera traitée par l\'agence sélectionnée dans les plus brefs délais.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: Colors.blue[700],
            size: 20,
          ),
          labelStyle: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: Colors.blue[700],
            size: 20,
          ),
          labelStyle: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: Colors.white,
        items: items,
        onChanged: onChanged,
        validator: (value) => value == null ? '$label requis' : null,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
        isExpanded: true,
        menuMaxHeight: 300,
      ),
    );
  }

  Widget _buildImageUpload({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: image != null ? Colors.green[400]! : Colors.blue[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.add_a_photo,
                      size: 32,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuyez pour ajouter',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case 'cin_recto':
            _cinRectoImage = File(pickedFile.path);
            break;
          case 'cin_verso':
            _cinVersoImage = File(pickedFile.path);
            break;
          case 'permis_recto':
            _permisRectoImage = File(pickedFile.path);
            break;
          case 'permis_verso':
            _permisVersoImage = File(pickedFile.path);
            break;
          case 'carte_grise_recto':
            _carteGriseRectoImage = File(pickedFile.path);
            break;
          case 'carte_grise_verso':
            _carteGriseVersoImage = File(pickedFile.path);
            break;
        }
      });
    }
  }

  void _handleNextOrSubmit() {
    if (_tabController.index < 2) {
      // Validation de l'onglet actuel
      if (_validateCurrentTab()) {
        _tabController.animateTo(_tabController.index + 1);
      }
    } else {
      // Soumission finale
      _submitDemande();
    }
  }

  bool _validateCurrentTab() {
    switch (_tabController.index) {
      case 0: // Infos personnelles
        return _nomController.text.isNotEmpty &&
               _prenomController.text.isNotEmpty &&
               _cinController.text.isNotEmpty &&
               _telephoneController.text.isNotEmpty &&
               _emailController.text.isNotEmpty &&
               _adresseController.text.isNotEmpty &&
               _cinRectoImage != null &&
               _cinVersoImage != null;
      case 1: // Véhicule
        return _immatriculationController.text.isNotEmpty &&
               _marqueController.text.isNotEmpty &&
               _modeleController.text.isNotEmpty &&
               _selectedTypeVehicule != null;
      case 2: // Compagnie
        return _selectedCompagnie != null &&
               _selectedAgence != null &&
               _selectedFormuleAssurance != null;
      default:
        return false;
    }
  }

  Future<void> _submitDemande() async {
    if (!_validateCurrentTab()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted) setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Gérer le mode offline
      String conducteurId;
      String conducteurEmail;

      if (user != null) {
        // Mode Firebase normal
        conducteurId = user.uid;
        conducteurEmail = user.email ?? _emailController.text.trim();
        print('📤 Envoi en mode Firebase: $conducteurId');
      } else {
        // Mode offline - utiliser les données locales
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((k) => k.startsWith('conducteur_')).toList();

        if (keys.isEmpty) {
          throw Exception('Aucune donnée utilisateur trouvée');
        }

        final dataString = prefs.getString(keys.first);
        if (dataString == null) {
          throw Exception('Données utilisateur corrompues');
        }

        final userData = json.decode(dataString) as Map<String, dynamic>;

        // Utiliser l'UID de l'utilisateur si disponible, sinon créer un ID cohérent
        if (userData['uid'] != null) {
          conducteurId = userData['uid'];
        } else {
          // Créer un ID basé sur l'email pour la cohérence
          conducteurId = 'offline_${_emailController.text.trim().hashCode.abs()}';
        }

        conducteurEmail = userData['email'] ?? _emailController.text.trim();
        print('📤 Envoi en mode offline: $conducteurId ($conducteurEmail)');
      }

      // Générer un numéro de demande unique
      final numeroDemande = 'D-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // Récupérer les noms de compagnie et agence
      final compagnieNom = _compagnies.firstWhere(
        (c) => c['id'] == _selectedCompagnie,
        orElse: () => {'nom': 'Inconnue'},
      )['nom'];

      final agenceNom = _agences.firstWhere(
        (a) => a['id'] == _selectedAgence,
        orElse: () => {'nom': 'Inconnue'},
      )['nom'];

      // Upload des images d'abord
      Map<String, String> imageUrls = {};
      try {
        print('📸 Upload des images...');

        if (_cinRectoImage != null) {
          final url = await _uploadImageToFirebase(_cinRectoImage!, 'cin_recto');
          if (url != null) imageUrls['cinRectoUrl'] = url;
        }

        if (_cinVersoImage != null) {
          final url = await _uploadImageToFirebase(_cinVersoImage!, 'cin_verso');
          if (url != null) imageUrls['cinVersoUrl'] = url;
        }

        if (_permisRectoImage != null) {
          final url = await _uploadImageToFirebase(_permisRectoImage!, 'permis_recto');
          if (url != null) imageUrls['permisRectoUrl'] = url;
        }

        if (_permisVersoImage != null) {
          final url = await _uploadImageToFirebase(_permisVersoImage!, 'permis_verso');
          if (url != null) imageUrls['permisVersoUrl'] = url;
        }

        if (_carteGriseRectoImage != null) {
          final url = await _uploadImageToFirebase(_carteGriseRectoImage!, 'carte_grise_recto');
          if (url != null) imageUrls['carteGriseRectoUrl'] = url;
        }

        if (_carteGriseVersoImage != null) {
          final url = await _uploadImageToFirebase(_carteGriseVersoImage!, 'carte_grise_verso');
          if (url != null) imageUrls['carteGriseVersoUrl'] = url;
        }

        print('✅ ${imageUrls.length} images uploadées');
      } catch (e) {
        print('⚠️ Erreur upload images: $e');
      }

      // Créer la demande dans Firestore
      await FirebaseFirestore.instance.collection('demandes_contrats').add({
        'numero': numeroDemande,
        'conducteurId': conducteurId,
        'conducteurEmail': conducteurEmail,
        'statut': 'en_attente',
        'dateCreation': FieldValue.serverTimestamp(),
        'modeEnvoi': user != null ? 'firebase' : 'offline',

        // Infos personnelles (format plat pour faciliter l'affichage)
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'cin': _cinController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'email': _emailController.text.trim(),
        'adresse': _adresseController.text.trim(),

        // Infos véhicule (format plat)
        'immatriculation': _immatriculationController.text.trim(),
        'marque': _marqueController.text.trim(),
        'modele': _modeleController.text.trim(),
        'annee': _anneeController.text.trim(),
        'puissance': _puissanceController.text.trim(),
        'typeVehicule': _selectedTypeVehicule,
        'carburant': _selectedCarburant,
        'usage': _selectedUsage,

        // Compagnie et agence avec noms
        'compagnieId': _selectedCompagnie,
        'compagnieNom': compagnieNom,
        'agenceId': _selectedAgence,
        'agenceNom': agenceNom,

        // Formule d'assurance
        'formuleAssurance': _selectedFormuleAssurance,
        'formuleAssuranceLabel': _formulesAssurance.firstWhere(
          (f) => f['value'] == _selectedFormuleAssurance,
          orElse: () => {'label': 'Non spécifiée'},
        )['label'],

        // Métadonnées pour le workflow
        'agentId': null,
        'agentNom': null,
        'motifRejet': null,
        'dateModification': FieldValue.serverTimestamp(),

        // URLs des images uploadées
        ...imageUrls,

        // Documents uploadés (pour compatibilité)
        'documents': {
          'cin_recto_uploaded': _cinRectoImage != null,
          'cin_verso_uploaded': _cinVersoImage != null,
          'permis_recto_uploaded': _permisRectoImage != null,
          'permis_verso_uploaded': _permisVersoImage != null,
          'carte_grise_recto_uploaded': _carteGriseRectoImage != null,
          'carte_grise_verso_uploaded': _carteGriseVersoImage != null,
        },
      });

      print('✅ Demande $numeroDemande sauvegardée avec succès');

      // Succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande $numeroDemande envoyée avec succès !'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Retourner au dashboard
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/conducteur-dashboard',
        (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  /// 📸 Upload une image vers Firebase Storage
  Future<String?> _uploadImageToFirebase(File imageFile, String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Utiliser CloudinaryStorageService si disponible
      final url = await CloudinaryStorageService.uploadImage(
        imageFile: imageFile,
        publicId: '${type}_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
        folder: 'demandes_contrats/${user.uid}',
      );

      if (url != null) {
        print('✅ Image $type uploadée: $url');
        return url;
      } else {
        print('❌ Échec upload $type');
        return null;
      }
    } catch (e) {
      print('❌ Erreur upload $type: $e');
      return null;
    }
  }
}

