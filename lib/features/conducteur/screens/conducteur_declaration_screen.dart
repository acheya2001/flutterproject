import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/session_utils.dart';
import '../../constat/models/constat_model.dart';
import '../../constat/models/temoin_model.dart';
import '../../constat/models/session_constat_model.dart';
import '../../constat/models/proprietaire_info.dart';
import '../../constat/providers/session_provider.dart';
import '../models/conducteur_info_model.dart';
import '../models/vehicule_accident_model.dart';
import '../models/assurance_info_model.dart';
import '../../constat/providers/constat_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ConducteurDeclarationScreen extends StatefulWidget {
  final String? sessionId;
  final String conducteurPosition;
  final String? invitationCode;

  const ConducteurDeclarationScreen({
    Key? key,
    this.sessionId,
    required this.conducteurPosition,
    this.invitationCode,
  }) : super(key: key);

  @override
  State<ConducteurDeclarationScreen> createState() => _ConducteurDeclarationScreenState();
}

class _ConducteurDeclarationScreenState extends State<ConducteurDeclarationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Contrôleurs de formulaire
  final _lieuController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _marqueController = TextEditingController();
  final _typeController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _sensController = TextEditingController();
  final _venantDeController = TextEditingController();
  final _allantAController = TextEditingController();
  final _societeAssuranceController = TextEditingController();
  final _numeroContratController = TextEditingController();
  final _agenceController = TextEditingController();
  final _observationsController = TextEditingController();

  // Contrôleurs pour le propriétaire (si différent du conducteur)
  final _proprietaireNomController = TextEditingController();
  final _proprietairePrenomController = TextEditingController();
  final _proprietaireAdresseController = TextEditingController();
  final _proprietaireTelephoneController = TextEditingController();

  // Variables d'état
  int _currentPage = 0;
  DateTime? _dateAccident;
  TimeOfDay? _heureAccident;
  Position? _positionActuelle;
  bool _blessesLegers = false;
  bool _degatsMaterielsAutres = false;
  bool _estProprietaire = true;
  final List<int> _circonstancesSelectionnees = [];
  final List<String> _degatsApparents = [];
  final List<File> _photosAccident = [];
  File? _photoPermis;
  File? _photoCarteGrise;
  File? _photoAttestation;
  final List<TemoinModel> _temoins = [];
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: const Color(0xFF2E3A59),
    exportBackgroundColor: Colors.white,
  );

  SessionConstatModel? _session;
  bool _isSessionMode = false;
  bool _isLoading = false;

  // Listes des circonstances (basées sur le constat papier)
  final List<String> _circonstances = [
    'En stationnement',
    'Quittait un stationnement',
    'Prenait un stationnement',
    'Sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre',
    'S\'engageait dans un parking, un lieu privé, un chemin de terre',
    'À l\'arrêt (circulation arrêtée)',
    'Roulait',
    'Heurtait à l\'arrière, en roulant dans le même sens et sur une même file',
    'Roulait dans le même sens et sur une file différente',
    'Changeait de file',
    'Doublait',
    'Virait à droite',
    'Virait à gauche',
    'Reculait',
    'Empiétait sur la partie de chaussée réservée à la circulation en sens inverse',
    'Venait de droite (dans un carrefour)',
    'N\'avait pas observé le signal de priorité',
  ];

  Color get _currentPositionColor => SessionUtils.getPositionColor(widget.conducteurPosition);

  @override
  void initState() {
    super.initState();
    _isSessionMode = widget.sessionId != null;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _obtenirPositionActuelle();
    
    if (_isSessionMode) {
      _chargerSession();
    }
  }

  Future<void> _chargerSession() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      final session = await sessionProvider.getSession(widget.sessionId!);
      
      setState(() {
        _session = session;
        // Pré-remplir les informations communes si elles existent
        if (session.lieuAccident.isNotEmpty) {
          _lieuController.text = session.lieuAccident;
        }
        _dateAccident = session.dateAccident;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Erreur chargement session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement session: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _signatureController.dispose();
    // Dispose des contrôleurs
    _lieuController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _numeroPermisController.dispose();
    _marqueController.dispose();
    _typeController.dispose();
    _immatriculationController.dispose();
    _sensController.dispose();
    _venantDeController.dispose();
    _allantAController.dispose();
    _societeAssuranceController.dispose();
    _numeroContratController.dispose();
    _agenceController.dispose();
    _observationsController.dispose();
    _proprietaireNomController.dispose();
    _proprietairePrenomController.dispose();
    _proprietaireAdresseController.dispose();
    _proprietaireTelephoneController.dispose();
    super.dispose();
  }

  Future<void> _obtenirPositionActuelle() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      _positionActuelle = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lieuController.text = 'Lat: ${_positionActuelle!.latitude.toStringAsFixed(6)}, '
              'Lng: ${_positionActuelle!.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
    }
  }

  Future<void> _selectionnerDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateAccident ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _currentPositionColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _heureAccident ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: _currentPositionColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: const Color(0xFF1F2937),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _dateAccident = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          _heureAccident = time;
        });
      }
    }
  }

  Future<void> _prendrePhoto(String type) async {
    final picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentPositionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: _currentPositionColor),
              ),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
              ),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          switch (type) {
            case 'accident':
              _photosAccident.add(File(pickedFile.path));
              break;
            case 'permis':
              _photoPermis = File(pickedFile.path);
              // TODO: Implémenter OCR pour extraire les informations du permis
              _extraireInfosPermis(File(pickedFile.path));
              break;
            case 'carte_grise':
              _photoCarteGrise = File(pickedFile.path);
              // TODO: Implémenter OCR pour extraire les informations de la carte grise
              _extraireInfosCarteGrise(File(pickedFile.path));
              break;
            case 'attestation':
              _photoAttestation = File(pickedFile.path);
              // TODO: Implémenter OCR pour extraire les informations d'assurance
              _extraireInfosAssurance(File(pickedFile.path));
              break;
          }
        });
      }
    }
  }

  // Méthodes OCR à implémenter
  Future<void> _extraireInfosPermis(File imageFile) async {
    // TODO: Implémentation future de l'OCR pour le permis
    debugPrint('OCR Permis: ${imageFile.path}');
  }

  Future<void> _extraireInfosCarteGrise(File imageFile) async {
    // TODO: Implémentation future de l'OCR pour la carte grise
    debugPrint('OCR Carte Grise: ${imageFile.path}');
  }

  Future<void> _extraireInfosAssurance(File imageFile) async {
    // TODO: Implémentation future de l'OCR pour l'assurance
    debugPrint('OCR Assurance: ${imageFile.path}');
  }

  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => _TemoinDialog(
        onAjouter: (temoin) {
          setState(() {
            _temoins.add(temoin);
          });
        },
        positionColor: _currentPositionColor,
      ),
    );
  }

  void _pageSuivante() {
    if (_currentPage < 7) { // 8 pages au total (0-7)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pagePrecedente() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _genererConstatId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 10000).toString().padLeft(4, '0');
    return 'CONST_${DateFormat('yyyyMMdd').format(now)}_$random';
  }

  // Créer un GeoPoint si nécessaire (adapter selon votre modèle)
  dynamic _creerGeoPoint() {
    if (_positionActuelle != null) {
      return {
        'latitude': _positionActuelle!.latitude,
        'longitude': _positionActuelle!.longitude,
      };
    }
    return null;
  }

  Future<void> _sauvegarderConstat() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (_isSessionMode) {
        await _sauvegarderDansSession();
      } else {
        await _sauvegarderConstatSimple();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Constat sauvegardé avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sauvegarderDansSession() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Obtenir la signature
    Uint8List? signature;
    if (_signatureController.isNotEmpty) {
      signature = await _signatureController.toPngBytes();
    }

    final now = DateTime.now();

    final conducteurInfo = ConducteurInfoModel(
      nom: _nomController.text,
      prenom: _prenomController.text,
      adresse: _adresseController.text,
      telephone: _telephoneController.text,
      numeroPermis: _numeroPermisController.text,
      userId: authProvider.currentUser!.id,
      createdAt: now,
    );

    final vehiculeInfo = VehiculeAccidentModel(
      marque: _marqueController.text,
      type: _typeController.text,
      numeroImmatriculation: _immatriculationController.text,
      venantDe: _venantDeController.text,
      allantA: _allantAController.text,
      degatsApparents: _degatsApparents,
      conducteurId: '',
      createdAt: now,
    );

    final assuranceInfo = AssuranceInfoModel(
      societeAssurance: _societeAssuranceController.text,
      numeroContrat: _numeroContratController.text,
      agence: _agenceController.text,
      conducteurId: '',
      createdAt: now,
    );

    ProprietaireInfo? proprietaireInfo;
    if (!_estProprietaire) {
      proprietaireInfo = ProprietaireInfo(
        nom: _proprietaireNomController.text,
        prenom: _proprietairePrenomController.text,
        adresse: _proprietaireAdresseController.text,
        telephone: _proprietaireTelephoneController.text,
      );
    }

    await sessionProvider.sauvegarderConducteurDansSession(
      sessionId: widget.sessionId!,
      position: widget.conducteurPosition,
      conducteurInfo: conducteurInfo,
      vehiculeInfo: vehiculeInfo,
      assuranceInfo: assuranceInfo,
      isProprietaire: _estProprietaire,
      proprietaireInfo: proprietaireInfo,
      circonstances: _circonstancesSelectionnees,
      degatsApparents: _degatsApparents,
      temoins: _temoins,
      photosAccident: _photosAccident,
      photoPermis: _photoPermis,
      photoCarteGrise: _photoCarteGrise,
      photoAttestation: _photoAttestation,
      signature: signature,
      observations: _observationsController.text,
    );
  }

  Future<void> _sauvegarderConstatSimple() async {
    final constatProvider = Provider.of<ConstatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Obtenir la signature
    Uint8List? signature;
    if (_signatureController.isNotEmpty) {
      signature = await _signatureController.toPngBytes();
    }

    final now = DateTime.now();

    // Créer le modèle de constat
    final constat = ConstatModel(
      id: '',
      dateAccident: _dateAccident ?? now,
      lieuAccident: _lieuController.text,
      coordonnees: _creerGeoPoint(),
      adresseAccident: _lieuController.text,
      vehiculeIds: [],
      conducteurIds: [],
      temoinsIds: [],
      photosUrls: [],
      validationStatus: {},
      status: ConstatStatus.draft,
      createdAt: now,
      updatedAt: now,
      createdBy: authProvider.currentUser!.id,
      circonstances: {
        'selectionnees': _circonstancesSelectionnees,
        'nombre': _circonstancesSelectionnees.length,
      },
      dommages: {
        'degats': _degatsApparents,
      },
      observations: _observationsController.text.isNotEmpty 
          ? {'texte': _observationsController.text} 
          : null,
    );

    final conducteurInfo = ConducteurInfoModel(
      nom: _nomController.text,
      prenom: _prenomController.text,
      adresse: _adresseController.text,
      telephone: _telephoneController.text,
      numeroPermis: _numeroPermisController.text,
      userId: authProvider.currentUser!.id,
      createdAt: now,
    );

    final vehiculeInfo = VehiculeAccidentModel(
      marque: _marqueController.text,
      type: _typeController.text,
      numeroImmatriculation: _immatriculationController.text,
      venantDe: _venantDeController.text,
      allantA: _allantAController.text,
      degatsApparents: _degatsApparents,
      conducteurId: '',
      createdAt: now,
    );

    final assuranceInfo = AssuranceInfoModel(
      societeAssurance: _societeAssuranceController.text,
      numeroContrat: _numeroContratController.text,
      agence: _agenceController.text,
      conducteurId: '',
      createdAt: now,
    );

    await constatProvider.sauvegarderConstatComplet(
      constat: constat,
      conducteurInfo: conducteurInfo,
      vehiculeInfo: vehiculeInfo,
      assuranceInfo: assuranceInfo,
      temoins: _temoins,
      photosAccident: _photosAccident,
      photoPermis: _photoPermis,
      photoCarteGrise: _photoCarteGrise,
      photoAttestation: _photoAttestation,
      signature: signature,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: CustomAppBar(
          title: _isSessionMode 
              ? 'Constat Collaboratif - Conducteur ${widget.conducteurPosition}'
              : 'Constat d\'accident',
          backgroundColor: _currentPositionColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: _isSessionMode 
            ? 'Constat Collaboratif - Conducteur ${widget.conducteurPosition}'
            : 'Constat d\'accident',
        backgroundColor: _currentPositionColor,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Indicateur de session collaborative
            if (_isSessionMode) _buildSessionHeader(),
            
            // Indicateur de progression
            _buildProgressIndicator(),
            
            // Contenu des pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPageInfosGenerales(),
                  _buildPageConducteur(),
                  _buildPageProprietaire(),
                  _buildPageVehicule(),
                  _buildPageAssurance(),
                  _buildPageCirconstances(),
                  _buildPagePhotos(),
                  _buildPageSignature(),
                ],
              ),
            ),
            
            // Boutons de navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader() {
    if (_session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentPositionColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.conducteurPosition,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                      'Session: ${_session!.sessionCode}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_session!.nombreConducteurs} conducteurs impliqués',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: _showSessionInfo,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSessionProgress(),
        ],
      ),
    );
  }

  Widget _buildSessionProgress() {
    if (_session == null) return const SizedBox.shrink();

    final completed = _session!.conducteursInfo.values
        .where((info) => info.isCompleted)
        .length;
    final total = _session!.nombreConducteurs;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progression globale',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            Text(
              '$completed/$total terminés',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: completed / total,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    const totalPages = 8;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Étape ${_currentPage + 1} sur $totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              Text(
                '${((_currentPage + 1) / totalPages * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _currentPositionColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / totalPages,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(_currentPositionColor),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPageInfosGenerales() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Informations générales',
              'Renseignez les détails de l\'accident',
              Icons.info_outline,
              _currentPositionColor,
            ),
            const SizedBox(height: 24),
            
            // Date et heure
            _buildDateTimeSelector(),
            const SizedBox(height: 20),
            
            // Lieu
            CustomTextField(
              controller: _lieuController,
              label: 'Lieu de l\'accident',
              hintText: 'Adresse ou description du lieu',
              prefixIcon: Icons.location_on,
              validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
              suffixIcon: IconButton(
                icon: Icon(Icons.my_location, color: _currentPositionColor),
                onPressed: _obtenirPositionActuelle,
              ),
            ),
            const SizedBox(height: 20),
            
            // Blessés et dégâts
            _buildCheckboxSection(),
            const SizedBox(height: 20),
            
            // Témoins
            _buildTemoinsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageConducteur() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Informations du conducteur',
            'Vos informations personnelles',
            Icons.person,
            _currentPositionColor,
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _nomController,
                  label: 'Nom',
                  prefixIcon: Icons.person_outline,
                  validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _prenomController,
                  label: 'Prénom',
                  prefixIcon: Icons.person_outline,
                  validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _adresseController,
            label: 'Adresse',
            prefixIcon: Icons.home,
            maxLines: 2,
            validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          
          // Permis de conduire
          _buildPermisSection(),
        ],
      ),
    );
  }

  Widget _buildPageProprietaire() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Propriétaire du véhicule',
            'Êtes-vous le propriétaire du véhicule ?',
            Icons.person_pin,
            _currentPositionColor,
          ),
          const SizedBox(height: 24),
          
          // Question propriétaire
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Êtes-vous le propriétaire de ce véhicule ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _estProprietaire = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _estProprietaire ? const Color(0xFF10B981) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _estProprietaire ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: _estProprietaire ? Colors.white : const Color(0xFF374151),
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Oui',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _estProprietaire ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _estProprietaire = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: !_estProprietaire ? const Color(0xFFEF4444) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !_estProprietaire ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cancel,
                                color: !_estProprietaire ? Colors.white : const Color(0xFF374151),
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Non',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: !_estProprietaire ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Informations du propriétaire si différent
          if (!_estProprietaire) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Veuillez renseigner les informations du propriétaire du véhicule',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _proprietaireNomController,
                    label: 'Nom du propriétaire',
                    prefixIcon: Icons.person_outline,
                    validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _proprietairePrenomController,
                    label: 'Prénom du propriétaire',
                    prefixIcon: Icons.person_outline,
                    validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              controller: _proprietaireAdresseController,
              label: 'Adresse du propriétaire',
              prefixIcon: Icons.home,
              maxLines: 2,
              validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              controller: _proprietaireTelephoneController,
              label: 'Téléphone du propriétaire',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageVehicule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Informations du véhicule',
            'Détails de votre véhicule',
            Icons.directions_car,
            _currentPositionColor,
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _marqueController,
                  label: 'Marque',
                  prefixIcon: Icons.branding_watermark,
                  validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _typeController,
                  label: 'Type/Modèle',
                  prefixIcon: Icons.model_training,
                  validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _immatriculationController,
            label: 'N° d\'immatriculation',
            prefixIcon: Icons.confirmation_number,
            validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _sensController,
            label: 'Sens suivi',
            prefixIcon: Icons.navigation,
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _venantDeController,
                  label: 'Venant de',
                  prefixIcon: Icons.arrow_back,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _allantAController,
                  label: 'Allant à',
                  prefixIcon: Icons.arrow_forward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Carte grise
          _buildCarteGriseSection(),
        ],
      ),
    );
  }

  Widget _buildPageAssurance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Informations d\'assurance',
            'Détails de votre assurance',
            Icons.security,
            _currentPositionColor,
          ),
          const SizedBox(height: 24),
          
          CustomTextField(
            controller: _societeAssuranceController,
            label: 'Société d\'assurance',
            prefixIcon: Icons.business,
            validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _numeroContratController,
            label: 'N° de contrat',
            prefixIcon: Icons.description,
            validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
          ),
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _agenceController,
            label: 'Agence',
            prefixIcon: Icons.location_city,
            validator: (value) => value?.isEmpty == true ? 'Champ requis' : null,
          ),
          const SizedBox(height: 20),
          
          // Attestation d'assurance
          _buildAttestationSection(),
        ],
      ),
    );
  }

  Widget _buildPageCirconstances() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Circonstances',
            'Cochez les cases correspondant à votre situation',
            Icons.checklist,
            _currentPositionColor,
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _currentPositionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.info, color: _currentPositionColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sélectionnez toutes les circonstances qui s\'appliquent',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nombre sélectionné: ${_circonstancesSelectionnees.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _currentPositionColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          ...List.generate(_circonstances.length, (index) {
            final isSelected = _circonstancesSelectionnees.contains(index + 1);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? _currentPositionColor.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _currentPositionColor : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _circonstancesSelectionnees.add(index + 1);
                    } else {
                      _circonstancesSelectionnees.remove(index + 1);
                    }
                  });
                },
                title: Text(
                  '${index + 1}. ${_circonstances[index]}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? _currentPositionColor : const Color(0xFF374151),
                  ),
                ),
                activeColor: _currentPositionColor,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            );
          }),
          
          const SizedBox(height: 20),
          
          // Dégâts apparents
          _buildDegatsSection(),
          const SizedBox(height: 20),
          
          // Observations
          CustomTextField(
            controller: _observationsController,
            label: 'Observations',
            hintText: 'Décrivez brièvement l\'accident...',
            prefixIcon: Icons.note,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPagePhotos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Photos et documents',
            'Ajoutez les photos nécessaires',
            Icons.camera_alt,
            _currentPositionColor,
          ),
          const SizedBox(height: 24),
          
          // Photos de l'accident
          _buildPhotosAccidentSection(),
          const SizedBox(height: 24),
          
          // Documents
          _buildDocumentsSection(),
        ],
      ),
    );
  }

  Widget _buildPageSignature() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Signature',
            'Signez pour valider votre déclaration',
            Icons.draw,
            _currentPositionColor,
          ),
          const SizedBox(height: 24),
          
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Effacer',
                    onPressed: () {
                      _signatureController.clear();
                    },
                    color: const Color(0xFF6B7280),
                    isOutlined: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Aperçu',
                    onPressed: () async {
                      final signature = await _signatureController.toPngBytes();
                      if (signature != null && mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Aperçu de la signature'),
                            content: Image.memory(signature),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    color: _currentPositionColor,
                    isOutlined: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: _currentPositionColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Information importante',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'En signant ce constat, vous certifiez que les informations fournies sont exactes. '
                  'Ce document sera transmis à votre compagnie d\'assurance.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Précédent',
                  onPressed: _pagePrecedente,
                  color: const Color(0xFF6B7280),
                  isOutlined: true,
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _currentPage == 7 ? 'Terminer' : 'Suivant',
                onPressed: _currentPage == 7 ? _sauvegarderConstat : _pageSuivante,
                color: _currentPositionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionInfo() {
    if (_session == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de la session'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Code de session: ${_session!.sessionCode}'),
              const SizedBox(height: 8),
              Text('Nombre de conducteurs: ${_session!.nombreConducteurs}'),
              const SizedBox(height: 16),
              const Text(
                'État des conducteurs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._session!.conducteursInfo.entries.map((entry) {
                final position = entry.key;
                final info = entry.value;
                final color = SessionUtils.getPositionColor(position);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            position,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                              'Conducteur $position',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              info.isCompleted 
                                  ? 'Terminé' 
                                  : info.hasJoined 
                                      ? 'En cours' 
                                      : info.isInvited 
                                          ? 'Invité' 
                                          : 'En attente',
                              style: TextStyle(
                                fontSize: 12,
                                color: info.isCompleted 
                                    ? Colors.green 
                                    : info.hasJoined 
                                        ? Colors.orange 
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        info.isCompleted 
                            ? Icons.check_circle 
                            : info.hasJoined 
                                ? Icons.access_time 
                                : Icons.mail_outline,
                        color: color,
                        size: 20,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return InkWell(
      onTap: _selectionnerDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentPositionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_today, color: _currentPositionColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date et heure de l\'accident',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateAccident != null
                        ? DateFormat('dd/MM/yyyy à HH:mm').format(_dateAccident!)
                        : 'Sélectionner la date et l\'heure',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _dateAccident != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conséquences de l\'accident',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _blessesLegers,
            onChanged: (value) {
              setState(() {
                _blessesLegers = value ?? false;
              });
            },
            title: const Text(
              'Blessés (même légers)',
              style: TextStyle(fontSize: 14),
            ),
            activeColor: const Color(0xFFEF4444),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _degatsMaterielsAutres,
            onChanged: (value) {
              setState(() {
                _degatsMaterielsAutres = value ?? false;
              });
            },
            title: const Text(
              'Dégâts matériels autres qu\'aux véhicules',
              style: TextStyle(fontSize: 14),
            ),
            activeColor: const Color(0xFFF59E0B),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTemoinsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Témoins',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: CustomButton(
                  text: 'Ajouter',
                  onPressed: _ajouterTemoin,
                  color: _currentPositionColor,
                  isOutlined: true,
                  isCompact: true,
                ),
              ),
            ],
          ),
          if (_temoins.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(_temoins.length, (index) {
              final temoin = _temoins[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            temoin.nom,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          if (temoin.telephone?.isNotEmpty == true)
                            Text(
                              temoin.telephone!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
                      onPressed: () {
                        setState(() {
                          _temoins.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPermisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permis de conduire',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _numeroPermisController,
            label: 'N° de permis (optionnel)',
            prefixIcon: Icons.credit_card,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _prendrePhoto('permis'),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _photoPermis != null ? Colors.transparent : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _photoPermis != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _photoPermis!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 32, color: Color(0xFF6B7280)),
                          SizedBox(height: 8),
                          Text(
                            'Photo du permis (optionnel)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteGriseSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carte grise',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _prendrePhoto('carte_grise'),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _photoCarteGrise != null ? Colors.transparent : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _photoCarteGrise != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _photoCarteGrise!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 32, color: Color(0xFF6B7280)),
                          SizedBox(height: 8),
                          Text(
                            'Photo de la carte grise',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttestationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attestation d\'assurance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _prendrePhoto('attestation'),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _photoAttestation != null ? Colors.transparent : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _photoAttestation != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _photoAttestation!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 32, color: Color(0xFF6B7280)),
                          SizedBox(height: 8),
                          Text(
                            'Photo de l\'attestation',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDegatsSection() {
    final degatsOptions = [
      'Pare-chocs avant',
      'Pare-chocs arrière',
      'Aile avant droite',
      'Aile avant gauche',
      'Aile arrière droite',
      'Aile arrière gauche',
      'Portière avant droite',
      'Portière avant gauche',
      'Portière arrière droite',
      'Portière arrière gauche',
      'Capot',
      'Coffre',
      'Toit',
      'Pare-brise',
      'Lunette arrière',
      'Phares',
      'Feux arrière',
      'Rétroviseurs',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dégâts apparents',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: degatsOptions.map((degat) {
              final isSelected = _degatsApparents.contains(degat);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _degatsApparents.remove(degat);
                    } else {
                      _degatsApparents.add(degat);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _currentPositionColor : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _currentPositionColor : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    degat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosAccidentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Photos de l\'accident',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: CustomButton(
                  text: 'Ajouter',
                  onPressed: () => _prendrePhoto('accident'),
                  color: _currentPositionColor,
                  isOutlined: true,
                  isCompact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_photosAccident.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photosAccident.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _photosAccident[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _photosAccident.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
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
                );
              },
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 32, color: Color(0xFF6B7280)),
                    SizedBox(height: 8),
                    Text(
                      'Aucune photo ajoutée',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      children: [
        _buildPermisSection(),
        const SizedBox(height: 16),
        _buildCarteGriseSection(),
        const SizedBox(height: 16),
        _buildAttestationSection(),
      ],
    );
  }
}

class _TemoinDialog extends StatefulWidget {
  final Function(TemoinModel) onAjouter;
  final Color positionColor;

  const _TemoinDialog({
    required this.onAjouter,
    required this.positionColor,
  });

  @override
  State<_TemoinDialog> createState() => _TemoinDialogState();
}

class _TemoinDialogState extends State<_TemoinDialog> {
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  bool _estPassagerA = false;
  bool _estPassagerB = false;

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _nomController,
              label: 'Nom complet',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _adresseController,
              label: 'Adresse',
              prefixIcon: Icons.home,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _telephoneController,
              label: 'Téléphone',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _estPassagerA,
              onChanged: (value) {
                setState(() {
                  _estPassagerA = value ?? false;
                  if (_estPassagerA) _estPassagerB = false;
                });
              },
              title: const Text('Passager du véhicule A'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: widget.positionColor,
            ),
            CheckboxListTile(
              value: _estPassagerB,
              onChanged: (value) {
                setState(() {
                  _estPassagerB = value ?? false;
                  if (_estPassagerB) _estPassagerA = false;
                });
              },
              title: const Text('Passager du véhicule B'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: widget.positionColor,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.positionColor,
          ),
          onPressed: () {
            if (_nomController.text.isNotEmpty && _adresseController.text.isNotEmpty) {
              final temoin = TemoinModel(
                nom: _nomController.text,
                adresse: _adresseController.text,
                telephone: _telephoneController.text.isNotEmpty ? _telephoneController.text : null,
                estPassagerA: _estPassagerA,
                estPassagerB: _estPassagerB,
                constatId: '',
                createdAt: DateTime.now(),
              );
              widget.onAjouter(temoin);
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
