import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/providers/auth_provider.dart';

import '../../constat/models/constat_model.dart';
import '../../constat/models/session_constat_model.dart';
import '../../constat/providers/constat_provider.dart';
import '../../constat/providers/session_provider.dart';
import '../models/conducteur_info_model.dart';
import '../models/vehicule_accident_model.dart';
import '../models/assurance_info_model.dart';
import '../../constat/models/temoin_model.dart';
import '../../constat/models/proprietaire_info.dart';
import '../../../core/utils/session_utils.dart';
import '../../../core/services/session_service.dart';
import '../widgets/email_invitation_dialog.dart';
import '../../constat/screens/autres_conducteurs_screen.dart';




class ConducteurDeclarationScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String conducteurPosition;
  final String? invitationCode;
  final bool isCollaborative;

  const ConducteurDeclarationScreen({
    Key? key,
    this.sessionId,
    required this.conducteurPosition,
    this.invitationCode,
    this.isCollaborative = false,
  }) : super(key: key);

  @override
  ConsumerState<ConducteurDeclarationScreen> createState() => _ConducteurDeclarationScreenState();
}

class _ConducteurDeclarationScreenState extends ConsumerState<ConducteurDeclarationScreen> with TickerProviderStateMixin {
  int _nombreVehicules = 2;
  // String? _sessionId; // This was in your original, but widget.sessionId is used
  bool isValidEmail(String email) {
  final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  return emailRegExp.hasMatch(email);
}
  // Ajoutez cette liste de circonstances au début de votre classe
  final List<String> _circonstances = [
    'en stationnement',
    'quittait un stationnement',
    'prenait un stationnement',
    'sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre',
    's\'engageait dans un parking, un lieu privé, d\'un chemin de terre',
    'arrêt de circulation',
    'frottement sans changement de file',
    'heurtait à l\'arrière, en roulant dans le même sens et sur une même file',
    'roulait dans le même sens et sur une file différente',
    'changeait de file',
    'doublait',
    'virait à droite',
    'virait à gauche',
    'reculait',
    'empiétait sur la partie de chaussée réservée à la circulation en sens inverse',
    'venait de droite (dans un carrefour)',
    'n\'avait pas observé le signal de priorité',
  ];
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Contrôleurs de texte
  final _lieuController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _numeroPermisController = TextEditingController();

  final _proprietaireNomController = TextEditingController();
  final _proprietairePrenomController = TextEditingController();

  final _proprietaireAdresseController = TextEditingController();
  final _proprietaireTelephoneController = TextEditingController();
  final _marqueController = TextEditingController();
  final _typeController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _venantDeController = TextEditingController();
  final _allantAController = TextEditingController();
  final _sensController = TextEditingController();
  final _societeAssuranceController = TextEditingController();
  final _numeroContratController = TextEditingController();
  final _agenceController = TextEditingController();
  final _observationsController = TextEditingController();

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

  late Color _currentPositionColor;

  @override
  void initState() {
    super.initState();
    
    _currentPositionColor = SessionUtils.getPositionColor(widget.conducteurPosition);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    _isSessionMode = widget.sessionId != null;

     _obtenirPositionActuelle(); // Call it here if needed on init
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Session loading désactivé pour éviter les erreurs de provider
    // La session sera chargée manuellement si nécessaire
    debugPrint('[ConducteurDeclaration] didChangeDependencies - Session mode: $_isSessionMode');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    
    _lieuController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _numeroPermisController.dispose();
    // _nomProprietaireController.dispose();
    // _adresseProprietaireController.dispose();
    _proprietaireNomController.dispose();
    _proprietairePrenomController.dispose();
    _proprietaireAdresseController.dispose();
    _proprietaireTelephoneController.dispose();
    _marqueController.dispose();
    _typeController.dispose();
    _immatriculationController.dispose();
    _venantDeController.dispose();
    _allantAController.dispose();
    _sensController.dispose();
    _societeAssuranceController.dispose();
    _numeroContratController.dispose();
    _agenceController.dispose();
    _observationsController.dispose();
    _signatureController.dispose();
    
    super.dispose();
  }

    Future<void> _chargerSession() async {
    if (widget.sessionId == null) return; // Guard clause
    setState(() => _isLoading = true);
    try {
      // Note: SessionProvider n'est pas un provider Riverpod, nous devons l'instancier
      // Pour l'instant, nous allons créer une instance temporaire
      final sessionProvider = SessionProvider(
        sessionService: SessionService(),
      );
      final sessionData = await sessionProvider.getSession(widget.sessionId!);
      
      if(mounted) {
        setState(() {
          _session = sessionData;
          if (_session != null) {
            if (_session!.lieuAccident.isNotEmpty) {
              _lieuController.text = _session!.lieuAccident;
            }
            _dateAccident = _session!.dateAccident;
            _heureAccident = TimeOfDay.fromDateTime(_session!.dateAccident);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement session: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // Utiliser WidgetsBinding pour afficher le message après que le widget soit construit
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur chargement session: $e'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        });
      }
    }
  }

  // This method seems unused in the provided code, but kept for completeness if needed later.
  // Future<void> _chargerDetailsSession() async {
  //   if (widget.sessionId == null) return;
  //   try {
  //     setState(() {
  //       _isLoading = true;
  //     });

  //     final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
  //     final sessionData = await sessionProvider.getSession(widget.sessionId!);
      
  //     if (!mounted) return;
      
  //     setState(() {
  //       _session = sessionData;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
      
  //     setState(() {
  //       _isLoading = false;
  //     });
      
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Erreur lors du chargement de la session: ${e.toString()}'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  Future<void> _creerSessionCollaborative() async {
    debugPrint('[ConducteurDeclaration] === DÉBUT CRÉATION SESSION COLLABORATIVE ===');
    if (!mounted) return;

    // Validate date and lieu if they are required for session creation
    if (_dateAccident == null || _lieuController.text.isEmpty) {
      debugPrint('[ConducteurDeclaration] Validation échouée - date ou lieu manquant');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner la date et le lieu de l\'accident avant de créer une session.'), backgroundColor: Colors.orange),
      );
      return;
    }

    debugPrint('[ConducteurDeclaration] Validation OK, début du processus');
    setState(() => _isLoading = true);
    try {
      debugPrint('[ConducteurDeclaration] Lecture du provider auth...');
      // Utilisez ref.read pour accéder aux providers
      final authProviderInstance = ref.read(authProvider);
      debugPrint('[ConducteurDeclaration] Provider auth lu: ${authProviderInstance.currentUser?.email}');

      debugPrint('[ConducteurDeclaration] Création des services...');
      final sessionProvider = SessionProvider(
        sessionService: SessionService(),
      );
      debugPrint('[ConducteurDeclaration] Services créés');

      if (authProviderInstance.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('[ConducteurDeclaration] Demande des emails...');
      List<String> emails = await _demanderEmailsAutresConducteurs();
      debugPrint('[ConducteurDeclaration] Emails reçus: $emails');
      if (!mounted) return;

      debugPrint('[ConducteurDeclaration] Création session avec ${_nombreVehicules} véhicules, emails: $emails');

      final newSessionId = await sessionProvider.creerSession(
        nombreConducteurs: _nombreVehicules,
        emailsInvites: emails,
        createdBy: authProviderInstance.currentUser!.id,
        userEmail: authProviderInstance.currentUser!.email,
        dateAccident: _dateAccident,
        lieuAccident: _lieuController.text,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('[ConducteurDeclaration] Timeout lors de la création de session');
          throw Exception('Timeout lors de la création de session');
        },
      );

      debugPrint('[ConducteurDeclaration] Session créée avec ID: $newSessionId');
        
      if (!mounted) return;
      setState(() => _isLoading = false);
        
      if (newSessionId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session créée et invitations envoyées!'), backgroundColor: Colors.green),
        );
        // Navigate to the same screen but with session ID, creator is 'A'
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => 
          ConducteurDeclarationScreen(
            sessionId: newSessionId, 
            conducteurPosition: 'A', // Creator is always 'A'
            isCollaborative: true,
          )
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: La création de la session a échoué.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

Future<List<String>> _demanderEmailsAutresConducteurs() async {
  debugPrint('[ConducteurDeclaration] === DÉBUT DEMANDE EMAILS ===');
  debugPrint('[ConducteurDeclaration] Demande emails pour ${_nombreVehicules - 1} autres conducteurs');

  final emails = await showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EmailInvitationDialog(
      nombreConducteurs: _nombreVehicules,
      currentPositionColor: _currentPositionColor,
    ),
  );

  debugPrint('[ConducteurDeclaration] Emails reçus: $emails');
  return emails ?? [];
}

  Future<void> _obtenirPositionActuelle() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le service de localisation est désactivé.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de localisation refusée.')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de localisation refusée de manière permanente.')));
        return;
      }

      _positionActuelle = await Geolocator.getCurrentPosition();
      if (mounted && _lieuController.text.isEmpty) { // Only fill if empty
        setState(() {
          _lieuController.text = 'Lat: ${_positionActuelle!.latitude.toStringAsFixed(6)}, Lng: ${_positionActuelle!.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur géolocalisation: $e')));
    }
  }

  Widget _buildDateTimeSelector() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    // final timeFormat = DateFormat('HH:mm'); // Unused
    
    String dateText = _dateAccident != null ? dateFormat.format(_dateAccident!) : 'Sélectionner la date';
    String timeText = _heureAccident != null ? '${_heureAccident!.hour.toString().padLeft(2, '0')}:${_heureAccident!.minute.toString().padLeft(2, '0')}' : 'Sélectionner l\'heure';
    
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDateTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: _currentPositionColor),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date et heure', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      const SizedBox(height: 4),
                      Text(
                        _dateAccident != null ? '$dateText à $timeText' : 'Sélectionner',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

Future<void> _selectDateTime() async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: _dateAccident ?? DateTime.now(),
    firstDate: DateTime(DateTime.now().year - 5), // Allow up to 5 years back
    lastDate: DateTime.now(),
  );
  
  if (pickedDate != null) {
    if (!mounted) return; // Check mounted before showing time picker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _heureAccident ?? TimeOfDay.now(),
    );
    
    if (pickedTime != null) {
      setState(() {
        _dateAccident = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        _heureAccident = pickedTime;
      });
    }
  }
}

  Future<void> _prendrePhoto(String type) async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une source'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Appareil photo'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galerie'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );

    if (source == null) return; // User cancelled dialog
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1024);

    if (pickedFile != null && mounted) {
      setState(() {
        File imageFile = File(pickedFile.path);
        switch (type) {
          case 'accident': _photosAccident.add(imageFile); break;
          case 'permis': _photoPermis = imageFile; _extraireInfosPermis(imageFile); break;
          case 'carte_grise': _photoCarteGrise = imageFile; _extraireInfosCarteGrise(imageFile); break;
          case 'attestation': _photoAttestation = imageFile; _extraireInfosAssurance(imageFile); break;
        }
      });
    }
  }

  Future<void> _extraireInfosPermis(File imageFile) async {
    // TODO: Implémenter OCR pour extraire les informations du permis
    debugPrint('OCR Permis: ${imageFile.path}');
  }

  Future<void> _extraireInfosCarteGrise(File imageFile) async {
    // TODO: Implémenter OCR pour extraire les informations de la carte grise
    debugPrint('OCR Carte Grise: ${imageFile.path}');
  }

  Future<void> _extraireInfosAssurance(File imageFile) async {
    // TODO: Implémenter OCR pour extraire les informations de l'assurance
    debugPrint('OCR Assurance: ${imageFile.path}');
  }

  /// 👥 Navigue vers l'écran de visualisation des autres conducteurs
  void _voirAutresConducteurs() {
    if (widget.sessionId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutresConducteursScreen(
          sessionId: widget.sessionId!,
          currentUserPosition: widget.conducteurPosition,
        ),
      ),
    );
  }

  /// ℹ️ Affiche les informations détaillées de la session
  void _afficherInfosSession() {
    _showSessionInfo();
  }

  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => _TemoinDialog(
        onAjouter: (temoin) => setState(() => _temoins.add(temoin)),
        positionColor: _currentPositionColor,
      ),
    );
  }

  void _pageSuivante() {
    if (_currentPage < 7) { _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
  }

  void _pagePrecedente() {
    if (_currentPage > 0) { _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
  }

  dynamic _creerGeoPoint() {
    if (_positionActuelle != null) {
      // For Firestore, GeoPoint is preferred
      // return GeoPoint(_positionActuelle!.latitude, _positionActuelle!.longitude);
      // For JSON serialization if not using GeoPoint directly:
      return {'latitude': _positionActuelle!.latitude, 'longitude': _positionActuelle!.longitude};
    }
    return null;
  }

  Future<void> _sauvegarderConstat() async {
  if (!_formKey.currentState!.validate()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires'), backgroundColor: Colors.orange),
    );
    return;
  }

  setState(() => _isLoading = true);
  try {
    // Utilisez ref.read pour accéder aux providers
    final authProviderInstance = ref.read(authProvider);

    if (authProviderInstance.currentUser == null) throw Exception('Utilisateur non connecté');

    if (_isSessionMode && widget.sessionId != null) {
      await _sauvegarderDansSession();
    } else {
      await _sauvegarderConstatSimple();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Constat sauvegardé avec succès'), backgroundColor: Color(0xFF10B981))
      );
      Navigator.pop(context, true); // Pop with a result indicating success
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }
}

Future<void> _sauvegarderDansSession() async {
  final sessionProvider = SessionProvider(
    sessionService: SessionService(),
  );
  final authProviderInstance = ref.read(authProvider);

  Uint8List? signatureBytes;
  if (_signatureController.isNotEmpty) signatureBytes = await _signatureController.toPngBytes();
  final now = DateTime.now();

  final conducteurInfo = ConducteurInfoModel(
    nom: _nomController.text,
    prenom: _prenomController.text,
    adresse: _adresseController.text,
    telephone: _telephoneController.text,
    numeroPermis: _numeroPermisController.text,
    userId: authProviderInstance.currentUser!.id,
    createdAt: now,
  );

  final vehiculeInfo = VehiculeAccidentModel(
    marque: _marqueController.text,
    type: _typeController.text,
    numeroImmatriculation: _immatriculationController.text,
    venantDe: _venantDeController.text,
    allantA: _allantAController.text,
    conducteurId: authProviderInstance.currentUser!.id,
    createdAt: now,
    degatsApparents: _degatsApparents,
  );

  final assuranceInfo = AssuranceInfoModel(
    societeAssurance: _societeAssuranceController.text,
    numeroContrat: _numeroContratController.text,
    agence: _agenceController.text,
    conducteurId: authProviderInstance.currentUser!.id,
    createdAt: now,
  );

  ProprietaireInfo? proprietaireInfoValue;
  if (!_estProprietaire) {
    proprietaireInfoValue = ProprietaireInfo(
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
    proprietaireInfo: proprietaireInfoValue,
    circonstances: _circonstancesSelectionnees,
    degatsApparents: _degatsApparents,
    temoins: _temoins,
    photosAccident: _photosAccident,
    photoPermis: _photoPermis,
    photoCarteGrise: _photoCarteGrise,
    photoAttestation: _photoAttestation,
    signature: signatureBytes,
    observations: _observationsController.text,
  );
}

Future<void> _sauvegarderConstatSimple() async {
  final constatProviderInstance = ref.read(constatProvider);
  final authProviderInstance = ref.read(authProvider);

  Uint8List? signatureBytes;
  if (_signatureController.isNotEmpty) signatureBytes = await _signatureController.toPngBytes();
  final now = DateTime.now();
  final currentUserId = authProviderInstance.currentUser!.id;

  final conducteurInfo = ConducteurInfoModel(
    nom: _nomController.text,
    prenom: _prenomController.text,
    adresse: _adresseController.text,
    telephone: _telephoneController.text,
    numeroPermis: _numeroPermisController.text,
    userId: currentUserId,
    createdAt: now,
  );

  final vehiculeInfo = VehiculeAccidentModel(
    marque: _marqueController.text,
    type: _typeController.text,
    numeroImmatriculation: _immatriculationController.text,
    venantDe: _venantDeController.text,
    allantA: _allantAController.text,
    conducteurId: currentUserId,
    createdAt: now,
    degatsApparents: _degatsApparents,
  );

  final assuranceInfo = AssuranceInfoModel(
    societeAssurance: _societeAssuranceController.text,
    numeroContrat: _numeroContratController.text,
    agence: _agenceController.text,
    conducteurId: currentUserId,
    createdAt: now,
  );



  final constat = ConstatModel(
    id: '',
    dateAccident: _dateAccident!,
    lieuAccident: _lieuController.text,
    coordonnees: _creerGeoPoint(),
    adresseAccident: _lieuController.text,
    vehiculeIds: [],
    conducteurIds: [currentUserId],
    temoinsIds: [],
    photosUrls: [],
    validationStatus: {widget.conducteurPosition: true},
    status: ConstatStatus.draft,
    createdAt: now,
    updatedAt: now,
    createdBy: currentUserId,
    circonstances: {'selectionnees': _circonstancesSelectionnees, 'nombre': _circonstancesSelectionnees.length},
    dommages: {'degats': _degatsApparents},
    observations: _observationsController.text.isNotEmpty ? {'texte': _observationsController.text} : null,
  );

  await constatProviderInstance.sauvegarderConstatComplet(
    constat: constat,
    conducteurInfo: conducteurInfo,
    vehiculeInfo: vehiculeInfo,
    assuranceInfo: assuranceInfo,
    temoins: _temoins,
    photosAccident: _photosAccident,
    photoPermis: _photoPermis,
    photoCarteGrise: _photoCarteGrise,
    photoAssurance: _photoAttestation,
    signature: signatureBytes,
  );
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: CustomAppBar(title: _isSessionMode ? 'Constat Collaboratif - Cond. ${widget.conducteurPosition}' : 'Constat d\'accident', backgroundColor: _currentPositionColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: _isSessionMode ? 'Constat Collaboratif - Cond. ${widget.conducteurPosition}' : 'Constat d\'accident',
        backgroundColor: _currentPositionColor,
        actions: _isSessionMode ? [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: _voirAutresConducteurs,
            tooltip: 'Voir les autres conducteurs',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _afficherInfosSession,
            tooltip: 'Informations de la session',
          ),
        ] : null,
      ),
      body: FadeTransition(opacity: _fadeAnimation, child: Column(children: [
        if (_isSessionMode) _buildSessionHeader(),
        _buildProgressIndicator(),
        Expanded(child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          physics: const NeverScrollableScrollPhysics(), // Disable swipe for PageView
          children: [
            _buildPageInfosGenerales(), _buildPageConducteur(), _buildPageProprietaire(),
            _buildPageVehicule(), _buildPageAssurance(), _buildPageCirconstances(),
            _buildPagePhotos(), _buildPageSignature(),
          ],
        )),
        _buildNavigationButtons(),
      ])),
    );
  }

Widget _buildSessionHeader() {
  if (_session == null) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.all(12), margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 2))]),
    child: Column(children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _currentPositionColor.withAlpha(26), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.group, color: _currentPositionColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Session collaborative', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _currentPositionColor)),
          Text('Code: ${_session!.sessionCode}', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        ])),
        IconButton(icon: const Icon(Icons.info_outline), onPressed: _showSessionInfo, color: _currentPositionColor),
      ]),
      const SizedBox(height: 12),
      _buildSessionProgress(),
    ]),
  );
}

  Widget _buildSessionProgress() {
  if (_session == null) return const SizedBox.shrink();
  final completed = _session!.conducteursInfo.values.where((info) => info.isCompleted).length;
  final total = _session!.nombreConducteurs;
  final progressValue = total > 0 ? completed / total : 0.0; // Avoid division by zero
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Progression: $completed/$total conducteurs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
      Text('${(progressValue * 100).toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _currentPositionColor)),
    ]),
    const SizedBox(height: 8),
    LinearProgressIndicator(value: progressValue, backgroundColor: const Color(0xFFE5E7EB), valueColor: AlwaysStoppedAnimation<Color>(_currentPositionColor), borderRadius: BorderRadius.circular(4)),
  ]);
}

  Widget _buildProgressIndicator() {
    const totalPages = 8; // Total number of pages (0-7)
    final progressValue = (_currentPage + 1) / totalPages;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]),
      child: Column(children: [
        Row(children: [
          Text('Étape ${_currentPage + 1} sur $totalPages', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
          const Spacer(),
          Text('${(progressValue * 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _currentPositionColor)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progressValue, backgroundColor: const Color(0xFFE5E7EB), valueColor: AlwaysStoppedAnimation<Color>(_currentPositionColor), minHeight: 4, borderRadius: BorderRadius.circular(2)),
      ]),
    );
  }

  Widget _buildPageInfosGenerales() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Form( // Ensure Form widget wraps this page if it contains FormFields
      // key: _formKey, // Assign the key if this is the primary form for validation, or use separate keys per page
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Informations générales', 'Renseignez les détails de l\'accident', Icons.info_outline, _currentPositionColor),
          const SizedBox(height: 24),
          if (!_isSessionMode || widget.conducteurPosition == 'A') 
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.directions_car_filled, color: _currentPositionColor, size: 20), const SizedBox(width: 8), const Text('Nombre de véhicules impliqués', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)))]),
                const SizedBox(height: 12),
                const Text('Sélectionnez le nombre total de véhicules impliqués dans l\'accident', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [2, 3, 4, 5, 6].map((nombre) => GestureDetector(onTap: () => setState(() => _nombreVehicules = nombre), child: Container(width: 48, height: 48, decoration: BoxDecoration(color: _nombreVehicules == nombre ? _currentPositionColor : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _nombreVehicules == nombre ? _currentPositionColor : const Color(0xFFE5E7EB), width: 2), boxShadow: _nombreVehicules == nombre ? [BoxShadow(color: _currentPositionColor.withAlpha(77), blurRadius: 8, offset: const Offset(0, 2))] : null), child: Center(child: Text('$nombre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _nombreVehicules == nombre ? Colors.white : const Color(0xFF6B7280))))))).toList()),
              ]),
            ),
          if (!_isSessionMode || widget.conducteurPosition == 'A') const SizedBox(height: 24),
          _buildDateTimeSelector(),
          const SizedBox(height: 20),
          CustomTextField(controller: _lieuController, label: 'Lieu de l\'accident', hintText: 'Adresse ou description du lieu', prefixIcon: Icons.location_on, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null, suffixIcon: IconButton(icon: Icon(Icons.my_location, color: _currentPositionColor), onPressed: _obtenirPositionActuelle)),
          const SizedBox(height: 20),
          _buildCheckboxSection(),
          const SizedBox(height: 20),
          _buildTemoinsSection(),
          if (!_isSessionMode && widget.conducteurPosition == 'A') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBAE6FD))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.group_add, color: Colors.white, size: 20)), const SizedBox(width: 12), const Expanded(child: Text('Constat collaboratif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))))]),
                const SizedBox(height: 12),
                const Text('Invitez les autres conducteurs impliqués à remplir leur partie du constat en ligne.', style: TextStyle(fontSize: 14, color: Color(0xFF0369A1))),
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: _creerSessionCollaborative, icon: const Icon(Icons.send), label: const Text('Inviter les autres conducteurs'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
              ]),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildPageConducteur() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Informations du conducteur', 'Vos informations personnelles', Icons.person, _currentPositionColor), const SizedBox(height: 24),
      Row(children: [
        Expanded(child: CustomTextField(controller: _nomController, label: 'Nom', prefixIcon: Icons.person_outline, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null)),
        const SizedBox(width: 16),
        Expanded(child: CustomTextField(controller: _prenomController, label: 'Prénom', prefixIcon: Icons.person_outline, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null)),
      ]), const SizedBox(height: 20),
      CustomTextField(controller: _adresseController, label: 'Adresse', prefixIcon: Icons.home, maxLines: 2, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null), const SizedBox(height: 20),
      CustomTextField(controller: _telephoneController, label: 'Téléphone', prefixIcon: Icons.phone, keyboardType: TextInputType.phone), const SizedBox(height: 20),
      _buildPermisSection(),
    ]));
  }

  Widget _buildPageProprietaire() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Propriétaire du véhicule', 'Êtes-vous le propriétaire du véhicule ?', Icons.person_pin, _currentPositionColor), const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Êtes-vous le propriétaire de ce véhicule ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))), const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => setState(() => _estProprietaire = true), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _estProprietaire ? const Color(0xFF10B981) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: _estProprietaire ? const Color(0xFF10B981) : const Color(0xFFE5E7EB))), child: Column(children: [Icon(Icons.check_circle, color: _estProprietaire ? Colors.white : const Color(0xFF374151), size: 32), const SizedBox(height: 8), Text('Oui', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _estProprietaire ? Colors.white : const Color(0xFF374151)))])))),
          const SizedBox(width: 16),
          Expanded(child: GestureDetector(onTap: () => setState(() => _estProprietaire = false), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: !_estProprietaire ? const Color(0xFFEF4444) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: !_estProprietaire ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB))), child: Column(children: [Icon(Icons.cancel, color: !_estProprietaire ? Colors.white : const Color(0xFF374151), size: 32), const SizedBox(height: 8), Text('Non', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: !_estProprietaire ? Colors.white : const Color(0xFF374151)))])))),
        ]),
      ])),
      if (!_estProprietaire) ...[
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B))), child: Row(children: [const Icon(Icons.warning, color: Color(0xFFF59E0B)), const SizedBox(width: 12), Expanded(child: Text('Veuillez renseigner les informations du propriétaire du véhicule', style: TextStyle(fontSize: 14, color: Colors.orange.shade800)))])), const SizedBox(height: 20),
        Row(children: [
          Expanded(child: CustomTextField(controller: _proprietaireNomController, label: 'Nom du propriétaire', prefixIcon: Icons.person_outline, validator: (v) => !_estProprietaire && v?.isEmpty == true ? 'Champ requis' : null)),
          const SizedBox(width: 16),
          Expanded(child: CustomTextField(controller: _proprietairePrenomController, label: 'Prénom du propriétaire', prefixIcon: Icons.person_outline, validator: (v) => !_estProprietaire && v?.isEmpty == true ? 'Champ requis' : null)),
        ]), const SizedBox(height: 20),
        CustomTextField(controller: _proprietaireAdresseController, label: 'Adresse du propriétaire', prefixIcon: Icons.home, maxLines: 2, validator: (v) => !_estProprietaire && v?.isEmpty == true ? 'Champ requis' : null), const SizedBox(height: 20),
        CustomTextField(controller: _proprietaireTelephoneController, label: 'Téléphone du propriétaire', prefixIcon: Icons.phone, keyboardType: TextInputType.phone, validator: (v) => !_estProprietaire && v?.isEmpty == true ? 'Champ requis' : null),
      ],
    ]));
  }

  Widget _buildPageVehicule() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Informations du véhicule', 'Détails de votre véhicule', Icons.directions_car, _currentPositionColor), const SizedBox(height: 24),
      Row(children: [
        Expanded(child: CustomTextField(controller: _marqueController, label: 'Marque', prefixIcon: Icons.branding_watermark, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null)),
        const SizedBox(width: 16),
        Expanded(child: CustomTextField(controller: _typeController, label: 'Type/Modèle', prefixIcon: Icons.model_training, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null)),
      ]), const SizedBox(height: 20),
      CustomTextField(controller: _immatriculationController, label: 'N° d\'immatriculation', prefixIcon: Icons.confirmation_number, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null), const SizedBox(height: 20),
      CustomTextField(controller: _sensController, label: 'Sens suivi', prefixIcon: Icons.navigation), const SizedBox(height: 20),
      Row(children: [
        Expanded(child: CustomTextField(controller: _venantDeController, label: 'Venant de', prefixIcon: Icons.arrow_back)),
        const SizedBox(width: 16),
        Expanded(child: CustomTextField(controller: _allantAController, label: 'Allant à', prefixIcon: Icons.arrow_forward)),
      ]), const SizedBox(height: 20),
      _buildCarteGriseSection(),
    ]));
  }

  Widget _buildPageAssurance() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Informations d\'assurance', 'Détails de votre assurance', Icons.security, _currentPositionColor), const SizedBox(height: 24),
      CustomTextField(controller: _societeAssuranceController, label: 'Société d\'assurance', prefixIcon: Icons.business, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null), const SizedBox(height: 20),
      CustomTextField(controller: _numeroContratController, label: 'N° de contrat', prefixIcon: Icons.description, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null), const SizedBox(height: 20),
      CustomTextField(controller: _agenceController, label: 'Agence', prefixIcon: Icons.location_city, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null), const SizedBox(height: 20),
      _buildAttestationSection(),
    ]));
  }

  Widget _buildPageCirconstances() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Circonstances', 'Cochez les cases correspondant à votre situation', Icons.checklist, _currentPositionColor), const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _currentPositionColor.withAlpha(26), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.info, color: _currentPositionColor, size: 20)), const SizedBox(width: 12), const Expanded(child: Text('Sélectionnez toutes les circonstances qui s\'appliquent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))))]),
        const SizedBox(height: 16), Text('Nombre sélectionné: ${_circonstancesSelectionnees.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _currentPositionColor)),
      ])), const SizedBox(height: 20),
      ...List.generate(_circonstances.length, (index) {
        final isSelected = _circonstancesSelectionnees.contains(index + 1);
        return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: isSelected ? _currentPositionColor.withAlpha(13) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? _currentPositionColor : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1)), child: CheckboxListTile(value: isSelected, onChanged: (value) => setState(() => value == true ? _circonstancesSelectionnees.add(index + 1) : _circonstancesSelectionnees.remove(index + 1)), title: Text('${index + 1}. ${_circonstances[index]}', style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? _currentPositionColor : const Color(0xFF374151))), activeColor: _currentPositionColor, checkColor: Colors.white, controlAffinity: ListTileControlAffinity.leading, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4)));
      }), const SizedBox(height: 20),
      _buildDegatsSection(), const SizedBox(height: 20),
      CustomTextField(controller: _observationsController, label: 'Observations', hintText: 'Décrivez brièvement l\'accident...', prefixIcon: Icons.note, maxLines: 4),
    ]));
  }

  Widget _buildPagePhotos() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Photos et documents', 'Ajoutez les photos nécessaires', Icons.camera_alt, _currentPositionColor), const SizedBox(height: 24),
      _buildPhotosAccidentSection(), const SizedBox(height: 24),
      _buildDocumentsSection(), // This includes permis, carte grise, attestation sections
    ]));
  }

  Widget _buildPageSignature() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader('Signature', 'Signez pour valider votre déclaration', Icons.draw, _currentPositionColor), const SizedBox(height: 24),
      Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Signature(controller: _signatureController, backgroundColor: Colors.white)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: SizedBox(width: double.infinity, child: CustomButton(text: 'Effacer', onPressed: () => _signatureController.clear(), color: const Color(0xFF6B7280), isOutlined: true))),
        const SizedBox(width: 16),
        Expanded(child: SizedBox(width: double.infinity, child: CustomButton(text: 'Aperçu', onPressed: () async { final signature = await _signatureController.toPngBytes(); if (signature != null && mounted) { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Aperçu de la signature'), content: Image.memory(signature), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))])); }}, color: _currentPositionColor, isOutlined: true))),
      ]), const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.info, color: _currentPositionColor, size: 20), const SizedBox(width: 8), const Text('Information importante', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)))]),
        const SizedBox(height: 8), const Text('En signant ce constat, vous certifiez que les informations fournies sont exactes. Ce document sera transmis à votre compagnie d\'assurance.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 12), Text('Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
      ])),
    ]));
  }

  Widget _buildNavigationButtons() {
    return Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, -2))]), child: Row(children: [
      if (_currentPage > 0) Expanded(child: SizedBox(width: double.infinity, child: CustomButton(text: 'Précédent', onPressed: _pagePrecedente, color: const Color(0xFF6B7280), isOutlined: true))),
      if (_currentPage > 0) const SizedBox(width: 16),
      Expanded(child: SizedBox(width: double.infinity, child: CustomButton(text: _currentPage == 7 ? 'Terminer' : 'Suivant', onPressed: _currentPage == 7 ? _sauvegarderConstat : _pageSuivante, color: _currentPositionColor))),
    ]));
  }

  void _showSessionInfo() {
  if (_session == null) return;
  showDialog(context: context, builder: (context) => AlertDialog(
    title: const Text('Informations de la session'),
    content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Code de session: ${_session!.sessionCode}'), const SizedBox(height: 8),
      Text('Nombre de conducteurs: ${_session!.nombreConducteurs}'), const SizedBox(height: 16),
      const Text('État des conducteurs:', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      ..._session!.conducteursInfo.entries.map((entry) {
        final position = entry.key; final info = entry.value; final color = SessionUtils.getPositionColor(position);
        return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(77))), child: Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: Center(child: Text(position, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Conducteur $position', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(info.isCompleted ? 'Terminé' : info.hasJoined ? 'En cours' : info.isInvited ? 'Invité' : 'En attente', style: TextStyle(fontSize: 12, color: info.isCompleted ? Colors.green : info.hasJoined ? Colors.orange : Colors.grey)),
          ])),
          Icon(info.isCompleted ? Icons.check_circle : info.hasJoined ? Icons.access_time : Icons.mail_outline, color: color, size: 20),
        ]));
      }).toList(),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
  ));
}

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withAlpha(26), color.withAlpha(13)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(51))), child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 24)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
        const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
      ])),
    ]));
  }

  Widget _buildCheckboxSection() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Conséquences de l\'accident', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))), const SizedBox(height: 12),
      CheckboxListTile(value: _blessesLegers, onChanged: (v) => setState(() => _blessesLegers = v ?? false), title: const Text('Blessés (même légers)', style: TextStyle(fontSize: 14)), activeColor: const Color(0xFFEF4444), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
      CheckboxListTile(value: _degatsMaterielsAutres, onChanged: (v) => setState(() => _degatsMaterielsAutres = v ?? false), title: const Text('Dégâts matériels autres qu\'aux véhicules', style: TextStyle(fontSize: 14)), activeColor: const Color(0xFFF59E0B), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
    ]));
  }

  Widget _buildTemoinsSection() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Témoins', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)))),
        SizedBox(width: 80, child: CustomButton(text: 'Ajouter', onPressed: _ajouterTemoin, color: _currentPositionColor, isOutlined: true, isCompact: true)),
      ]),
      if (_temoins.isNotEmpty) ...[
        const SizedBox(height: 12),
        ...List.generate(_temoins.length, (index) {
          final temoin = _temoins[index];
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(temoin.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              if (temoin.telephone?.isNotEmpty == true) Text(temoin.telephone!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            IconButton(icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20), onPressed: () => setState(() => _temoins.removeAt(index))),
          ]));
        }),
      ],
    ]));
  }

  Widget _buildPermisSection() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Permis de conduire', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))), const SizedBox(height: 12),
      CustomTextField(controller: _numeroPermisController, label: 'N° de permis (optionnel)', prefixIcon: Icons.credit_card), const SizedBox(height: 16),
      InkWell(onTap: () => _prendrePhoto('permis'), child: Container(height: 120, decoration: BoxDecoration(color: _photoPermis != null ? Colors.transparent : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))), child: _photoPermis != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_photoPermis!, fit: BoxFit.cover, width: double.infinity)) : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 32, color: Color(0xFF6B7280)), SizedBox(height: 8), Text('Photo du permis (optionnel)', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)))])))),
    ]));
  }

  Widget _buildCarteGriseSection() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Carte grise', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))), const SizedBox(height: 12),
      InkWell(onTap: () => _prendrePhoto('carte_grise'), child: Container(height: 120, decoration: BoxDecoration(color: _photoCarteGrise != null ? Colors.transparent : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))), child: _photoCarteGrise != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_photoCarteGrise!, fit: BoxFit.cover, width: double.infinity)) : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 32, color: Color(0xFF6B7280)), SizedBox(height: 8), Text('Photo de la carte grise', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)))])))),
    ]));
  }

  Widget _buildAttestationSection() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Attestation d\'assurance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))), const SizedBox(height: 12),
      InkWell(onTap: () => _prendrePhoto('attestation'), child: Container(height: 120, decoration: BoxDecoration(color: _photoAttestation != null ? Colors.transparent : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))), child: _photoAttestation != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_photoAttestation!, fit: BoxFit.cover, width: double.infinity)) : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 32, color: Color(0xFF6B7280)), SizedBox(height: 8), Text('Photo de l\'attestation', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)))])))),
    ]));
  }

  Widget _buildDegatsSection() {
    final degatsOptions = [ 'Pare-chocs avant', 'Pare-chocs arrière', 'Aile avant droite', 'Aile avant gauche', 'Aile arrière droite', 'Aile arrière gauche', 'Portière avant droite', 'Portière avant gauche', 'Portière arrière droite', 'Portière arrière gauche', 'Capot', 'Coffre', 'Toit', 'Pare-brise', 'Lunette arrière', 'Phares', 'Feux arrière', 'Rétroviseurs', ];
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Dégâts apparents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))), const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: degatsOptions.map((degat) {
        final isSelected = _degatsApparents.contains(degat);
        return GestureDetector(onTap: () => setState(() => isSelected ? _degatsApparents.remove(degat) : _degatsApparents.add(degat)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isSelected ? _currentPositionColor : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? _currentPositionColor : const Color(0xFFE5E7EB))), child: Text(degat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF374151)))));
      }).toList()),
    ]));
  }

  Widget _buildPhotosAccidentSection() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Photos de l\'accident', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)))),
        SizedBox(width: 80, child: CustomButton(text: 'Ajouter', onPressed: () => _prendrePhoto('accident'), color: _currentPositionColor, isOutlined: true, isCompact: true)),
      ]), const SizedBox(height: 12),
      if (_photosAccident.isNotEmpty) GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _photosAccident.length, itemBuilder: (context, index) => Stack(children: [ ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_photosAccident[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity)), Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _photosAccident.removeAt(index)), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))) ]))
      else Container(height: 120, decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 32, color: Color(0xFF6B7280)), SizedBox(height: 8), Text('Aucune photo ajoutée', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)))]))),
    ]));
  }

  Widget _buildDocumentsSection() {
    // This combines the individual document sections into one logical group for the "Photos et documents" page
    return Column(children: [
      // _buildPermisSection(), // Already part of _buildPageConducteur
      // const SizedBox(height: 16),
      // _buildCarteGriseSection(), // Already part of _buildPageVehicule
      // const SizedBox(height: 16),
      // _buildAttestationSection(), // Already part of _buildPageAssurance
      // The individual sections are now called within their respective pages.
      // This _buildDocumentsSection can be simplified or removed if photos are the only new item on this page.
      // For now, let's assume it's a placeholder or if you want to re-show them here.
      // If the goal is just to have a "Photos" page, then only _buildPhotosAccidentSection might be needed.
      // However, the original code had _buildDocumentsSection calling these again.
      // Let's keep it as is from the provided file, which means these sections will appear again on page 6.
       _buildPermisSection(), const SizedBox(height: 16), _buildCarteGriseSection(), const SizedBox(height: 16), _buildAttestationSection()
    ]);
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
    _nomController.dispose(); _adresseController.dispose(); _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CustomTextField(controller: _nomController, label: 'Nom complet', prefixIcon: Icons.person), const SizedBox(height: 16),
        CustomTextField(controller: _adresseController, label: 'Adresse', prefixIcon: Icons.home, maxLines: 2), const SizedBox(height: 16),
        CustomTextField(controller: _telephoneController, label: 'Téléphone', prefixIcon: Icons.phone, keyboardType: TextInputType.phone), const SizedBox(height: 16),
        CheckboxListTile(value: _estPassagerA, onChanged: (v) => setState(() { _estPassagerA = v ?? false; if (_estPassagerA) _estPassagerB = false; }), title: const Text('Passager du véhicule A'), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: widget.positionColor),
        CheckboxListTile(value: _estPassagerB, onChanged: (v) => setState(() { _estPassagerB = v ?? false; if (_estPassagerB) _estPassagerA = false; }), title: const Text('Passager du véhicule B'), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: widget.positionColor),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.positionColor),
          onPressed: () {
            if (_nomController.text.isNotEmpty && _adresseController.text.isNotEmpty) {
              widget.onAjouter(TemoinModel(nom: _nomController.text, adresse: _adresseController.text, telephone: _telephoneController.text.isNotEmpty ? _telephoneController.text : null, estPassagerA: _estPassagerA, estPassagerB: _estPassagerB, constatId: '', createdAt: DateTime.now()));
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
