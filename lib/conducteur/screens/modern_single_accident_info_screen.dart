import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../../services/accident_session_complete_service.dart';
import '../../services/conducteur_data_service.dart';
import '../../services/draft_service.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/collaborative_session_state_service.dart';
import '../../models/accident_session_complete.dart';
import 'accident_form_step2_vehicules.dart';
import 'accident_form_step3_assurance.dart';
import 'accident_form_step4_circonstances.dart';
import 'signature_screen.dart';
import 'modern_collaborative_sketch_screen.dart';
import 'accident_form_step6_signatures.dart';
import 'modern_collaborative_sketch_screen.dart';
import '../../models/collaborative_session_model.dart';
import 'collaborative_session_dashboard.dart';
import 'session_dashboard_screen.dart';

/// 🚗 Écran moderne pour déclaration d'accident (simple et collaboratif)
class ModernSingleAccidentInfoScreen extends StatefulWidget {
  final String typeAccident;
  final CollaborativeSession? session;
  final bool isCollaborative;
  final String? roleVehicule;
  final bool isCreator; // Nouveau : indique si c'est le créateur de la session
  final bool isRegisteredUser; // Nouveau : indique si l'utilisateur est inscrit

  const ModernSingleAccidentInfoScreen({
    super.key,
    required this.typeAccident,
    this.session,
    this.isCollaborative = false,
    this.roleVehicule,
    this.isCreator = false,
    this.isRegisteredUser = true,
  });

  @override
  State<ModernSingleAccidentInfoScreen> createState() => _ModernSingleAccidentInfoScreenState();
}

class _ModernSingleAccidentInfoScreenState extends State<ModernSingleAccidentInfoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Contrôleurs pour les champs
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _lieuController = TextEditingController();
  final _detailsBlessesController = TextEditingController();

  // Contrôleurs pour les informations auto-remplies
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _compagnieController = TextEditingController();
  final _agenceController = TextEditingController();
  final _numeroContratController = TextEditingController();

  // Contrôleurs pour le conducteur
  final _nomConducteurController = TextEditingController();
  final _prenomConducteurController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _circonstancesController = TextEditingController();

  // Contrôleurs pour les observations (ÉTAPE 4)
  final _observationsController = TextEditingController();
  final _remarquesController = TextEditingController();

  // Variables d'état
  DateTime _dateAccident = DateTime.now();
  TimeOfDay _heureAccident = TimeOfDay.now();
  bool _blesses = false;
  Map<String, dynamic>? _lieuGps;
  List<Temoin> _temoins = [];

  // Données du conducteur (remplissage automatique)
  Map<String, dynamic>? _donneesConducteur;
  bool _donneesChargees = false;

  // Gestion conducteur/propriétaire
  bool _proprietaireConduit = true; // Le propriétaire conduit-il ?
  bool _conducteurAPermis = true; // Le conducteur a-t-il un permis ?
  String? _photoPermisRectoUrl;
  String? _photoPermisVersoUrl;
  File? _photoPermisRecto;
  File? _photoPermisVerso;
  final ImagePicker _picker = ImagePicker();

  // Variables pour la sélection de véhicule
  String? _vehiculeSelectionneId;
  Map<String, dynamic>? _vehiculeSelectionne;

  // Variables pour le point de choc et dégâts (ÉTAPE 3)
  String _pointChocSelectionne = '';
  List<String> _degatsSelectionnes = [];
  List<String> _photosDegatUrls = [];

  // Variables pour le croquis (ÉTAPE 6)
  List<Map<String, dynamic>> _croquisData = [];
  bool _croquisExiste = false;
  String? _croquisImageUrl;

  // Variables pour le mode collaboratif
  bool get _estCreateur => widget.isCreator;
  bool get _estUtilisateurInscrit => widget.isRegisteredUser;
  bool get _estModeCollaboratif => widget.isCollaborative;
  Map<String, dynamic>? _donneesCommunes; // Données partagées par le créateur
  final List<String> _pointsChocDisponibles = [
    'Avant gauche', 'Avant centre', 'Avant droit',
    'Côté gauche avant', 'Côté gauche arrière',
    'Côté droit avant', 'Côté droit arrière',
    'Arrière gauche', 'Arrière centre', 'Arrière droit',
    'Toit', 'Dessous'
  ];
  final List<String> _degatsDisponibles = [
    'Rayure légère', 'Rayure profonde', 'Bosselure',
    'Fissure', 'Cassure', 'Déformation',
    'Peinture écaillée', 'Vitre brisée', 'Phare cassé',
    'Pare-chocs endommagé', 'Portière enfoncée'
  ];

  // Variables pour les circonstances (ÉTAPE 5)
  List<int> _circonstancesSelectionnees = [];

  // Variables pour la signature (ÉTAPE 6)
  Uint8List? _signatureData;

  // Variables pour la sauvegarde automatique
  String? _sessionId;
  Timer? _autoSaveTimer;

  // 🎯 Système de progression par étapes (8 étapes) - Structure du matin
  int _etapeActuelle = 2; // Commencer à l'étape 2 (Informations Générales)
  final int _nombreEtapes = 8;

  // Validation des étapes - Nouvelle structure
  Map<int, bool> _etapesValidees = {
    1: true,  // Étape 1 sautée (réservée pour sélection type accident)
    2: false, // Informations générales
    3: false, // Point de choc + Dégâts
    4: false, // Observations
    5: false, // Circonstances (étape séparée)
    6: false, // Croquis
    7: false, // Signature
    8: false, // Résumé Complet
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _initialiserFormulaire();
    _initialiserSession();

    // 🛡️ Utiliser addPostFrameCallback pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerDonneesConducteur();

      // Charger les données selon le mode
      if (_estModeCollaboratif) {
        _chargerDonneesCollaboratives();
        // 🆕 Marquer le formulaire comme "en cours" dès l'ouverture
        _mettreAJourEtatFormulaire(FormulaireStatus.en_cours);
      } else {
        _recupererBrouillonExistant();
      }

      _obtenirPositionActuelle();
      _chargerCroquisDepuisFirebase();

      _animationController.forward();
    });
  }

  @override
  void dispose() {
    // Sauvegarde automatique en sortie pour les sessions collaboratives
    if (_estModeCollaboratif && widget.session?.id != null) {
      _sauvegardeAutomatiqueEnSortie();
    }

    _animationController.dispose();
    _autoSaveTimer?.cancel();
    _dateController.dispose();
    _heureController.dispose();
    _lieuController.dispose();
    _detailsBlessesController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _compagnieController.dispose();
    _agenceController.dispose();
    _numeroContratController.dispose();
    _nomConducteurController.dispose();
    _prenomConducteurController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  /// 📝 Remplir automatiquement tous les champs depuis les données
  void _remplirChampsAutomatiquement(Map<String, dynamic> donnees) {
    // Informations véhicule
    final vehicule = donnees['vehicule'] ?? {};
    _immatriculationController.text = vehicule['numeroImmatriculation'] ?? '';
    _marqueController.text = vehicule['marque'] ?? '';
    _modeleController.text = vehicule['modele'] ?? '';

    // Informations assurance
    final assurance = donnees['assurance'] ?? {};
    _compagnieController.text = assurance['compagnieNom'] ?? '';
    _agenceController.text = assurance['agenceNom'] ?? '';
    _numeroContratController.text = assurance['numeroPolice'] ?? '';

    // Informations conducteur (propriétaire par défaut)
    final conducteur = donnees['conducteur'] ?? {};
    _nomConducteurController.text = conducteur['nom'] ?? '';
    _prenomConducteurController.text = conducteur['prenom'] ?? '';
    _telephoneController.text = conducteur['telephone'] ?? '';
    _adresseController.text = conducteur['adresse'] ?? '';

    print('✅ Champs remplis automatiquement:');
    print('   - Véhicule: ${_marqueController.text} ${_modeleController.text}');
    print('   - Immatriculation: ${_immatriculationController.text}');
    print('   - Compagnie: ${_compagnieController.text}');
    print('   - Conducteur: ${_nomConducteurController.text} ${_prenomConducteurController.text}');
  }

  void _initialiserFormulaire() {
    _dateController.text = '${_dateAccident.day}/${_dateAccident.month}/${_dateAccident.year}';
    _heureController.text = '${_heureAccident.hour}:${_heureAccident.minute.toString().padLeft(2, '0')}';
  }

  /// 📊 Charger toutes les données du conducteur automatiquement
  Future<void> _chargerDonneesConducteur() async {
    try {
      print('🔄 Chargement données conducteur...');

      final donnees = await ConducteurDataService.recupererDonneesConducteur();

      if (donnees != null && mounted) {
        setState(() {
          _donneesConducteur = donnees;
          _donneesChargees = true;

          // Remplir automatiquement tous les champs
          _remplirChampsAutomatiquement(donnees);
        });

        print('✅ Données conducteur chargées:');
        print('   - Nom: ${donnees['conducteur']?['nom']} ${donnees['conducteur']?['prenom']}');
        print('   - Véhicule: ${donnees['vehicule']?['marque']} ${donnees['vehicule']?['modele']}');
        print('   - Compagnie: ${donnees['assurance']?['compagnieNom']}');
        print('   - Agence: ${donnees['assurance']?['agenceNom']}');
        print('   - Contrat actif: ${donnees['contrat']?['estActif']}');

        // Afficher un message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Informations chargées automatiquement depuis votre contrat',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('❌ Aucune donnée trouvée pour le conducteur');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Aucun contrat trouvé. Veuillez remplir manuellement.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCouleurTypeAccident().withOpacity(0.8),
              _getCouleurTypeAccident(),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderne
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFormulaire(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCouleurTypeAccident() {
    switch (widget.typeAccident) {
      case 'Sortie de route':
        return Colors.orange;
      case 'Collision avec objet fixe':
        return Colors.red;
      case 'Accident avec piéton ou cycliste':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getIconeTypeAccident() {
    switch (widget.typeAccident) {
      case 'Sortie de route':
        return '🛣️';
      case 'Collision avec objet fixe':
        return '🛑';
      case 'Accident avec piéton ou cycliste':
        return '🚴‍♂️';
      default:
        return '🚗';
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Bouton retour et titre
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Déclaration d\'accident',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Bouton de test pour recharger les données
                        IconButton(
                          onPressed: _chargerDonneesConducteur,
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Recharger les données',
                        ),
                      ],
                    ),
                    Text(
                      widget.typeAccident,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Icône du type
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    _getIconeTypeAccident(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Message informatif
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getMessageInfo(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMessageInfo() {
    switch (widget.typeAccident) {
      case 'Sortie de route':
        return 'Déclaration simplifiée pour sortie de route - Aucun autre conducteur à inviter';
      case 'Collision avec objet fixe':
        return 'Collision avec un objet fixe - Processus de déclaration individuel';
      case 'Accident avec piéton ou cycliste':
        return 'Accident impliquant un piéton ou cycliste - Informations détaillées requises';
      default:
        return 'Déclaration d\'accident individuelle';
    }
  }

  // 🎯 Méthodes de gestion des étapes
  void _allerEtapeSuivante() {
    if (_etapeActuelle < _nombreEtapes && _validerEtapeActuelle()) {
      // Sauvegarder avant de passer à l'étape suivante
      _sauvegarderAutomatiquement();

      // Si on quitte l'étape croquis (6), recharger les données du croquis
      if (_etapeActuelle == 6) {
        _chargerCroquisDepuisFirebase();
      }

      if (mounted) {
        setState(() {
          _etapesValidees[_etapeActuelle] = true;
          _etapeActuelle++;
        });
      }
    }
  }

  void _allerEtapePrecedente() {
    if (_etapeActuelle > 2) { // Commencer à l'étape 2, pas 1
      if (mounted) {
        setState(() {
          _etapeActuelle--;
        });
      }
    }
  }

  void _allerAEtape(int etape) {
    if (etape >= 1 && etape <= _nombreEtapes) {
      if (mounted) {
        setState(() {
          _etapeActuelle = etape;
        });

        // Si on va à l'étape résumé (8), s'assurer que le croquis est chargé
        if (etape == 8) {
          Future.delayed(Duration.zero, () {
            _chargerCroquisDepuisFirebase();
          });
        }
      }
    }
  }

  bool _validerEtapeActuelle() {
    switch (_etapeActuelle) {
      case 1: // Type accident (sautée)
        return true;
      case 2: // Informations générales
        return _dateController.text.isNotEmpty &&
               _heureController.text.isNotEmpty &&
               _lieuController.text.isNotEmpty &&
               _vehiculeSelectionne != null; // Véhicule sélectionné
      case 3: // Point de choc + Dégâts
        return true; // Optionnel mais recommandé
      case 4: // Observations
        return true; // Optionnel
      case 5: // Circonstances
        return true; // Optionnel mais important
      case 6: // Croquis
        return true; // Optionnel
      case 7: // Signature
        return true; // Optionnel
      case 8: // Résumé
        return true; // Sera validé lors de la finalisation
      default:
        return false;
    }
  }

  String _getTitreEtape(int etape) {
    switch (etape) {
      case 1: return 'Type d\'accident'; // Étape sautée
      case 2: return 'Informations Générales';
      case 3: return 'Point de choc + Dégâts';
      case 4: return 'Observations';
      case 5: return 'Circonstances';
      case 6: return 'Croquis';
      case 7: return 'Signature';
      case 8: return 'Résumé Complet';
      default: return 'Étape $etape';
    }
  }

  IconData _getIconeEtape(int etape) {
    switch (etape) {
      case 1: return Icons.category; // Type d'accident
      case 2: return Icons.info; // Informations générales
      case 3: return Icons.gps_fixed; // Point de choc + Dégâts
      case 4: return Icons.visibility; // Observations
      case 5: return Icons.checklist; // Circonstances
      case 6: return Icons.draw; // Croquis
      case 7: return Icons.edit; // Signature
      case 8: return Icons.assignment_turned_in; // Résumé
      default: return Icons.circle;
    }
  }

  Widget _buildFormulaire() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 🎯 Barre de progression des étapes
          _buildBarreProgression(),

          // Contenu de l'étape actuelle
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildContenuEtape(),
            ),
          ),

          // 🎯 Boutons de navigation
          _buildBoutonsNavigation(),
        ],
      ),
    );
  }

  Widget _buildBarreProgression() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre de l'étape actuelle
          Text(
            'Étape $_etapeActuelle/$_nombreEtapes: ${_getTitreEtape(_etapeActuelle)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Indicateurs d'étapes
          Row(
            children: List.generate(_nombreEtapes, (index) {
              final etape = index + 1;
              final estActuelle = etape == _etapeActuelle;
              final estValidee = _etapesValidees[etape] == true;
              final estAccessible = etape <= _etapeActuelle || estValidee;

              return Expanded(
                child: GestureDetector(
                  onTap: estAccessible ? () => _allerAEtape(etape) : null,
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < _nombreEtapes - 1 ? 8 : 0,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: estValidee
                                ? Colors.green
                                : estActuelle
                                    ? _getCouleurTypeAccident()
                                    : Colors.grey[300],
                            shape: BoxShape.circle,
                            border: estActuelle
                                ? Border.all(color: _getCouleurTypeAccident(), width: 3)
                                : null,
                          ),
                          child: Icon(
                            estValidee
                                ? Icons.check
                                : _getIconeEtape(etape),
                            color: estValidee || estActuelle
                                ? Colors.white
                                : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          etape.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: estActuelle ? FontWeight.bold : FontWeight.normal,
                            color: estValidee
                                ? Colors.green
                                : estActuelle
                                    ? _getCouleurTypeAccident()
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContenuEtape() {
    switch (_etapeActuelle) {
      case 1:
        return const Center(child: Text('Étape 1 sautée')); // Type accident déjà sélectionné
      case 2:
        return _buildEtapeInformationsGenerales(); // 2/7 : Informations Générales
      case 3:
        return _buildEtapePointChocDegats(); // 3/7 : Point de choc + Dégâts
      case 4:
        return _buildEtapeObservations(); // 4/7 : Observations
      case 5:
        return _buildEtapeCirconstances(); // 5/8 : Circonstances (étape séparée)
      case 6:
        return _buildEtapeCroquis(); // 6/8 : Croquis
      case 7:
        return _buildEtapeSignature(); // 7/8 : Signature
      case 8:
        return _buildEtapeResumeComplet(); // 8/8 : Résumé Complet
      default:
        return const Center(child: Text('Étape non trouvée'));
    }
  }

  // 🎯 ÉTAPE 2/8: Informations Générales (adaptée selon le rôle)
  Widget _buildEtapeInformationsGenerales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleSection(),

        // Afficher un message différent selon le rôle
        if (_estModeCollaboratif) ...[
          const SizedBox(height: 16),
          _buildCollaborativeRoleInfo(),
          const SizedBox(height: 24),
        ] else ...[
          const SizedBox(height: 32),
        ],

        _buildDateHeureSection(),
        const SizedBox(height: 24),
        _buildLieuSection(),
        const SizedBox(height: 24),
        _buildBlessesSection(),
        const SizedBox(height: 24),
        _buildTemoinsSection(),
        const SizedBox(height: 24),
        // Sélection de véhicule depuis les contrats
        _buildSelectionVehiculeSection(),
        const SizedBox(height: 24),
        // 🚗 Gestion propriétaire/conducteur
        _buildProprietaireConducteurSection(),
      ],
    );
  }

  // 🎯 ÉTAPE 3/7: Point de choc + Dégâts (Interface créative)
  Widget _buildEtapePointChocDegats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Designer de véhicule interactif
        _buildVehiculeDesignerSection(),
        const SizedBox(height: 24),
        // Dégâts avec photos
        _buildDegatsAvecPhotosSection(),
      ],
    );
  }

  // 🎯 ÉTAPE 4/7: Observations (Interface moderne)
  Widget _buildEtapeObservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header moderne avec gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo[50]!,
                Colors.blue[50]!,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
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
                      gradient: LinearGradient(
                        colors: [Colors.indigo[600]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Observations & Témoignages',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Décrivez précisément ce que vous avez observé',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section conditions de l'accident
        _buildObservationCard(
          'Conditions de l\'accident',
          Icons.wb_sunny,
          Colors.orange,
          [
            _buildConditionsSelector(),
          ],
        ),

        const SizedBox(height: 20),

        // Section observations détaillées
        _buildObservationCard(
          'Observations détaillées',
          Icons.remove_red_eye,
          Colors.blue,
          [
            _buildChampTexteModerne(
              controller: _circonstancesController,
              label: 'Décrivez précisément ce que vous avez vu',
              icone: Icons.visibility,
              maxLines: 5,
              hintText: 'Ex: Le véhicule adverse a grillé le feu rouge, conditions météo pluvieuses, visibilité réduite...',
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section témoins
        _buildObservationCard(
          'Témoins présents',
          Icons.people,
          Colors.green,
          [
            _buildTemoinsSection(),
          ],
        ),

        const SizedBox(height: 20),

        // Section remarques additionnelles
        _buildObservationCard(
          'Remarques importantes',
          Icons.priority_high,
          Colors.purple,
          [
            _buildChampTexteModerne(
              controller: _detailsBlessesController,
              label: 'Éléments particuliers à signaler',
              icone: Icons.note_add,
              maxLines: 3,
              hintText: 'Ex: Véhicule en panne, conducteur au téléphone, alcool suspecté...',
            ),
          ],
        ),
      ],
    );
  }

  // 🎯 ÉTAPE 5/7: Circonstances (étape séparée)
  Widget _buildEtapeCirconstances() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCirconstancesOfficiellesSection(),
      ],
    );
  }

  // 🎯 ÉTAPE 6/8: Croquis de l'accident
  Widget _buildEtapeCroquis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header moderne avec gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple[600]!,
                Colors.indigo[600]!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.draw,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Croquis de l\'accident',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Dessinez un schéma de l\'accident (optionnel)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Zone de croquis
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Vous pouvez dessiner un schéma simple de l\'accident pour clarifier les circonstances',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Bouton pour ouvrir l'éditeur de croquis
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _ouvrirEditeurCroquis,
                  icon: const Icon(Icons.draw),
                  label: const Text('Ouvrir l\'éditeur de croquis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Message informatif
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Le croquis est optionnel mais peut aider à clarifier les circonstances de l\'accident',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
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
    );
  }

  // 🎯 ÉTAPE 7/8: Signature électronique
  Widget _buildEtapeSignature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          'Signature électronique',
          Icons.edit,
          [
            const Text(
              'Signez le constat pour valider vos informations :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // Zone de signature
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _signatureData != null ? Colors.green : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: _signatureData != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _signatureData!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _effacerSignature,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(15),
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
                    )
                  : GestureDetector(
                      onTap: _signerConstat,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Appuyez pour signer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votre signature valide les informations saisies',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Bouton pour signer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signerConstat,
                icon: Icon(_signatureData != null ? Icons.edit : Icons.draw),
                label: Text(_signatureData != null ? 'Modifier la signature' : 'Signer le constat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _signatureData != null ? Colors.orange[600] : Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_signatureData != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Signature enregistrée avec succès',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // 🎯 ÉTAPE 8/8: Résumé Complet
  Widget _buildEtapeResumeComplet() {
    // Charger le croquis quand on affiche le résumé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔍 Chargement croquis depuis résumé...');
      _chargerCroquisDepuisFirebase();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header du résumé
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[600]!,
                Colors.teal[600]!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.summarize,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé complet du constat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vérifiez toutes les informations avant finalisation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // RÉSUMÉ COMPLET avec TOUTES les informations
        _buildResumeCompletConstat(),
      ],
    );
  }

  // 🎯 Boutons de navigation entre étapes
  Widget _buildBoutonsNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Précédent (à partir de l'étape 3)
          if (_etapeActuelle > 2)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _allerEtapePrecedente,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          if (_etapeActuelle > 2) const SizedBox(width: 16),

          // Bouton Suivant/Terminer
          Expanded(
            flex: _etapeActuelle == 2 ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: _etapeActuelle == _nombreEtapes ? _continuer : _allerEtapeSuivante,
              icon: Icon(_etapeActuelle == _nombreEtapes ? Icons.check : Icons.arrow_forward),
              label: Text(_etapeActuelle == _nombreEtapes ? 'Terminer' : 'Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getCouleurTypeAccident(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de l\'accident',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _getCouleurTypeAccident(),
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Renseignez les informations essentielles de votre accident',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeureSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCouleurTypeAccident(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Date et heure de l\'accident',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Afficher un message si les champs sont pré-remplis
            if (_estModeCollaboratif && !_estCreateur && _donneesCommunes != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ces informations ont été remplies par le créateur de la session',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                      // Ajouter un indicateur si le champ est pré-rempli
                      suffixIcon: (_estModeCollaboratif && !_estCreateur && _donneesCommunes != null)
                          ? Icon(Icons.lock_outline, color: Colors.grey[400], size: 16)
                          : null,
                    ),
                    readOnly: true,
                    onTap: (_estModeCollaboratif && !_estCreateur && _donneesCommunes != null)
                        ? null
                        : _selectionnerDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date requise';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heureController,
                    decoration: InputDecoration(
                      labelText: 'Heure *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                      // Ajouter un indicateur si le champ est pré-rempli
                      suffixIcon: (_estModeCollaboratif && !_estCreateur && _donneesCommunes != null)
                          ? Icon(Icons.lock_outline, color: Colors.grey[400], size: 16)
                          : null,
                    ),
                    readOnly: true,
                    onTap: (_estModeCollaboratif && !_estCreateur && _donneesCommunes != null)
                        ? null
                        : _selectionnerHeure,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Heure requise';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLieuSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCouleurTypeAccident(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Lieu de l\'accident',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _lieuController,
              decoration: InputDecoration(
                labelText: 'Adresse ou description du lieu *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
                hintText: 'Ex: Avenue Habib Bourguiba, Tunis',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lieu requis';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _obtenirPositionGPS,
                icon: Icon(_lieuGps == null || _lieuGps!.isEmpty ? Icons.my_location : Icons.location_on),
                label: Text(
                  _lieuGps == null || _lieuGps!.isEmpty
                    ? '📍 Obtenir position GPS'
                    : '✅ Position GPS obtenue',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lieuGps == null || _lieuGps!.isEmpty ? Colors.blue[600] : Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Afficher les coordonnées si disponibles
            if (_lieuGps != null && _lieuGps!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coordonnées: $_lieuGps',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlessesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCouleurTypeAccident(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Blessés (même légers)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _blesses ? _getCouleurTypeAccident().withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _blesses ? _getCouleurTypeAccident() : Colors.grey[300]!,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      title: const Text('Oui'),
                      value: true,
                      groupValue: _blesses,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _blesses = value!;
                          });
                        }
                      },
                      activeColor: _getCouleurTypeAccident(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_blesses ? Colors.green.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_blesses ? Colors.green : Colors.grey[300]!,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      title: const Text('Non'),
                      value: false,
                      groupValue: _blesses,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _blesses = value!;
                          });
                        }
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_blesses) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsBlessesController,
                decoration: InputDecoration(
                  labelText: 'Détails des blessures',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Décrivez les blessures...',
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemoinsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '4',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCouleurTypeAccident(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Témoins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _ajouterTemoin,
                  icon: Icon(
                    Icons.add_circle,
                    color: _getCouleurTypeAccident(),
                    size: 28,
                  ),
                  tooltip: 'Ajouter un témoin',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_temoins.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucun témoin ajouté. Vous pouvez ajouter des témoins si nécessaire.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._temoins.asMap().entries.map((entry) {
                final index = entry.key;
                final temoin = entry.value;
                return _buildTemoinCard(temoin, index);
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemoinCard(Temoin temoin, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCouleurTypeAccident().withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCouleurTypeAccident().withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCouleurTypeAccident().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getCouleurTypeAccident(),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temoin.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (temoin.telephone.isNotEmpty)
                  Text(
                    temoin.telephone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _supprimerTemoin(index),
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonContinuer() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _continuer,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCouleurTypeAccident(),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 8,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continuer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
      ),
    );
  }

  void _selectionnerDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateAccident,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (date != null && mounted) {
      setState(() {
        _dateAccident = date;
        _dateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  void _selectionnerHeure() async {
    final heure = await showTimePicker(
      context: context,
      initialTime: _heureAccident,
    );
    
    if (heure != null && mounted) {
      setState(() {
        _heureAccident = heure;
        _heureController.text = '${heure.hour}:${heure.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _obtenirPositionGPS() async {
    try {
      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('📍 Recherche de votre position GPS...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement. Veuillez l\'activer dans les paramètres.');
      }

      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service de localisation désactivé. Veuillez l\'activer.');
      }

      // Essayer d'abord avec une position rapide (moins précise)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // Si la position rapide échoue, essayer avec la dernière position connue
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          // Dernier recours : position précise avec timeout plus long
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 30),
          );
        }
      }

      // Vérifier si on a réussi à obtenir une position
      if (position == null) {
        throw Exception('Impossible d\'obtenir la position GPS');
      }

      if (mounted) {
        setState(() {
          _lieuGps = {
            'latitude': position!.latitude,
            'longitude': position!.longitude,
            'accuracy': position!.accuracy,
          };
        });

        // Obtenir l'adresse à partir des coordonnées GPS
        _obtenirAdresseDepuisGPS(position!.latitude, position!.longitude);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        String messageSucces;
        if (position!.accuracy > 50) {
          messageSucces = 'Position GPS obtenue (précision: ±${position!.accuracy.toStringAsFixed(0)}m)\nAmélioration en cours...';
          // Essayer d'obtenir une position plus précise en arrière-plan
          _obtenirPositionPrecise();
        } else {
          messageSucces = 'Position GPS précise obtenue (±${position!.accuracy.toStringAsFixed(1)}m)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(messageSucces)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur GPS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        String messageErreur;
        IconData iconeErreur = Icons.error;

        if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
          messageErreur = 'Timeout GPS - Vérifiez votre connexion et réessayez';
          iconeErreur = Icons.access_time;
        } else if (e.toString().contains('location service')) {
          messageErreur = 'Services de localisation désactivés';
          iconeErreur = Icons.location_disabled;
        } else if (e.toString().contains('permission')) {
          messageErreur = 'Permission de localisation requise';
          iconeErreur = Icons.location_off;
        } else {
          messageErreur = 'Impossible d\'obtenir la position GPS';
          iconeErreur = Icons.gps_off;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(iconeErreur, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(messageErreur)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _obtenirPositionGPS,
            ),
          ),
        );
      }
    }
  }

  /// 🏠 Obtenir l'adresse à partir des coordonnées GPS
  Future<void> _obtenirAdresseDepuisGPS(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks.first;
        String adresse = '';

        if (place.street != null && place.street!.isNotEmpty) {
          adresse += place.street!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (adresse.isNotEmpty) adresse += ', ';
          adresse += place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (adresse.isNotEmpty) adresse += ', ';
          adresse += place.administrativeArea!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          if (adresse.isNotEmpty) adresse += ', ';
          adresse += place.country!;
        }

        if (adresse.isNotEmpty) {
          setState(() {
            _lieuController.text = adresse;
          });
        }
      }
    } catch (e) {
      print('ℹ️ Impossible d\'obtenir l\'adresse: $e');
    }
  }

  /// 🎯 Obtenir une position GPS plus précise en arrière-plan
  void _obtenirPositionPrecise() async {
    try {
      // Attendre un peu avant d'essayer une position plus précise
      await Future.delayed(const Duration(seconds: 2));

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      if (mounted && _lieuGps != null) {
        // Vérifier si la nouvelle position est significativement différente
        double distance = Geolocator.distanceBetween(
          _lieuGps!['latitude'],
          _lieuGps!['longitude'],
          position.latitude,
          position.longitude,
        );

        // Mettre à jour seulement si la nouvelle position est plus précise
        if (position.accuracy < _lieuGps!['accuracy'] || distance > 10) {
          setState(() {
            _lieuGps = {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
            };
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Position GPS mise à jour (±${position.accuracy.toStringAsFixed(1)}m)'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Ignorer les erreurs de position précise (c'est optionnel)
      print('ℹ️ Position précise non disponible: $e');
    }
  }

  /// 📸 Prendre une photo du permis (recto ou verso)
  Future<void> _prendrePhotoPermis(bool isRecto) async {
    try {
      // Afficher un dialog de choix entre caméra et galerie
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('📸 Photo ${isRecto ? 'Recto' : 'Verso'} du permis'),
            content: const Text('Choisissez la source de l\'image :'),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

      if (source == null) return;

      // Prendre la photo
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          if (isRecto) {
            _photoPermisRecto = File(image.path);
            _photoPermisRectoUrl = image.path;
          } else {
            _photoPermisVerso = File(image.path);
            _photoPermisVersoUrl = image.path;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('✅ Photo ${isRecto ? 'recto' : 'verso'} du permis prise avec succès'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Erreur lors de la prise de photo: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 🚗 Sélectionner un contrat et remplir automatiquement les informations
  void _selectionnerVehicule(Map<String, dynamic> contrat) {
    if (mounted) {
      setState(() {
        _vehiculeSelectionneId = contrat['id'];
        _vehiculeSelectionne = contrat;
      });

      // Remplir automatiquement tous les champs depuis le contrat
      _remplirChampsDepuisContrat(contrat);

      final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>? ?? {};

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Contrat sélectionné: ${vehiculeInfo['marque']} ${vehiculeInfo['modele']} (${contrat['numeroContrat']})',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 📋 Remplir les champs depuis un contrat sélectionné
  void _remplirChampsDepuisContrat(Map<String, dynamic> contrat) {
    final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>? ?? {};

    print('🔍 Données du contrat à remplir:');
    print('   - Contrat complet: $contrat');
    print('   - VehiculeInfo: $vehiculeInfo');

    // Informations véhicule depuis le contrat
    final immatriculation = vehiculeInfo['numeroImmatriculation'] ??
                           contrat['numeroImmatriculation'] ??
                           contrat['immatriculation'] ?? '';
    final marque = vehiculeInfo['marque'] ?? contrat['marque'] ?? '';
    final modele = vehiculeInfo['modele'] ?? contrat['modele'] ?? '';

    _immatriculationController.text = immatriculation;
    _marqueController.text = marque;
    _modeleController.text = modele;

    print('🔧 Remplissage immatriculation:');
    print('   - vehiculeInfo[numeroImmatriculation]: ${vehiculeInfo['numeroImmatriculation']}');
    print('   - contrat[numeroImmatriculation]: ${contrat['numeroImmatriculation']}');
    print('   - contrat[immatriculation]: ${contrat['immatriculation']}');
    print('   - Résultat final: $immatriculation');

    // Informations assurance depuis le contrat - utiliser les vraies données
    final compagnie = contrat['compagnieNom'] ??
                     contrat['compagnieAssurance'] ??
                     'Assurance Elite Tunisie';
    final agence = contrat['agenceNom'] ??
                  contrat['agenceAssurance'] ??
                  'Agence Centrale Tunis';
    final numeroContrat = contrat['numeroContrat'] ??
                         contrat['numeroPolice'] ?? '';

    _compagnieController.text = compagnie;
    _agenceController.text = agence;
    _numeroContratController.text = numeroContrat;

    // Informations conducteur (propriétaire) depuis le contrat
    final nom = contrat['proprietaireNom'] ??
               contrat['nomConducteur'] ??
               contrat['nom'] ?? '';
    final prenom = contrat['proprietairePrenom'] ??
                  contrat['prenomConducteur'] ??
                  contrat['prenom'] ?? '';
    final telephone = contrat['proprietaireTelephone'] ??
                     contrat['telephoneConducteur'] ??
                     contrat['telephone'] ?? '';
    final adresse = contrat['proprietaireAdresse'] ??
                   contrat['adresseConducteur'] ??
                   contrat['adresse'] ?? '';

    _nomConducteurController.text = nom;
    _prenomConducteurController.text = prenom;
    _telephoneController.text = telephone;
    _adresseController.text = adresse;

    print('✅ Champs remplis depuis contrat sélectionné:');
    print('   - Véhicule: $marque $modele');
    print('   - Immatriculation: $immatriculation');
    print('   - Contrat: $numeroContrat');
    print('   - Compagnie: $compagnie');
    print('   - Agence: $agence');
    print('   - Propriétaire: $nom $prenom');
    print('   - Téléphone: $telephone');
    print('   - Adresse: $adresse');
  }

  /// 📋 Récupérer les contrats actifs du conducteur depuis les demandes de contrats
  Future<List<Map<String, dynamic>>> _recupererContratsActifs() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Utilisateur non connecté');
        return [];
      }

      print('🔍 Récupération des contrats actifs pour: ${user.uid}');

      // D'abord, essayons la collection 'contrats'
      print('🔍 Recherche dans la collection "contrats"...');
      final contratsSnapshot = await FirebaseFirestore.instance
          .collection('contrats')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      print('📊 ${contratsSnapshot.docs.length} documents trouvés dans "contrats"');

      // Si aucun contrat trouvé, essayons 'demandes_contrats'
      if (contratsSnapshot.docs.isEmpty) {
        print('🔍 Recherche dans la collection "demandes_contrats"...');
        final demandesSnapshot = await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .where('conducteurId', isEqualTo: user.uid)
            .where('statut', whereIn: ['contrat_actif', 'contrat_valide', 'affectee'])
            .get();

        print('📊 ${demandesSnapshot.docs.length} demandes trouvées dans "demandes_contrats"');

        List<Map<String, dynamic>> contratsActifs = [];

        for (final doc in demandesSnapshot.docs) {
          final data = doc.data();

          print('📋 Traitement demande: ${doc.id}');
          print('   - Toutes les clés: ${data.keys.toList()}');
          print('   - Marque: ${data['marque']}');
          print('   - Modèle: ${data['modele']}');
          print('   - Immatriculation: ${data['immatriculation']}');
          print('   - Statut: ${data['statut']}');
          print('   - Nom: ${data['nom']}');
          print('   - Prénom: ${data['prenom']}');
          print('   - Téléphone: ${data['telephone']}');
          print('   - Adresse: ${data['adresse']}');
          print('   - Compagnie: ${data['compagnieNom']}');
          print('   - Agence: ${data['agenceNom']}');

          // Créer un objet contrat avec toutes les informations nécessaires
          final contrat = {
            'id': doc.id,
            'numeroContrat': data['numeroContrat'] ?? '',
            'numeroDemande': data['numeroDemande'] ?? '',
            'statut': data['statut'] ?? '',
            'dateDebut': data['dateDebut'],
            'dateFin': data['dateFin'],

            // Informations véhicule
            'vehiculeInfo': {
              'marque': data['marque'] ?? '',
              'modele': data['modele'] ?? '',
              'numeroImmatriculation': data['immatriculation'] ?? '',
              'typeCarburant': data['typeCarburant'] ?? '',
              'puissance': data['puissance'] ?? '',
              'anneeConstruction': data['anneeConstruction'] ?? '',
            },

            // Aussi stocker directement au niveau racine pour compatibilité
            'marque': data['marque'] ?? '',
            'modele': data['modele'] ?? '',
            'numeroImmatriculation': data['immatriculation'] ?? '',
            'immatriculation': data['immatriculation'] ?? '',

            // Informations assurance
            'compagnieNom': data['compagnieNom'] ?? 'Assurance Elite Tunisie',
            'agenceNom': data['agenceNom'] ?? 'Agence Centrale Tunis',
            'compagnieAssurance': data['compagnieNom'] ?? 'Assurance Elite Tunisie',
            'agenceAssurance': data['agenceNom'] ?? 'Agence Centrale Tunis',
            'typeContrat': data['typeContrat'] ?? '',
            'prime': data['prime'] ?? 0,
            'franchise': data['franchise'] ?? 0,

            // Informations conducteur/propriétaire (utiliser les vrais noms de champs)
            'proprietaireNom': data['nom'] ?? '',
            'proprietairePrenom': data['prenom'] ?? '',
            'proprietaireTelephone': data['telephone'] ?? '',
            'proprietaireAdresse': data['adresse'] ?? '',
            'proprietaireEmail': data['email'] ?? '',

            // Aussi stocker avec d'autres noms pour compatibilité
            'nomConducteur': data['nom'] ?? '',
            'prenomConducteur': data['prenom'] ?? '',
            'telephoneConducteur': data['telephone'] ?? '',
            'adresseConducteur': data['adresse'] ?? '',
            'nom': data['nom'] ?? '',
            'prenom': data['prenom'] ?? '',
            'telephone': data['telephone'] ?? '',
            'adresse': data['adresse'] ?? '',
          };

          contratsActifs.add(contrat);

          final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>;
          print('✅ Contrat actif créé: ${vehiculeInfo['marque']} ${vehiculeInfo['modele']} (${contrat['numeroContrat']})');
          print('   - Immatriculation dans vehiculeInfo: ${vehiculeInfo['numeroImmatriculation']}');
          print('   - Immatriculation racine: ${contrat['numeroImmatriculation']}');
        }

        print('📋 ${contratsActifs.length} contrats actifs récupérés depuis "demandes_contrats"');
        return contratsActifs;
      }

      // Traitement des contrats depuis la collection 'contrats'
      List<Map<String, dynamic>> contratsActifs = [];

      for (final doc in contratsSnapshot.docs) {
        final data = doc.data();

        print('📋 Traitement contrat: ${doc.id}');
        print('   - Data keys: ${data.keys.toList()}');

        // Vérifier si le contrat est actif (date de fin dans le futur)
        final dateFin = (data['dateFin'] as Timestamp?)?.toDate();
        final isActive = dateFin?.isAfter(DateTime.now()) ?? false;

        if (!isActive) {
          print('⏭️ Contrat expiré ignoré: ${doc.id}');
          continue;
        }

        // Créer un objet contrat avec toutes les informations nécessaires
        final contrat = {
          'id': doc.id,
          'numeroContrat': data['numeroContrat'] ?? data['numeroPolice'] ?? '',
          'numeroDemande': data['numeroDemande'] ?? '',
          'statut': 'contrat_actif',
          'dateDebut': data['dateDebut'],
          'dateFin': data['dateFin'],

          // Informations véhicule depuis vehiculeInfo
          'vehiculeInfo': data['vehiculeInfo'] ?? {
            'marque': data['marque'] ?? '',
            'modele': data['modele'] ?? '',
            'numeroImmatriculation': data['numeroImmatriculation'] ?? '',
            'typeCarburant': data['typeCarburant'] ?? '',
            'puissance': data['puissance'] ?? '',
            'anneeConstruction': data['anneeConstruction'] ?? '',
          },

          // Informations assurance
          'compagnieNom': data['compagnieAssurance'] ?? data['compagnieNom'] ?? 'Assurance Elite Tunisie',
          'agenceNom': data['agenceAssurance'] ?? data['agenceNom'] ?? 'Agence Centrale Tunis',
          'typeContrat': data['typeContrat'] ?? data['typeAssurance'] ?? '',
          'prime': data['montantPrime'] ?? data['prime'] ?? 0,
          'franchise': data['franchise'] ?? 0,

          // Informations conducteur/propriétaire
          'proprietaireNom': data['proprietaireNom'] ?? data['nomConducteur'] ?? '',
          'proprietairePrenom': data['proprietairePrenom'] ?? data['prenomConducteur'] ?? '',
          'proprietaireTelephone': data['proprietaireTelephone'] ?? data['telephoneConducteur'] ?? '',
          'proprietaireAdresse': data['proprietaireAdresse'] ?? data['adresseConducteur'] ?? '',
          'proprietaireEmail': data['proprietaireEmail'] ?? data['emailConducteur'] ?? '',
        };

        contratsActifs.add(contrat);

        final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>;
        print('✅ Contrat actif trouvé: ${vehiculeInfo['marque']} ${vehiculeInfo['modele']} (${contrat['numeroContrat']})');
      }

      print('📋 ${contratsActifs.length} contrats actifs récupérés depuis "contrats"');
      return contratsActifs;

    } catch (e) {
      print('❌ Erreur lors de la récupération des contrats: $e');
      return [];
    }
  }

  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => _buildDialogueTemoin(),
    );
  }

  Widget _buildDialogueTemoin() {
    final nomController = TextEditingController();
    final adresseController = TextEditingController();
    final telephoneController = TextEditingController();

    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nomController,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: adresseController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: telephoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nomController.text.trim().isNotEmpty) {
              if (mounted) {
                setState(() {
                  _temoins.add(Temoin(
                    nom: nomController.text.trim(),
                    adresse: adresseController.text.trim(),
                    telephone: telephoneController.text.trim(),
                  ));
                });
              }
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getCouleurTypeAccident(),
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  void _supprimerTemoin(int index) {
    if (mounted) {
      setState(() {
        _temoins.removeAt(index);
      });
    }
  }

  void _continuer() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // 🎯 NOUVEAU: Vérifier si c'est un mode collaboratif
      if (_estModeCollaboratif && widget.session != null) {
        await _terminerFormulaireCollaboratif();
        return;
      }

      // Mode non-collaboratif (ancien code)
      final contratSelectionne = _vehiculeSelectionne;
      if (contratSelectionne == null) {
        throw Exception('Aucun véhicule sélectionné');
      }

      print('🚗 Création session avec contrat: ${contratSelectionne['numeroContrat']}');

      final session = await AccidentSessionCompleteService.creerNouvelleSession(
        typeAccident: widget.typeAccident,
        nombreVehicules: 1, // Accident à véhicule unique
        nomCreateur: contratSelectionne['nom'] ?? 'Nom Utilisateur',
        prenomCreateur: contratSelectionne['prenom'] ?? 'Prénom Utilisateur',
        emailCreateur: contratSelectionne['email'] ?? user.email ?? 'email@example.com',
        telephoneCreateur: contratSelectionne['telephone'] ?? '+216 XX XXX XXX',
      );

      // Mettre à jour les informations générales
      final infosGenerales = InfosGeneralesAccident(
        dateAccident: _dateAccident,
        heureAccident: _heureController.text,
        lieuAccident: _lieuController.text.trim(),
        lieuGps: _lieuGps != null && _lieuGps!.isNotEmpty
            ? '${_lieuGps!['latitude']?.toStringAsFixed(6)}, ${_lieuGps!['longitude']?.toStringAsFixed(6)}'
            : '',
        blesses: _blesses,
        detailsBlesses: _detailsBlessesController.text.trim(),
        degatsMaterielsAutres: false, // Pas applicable pour accident unique
        detailsDegatsAutres: '',
        temoins: _temoins,
      );

      await AccidentSessionCompleteService.mettreAJourInfosGenerales(
        session.id,
        infosGenerales,
      );

      // 🎯 NOUVEAU: Créer automatiquement le véhicule du conducteur avec les infos du contrat
      final vehiculeConducteur = VehiculeAccident(
        roleVehicule: 'A', // Le conducteur est toujours véhicule A
        conducteurId: user.uid,

        // Informations véhicule depuis le contrat
        marque: contratSelectionne['marque'] ?? '',
        modele: contratSelectionne['modele'] ?? '',
        immatriculation: contratSelectionne['immatriculation'] ?? '',
        sensCirculation: '', // À remplir plus tard
        pointChocInitial: '', // À remplir plus tard
        degatsApparents: [], // À remplir plus tard

        // Informations assurance depuis le contrat
        societeAssurance: contratSelectionne['compagnieNom'] ?? '',
        numeroContrat: contratSelectionne['numeroContrat'] ?? '',
        agence: contratSelectionne['agenceNom'] ?? '',
        validiteAssuranceDebut: DateTime.now().subtract(const Duration(days: 30)), // Approximation
        validiteAssuranceFin: DateTime.now().add(const Duration(days: 335)), // Approximation

        // Informations conducteur depuis le contrat
        nomConducteur: contratSelectionne['nom'] ?? '',
        prenomConducteur: contratSelectionne['prenom'] ?? '',
        adresseConducteur: contratSelectionne['adresse'] ?? '',
        numeroPermis: '', // À remplir si nécessaire
        dateDelivrancePermis: DateTime.now().subtract(const Duration(days: 365)), // Approximation
        categoriePermis: 'B', // Valeur par défaut

        // Assuré (même personne que le conducteur)
        assureDifferent: false,
        nomAssure: contratSelectionne['nom'] ?? '',
        prenomAssure: contratSelectionne['prenom'] ?? '',
        adresseAssure: contratSelectionne['adresse'] ?? '',
      );

      // Sauvegarder le véhicule du conducteur
      await AccidentSessionCompleteService.mettreAJourVehicule(
        session.id,
        vehiculeConducteur,
      );

      print('✅ Véhicule conducteur créé automatiquement avec les données du contrat');

      if (mounted) {
        // 🎯 NOUVEAU: Passer directement aux circonstances (étape 4)
        // puisque nous avons déjà les informations véhicule et assurance
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AccidentFormStep4Circonstances(
              session: session,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🎯 Terminer le formulaire en mode collaboratif
  Future<void> _terminerFormulaireCollaboratif() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      print('🎯 Début terminer formulaire collaboratif');
      print('📋 Session ID: ${widget.session?.id}');
      print('👤 User ID: ${user.uid}');
      print('🏗️ Est créateur: $_estCreateur');

      // Préparer toutes les données du formulaire
      final donneesFormulaire = {
        // Informations générales
        'dateAccident': _dateAccident.toIso8601String(),
        'heureAccident': _heureController.text,
        'lieuAccident': _lieuController.text.trim(),
        'lieuGps': _lieuGps,
        'blesses': _blesses,
        'detailsBlesses': _detailsBlessesController.text.trim(),
        'temoins': _temoins.map((t) => {
          'nom': t.nom,
          'adresse': t.adresse,
          'telephone': t.telephone,
        }).toList(),

        // Véhicule sélectionné
        'vehiculeSelectionne': _vehiculeSelectionne,

        // Point de choc et dégâts
        'pointChocSelectionne': _pointChocSelectionne,
        'degatsSelectionnes': _degatsSelectionnes,

        // Observations
        'observationsController': _observationsController.text.trim(),

        // Circonstances
        'circonstancesSelectionnees': _circonstancesSelectionnees,

        // Croquis
        'croquisData': _croquisData,

        // Signature
        'signatureData': _signatureData != null ? 'Signé' : null,

        // Métadonnées
        'dateTermine': DateTime.now().toIso8601String(),
        'roleVehicule': widget.roleVehicule ?? 'A',
        'estCreateur': _estCreateur,
        'estUtilisateurInscrit': _estUtilisateurInscrit,
      };

      // Sauvegarder l'état final du formulaire
      List<bool> etapesValideesListe = List.generate(_nombreEtapes, (index) {
        return _etapesValidees[index + 1] ?? false;
      });

      // Marquer toutes les étapes comme validées
      for (int i = 0; i < etapesValideesListe.length; i++) {
        etapesValideesListe[i] = true;
      }

      // 🆕 Marquer le formulaire comme terminé AVANT la sauvegarde
      await _mettreAJourEtatFormulaire(FormulaireStatus.termine);
      print('✅ État formulaire mis à jour: terminé');

      await CollaborativeSessionStateService.sauvegarderEtatFormulaire(
        sessionId: widget.session!.id!,
        participantId: user.uid,
        donneesFormulaire: donneesFormulaire,
        etapeActuelle: _nombreEtapes.toString(),
        etapesValidees: etapesValideesListe,
      );

      // Si c'est le créateur, sauvegarder aussi les données communes
      if (_estCreateur) {
        await _sauvegarderDonneesCommunes();
      }

      // Sauvegarder dans l'historique personnel des sinistres
      await _sauvegarderDansHistoriqueSinistres(donneesFormulaire);

      // Mettre à jour le statut de la session collaborative
      await _mettreAJourStatutSession();

      if (mounted) {
        // Afficher message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _estCreateur
                        ? 'Session créée avec succès ! Partagez le code avec les autres conducteurs.'
                        : 'Votre formulaire a été enregistré avec succès !',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Naviguer vers le dashboard de session avec données complètes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDashboardScreen(
              session: widget.session!,
            ),
          ),
        );
      }

    } catch (e) {
      print('❌ Erreur lors de la finalisation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🗄️ Sauvegarder les données du participant dans la session collaborative
  Future<void> _sauvegarderDansHistoriqueSinistres(Map<String, dynamic> donneesFormulaire) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Pour les sessions collaboratives, on sauvegarde les données du participant dans la session
      // au lieu de créer un sinistre individuel
      if (widget.session != null) {
        await _sauvegarderDonneesParticipantDansSession(donneesFormulaire);
        print('✅ Données participant sauvegardées dans la session collaborative');
        return;
      }

      // Pour les sinistres individuels (non collaboratifs), on garde l'ancien comportement
      final sinistreId = 'sinistre_${DateTime.now().millisecondsSinceEpoch}_${user.uid}';

      final sinistreData = {
        'id': sinistreId,
        'numeroSinistre': 'IND-${DateTime.now().millisecondsSinceEpoch}',
        'typeAccident': widget.typeAccident,
        'dateAccident': donneesFormulaire['dateAccident'],
        'heureAccident': donneesFormulaire['heureAccident'],
        'lieuAccident': donneesFormulaire['lieuAccident'],
        'statut': 'termine',
        'estCollaboratif': false,
        'vehiculeInfo': donneesFormulaire['vehiculeSelectionne'],
        'donneesFormulaire': donneesFormulaire,
        'dateCreation': FieldValue.serverTimestamp(),
        'dateTermine': FieldValue.serverTimestamp(),
        'conducteurId': user.uid,
        'conducteurDeclarantId': user.uid,
        'createdBy': user.uid,
        'userId': user.uid,
      };

      // Sauvegarder dans la collection sinistres pour les sinistres individuels
      await FirebaseFirestore.instance
          .collection('sinistres')
          .doc(sinistreId)
          .set(sinistreData);

      print('✅ Sinistre individuel sauvegardé avec ID: $sinistreId');

    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
    }
  }

  /// 💾 Sauvegarder les données du participant dans la session collaborative
  Future<void> _sauvegarderDonneesParticipantDansSession(Map<String, dynamic> donneesFormulaire) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final sessionRef = FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .doc(widget.session!.id);

      // Récupérer la session actuelle
      final sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) {
        print('❌ Session non trouvée: ${widget.session!.id}');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // Trouver le participant actuel et mettre à jour ses données
      bool participantTrouve = false;
      for (int i = 0; i < participants.length; i++) {
        if (participants[i]['userId'] == user.uid) {
          participants[i]['donneesFormulaire'] = donneesFormulaire;
          participants[i]['formulaireComplete'] = true;
          participants[i]['dateFormulaireFini'] = FieldValue.serverTimestamp();
          participantTrouve = true;
          break;
        }
      }

      // Si le participant n'est pas trouvé, l'ajouter (cas du créateur)
      if (!participantTrouve) {
        participants.add({
          'userId': user.uid,
          'donneesFormulaire': donneesFormulaire,
          'formulaireComplete': true,
          'dateFormulaireFini': FieldValue.serverTimestamp(),
          'estCreateur': _estCreateur,
          'roleVehicule': widget.roleVehicule ?? 'vehicule_a',
          'statut': 'termine',
        });
      }

      // Mettre à jour la session avec les nouvelles données
      await sessionRef.update({
        'participants': participants,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });

      print('✅ Données participant sauvegardées dans la session: ${widget.session!.id}');

    } catch (e) {
      print('❌ Erreur sauvegarde données participant: $e');
      throw e;
    }
  }

  /// 📝 Mettre à jour l'état du formulaire du participant actuel
  Future<void> _mettreAJourEtatFormulaire(FormulaireStatus nouvelEtat) async {
    try {
      if (widget.session?.id == null) return;

      final user = FirebaseAuth.instance.currentUser!;

      await CollaborativeSessionService.mettreAJourEtatFormulaire(
        sessionId: widget.session!.id,
        userId: user.uid,
        nouvelEtat: nouvelEtat,
      );

      print('✅ État formulaire mis à jour: ${nouvelEtat.name}');

    } catch (e) {
      print('❌ Erreur mise à jour état formulaire: $e');
    }
  }

  /// 📊 Mettre à jour le statut de la session collaborative
  Future<void> _mettreAJourStatutSession() async {
    try {
      if (widget.session?.id == null) return;

      final user = FirebaseAuth.instance.currentUser!;
      final sessionRef = FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .doc(widget.session!.id);

      // Récupérer la session actuelle
      final sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) {
        print('❌ Session non trouvée: ${widget.session!.id}');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // Trouver et mettre à jour le participant actuel
      bool participantTrouve = false;
      for (int i = 0; i < participants.length; i++) {
        if (participants[i]['userId'] == user.uid) {
          participants[i]['statut'] = 'termine';
          participants[i]['dateTermine'] = FieldValue.serverTimestamp();
          participants[i]['formulaireComplete'] = true;
          participantTrouve = true;
          break;
        }
      }

      // Si le participant n'est pas trouvé, l'ajouter (cas du créateur)
      if (!participantTrouve) {
        participants.add({
          'userId': user.uid,
          'statut': 'termine',
          'dateTermine': FieldValue.serverTimestamp(),
          'formulaireComplete': true,
          'estCreateur': _estCreateur,
          'roleVehicule': widget.roleVehicule ?? 'vehicule_a',
        });
      }

      // Calculer les statistiques
      final participantsTermines = participants.where((p) => p['statut'] == 'termine').length;
      final nombreTotalParticipants = participants.length;
      final tousTermines = participantsTermines >= nombreTotalParticipants;

      // Mettre à jour la session
      await sessionRef.update({
        'participants': participants,
        'statut': tousTermines ? 'termine' : 'en_cours',
        'derniereMiseAJour': FieldValue.serverTimestamp(),
        'progression': {
          'participantsRejoints': nombreTotalParticipants,
          'formulairesTermines': participantsTermines,
          'pourcentage': ((participantsTermines / nombreTotalParticipants) * 100).round(),
        },
      });

      print('✅ Statut session mis à jour: ${widget.session!.id}');
      print('📊 Participants terminés: $participantsTermines/$nombreTotalParticipants');

    } catch (e) {
      print('❌ Erreur mise à jour statut session: $e');
    }
  }

  /// 🚗 Section de sélection de véhicule depuis les contrats
  Widget _buildSelectionVehiculeSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recupererContratsActifs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Chargement de vos véhicules...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors du chargement des véhicules: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          );
        }

        final contrats = snapshot.data ?? [];

        if (contrats.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Aucun contrat actif trouvé. Veuillez d\'abord souscrire à une assurance.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sélectionnez votre contrat d\'assurance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Choisissez le contrat d\'assurance du véhicule impliqué dans l\'accident pour remplir automatiquement toutes les informations :',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ...contrats.map((contrat) => _buildContratCard(contrat)).toList(),
            ],
          ),
        );
      },
    );
  }

  /// 📄 Carte de contrat sélectionnable
  Widget _buildContratCard(Map<String, dynamic> contrat) {
    final bool isSelected = _vehiculeSelectionneId == contrat['id'];
    final vehiculeInfo = contrat['vehiculeInfo'] as Map<String, dynamic>? ?? {};
    final statut = contrat['statut'] ?? '';
    final isActif = statut == 'contrat_actif';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.green[400]! : (isActif ? Colors.blue[300]! : Colors.orange[300]!),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectionnerVehicule(contrat),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green[600]
                        : (isActif ? Colors.blue[600] : Colors.orange[600]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : (isActif ? Icons.verified : Icons.pending),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehiculeInfo['marque']} ${vehiculeInfo['modele']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.green[800] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🚗 ${vehiculeInfo['numeroImmatriculation']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.green[700] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📋 Contrat: ${contrat['numeroContrat']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.green[600] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActif ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActif ? '✅ ACTIF' : '⏳ EN COURS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActif ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '🏢 ${contrat['compagnieNom']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📋 Section des informations auto-remplies
  Widget _buildInformationsAutoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informations chargées automatiquement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Véhicule
          _buildInfoAutoRow('🚗 Véhicule', '${_marqueController.text} ${_modeleController.text}'),
          _buildInfoAutoRow('🔢 Immatriculation', _immatriculationController.text),
          _buildInfoAutoRow('📋 N° Contrat', _numeroContratController.text),

          const SizedBox(height: 12),

          // Assurance
          _buildInfoAutoRow('🏢 Compagnie', _compagnieController.text),
          _buildInfoAutoRow('🏪 Agence', _agenceController.text),

          const SizedBox(height: 12),

          // Propriétaire
          _buildInfoAutoRow('👤 Propriétaire', '${_nomConducteurController.text} ${_prenomConducteurController.text}'),
          _buildInfoAutoRow('📞 Téléphone', _telephoneController.text),
        ],
      ),
    );
  }

  /// 📝 Ligne d'information auto-remplie
  Widget _buildInfoAutoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(
                fontSize: 13,
                color: value.isNotEmpty ? Colors.black87 : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Section gestion conducteur/propriétaire
  Widget _buildConducteurProprietaireSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👤 Qui conduisait le véhicule ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Question propriétaire conduit
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _proprietaireConduit,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _proprietaireConduit = value!;
                          });
                        }
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Le propriétaire du véhicule conduisait',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _proprietaireConduit,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _proprietaireConduit = value!;
                          });
                        }
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Une autre personne conduisait',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Si ce n'est pas le propriétaire qui conduit
          if (!_proprietaireConduit) ...[
            const Text(
              'Informations du conducteur',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Champs conducteur
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomConducteurController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du conducteur',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _prenomConducteurController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone du conducteur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 16),
          ],

          // Question permis - seulement si ce n'est pas le propriétaire qui conduit
          if (!_proprietaireConduit) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!, width: 2),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🪪 Le conducteur a-t-il un permis de conduire ?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _conducteurAPermis,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _conducteurAPermis = value!;
                          });
                        }
                      },
                    ),
                    const Text(
                      'Oui, permis valide',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Radio<bool>(
                      value: false,
                      groupValue: _conducteurAPermis,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _conducteurAPermis = value!;
                          });
                        }
                      },
                    ),
                    const Text(
                      'Non, pas de permis',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                if (_conducteurAPermis) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '📸 Photos du permis (optionnel)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoPermisButton('Recto', _photoPermisRectoUrl, true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPhotoPermisButton('Verso', _photoPermisVersoUrl, false),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Conduite sans permis - Infraction grave',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          ], // Fin du bloc conditionnel pour la question du permis
        ],
      ),
    );
  }

  /// 📸 Bouton pour photo permis
  Widget _buildPhotoPermisButton(String label, String? photoUrl, bool isRecto) {
    final bool hasPhoto = photoUrl != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasPhoto ? Colors.green : Colors.grey[400]!,
          width: hasPhoto ? 2 : 1,
        ),
        color: hasPhoto ? Colors.green[50] : Colors.grey[50],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _prendrePhotoPermis(isRecto),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPhoto ? Icons.check_circle : Icons.camera_alt,
                  color: hasPhoto ? Colors.green[600] : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto ? '$label ✓' : label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasPhoto ? Colors.green[700] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Modifier',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 Sections pour les étapes
  Widget _buildAssuranceSection() {
    return _buildSection(
      'Assurance',
      Icons.security,
      [
        _buildChampTexte(
          controller: _compagnieController,
          label: 'Compagnie d\'assurance',
          icone: Icons.business,
          obligatoire: true,
        ),
        const SizedBox(height: 16),
        _buildChampTexte(
          controller: _numeroContratController,
          label: 'Numéro de contrat',
          icone: Icons.confirmation_number,
          obligatoire: true,
        ),
      ],
    );
  }

  Widget _buildCirconstancesSection() {
    return _buildSection(
      'Circonstances de l\'accident',
      Icons.description,
      [
        const Text(
          'Décrivez les circonstances de l\'accident:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _circonstancesController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Décrivez ce qui s\'est passé...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCroquisSection() {
    return _buildSection(
      'Croquis de l\'accident',
      Icons.draw,
      [
        const Text(
          'Dessinez un croquis de l\'accident (optionnel):',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Zone de dessin du croquis\n(À implémenter)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return _buildSection(
      'Photos et documents',
      Icons.camera_alt,
      [
        const Text(
          'Ajoutez des photos de l\'accident (optionnel):',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implémenter la prise de photos
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('Prendre une photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getCouleurTypeAccident(),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSignaturesSection() {
    return _buildSection(
      'Signatures électroniques',
      Icons.edit,
      [
        const Text(
          'Signatures des parties impliquées:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Zone de signature\n(À implémenter)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  // 🎯 MÉTHODES UTILITAIRES MANQUANTES

  /// 📝 Méthode générique pour construire une section avec titre et contenu
  Widget _buildSection(String titre, IconData icone, List<Widget> contenu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCouleurTypeAccident().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icone,
                    color: _getCouleurTypeAccident(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...contenu,
          ],
        ),
      ),
    );
  }

  /// 📝 Méthode pour construire un champ de texte stylisé
  Widget _buildChampTexte({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    bool obligatoire = false,
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: obligatoire ? '$label *' : label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icone),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: obligatoire ? (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label requis';
        }
        return null;
      } : null,
    );
  }

  /// 🚗 Navigation vers le formulaire véhicules
  void _allerVersVehicules() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélection de véhicule intégrée dans cette étape'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 🎨 Navigation vers l'éditeur de croquis
  void _allerVersCroquis() {
    if (widget.session != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModernCollaborativeSketchScreen(
            session: widget.session!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session requise pour le croquis'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// ✍️ Signature du constat
  void _signerConstat() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignatureScreen(
            title: 'Signature du constat',
            subtitle: 'Signez pour valider vos informations',
          ),
        ),
      );

      if (result != null && result is Uint8List && mounted) {
        setState(() {
          _signatureData = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Signature enregistrée avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Sauvegarder automatiquement
        _sauvegarderAutomatiquement();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur lors de la signature: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 🗑️ Effacer la signature
  void _effacerSignature() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Effacer la signature'),
            ],
          ),
          content: const Text('Êtes-vous sûr de vouloir effacer votre signature ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() {
                    _signatureData = null;
                  });
                  _sauvegarderAutomatiquement();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signature effacée'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Effacer'),
            ),
          ],
        );
      },
    );
  }

  // 🎯 NOUVELLES MÉTHODES POUR LA STRUCTURE EN 7 ÉTAPES

  /// 📋 Liste de circonstances officielles (17 circonstances) - Version moderne
  Widget _buildCirconstancesOfficiellesSection() {
    final circonstancesOfficielles = [
      {'numero': 1, 'texte': 'Stationnait', 'icone': Icons.local_parking},
      {'numero': 2, 'texte': 'Quittait un stationnement', 'icone': Icons.exit_to_app},
      {'numero': 3, 'texte': 'Prenait un stationnement', 'icone': Icons.input},
      {'numero': 4, 'texte': 'Sortait d\'un parking, d\'un lieu privé', 'icone': Icons.garage},
      {'numero': 5, 'texte': 'S\'engageait dans un parking, un lieu privé', 'icone': Icons.home_work},
      {'numero': 6, 'texte': 'S\'engageait sur une place à sens giratoire', 'icone': Icons.rotate_right},
      {'numero': 7, 'texte': 'Circulait sur une place à sens giratoire', 'icone': Icons.loop},
      {'numero': 8, 'texte': 'S\'engageait dans une voie de circulation', 'icone': Icons.merge_type},
      {'numero': 9, 'texte': 'Changeait de file', 'icone': Icons.swap_horiz},
      {'numero': 10, 'texte': 'Doublait', 'icone': Icons.fast_forward},
      {'numero': 11, 'texte': 'Virait à droite', 'icone': Icons.turn_right},
      {'numero': 12, 'texte': 'Virait à gauche', 'icone': Icons.turn_left},
      {'numero': 13, 'texte': 'Reculait', 'icone': Icons.keyboard_backspace},
      {'numero': 14, 'texte': 'Empiétait sur une voie réservée à la circulation en sens inverse', 'icone': Icons.warning},
      {'numero': 15, 'texte': 'Venait de droite (dans un carrefour)', 'icone': Icons.call_received},
      {'numero': 16, 'texte': 'N\'avait pas observé un signal de priorité ou d\'interdiction', 'icone': Icons.traffic},
      {'numero': 17, 'texte': 'Était en infraction avec la signalisation routière', 'icone': Icons.report_problem},
    ];

    return _buildSection(
      'Circonstances de l\'accident',
      Icons.checklist_rtl,
      [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cochez toutes les circonstances qui correspondent à votre situation au moment de l\'accident',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Liste des circonstances avec design moderne
        ...circonstancesOfficielles.map((circonstance) {
          final numero = circonstance['numero'] as int;
          final texte = circonstance['texte'] as String;
          final icone = circonstance['icone'] as IconData;
          final estSelectionne = _circonstancesSelectionnees.contains(numero);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: estSelectionne ? _getCouleurTypeAccident().withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: estSelectionne ? _getCouleurTypeAccident() : Colors.grey[300]!,
                width: estSelectionne ? 2 : 1,
              ),
              boxShadow: estSelectionne ? [
                BoxShadow(
                  color: _getCouleurTypeAccident().withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      if (estSelectionne) {
                        _circonstancesSelectionnees.remove(numero);
                      } else {
                        _circonstancesSelectionnees.add(numero);
                      }
                    });
                    _sauvegarderAutomatiquement();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Numéro avec icône
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: estSelectionne ? _getCouleurTypeAccident() : Colors.grey[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            numero.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Icône de la circonstance
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: estSelectionne ? _getCouleurTypeAccident().withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icone,
                          color: estSelectionne ? _getCouleurTypeAccident() : Colors.grey[600],
                          size: 18,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Texte de la circonstance
                      Expanded(
                        child: Text(
                          texte,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: estSelectionne ? FontWeight.w600 : FontWeight.normal,
                            color: estSelectionne ? _getCouleurTypeAccident() : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),

                      // Checkbox
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: estSelectionne ? _getCouleurTypeAccident() : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: estSelectionne ? _getCouleurTypeAccident() : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: estSelectionne
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),

        // Résumé des circonstances sélectionnées
        if (_circonstancesSelectionnees.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Circonstances sélectionnées (${_circonstancesSelectionnees.length}):',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _circonstancesSelectionnees.map((num) => 'N°$num').join(', '),
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 📋 RÉSUMÉ COMPLET avec TOUTES les informations du constat
  Widget _buildResumeCompletConstat() {
    return _buildSection(
      'Résumé Complet du Constat',
      Icons.assignment_turned_in,
      [
        const Text(
          'Vérifiez toutes les informations avant finalisation :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
        ),
        const SizedBox(height: 20),

        // Informations Générales
        _buildSectionResumeComplete(
          'Informations Générales',
          Icons.info,
          [
            'Date: ${_dateAccident.day.toString().padLeft(2, '0')}/${_dateAccident.month.toString().padLeft(2, '0')}/${_dateAccident.year}',
            'Heure: ${_heureAccident.hour.toString().padLeft(2, '0')}:${_heureAccident.minute.toString().padLeft(2, '0')}',
            'Lieu: ${_lieuController.text.isNotEmpty ? _lieuController.text : "Non renseigné"}',
            if (_lieuGps != null && _lieuGps!.isNotEmpty) 'GPS: ${_lieuGps!['latitude']?.toStringAsFixed(6)}, ${_lieuGps!['longitude']?.toStringAsFixed(6)}',
            'Blessés: ${_blesses ? "Oui" : "Non"}',
            if (_blesses && _detailsBlessesController.text.isNotEmpty)
              'Détails blessés: ${_detailsBlessesController.text}',
            'Témoins: ${_temoins.length}',
          ],
        ),

        const SizedBox(height: 16),

        // Véhicule et Conducteur
        _buildSectionResumeComplete(
          'Véhicule et Conducteur',
          Icons.directions_car,
          [
            'Marque: ${_marqueController.text}',
            'Modèle: ${_modeleController.text}',
            'Immatriculation: ${_immatriculationController.text}',
            'Conducteur: ${_nomConducteurController.text} ${_prenomConducteurController.text}',
            'Téléphone: ${_telephoneController.text}',
            'Adresse: ${_adresseController.text}',
          ],
        ),

        const SizedBox(height: 16),

        // Assurance
        _buildSectionResumeComplete(
          'Assurance',
          Icons.security,
          [
            'Compagnie: ${_compagnieController.text}',
            'Agence: ${_agenceController.text}',
            'N° Contrat: ${_numeroContratController.text}',
          ],
        ),

        const SizedBox(height: 16),

        // Point de Choc et Dégâts
        _buildSectionResumeCompleteAvecPhotos(
          'Point de Choc et Dégâts',
          Icons.gps_fixed,
          [
            'Point de choc: ${_pointChocSelectionne.isNotEmpty ? _pointChocSelectionne : "Non renseigné"}',
            'Dégâts sélectionnés: ${_degatsSelectionnes.isNotEmpty ? _degatsSelectionnes.join(", ") : "Aucun"}',
          ],
          _photosDegatUrls,
        ),

        const SizedBox(height: 16),

        // Observations
        _buildSectionResumeComplete(
          'Observations',
          Icons.visibility,
          [
            'Observations générales: ${_observationsController.text.isNotEmpty ? _observationsController.text : "Aucune"}',
            'Remarques additionnelles: ${_remarquesController.text.isNotEmpty ? _remarquesController.text : "Aucune"}',
            'Circonstances: ${_circonstancesController.text.isNotEmpty ? _circonstancesController.text : "Aucune"}',
          ],
        ),

        const SizedBox(height: 16),

        // Circonstances
        _buildSectionResumeComplete(
          'Circonstances',
          Icons.checklist,
          [
            'Circonstances sélectionnées: ${_circonstancesSelectionnees.isNotEmpty ? _circonstancesSelectionnees.map((index) => "Circonstance $index").join(", ") : "Aucune"}',
            'Nombre de circonstances: ${_circonstancesSelectionnees.length}',
          ],
        ),

        const SizedBox(height: 16),

        // Croquis
        _buildSectionCroquisResume(),

        const SizedBox(height: 16),

        // Signature
        _buildSectionResumeComplete(
          'Signature',
          Icons.edit,
          [
            'Statut signature: ${_signatureData != null ? "✅ Signée" : "❌ Non signée"}',
            if (_signatureData != null) 'Signature enregistrée avec succès',
          ],
        ),

        const SizedBox(height: 20),

        // Message de confirmation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _signatureData != null ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _signatureData != null ? Colors.green[200]! : Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(
                _signatureData != null ? Icons.check_circle : Icons.warning,
                color: _signatureData != null ? Colors.green[600] : Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _signatureData != null
                      ? 'Constat complet et signé ! Vous pouvez maintenant le finaliser.'
                      : 'Toutes les informations ont été collectées. Retournez à l\'étape 6 pour signer le constat.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _signatureData != null ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📝 Section détaillée pour le résumé complet avec photos
  Widget _buildSectionResumeCompleteAvecPhotos(String titre, IconData icone, List<String> elements, List<String> photosUrls) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                titre,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...elements.map((element) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $element',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          )),

          // Affichage des photos si disponibles
          if (photosUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Photos de dégâts (${photosUrls.length}):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photosUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _voirPhotoEnGrand(photosUrls[index]),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            File(photosUrls[index]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📝 Section détaillée pour le résumé complet
  Widget _buildSectionResumeComplete(String titre, IconData icone, List<String> elements) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                titre,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...elements.map((element) => Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 2),
            child: Text(
              '• $element',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// 🚗 Section propriétaire/conducteur avec gestion du permis
  Widget _buildProprietaireConducteurSection() {
    return _buildSection(
      'Propriétaire et Conducteur',
      Icons.person_pin,
      [
        const Text(
          'Le propriétaire du véhicule conduit-il ?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Question propriétaire conduit
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _proprietaireConduit ? _getCouleurTypeAccident().withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _proprietaireConduit ? _getCouleurTypeAccident() : Colors.grey[300]!,
                  ),
                ),
                child: RadioListTile<bool>(
                  title: const Text('Oui'),
                  value: true,
                  groupValue: _proprietaireConduit,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _proprietaireConduit = value!;
                      });
                    }
                  },
                  activeColor: _getCouleurTypeAccident(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: !_proprietaireConduit ? Colors.orange.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_proprietaireConduit ? Colors.orange : Colors.grey[300]!,
                  ),
                ),
                child: RadioListTile<bool>(
                  title: const Text('Non'),
                  value: false,
                  groupValue: _proprietaireConduit,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _proprietaireConduit = value!;
                      });
                    }
                  },
                  activeColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),

        // Si le propriétaire ne conduit pas
        if (!_proprietaireConduit) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le conducteur a-t-il un permis de conduire ?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _conducteurAPermis ? Colors.green.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _conducteurAPermis ? Colors.green : Colors.grey[300]!,
                          ),
                        ),
                        child: RadioListTile<bool>(
                          title: const Text('Oui'),
                          value: true,
                          groupValue: _conducteurAPermis,
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                _conducteurAPermis = value!;
                              });
                            }
                          },
                          activeColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_conducteurAPermis ? Colors.red.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_conducteurAPermis ? Colors.red : Colors.grey[300]!,
                          ),
                        ),
                        child: RadioListTile<bool>(
                          title: const Text('Non'),
                          value: false,
                          groupValue: _conducteurAPermis,
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                _conducteurAPermis = value!;
                              });
                            }
                          },
                          activeColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

                // Si le conducteur a un permis, demander les photos
                if (_conducteurAPermis) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Photos du permis de conduire :',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Photo recto
                      Expanded(
                        child: _buildPhotoPermisCard(true), // true = recto
                      ),
                      const SizedBox(width: 12),
                      // Photo verso
                      Expanded(
                        child: _buildPhotoPermisCard(false), // false = verso
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 📸 Card pour photo du permis (recto/verso)
  Widget _buildPhotoPermisCard(bool isRecto) {
    final photo = isRecto ? _photoPermisRecto : _photoPermisVerso;
    final photoUrl = isRecto ? _photoPermisRectoUrl : _photoPermisVersoUrl;

    return GestureDetector(
      onTap: () => _prendrePhotoPermis(isRecto),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: photo != null || (photoUrl != null && photoUrl.isNotEmpty)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photo != null
                    ? Image.file(photo, fit: BoxFit.cover)
                    : Image.network(photoUrl!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRecto ? 'Recto' : 'Verso',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 🚗 Designer de véhicule interactif pour point de choc
  Widget _buildVehiculeDesignerSection() {
    return _buildSection(
      'Point de choc',
      Icons.gps_fixed,
      [
        // Sélection par chips compacts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sélectionnez la zone d\'impact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (_pointChocSelectionne.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '✓',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Grille compacte 4x3
              SizedBox(
                height: 200,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _pointsChocDisponibles.length,
                  itemBuilder: (context, index) {
                    final point = _pointsChocDisponibles[index];
                    final estSelectionne = _pointChocSelectionne == point;
                    return _buildZoneImpactCardCompact(point, estSelectionne, index);
                  },
                ),
              ),
            ],
          ),
        ),

        // Point sélectionné
        if (_pointChocSelectionne.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zone sélectionnée: $_pointChocSelectionne',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 🎨 Card compacte pour zone d'impact
  Widget _buildZoneImpactCardCompact(String point, bool estSelectionne, int index) {
    // Icônes simplifiées selon la zone
    final icones = [
      Icons.keyboard_arrow_up, Icons.arrow_upward, Icons.keyboard_arrow_up, // Avant
      Icons.keyboard_arrow_left, Icons.keyboard_arrow_right, // Côtés avant
      Icons.keyboard_arrow_left, Icons.keyboard_arrow_right, // Côtés arrière
      Icons.keyboard_arrow_down, Icons.arrow_downward, Icons.keyboard_arrow_down, // Arrière
      Icons.roofing, Icons.vertical_align_bottom, // Toit, Dessous
    ];

    final couleurs = [
      Colors.red, Colors.orange, Colors.red, // Avant
      Colors.blue, Colors.blue, // Côtés avant
      Colors.purple, Colors.purple, // Côtés arrière
      Colors.green, Colors.teal, Colors.green, // Arrière
      Colors.brown, Colors.grey, // Toit, Dessous
    ];

    final icone = index < icones.length ? icones[index] : Icons.location_on;
    final couleur = index < couleurs.length ? couleurs[index] : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _pointChocSelectionne = point;
          });
          _sauvegarderAutomatiquement();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: estSelectionne ? couleur : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: estSelectionne ? couleur : Colors.grey[300]!,
            width: estSelectionne ? 2 : 1,
          ),
          boxShadow: [
            if (estSelectionne)
              BoxShadow(
                color: couleur.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              color: estSelectionne ? Colors.white : couleur,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              point.length > 8 ? point.substring(0, 8) + '...' : point,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: estSelectionne ? FontWeight.bold : FontWeight.w500,
                color: estSelectionne ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 Card moderne pour zone d'impact (version complète - gardée pour compatibilité)
  Widget _buildZoneImpactCard(String point, bool estSelectionne, int index) {
    // Icônes spécifiques selon la zone
    final icones = [
      Icons.keyboard_arrow_up, Icons.arrow_upward, Icons.keyboard_arrow_up, // Avant
      Icons.keyboard_arrow_left, Icons.keyboard_arrow_right, // Côtés avant
      Icons.keyboard_arrow_left, Icons.keyboard_arrow_right, // Côtés arrière
      Icons.keyboard_arrow_down, Icons.arrow_downward, Icons.keyboard_arrow_down, // Arrière
      Icons.roofing, Icons.vertical_align_bottom, // Toit, Dessous
    ];

    final couleurs = [
      Colors.red, Colors.orange, Colors.red, // Avant
      Colors.blue, Colors.blue, // Côtés avant
      Colors.purple, Colors.purple, // Côtés arrière
      Colors.green, Colors.teal, Colors.green, // Arrière
      Colors.brown, Colors.grey, // Toit, Dessous
    ];

    final icone = index < icones.length ? icones[index] : Icons.location_on;
    final couleur = index < couleurs.length ? couleurs[index] : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _pointChocSelectionne = point;
          });
          _sauvegarderAutomatiquement();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: estSelectionne
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [couleur.withOpacity(0.8), couleur],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey[50]!],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estSelectionne ? couleur : Colors.grey[300]!,
            width: estSelectionne ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: estSelectionne
                  ? couleur.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: estSelectionne ? 8 : 4,
              offset: Offset(0, estSelectionne ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: estSelectionne ? Colors.white.withOpacity(0.9) : couleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icone,
                color: estSelectionne ? couleur : couleur.withOpacity(0.7),
                size: estSelectionne ? 28 : 24,
              ),
            ),

            const SizedBox(height: 8),

            // Texte
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                point,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: estSelectionne ? FontWeight.bold : FontWeight.w500,
                  color: estSelectionne ? Colors.white : Colors.black87,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Indicateur de sélection
            if (estSelectionne) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  /// 📸 Section dégâts avec photos Cloudinary
  Widget _buildDegatsAvecPhotosSection() {
    return _buildSection(
      'Dégâts apparents',
      Icons.warning_amber,
      [
        const Text(
          'Sélectionnez les types de dégâts et ajoutez des photos :',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Sélection des types de dégâts
        const Text(
          'Types de dégâts :',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _degatsDisponibles.map((degat) =>
            _buildDegatChip(degat)
          ).toList(),
        ),

        const SizedBox(height: 20),

        // Section photos
        const Text(
          'Photos des dégâts :',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),

        // Bouton ajouter photo
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _ajouterPhotoDegat,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter une photo',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stockage sécurisé Cloudinary',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Affichage des photos ajoutées
        if (_photosDegatUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Photos ajoutées :',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photosDegatUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Image cliquable pour agrandir
                      GestureDetector(
                        onTap: () => _voirImageEnGrand(_photosDegatUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_photosDegatUrls[index]),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Erreur chargement image: $error');
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.grey[600], size: 24),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Erreur',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Indicateur de zoom
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),

                      // Bouton supprimer
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _supprimerPhotoDegat(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
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
                );
              },
            ),
          ),
        ],

        // Résumé des dégâts sélectionnés
        if (_degatsSelectionnes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Dégâts sélectionnés (${_degatsSelectionnes.length}):',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _degatsSelectionnes.join(', '),
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 🏷️ Chip pour sélection de dégât
  Widget _buildDegatChip(String degat) {
    final estSelectionne = _degatsSelectionnes.contains(degat);

    return FilterChip(
      label: Text(degat),
      selected: estSelectionne,
      onSelected: (selected) {
        if (mounted) {
          setState(() {
            if (selected) {
              _degatsSelectionnes.add(degat);
            } else {
              _degatsSelectionnes.remove(degat);
            }
          });
        }
      },
      selectedColor: Colors.orange.withOpacity(0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: estSelectionne ? Colors.orange[700] : Colors.grey[700],
        fontWeight: estSelectionne ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  /// 📸 Ajouter une photo de dégât
  void _ajouterPhotoDegat() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.add_a_photo, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text('Photo des dégâts'),
              ],
            ),
            content: const Text('Choisissez la source de l\'image :'),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

      if (source == null) return;

      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                ),
                SizedBox(width: 12),
                Text('📸 Traitement de l\'image...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Utiliser le chemin local de l'image au lieu d'une URL placeholder
        final imagePath = image.path;

        setState(() {
          _photosDegatUrls.add(imagePath);
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Photo ajoutée avec succès (${_photosDegatUrls.length} photo${_photosDegatUrls.length > 1 ? 's' : ''})'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Sauvegarder automatiquement
        _sauvegarderAutomatiquement();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 🔍 Voir l'image en grand
  void _voirImageEnGrand(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Image en plein écran
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text(
                                'Impossible d\'afficher l\'image',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Bouton fermer
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🗑️ Supprimer une photo de dégât
  void _supprimerPhotoDegat(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Supprimer la photo'),
            ],
          ),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() {
                    _photosDegatUrls.removeAt(index);
                  });
                  _sauvegarderAutomatiquement();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo supprimée'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  /// 🆔 Initialiser la session avec un ID unique
  void _initialiserSession() {
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${FirebaseAuth.instance.currentUser?.uid ?? 'anonymous'}';
    print('🆔 Session initialisée: $_sessionId');
  }

  /// 🤝 Charger les données collaboratives
  Future<void> _chargerDonneesCollaboratives() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.session?.id == null) return;

      print('🔄 Chargement données collaboratives pour session: ${widget.session!.id}');

      // 1. Charger l'état du formulaire du participant
      final etatFormulaire = await CollaborativeSessionStateService.chargerEtatFormulaire(
        sessionId: widget.session!.id!,
        participantId: user.uid,
      );

      if (etatFormulaire != null && mounted) {
        print('✅ État formulaire trouvé, application des données...');
        _appliquerDonneesCollaboratives(etatFormulaire);
      }

      // 2. Charger les données communes si pas créateur
      if (!_estCreateur) {
        await _chargerDonneesCommunes();
      }

      // 3. Afficher message de récupération
      if (etatFormulaire != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_download, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _estCreateur
                        ? 'Session restaurée avec vos données'
                        : 'Formulaire restauré avec vos données',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      print('❌ Erreur chargement données collaboratives: $e');
    }
  }

  /// 📝 Appliquer les données collaboratives récupérées
  void _appliquerDonneesCollaboratives(Map<String, dynamic> etat) {
    try {
      final donneesFormulaire = etat['donneesFormulaire'] as Map<String, dynamic>?;
      if (donneesFormulaire == null) return;

      setState(() {
        // Informations générales
        if (donneesFormulaire['dateAccident'] != null) {
          _dateAccident = DateTime.parse(donneesFormulaire['dateAccident']);
          _dateController.text = '${_dateAccident.day.toString().padLeft(2, '0')}/${_dateAccident.month.toString().padLeft(2, '0')}/${_dateAccident.year}';
        }

        if (donneesFormulaire['heureAccident'] != null) {
          _heureController.text = donneesFormulaire['heureAccident'];
        }

        if (donneesFormulaire['lieuAccident'] != null) {
          _lieuController.text = donneesFormulaire['lieuAccident'];
        }

        if (donneesFormulaire['lieuGps'] != null) {
          _lieuGps = Map<String, dynamic>.from(donneesFormulaire['lieuGps']);
        }

        if (donneesFormulaire['blesses'] != null) {
          _blesses = donneesFormulaire['blesses'];
        }

        if (donneesFormulaire['detailsBlesses'] != null) {
          _detailsBlessesController.text = donneesFormulaire['detailsBlesses'];
        }

        // Véhicule sélectionné
        if (donneesFormulaire['vehiculeSelectionne'] != null) {
          _vehiculeSelectionne = Map<String, dynamic>.from(donneesFormulaire['vehiculeSelectionne']);
        }

        // Point de choc et dégâts
        if (donneesFormulaire['pointChocSelectionne'] != null) {
          _pointChocSelectionne = donneesFormulaire['pointChocSelectionne'];
        }

        if (donneesFormulaire['degatsSelectionnes'] != null) {
          _degatsSelectionnes = List<String>.from(donneesFormulaire['degatsSelectionnes'] as List);
        }

        // Observations
        if (donneesFormulaire['observationsController'] != null) {
          _observationsController.text = donneesFormulaire['observationsController'];
        }

        // Circonstances
        if (donneesFormulaire['circonstancesSelectionnees'] != null) {
          _circonstancesSelectionnees = List<int>.from(donneesFormulaire['circonstancesSelectionnees'] as List);
        }

        // Croquis
        if (donneesFormulaire['croquisData'] != null) {
          _croquisData = List<Map<String, dynamic>>.from(donneesFormulaire['croquisData'] as List);
          _croquisExiste = _croquisData.isNotEmpty;
        }

        // Témoins
        if (donneesFormulaire['temoins'] != null) {
          final temoinsData = donneesFormulaire['temoins'] as List;
          _temoins.clear();
          for (var temoinData in temoinsData) {
            _temoins.add(Temoin(
              nom: temoinData['nom'] ?? '',
              adresse: temoinData['adresse'] ?? '',
              telephone: temoinData['telephone'] ?? '',
            ));
          }
        }

        // Étapes validées
        if (etat['etapesValidees'] != null) {
          final etapesListe = List<bool>.from(etat['etapesValidees']);
          for (int i = 0; i < etapesListe.length && i < _nombreEtapes; i++) {
            _etapesValidees[i + 1] = etapesListe[i];
          }
        }

        // Étape actuelle
        if (etat['etapeActuelle'] != null) {
          final etapeStr = etat['etapeActuelle'].toString();
          final etapeNum = int.tryParse(etapeStr);
          if (etapeNum != null && etapeNum >= 1 && etapeNum <= _nombreEtapes) {
            _etapeActuelle = etapeNum;
          }
        }
      });

      print('✅ Données collaboratives appliquées avec succès');

    } catch (e) {
      print('❌ Erreur application données collaboratives: $e');
    }
  }

  /// 📖 Récupérer un brouillon existant
  Future<void> _recupererBrouillonExistant() async {
    if (_sessionId == null) return;

    try {
      final etapeActuelle = 'etape_$_etapeActuelle';
      final brouillon = await DraftService.recupererBrouillon(
        sessionId: _sessionId!,
        etape: etapeActuelle,
      );

      if (brouillon != null && mounted) {
        _appliquerBrouillon(brouillon);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📖 Brouillon récupéré automatiquement'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur récupération brouillon: $e');
    }
  }

  /// 📝 Appliquer les données du brouillon
  void _appliquerBrouillon(Map<String, dynamic> brouillon) {
    setState(() {
      // Informations générales
      if (brouillon['dateAccident'] != null) {
        _dateAccident = DateTime.parse(brouillon['dateAccident']);
        _dateController.text = '${_dateAccident.day}/${_dateAccident.month}/${_dateAccident.year}';
      }
      if (brouillon['heureAccident'] != null) {
        _heureController.text = brouillon['heureAccident'];
      }
      if (brouillon['lieuAccident'] != null) {
        _lieuController.text = brouillon['lieuAccident'];
      }
      if (brouillon['blesses'] != null) {
        _blesses = brouillon['blesses'];
      }
      if (brouillon['detailsBlesses'] != null) {
        _detailsBlessesController.text = brouillon['detailsBlesses'];
      }

      // Point de choc et dégâts
      if (brouillon['pointChocSelectionne'] != null) {
        _pointChocSelectionne = brouillon['pointChocSelectionne'];
      }
      if (brouillon['degatsSelectionnes'] != null) {
        _degatsSelectionnes = List<String>.from(brouillon['degatsSelectionnes']);
      }
      if (brouillon['photosDegatUrls'] != null) {
        _photosDegatUrls = List<String>.from(brouillon['photosDegatUrls']);
      }

      // Circonstances
      if (brouillon['circonstancesSelectionnees'] != null) {
        _circonstancesSelectionnees = List<int>.from(brouillon['circonstancesSelectionnees']);
      }

      // Croquis
      if (brouillon['croquisData'] != null) {
        _croquisData = List<Map<String, dynamic>>.from(brouillon['croquisData']);
        _croquisExiste = _croquisData.isNotEmpty;
      }

      // Propriétaire/Conducteur
      if (brouillon['proprietaireConduit'] != null) {
        _proprietaireConduit = brouillon['proprietaireConduit'];
      }
      if (brouillon['conducteurAPermis'] != null) {
        _conducteurAPermis = brouillon['conducteurAPermis'];
      }
    });
  }

  /// 💾 Sauvegarder automatiquement avec debounce
  void _sauvegarderAutomatiquement() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (_estModeCollaboratif && widget.session?.id != null) {
        _sauvegarderEtatCollaboratif();
      } else if (_sessionId != null) {
        _sauvegarderBrouillon();
      }
    });
  }

  /// 🤝 Sauvegarder l'état collaboratif
  Future<void> _sauvegarderEtatCollaboratif() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || widget.session?.id == null) return;

      // Préparer toutes les données du formulaire
      final donneesFormulaire = {
        // Informations générales
        'dateAccident': _dateAccident.toIso8601String(),
        'heureAccident': _heureController.text,
        'lieuAccident': _lieuController.text.trim(),
        'lieuGps': _lieuGps,
        'blesses': _blesses,
        'detailsBlesses': _detailsBlessesController.text.trim(),
        'temoins': _temoins.map((t) => {
          'nom': t.nom,
          'adresse': t.adresse,
          'telephone': t.telephone,
        }).toList(),

        // Véhicule sélectionné
        'vehiculeSelectionne': _vehiculeSelectionne,

        // Point de choc et dégâts
        'pointChocSelectionne': _pointChocSelectionne,
        'degatsSelectionnes': _degatsSelectionnes,

        // Observations
        'observationsController': _observationsController.text.trim(),

        // Circonstances
        'circonstancesSelectionnees': _circonstancesSelectionnees,

        // Croquis
        'croquisData': _croquisData,

        // Métadonnées
        'derniereMiseAJour': DateTime.now().toIso8601String(),
        'roleVehicule': widget.roleVehicule ?? 'A',
        'estCreateur': _estCreateur,
        'estUtilisateurInscrit': _estUtilisateurInscrit,
      };

      // Convertir les étapes validées en liste
      List<bool> etapesValideesListe = List.generate(_nombreEtapes, (index) {
        return _etapesValidees[index + 1] ?? false;
      });

      await CollaborativeSessionStateService.sauvegarderEtatFormulaire(
        sessionId: widget.session!.id!,
        participantId: user.uid,
        donneesFormulaire: donneesFormulaire,
        etapeActuelle: _etapeActuelle.toString(),
        etapesValidees: etapesValideesListe,
      );

      // Sauvegarder aussi les données communes si créateur
      if (_estCreateur) {
        await _sauvegarderDonneesCommunes();
      }

      print('✅ État collaboratif sauvegardé automatiquement');

    } catch (e) {
      print('❌ Erreur sauvegarde état collaboratif: $e');
    }
  }

  /// 💾 Sauvegarder le brouillon actuel
  Future<void> _sauvegarderBrouillon() async {
    if (_sessionId == null) return;

    try {
      final etapeActuelle = 'etape_$_etapeActuelle';
      final donnees = _obtenirDonneesActuelles();

      await DraftService.sauvegarderBrouillon(
        sessionId: _sessionId!,
        etape: etapeActuelle,
        donnees: donnees,
      );

      print('💾 Brouillon sauvegardé automatiquement');
    } catch (e) {
      print('❌ Erreur sauvegarde brouillon: $e');
    }
  }

  /// 📊 Obtenir toutes les données actuelles du formulaire
  Map<String, dynamic> _obtenirDonneesActuelles() {
    return {
      // Informations générales
      'dateAccident': _dateAccident.toIso8601String(),
      'heureAccident': _heureController.text,
      'lieuAccident': _lieuController.text,
      'blesses': _blesses,
      'detailsBlesses': _detailsBlessesController.text,

      // Véhicule sélectionné
      'vehiculeSelectionneId': _vehiculeSelectionneId,

      // Point de choc et dégâts
      'pointChocSelectionne': _pointChocSelectionne,
      'degatsSelectionnes': _degatsSelectionnes,
      'photosDegatUrls': _photosDegatUrls,

      // Circonstances
      'circonstancesSelectionnees': _circonstancesSelectionnees,

      // Croquis
      'croquisData': _croquisData,
      'croquisExiste': _croquisExiste,

      // Propriétaire/Conducteur
      'proprietaireConduit': _proprietaireConduit,
      'conducteurAPermis': _conducteurAPermis,

      // Métadonnées
      'etapeActuelle': _etapeActuelle,
      'etapesValidees': _etapesValidees,
      'dateSauvegarde': DateTime.now().toIso8601String(),
    };
  }

  /// 🗑️ Supprimer le brouillon (quand finalisé)
  Future<void> _supprimerBrouillon() async {
    if (_sessionId == null) return;

    try {
      final etapeActuelle = 'etape_$_etapeActuelle';
      await DraftService.supprimerBrouillon(
        sessionId: _sessionId!,
        etape: etapeActuelle,
      );
      print('🗑️ Brouillon supprimé');
    } catch (e) {
      print('❌ Erreur suppression brouillon: $e');
    }
  }

  /// 📍 Obtenir la position GPS actuelle
  Future<void> _obtenirPositionActuelle() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Services de localisation désactivés');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Veuillez activer les services de localisation'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Permission de localisation refusée');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📍 Permission de localisation requise'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permission de localisation refusée définitivement');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Veuillez autoriser la localisation dans les paramètres'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Obtention de la position GPS...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Timeout de 10 secondes
      );

      if (mounted) {
        setState(() {
          _lieuGps = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
          };

          // Écrire automatiquement dans le champ lieu
          final coordonnees = 'GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          if (_lieuController.text.isEmpty) {
            _lieuController.text = coordonnees;
          } else {
            _lieuController.text = '${_lieuController.text} - $coordonnees';
          }
        });

        print('📍 Position obtenue: ${position.latitude}, ${position.longitude}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Position GPS obtenue avec précision: ${position.accuracy.toStringAsFixed(1)}m'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Sauvegarder automatiquement
        _sauvegarderAutomatiquement();
      }
    } catch (e) {
      print('❌ Erreur obtention position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur GPS: ${e.toString().contains('timeout') ? 'Timeout - Vérifiez votre connexion' : 'Impossible d\'obtenir la position'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 🎨 Card moderne pour les observations
  Widget _buildObservationCard(String titre, IconData icone, Color couleur, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: couleur.withOpacity(0.1),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: couleur, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                titre,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: couleur.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// 📝 Champ de texte moderne avec style amélioré
  Widget _buildChampTexteModerne({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    int maxLines = 1,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (value) => _sauvegarderAutomatiquement(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icone, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(color: Colors.grey[700]),
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        style: const TextStyle(fontSize: 15, height: 1.4),
      ),
    );
  }

  /// 🌤️ Sélecteur de conditions météo et de visibilité
  Widget _buildConditionsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conditions au moment de l\'accident :',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildConditionChip('☀️ Ensoleillé', Colors.orange),
            _buildConditionChip('☁️ Nuageux', Colors.grey),
            _buildConditionChip('🌧️ Pluvieux', Colors.blue),
            _buildConditionChip('🌫️ Brouillard', Colors.blueGrey),
            _buildConditionChip('❄️ Neige', Colors.lightBlue),
            _buildConditionChip('🌙 Nuit', Colors.indigo),
            _buildConditionChip('💡 Éclairage public', Colors.yellow),
            _buildConditionChip('👁️ Bonne visibilité', Colors.green),
            _buildConditionChip('🚫 Visibilité réduite', Colors.red),
          ],
        ),
      ],
    );
  }

  /// 🏷️ Chip pour les conditions
  Widget _buildConditionChip(String condition, Color couleur) {
    // Pour simplifier, on utilise une liste temporaire
    // Dans une vraie app, vous stockeriez cela dans l'état
    return FilterChip(
      label: Text(condition),
      selected: false, // À gérer avec l'état
      onSelected: (selected) {
        _sauvegarderAutomatiquement();
      },
      selectedColor: couleur.withOpacity(0.2),
      checkmarkColor: couleur,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  /// 🎨 Ouvrir l'éditeur de croquis
  void _ouvrirEditeurCroquis() async {
    // Créer une session temporaire pour le croquis si elle n'existe pas
    final session = widget.session ?? CollaborativeSession(
      id: _sessionId ?? 'temp_session',
      codeSession: 'CROQUIS_${DateTime.now().millisecondsSinceEpoch}',
      qrCodeData: '',
      typeAccident: widget.typeAccident,
      nombreVehicules: 1,
      statut: SessionStatus.en_cours,
      conducteurCreateur: FirebaseAuth.instance.currentUser?.uid ?? 'temp_user',
      participants: [],
      progression: SessionProgress(
        participantsRejoints: 1,
        formulairesTermines: 0,
        croquisValides: 0,
        signaturesEffectuees: 0,
        croquisCree: false,
        peutFinaliser: false,
      ),
      parametres: SessionSettings(
        autoValidationCroquis: false,
        timeoutMinutes: 30,
        notificationsActives: true,
        modeDebug: false,
      ),
      dateCreation: DateTime.now(),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernCollaborativeSketchScreen(session: session),
      ),
    );

    // Recharger le croquis après retour de l'éditeur
    await _chargerCroquisDepuisFirebase();

    // Capturer l'image du croquis si des données existent
    if (_croquisData.isNotEmpty) {
      await _capturerImageCroquis();
    }

    // Sauvegarder automatiquement après modification du croquis
    _sauvegarderAutomatiquement();
  }

  /// 📸 Marquer le croquis comme existant
  Future<void> _capturerImageCroquis() async {
    try {
      if (_croquisData.isEmpty) return;

      if (mounted) {
        setState(() {
          _croquisExiste = true;
        });
      }
      print('✅ Croquis marqué comme existant: ${_croquisData.length} éléments');
    } catch (e) {
      print('❌ Erreur marquage croquis: $e');
    }
  }

  /// 🤝 Charger les données communes de la session collaborative
  Future<void> _chargerDonneesCommunes() async {
    try {
      if (widget.session?.id == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .doc(widget.session!.id)
          .get();

      if (doc.exists && doc.data()?['donneesCommunes'] != null) {
        final donneesCommunes = doc.data()!['donneesCommunes'] as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _donneesCommunes = donneesCommunes;

            // Pré-remplir les champs avec les données communes
            if (donneesCommunes['dateAccident'] != null) {
              _dateController.text = donneesCommunes['dateAccident'];
            }
            if (donneesCommunes['heureAccident'] != null) {
              _heureController.text = donneesCommunes['heureAccident'];
            }
            if (donneesCommunes['lieuAccident'] != null) {
              _lieuController.text = donneesCommunes['lieuAccident'];
            }
            if (donneesCommunes['blesses'] != null) {
              _blesses = donneesCommunes['blesses'];
            }
          });
        }

        print('✅ Données communes chargées: ${donneesCommunes.keys}');
      }
    } catch (e) {
      print('❌ Erreur chargement données communes: $e');
    }
  }

  /// 💾 Sauvegarde automatique en sortie du formulaire
  Future<void> _sauvegardeAutomatiqueEnSortie() async {
    try {
      if (!_estModeCollaboratif || widget.session?.id == null) return;

      final donneesFormulaire = _collecterDonneesFormulaire();

      // Convertir Map<int, bool> en List<bool>
      List<bool> etapesValideesListe = List.generate(_nombreEtapes, (index) {
        return _etapesValidees[index + 1] ?? false;
      });

      await CollaborativeSessionStateService.sauvegardeAutomatiqueEnSortie(
        sessionId: widget.session!.id!,
        donneesFormulaire: donneesFormulaire,
        etapeActuelle: _etapeActuelle.toString(),
        etapesValidees: etapesValideesListe,
      );

      print('✅ Sauvegarde automatique en sortie effectuée');
    } catch (e) {
      print('❌ Erreur sauvegarde automatique en sortie: $e');
    }
  }

  /// 📋 Collecter toutes les données du formulaire
  Map<String, dynamic> _collecterDonneesFormulaire() {
    return {
      // Informations générales
      'dateAccident': _dateController.text,
      'heureAccident': _heureController.text,
      'lieuAccident': _lieuController.text,
      'blesses': _blesses,
      'detailsBlesses': _detailsBlessesController.text,
      'temoins': _temoins.map((t) => {
        'nom': t.nom,
        'telephone': t.telephone,
        'adresse': t.adresse,
      }).toList(),

      // Véhicule
      'vehicule': {
        'immatriculation': _immatriculationController.text,
        'marque': _marqueController.text,
        'modele': _modeleController.text,
        'numeroContrat': _numeroContratController.text,
        'compagnie': _compagnieController.text,
        'agence': _agenceController.text,
      },

      // Conducteur
      'conducteur': {
        'nom': _nomConducteurController.text,
        'prenom': _prenomConducteurController.text,
        'telephone': _telephoneController.text,
        'adresse': _adresseController.text,
      },

      // Point de choc et dégâts
      'pointChoc': _pointChocSelectionne,
      'photosDegatUrls': _photosDegatUrls,

      // Observations et circonstances
      'observations': _observationsController.text,
      'circonstances': _circonstancesSelectionnees,

      // Croquis et signature
      'croquisExiste': _croquisExiste,
      'croquisData': _croquisData,
      'signatureData': _signatureData,

      // Métadonnées
      'etapeActuelle': _etapeActuelle,
      'etapesValidees': _etapesValidees,
      'sessionId': _sessionId,
    };
  }

  /// 💾 Sauvegarder les données communes (pour le créateur)
  Future<void> _sauvegarderDonneesCommunes() async {
    try {
      if (!_estModeCollaboratif || !_estCreateur || widget.session?.id == null) return;

      final donneesCommunes = {
        'dateAccident': _dateController.text,
        'heureAccident': _heureController.text,
        'lieuAccident': _lieuController.text,
        'blesses': _blesses,
        'detailsBlesses': _detailsBlessesController.text,
        'temoins': _temoins.map((temoin) => {
          'nom': temoin.nom,
          'telephone': temoin.telephone,
          'adresse': temoin.adresse,
        }).toList(),
        'dateModification': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .doc(widget.session!.id)
          .update({
        'donneesCommunes': donneesCommunes,
      });

      print('✅ Données communes sauvegardées');
    } catch (e) {
      print('❌ Erreur sauvegarde données communes: $e');
    }
  }

  /// 📥 Charger le croquis depuis Firebase
  Future<void> _chargerCroquisDepuisFirebase() async {
    try {
      final sessionId = _sessionId ?? widget.session?.id;
      print('🔍 Tentative de chargement croquis pour session: $sessionId');

      if (sessionId == null) {
        print('❌ Aucun sessionId disponible pour charger le croquis');
        return;
      }

      // Essayer les deux collections possibles
      List<String> collections = ['collaborative_sessions', 'accident_sessions'];

      for (String collection in collections) {
        print('🔍 Recherche dans la collection: $collection');

        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(sessionId)
            .get();

        print('🔍 Document existe dans $collection: ${doc.exists}');

        if (doc.exists) {
          final data = doc.data();
          print('🔍 Données du document dans $collection: ${data?.keys}');
          print('🔍 Croquis data présent dans $collection: ${data?['croquis_data'] != null}');

          if (data?['croquis_data'] != null) {
            final croquisData = data!['croquis_data'] as List;
            final croquisImageUrl = data['croquis_image_url'] as String?;
            print('🔍 Nombre d\'éléments dans le croquis ($collection): ${croquisData.length}');
            print('🔍 URL image croquis: $croquisImageUrl');

            if (mounted) {
              setState(() {
                _croquisData = List<Map<String, dynamic>>.from(croquisData);
                _croquisExiste = _croquisData.isNotEmpty;
                _croquisImageUrl = croquisImageUrl;
              });
            }
            print('✅ Croquis chargé avec succès depuis $collection: ${_croquisData.length} éléments');
            return; // Sortir dès qu'on trouve des données
          } else {
            print('ℹ️ Aucune donnée de croquis trouvée dans $collection');
          }
        } else {
          print('❌ Document non trouvé dans $collection');
        }
      }

      // Si aucune donnée trouvée dans aucune collection
      if (mounted) {
        setState(() {
          _croquisData = [];
          _croquisExiste = false;
        });
      }
      print('❌ Aucun croquis trouvé dans aucune collection');

    } catch (e) {
      print('❌ Erreur chargement croquis: $e');
    }
  }

  /// 🤝 Informations sur le rôle collaboratif
  Widget _buildCollaborativeRoleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _estCreateur
              ? [Colors.orange[100]!, Colors.orange[50]!]
              : [Colors.blue[100]!, Colors.blue[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _estCreateur ? Colors.orange[300]! : Colors.blue[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _estCreateur ? Colors.orange[600] : Colors.blue[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _estCreateur ? Icons.star : Icons.group,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _estCreateur ? 'Créateur de la session' : 'Participant invité',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _estCreateur ? Colors.orange[800] : Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _estCreateur
                      ? 'Vous remplissez les informations communes pour tous les participants'
                      : _estUtilisateurInscrit
                          ? 'Certaines informations sont pré-remplies par le créateur'
                          : 'Vous devez remplir vos informations personnelles complètes',
                  style: TextStyle(
                    fontSize: 12,
                    color: _estCreateur ? Colors.orange[700] : Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          if (widget.session != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.session!.codeSession,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎨 Section croquis dans le résumé
  Widget _buildSectionCroquisResume() {
    print('🔍 [RÉSUMÉ CROQUIS] _croquisExiste: $_croquisExiste, _croquisData.length: ${_croquisData.length}');

    // Forcer le rechargement du croquis si pas encore chargé
    if (_croquisData.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🔄 Rechargement forcé du croquis depuis le résumé...');
        _chargerCroquisDepuisFirebase();
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.draw,
                  color: Colors.purple[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Croquis de l\'accident',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Contenu du croquis - Toujours afficher si des données existent
          if (_croquisData.isNotEmpty) ...[
            // Croquis dessiné directement
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  // Zone de dessin avec le croquis
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      child: CustomPaint(
                        size: const Size(double.infinity, 250),
                        painter: CroquisPreviewPainter(_croquisData),
                      ),
                    ),
                  ),
                  // Overlay avec informations
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_croquisData.length} éléments',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // Badge "Croquis créé"
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          const Text(
                            'Croquis créé',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Informations sur le croquis
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Croquis créé avec ${_croquisData.length} éléments',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    'Terminé',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_croquisData.isEmpty) ...[
            // Pas de croquis - Version simplifiée pour le résumé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun croquis créé (optionnel)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Non requis',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🔍 Voir une photo en grand
  void _voirPhotoEnGrand(String photoPath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Photo en grand
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(photoPath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Impossible de charger l\'image',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Bouton fermer
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

/// 🎨 Painter pour l'aperçu du croquis dans le résumé
class CroquisPreviewPainter extends CustomPainter {
  final List<Map<String, dynamic>> croquisData;

  CroquisPreviewPainter(this.croquisData);

  @override
  void paint(Canvas canvas, Size size) {
    if (croquisData.isEmpty) return;

    // Dessiner un fond blanc
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Créer un paint pour dessiner
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Dessiner chaque élément du croquis
    for (final element in croquisData) {
      try {
        final type = element['type'] as String?;
        final color = element['color'] as int?;
        final strokeWidth = (element['strokeWidth'] as num?)?.toDouble() ?? 2.0;

        if (color != null) {
          paint.color = Color(color);
        } else {
          paint.color = Colors.black;
        }
        paint.strokeWidth = strokeWidth * 0.8; // Réduire légèrement pour l'aperçu

        switch (type) {
          case 'path':
            _drawPath(canvas, element, paint, size);
            break;
          case 'line':
            _drawLine(canvas, element, paint, size);
            break;
          case 'circle':
            _drawCircle(canvas, element, paint, size);
            break;
          case 'rectangle':
            _drawRectangle(canvas, element, paint, size);
            break;
          case 'text':
            _drawText(canvas, element, size);
            break;
          case 'vehicle':
            _drawVehicle(canvas, element, paint, size);
            break;
          case 'road':
            _drawRoad(canvas, element, paint, size);
            break;
        }
      } catch (e) {
        print('❌ Erreur dessin élément croquis: $e');
      }
    }

    // Ajouter une bordure subtile
    final borderPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  void _drawPath(Canvas canvas, Map<String, dynamic> element, Paint paint, Size size) {
    final points = element['points'] as List?;
    if (points == null || points.isEmpty) return;

    final path = Path();
    bool isFirst = true;

    for (final point in points) {
      if (point is Map) {
        final x = (point['x'] as num?)?.toDouble();
        final y = (point['y'] as num?)?.toDouble();
        if (x != null && y != null) {
          // Adapter les coordonnées à la taille de l'aperçu
          final scaledX = x * size.width / 400; // Supposons une taille originale de 400
          final scaledY = y * size.height / 300; // Supposons une taille originale de 300

          if (isFirst) {
            path.moveTo(scaledX, scaledY);
            isFirst = false;
          } else {
            path.lineTo(scaledX, scaledY);
          }
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, Map<String, dynamic> element, Paint paint, Size size) {
    final start = element['start'] as Map?;
    final end = element['end'] as Map?;

    if (start != null && end != null) {
      final x1 = (start['x'] as num?)?.toDouble();
      final y1 = (start['y'] as num?)?.toDouble();
      final x2 = (end['x'] as num?)?.toDouble();
      final y2 = (end['y'] as num?)?.toDouble();

      if (x1 != null && y1 != null && x2 != null && y2 != null) {
        final scaledX1 = x1 * size.width / 400;
        final scaledY1 = y1 * size.height / 300;
        final scaledX2 = x2 * size.width / 400;
        final scaledY2 = y2 * size.height / 300;

        canvas.drawLine(
          Offset(scaledX1, scaledY1),
          Offset(scaledX2, scaledY2),
          paint,
        );
      }
    }
  }

  void _drawCircle(Canvas canvas, Map<String, dynamic> element, Paint paint, Size size) {
    final center = element['center'] as Map?;
    final radius = (element['radius'] as num?)?.toDouble();

    if (center != null && radius != null) {
      final x = (center['x'] as num?)?.toDouble();
      final y = (center['y'] as num?)?.toDouble();

      if (x != null && y != null) {
        final scaledX = x * size.width / 400;
        final scaledY = y * size.height / 300;
        final scaledRadius = radius * size.width / 400;

        canvas.drawCircle(
          Offset(scaledX, scaledY),
          scaledRadius,
          paint,
        );
      }
    }
  }

  void _drawRectangle(Canvas canvas, Map<String, dynamic> element, Paint paint, Size size) {
    final rect = element['rect'] as Map?;

    if (rect != null) {
      final left = (rect['left'] as num?)?.toDouble();
      final top = (rect['top'] as num?)?.toDouble();
      final right = (rect['right'] as num?)?.toDouble();
      final bottom = (rect['bottom'] as num?)?.toDouble();

      if (left != null && top != null && right != null && bottom != null) {
        final scaledLeft = left * size.width / 400;
        final scaledTop = top * size.height / 300;
        final scaledRight = right * size.width / 400;
        final scaledBottom = bottom * size.height / 300;

        canvas.drawRect(
          Rect.fromLTRB(scaledLeft, scaledTop, scaledRight, scaledBottom),
          paint,
        );
      }
    }
  }

  void _drawText(Canvas canvas, Map<String, dynamic> element, Size size) {
    final text = element['text'] as String?;
    final position = element['position'] as Map?;
    final fontSize = (element['fontSize'] as num?)?.toDouble() ?? 14.0;
    final color = element['color'] as int?;

    if (text != null && position != null) {
      final x = (position['x'] as num?)?.toDouble();
      final y = (position['y'] as num?)?.toDouble();

      if (x != null && y != null) {
        final scaledX = x * size.width / 400;
        final scaledY = y * size.height / 300;
        final scaledFontSize = fontSize * size.width / 400;

        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color != null ? Color(color) : Colors.black,
              fontSize: scaledFontSize,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(canvas, Offset(scaledX, scaledY));
      }
    }
  }

  void _drawVehicle(Canvas canvas, Map<String, dynamic> element, Paint paint, Size size) {
    final center = element['center'] as Map?;
    final vehicleSize = (element['size'] as num?)?.toDouble() ?? 30.0;

    if (center != null) {
      final x = (center['x'] as num?)?.toDouble();
      final y = (center['y'] as num?)?.toDouble();

      if (x != null && y != null) {
        final scaledX = x * size.width / 400;
        final scaledY = y * size.height / 300;
        final scaledSize = vehicleSize * size.width / 400;

        // Dessiner un rectangle pour représenter le véhicule
        final rect = Rect.fromCenter(
          center: Offset(scaledX, scaledY),
          width: scaledSize,
          height: scaledSize * 0.6,
        );

        paint.style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);

        // Bordure
        paint.style = PaintingStyle.stroke;
        paint.color = Colors.black;
        paint.strokeWidth = 1.0;
        canvas.drawRect(rect, paint);
      }
    }
  }

  void _drawRoad(Canvas canvas, Map<String, dynamic> element, Paint paint, Size size) {
    final start = element['start'] as Map?;
    final end = element['end'] as Map?;

    if (start != null && end != null) {
      final x1 = (start['x'] as num?)?.toDouble();
      final y1 = (start['y'] as num?)?.toDouble();
      final x2 = (end['x'] as num?)?.toDouble();
      final y2 = (end['y'] as num?)?.toDouble();

      if (x1 != null && y1 != null && x2 != null && y2 != null) {
        final scaledX1 = x1 * size.width / 400;
        final scaledY1 = y1 * size.height / 300;
        final scaledX2 = x2 * size.width / 400;
        final scaledY2 = y2 * size.height / 300;

        // Dessiner une ligne épaisse pour la route
        paint.strokeWidth = 8.0;
        paint.color = Colors.grey[600]!;
        canvas.drawLine(
          Offset(scaledX1, scaledY1),
          Offset(scaledX2, scaledY2),
          paint,
        );

        // Ligne centrale pointillée
        paint.strokeWidth = 2.0;
        paint.color = Colors.white;
        _drawDashedLine(canvas, Offset(scaledX1, scaledY1), Offset(scaledX2, scaledY2), paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startRatio = (i * (dashWidth + dashSpace)) / distance;
      final endRatio = ((i * (dashWidth + dashSpace)) + dashWidth) / distance;

      final dashStart = Offset.lerp(start, end, startRatio)!;
      final dashEnd = Offset.lerp(start, end, endRatio)!;

      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
