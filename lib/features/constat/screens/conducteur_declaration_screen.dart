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
import '../../../core/utils/session_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

// Assurez-vous que ce modèle est correctement défini et correspond à ce qui est retourné par votre SessionProvider
import '../models/constat_session_model.dart';
// IMPORTANT: Pour que ConstatProvider soit reconnu comme un type, il doit être défini comme une classe,
// par exemple: class ConstatProvider extends ChangeNotifier { ... }
// et être correctement importé et fourni via un ChangeNotifierProvider plus haut dans l'arbre des widgets.
// L'erreur "ConstatProvider isn't a type" et "unused_import" sont liées.
// Si ConstatProvider est bien défini, assurez-vous que l'import est utilisé.

import '../providers/session_provider.dart';
import '../../conducteur/models/conducteur_info_model.dart' as conducteur_model_feature;
import '../../conducteur/models/vehicule_accident_model.dart' as vehicule_accident_model_feature;
import '../../conducteur/models/assurance_info_model.dart' as assurance_model_feature;
import '../../vehicule/models/vehicule_model.dart';
import '../models/temoin_model.dart';
import '../models/proprietaire_info.dart';
import '../../../core/config/app_routes.dart';
import '../services/auto_fill_service.dart';
import '../widgets/auto_fill_indicator.dart';
import '../../../core/services/session_service.dart';

class ConducteurDeclarationScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String conducteurPosition;
  final String? invitationCode;
  final VehiculeModel? selectedVehicule;
  final bool isCollaborative;

  const ConducteurDeclarationScreen({
    Key? key,
    this.sessionId,
    required this.conducteurPosition,
    this.invitationCode,
    this.selectedVehicule,
    required this.isCollaborative,
  }) : super(key: key);

  @override
  ConsumerState<ConducteurDeclarationScreen> createState() => _ConducteurDeclarationScreenState();
}

class _ConducteurDeclarationScreenState extends ConsumerState<ConducteurDeclarationScreen> with TickerProviderStateMixin {
  int _nombreVehiculesPourInitiation = 2;
  bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegExp.hasMatch(email);
  }

  final List<String> _circonstances = [
    'en stationnement / à l\'arrêt',
    'quittait un stationnement / ouvrait une portière',
    'prenait un stationnement',
    'sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre',
    's\'engageait dans un parking, un lieu privé, d\'un chemin de terre',
    's\'engageait sur un sens giratoire',
    'roulait sur un sens giratoire',
    'heurtait à l\'arrière, en roulant dans le même sens et sur une même file',
    'roulait dans le même sens et sur une file différente',
    'changeait de file',
    'doublait',
    'virait à droite',
    'virait à gauche',
    'reculait',
    'empiétait sur la partie de chaussée réservée à la circulation en sens inverse',
    'venait de droite (dans un carrefour)',
    'n\'avait pas observé le signal de priorité ou un feu rouge',
  ];

  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  final _dateAccidentController = TextEditingController();
  final _heureAccidentController = TextEditingController();

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
    penStrokeWidth: 2, penColor: const Color(0xFF2E3A59), exportBackgroundColor: Colors.white,
  );

  // Correction du type ici pour correspondre à ce qui est attendu
  ConstatSessionModel? _session;
  bool _isLoading = false;
  late Color _currentPositionColor;
  AutoFillData? _autoFillData;

  @override
  void initState() {
    super.initState();
    _currentPositionColor = SessionUtils.getPositionColor(widget.conducteurPosition);
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
    
    if (widget.isCollaborative && widget.sessionId != null) {
      _chargerSessionDetails();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillData();
    });
    _obtenirPositionActuelle();
  }

  @override
  void dispose() {
    _pageController.dispose(); _animationController.dispose();
    _lieuController.dispose(); _nomController.dispose(); _prenomController.dispose();
    _adresseController.dispose(); _telephoneController.dispose(); _numeroPermisController.dispose();
    _proprietaireNomController.dispose(); _proprietairePrenomController.dispose();
    _proprietaireAdresseController.dispose(); _proprietaireTelephoneController.dispose();
    _marqueController.dispose(); _typeController.dispose(); _immatriculationController.dispose();
    _venantDeController.dispose(); _allantAController.dispose(); _sensController.dispose();
    _societeAssuranceController.dispose(); _numeroContratController.dispose();
    _agenceController.dispose(); _observationsController.dispose(); _signatureController.dispose();
    _dateAccidentController.dispose(); _heureAccidentController.dispose();
    super.dispose();
  }

  Future<void> _prefillData() async {
    debugPrint('[ConducteurDeclarationScreen] 🚀 Début du pré-remplissage automatique');

    final authProviderInstance = ref.read(authProvider);
    final UserModel? currentUser = authProviderInstance.currentUser;

    if (currentUser == null) {
      debugPrint('[ConducteurDeclarationScreen] ❌ Aucun utilisateur connecté');
      return;
    }

    try {
      // Utiliser le service d'auto-remplissage
      final autoFillData = await AutoFillService.getAutoFillData(
        currentUser: currentUser,
        selectedVehicule: widget.selectedVehicule,
      );

      debugPrint('[ConducteurDeclarationScreen] 📋 Données récupérées: $autoFillData');

      if (!mounted) return;

      // Créer une map des contrôleurs pour faciliter l'application
      final controllers = {
        'nom': _nomController,
        'prenom': _prenomController,
        'adresse': _adresseController,
        'telephone': _telephoneController,
        'numeroPermis': _numeroPermisController,
        'marque': _marqueController,
        'type': _typeController,
        'immatriculation': _immatriculationController,
        'societeAssurance': _societeAssuranceController,
        'numeroContrat': _numeroContratController,
        'agence': _agenceController,
      };

      // Appliquer les données d'auto-remplissage
      AutoFillService.applyAutoFillData(autoFillData, controllers);

      // Mettre à jour l'état du propriétaire et stocker les données
      setState(() {
        _estProprietaire = autoFillData.estProprietaire;
        _autoFillData = autoFillData;
      });

      // Afficher un message de confirmation
      if (mounted) {
        String message = '✅ Formulaire pré-rempli automatiquement';
        if (autoFillData.vehiculeComplete) {
          message += '\n🚗 Véhicule: ${autoFillData.vehiculeMarque} ${autoFillData.vehiculeModele}';
        }
        if (autoFillData.assuranceComplete) {
          message += '\n🛡️ Assurance: ${autoFillData.assuranceCompagnie}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint('[ConducteurDeclarationScreen] ✅ Pré-remplissage terminé avec succès');

    } catch (e) {
      debugPrint('[ConducteurDeclarationScreen] ❌ Erreur lors du pré-remplissage: $e');

      // Fallback vers l'ancien système en cas d'erreur
      _prefillDataFallback(currentUser);
    }
  }

  /// Méthode de fallback pour le pré-remplissage en cas d'erreur
  void _prefillDataFallback(UserModel currentUser) {
    debugPrint('[ConducteurDeclarationScreen] 🔄 Utilisation du pré-remplissage de base');

    // Remplir au minimum les données de base
    _nomController.text = currentUser.nom;
    _prenomController.text = currentUser.prenom;
    _adresseController.text = currentUser.adresse ?? '';
    _telephoneController.text = currentUser.telephone ?? '';

    if (widget.selectedVehicule != null) {
      final vehicule = widget.selectedVehicule!;
      _marqueController.text = vehicule.marque;
      _typeController.text = vehicule.modele;
      _immatriculationController.text = vehicule.immatriculation;
      _societeAssuranceController.text = vehicule.compagnieAssurance;
      _numeroContratController.text = vehicule.numeroContrat;
      _agenceController.text = vehicule.agence;

      setState(() {
        _estProprietaire = vehicule.proprietaireId == currentUser.id;
      });
    }
  }

  Future<void> _chargerSessionDetails() async {
    if (widget.sessionId == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final sessionProvider = SessionProvider(sessionService: SessionService());
      // Correction de l'erreur d'assignation:
      // S'assurer que getSession retourne bien un ConstatSessionModel?
      // ou caster explicitement si vous êtes sûr du type.
      final dynamic sessionDataDynamic = await sessionProvider.getSession(widget.sessionId!);
      
      if(mounted){
        setState(() {
          if (sessionDataDynamic is ConstatSessionModel) { // Ligne 211
            _session = sessionDataDynamic;
          } else if (sessionDataDynamic != null) {
            // Si sessionDataDynamic est d'un autre type (ex: SessionConstatModel)
            // vous devez le convertir en ConstatSessionModel.
            // Exemple: _session = ConstatSessionModel.fromJson(sessionDataDynamic.toJson());
            // Pour l'instant, on logue une erreur si le type n'est pas directement ConstatSessionModel.
            debugPrint("Type de session inattendu: ${sessionDataDynamic.runtimeType}. Attendu: ConstatSessionModel. Conversion manuelle nécessaire.");
            // Vous pouvez tenter un cast si vous êtes sûr, mais c'est risqué:
            // _session = sessionDataDynamic as ConstatSessionModel?;
          }

          if (_session != null) {
            if (_session!.lieuAccident != null && _session!.lieuAccident!.isNotEmpty) {
              _lieuController.text = _session!.lieuAccident!;
            }
            _dateAccident = _session!.dateAccident;
             if (_session!.dateAccident != null) {
              _heureAccident = TimeOfDay.fromDateTime(_session!.dateAccident!);
              _dateAccidentController.text = DateFormat('dd/MM/yyyy').format(_session!.dateAccident!);
              _heureAccidentController.text = _heureAccident!.format(context);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement session: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement session: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }
  
  Future<void> _creerSessionCollaborative() async {
    if (!mounted) return;
    if (_dateAccident == null || _lieuController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner la date et le lieu de l\'accident avant de créer une session.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final authProviderInstance = ref.read(authProvider);
      final sessionProvider = SessionProvider(sessionService: SessionService());

      if (authProviderInstance.currentUser == null || authProviderInstance.currentUser!.id.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      List<String> emails = await _demanderEmailsAutresConducteurs();
      if (!mounted) return;

      final String? newSessionId = await sessionProvider.creerSession(
        nombreConducteurs: _nombreVehiculesPourInitiation,
        emailsInvites: emails,
        createdBy: authProviderInstance.currentUser!.id,
        dateAccident: _dateAccident,
        lieuAccident: _lieuController.text,
      );

      if (newSessionId == null) {
        throw Exception("La création de session a échoué (ID nul retourné).");
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session créée et invitations envoyées!'), backgroundColor: Colors.green),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.conducteurDeclaration, arguments: {
        'sessionId': newSessionId,
        'conducteurPosition': 'A',
        'isCollaborative': true,
        'selectedVehicule': widget.selectedVehicule, 
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _demanderEmailsAutresConducteurs() async {
    List<String> emails = [];
    List<TextEditingController> controllers = List.generate(_nombreVehiculesPourInitiation - 1, (_) => TextEditingController());
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inviter les autres conducteurs'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Entrez les adresses email des autres conducteurs impliqués:'), const SizedBox(height: 16),
          ...List.generate(_nombreVehiculesPourInitiation - 1, (index) {
            final position = ['B', 'C', 'D', 'E', 'F'][index]; final color = SessionUtils.getPositionColor(position);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controllers[index],
                decoration: InputDecoration(
                  labelText: 'Email conducteur $position',
                  prefixIcon: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)), child: Text(position, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ), keyboardType: TextInputType.emailAddress,
              ),
            );
          }),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              emails = controllers.map((c) => c.text.trim()).where((email) => email.isNotEmpty && isValidEmail(email)).toList();
              Navigator.pop(dialogContext);
            }, child: const Text('Inviter'),
          ),
        ],
      ),
    );
    for (var c in controllers) { c.dispose(); }
    return emails;
  }

  Future<void> _obtenirPositionActuelle() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le service de localisation est désactivé.'))); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de localisation refusée.'))); return; }
      }
      if (permission == LocationPermission.deniedForever) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission de localisation refusée de manière permanente.'))); return; }
      _positionActuelle = await Geolocator.getCurrentPosition();
      if (mounted && _lieuController.text.isEmpty) {
        setState(() => _lieuController.text = 'Lat: ${_positionActuelle!.latitude.toStringAsFixed(6)}, Lng: ${_positionActuelle!.longitude.toStringAsFixed(6)}');
      }
    } catch (e) { debugPrint('Erreur géolocalisation: $e'); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur géolocalisation: $e'))); }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: _dateAccident ?? DateTime.now(), firstDate: DateTime(DateTime.now().year - 5), lastDate: DateTime.now());
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: _heureAccident ?? TimeOfDay.now());
      if (pickedTime != null) {
        setState(() {
          _dateAccident = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          _heureAccident = pickedTime;
          _dateAccidentController.text = DateFormat('dd/MM/yyyy').format(_dateAccident!);
          _heureAccidentController.text = _heureAccident!.format(context);
        });
      }
    }
  }

  Future<void> _prendrePhoto(String type) async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Choisir une source'), content: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Appareil photo'), onTap: () => Navigator.pop(dialogContext, ImageSource.camera)), ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galerie'), onTap: () => Navigator.pop(dialogContext, ImageSource.gallery))])));
    if (source == null) return;
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1024);
    if (pickedFile != null && mounted) {
      setState(() {
        File imageFile = File(pickedFile.path);
        switch (type) {
          case 'accident': _photosAccident.add(imageFile); break;
          case 'permis': _photoPermis = imageFile; break;
          case 'carte_grise': _photoCarteGrise = imageFile; break;
          case 'attestation': _photoAttestation = imageFile; break;
        }
      });
    }
  }

  void _ajouterTemoin() {
    showDialog(context: context, builder: (dialogContext) => _TemoinDialog(onAjouter: (temoin) => setState(() => _temoins.add(temoin)), positionColor: _currentPositionColor));
  }

  void _pageSuivante() { if (_currentPage < 7) { _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } }
  void _pagePrecedente() { if (_currentPage > 0) { _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } }
  dynamic _creerGeoPoint() { if (_positionActuelle != null) { return {'latitude': _positionActuelle!.latitude, 'longitude': _positionActuelle!.longitude}; } return null; }

  Future<void> _sauvegarderConstat() async {
    if (_formKey.currentState?.validate() != true) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez corriger les erreurs.'))); 
      return; 
    }
    if (_dateAccident == null) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner la date et l\'heure.'))); 
      return; 
    }
    if (_signatureController.isEmpty && _currentPage == 7) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votre signature est requise.'))); 
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final authProviderInstance = ref.read(authProvider);
    final sessionProvider = SessionProvider(sessionService: SessionService());
    
    // Note: ConstatProvider n'est pas utilisé dans cette version simplifiée
    
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (authProviderInstance.currentUser == null || authProviderInstance.currentUser!.id.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }
      final currentUserId = authProviderInstance.currentUser!.id;

      Uint8List? signatureBytes;
      if (_signatureController.isNotEmpty) signatureBytes = await _signatureController.toPngBytes();
      final now = DateTime.now();

      final conducteurInfo = conducteur_model_feature.ConducteurInfoModel(
        nom: _nomController.text, prenom: _prenomController.text, adresse: _adresseController.text,
        telephone: _telephoneController.text, numeroPermis: _numeroPermisController.text,
        userId: currentUserId, createdAt: now,
      );
      final vehiculeInfo = vehicule_accident_model_feature.VehiculeAccidentModel(
        marque: _marqueController.text, type: _typeController.text, numeroImmatriculation: _immatriculationController.text,
        venantDe: _venantDeController.text, allantA: _allantAController.text,
        degatsApparents: _degatsApparents, conducteurId: currentUserId, createdAt: now,
      );
      final assuranceInfo = assurance_model_feature.AssuranceInfoModel(
        societeAssurance: _societeAssuranceController.text, numeroContrat: _numeroContratController.text,
        agence: _agenceController.text, conducteurId: currentUserId, createdAt: now,
      );
      final proprietaireInfoValue = _estProprietaire ? null : ProprietaireInfo(
        nom: _proprietaireNomController.text, prenom: _proprietairePrenomController.text,
        adresse: _proprietaireAdresseController.text, telephone: _proprietaireTelephoneController.text,
      );

      if (widget.isCollaborative && widget.sessionId != null) {
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
      } else {
        // TODO: Implémenter la sauvegarde du constat individuel
        // Pour l'instant, on simule une sauvegarde réussie
        debugPrint('[ConducteurDeclarationScreen] Sauvegarde constat individuel simulée');
      }

      messenger.showSnackBar(const SnackBar(content: Text('Constat sauvegardé avec succès'), backgroundColor: Color(0xFF10B981)));
      navigator.pop(true);
      
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFEF4444)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !(widget.isCollaborative && _session == null)) { 
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: CustomAppBar(title: 'Sauvegarde...', backgroundColor: _currentPositionColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
     if (_isLoading && widget.isCollaborative && _session == null) { 
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: CustomAppBar(title: 'Chargement session...', backgroundColor: _currentPositionColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(title: widget.isCollaborative ? 'Constat Collaboratif - Cond. ${widget.conducteurPosition}' : 'Constat d\'accident', backgroundColor: _currentPositionColor),
      body: FadeTransition(opacity: _fadeAnimation, child: Form( key: _formKey, child: Column(children: [
        if (widget.isCollaborative) _buildSessionHeader(),
        if (_autoFillData != null) AutoFillSummary(autoFillData: _autoFillData!),
        _buildProgressIndicator(),
        Expanded(child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPageInfosGenerales(), _buildPageConducteur(), _buildPageProprietaire(),
            _buildPageVehicule(), _buildPageAssurance(), _buildPageCirconstances(),
            _buildPagePhotos(), _buildPageSignature(),
          ],
        )),
        _buildNavigationButtons(),
      ]))),
    );
  }

  Widget _buildSessionHeader() {
    if (_session == null && widget.isCollaborative) { 
      return Container(
        padding: const EdgeInsets.all(12), margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 2))]),
        child: const Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text("Chargement de la session...")]),
      );
    }
    if (_session == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12), margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _currentPositionColor.withAlpha(26), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.group, color: _currentPositionColor, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Session collaborative', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _currentPositionColor)),
            Text('Code: ${_session!.sessionCode ?? "N/A"}', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
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
    final completed = _session!.parties.where((partie) => partie.isSubmitted).length;
    final total = _session!.nombreVehicules; 
    final progressValue = total > 0 ? completed / total : 0.0;
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
    const totalPages = 8; 
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Informations générales', 'Renseignez les détails de l\'accident', Icons.info_outline, _currentPositionColor),
          const SizedBox(height: 24),
          if (_autoFillData != null) ...[
            AutoFillIndicator(
              autoFillData: _autoFillData!,
              onRefresh: () => _prefillData(),
            ),
            const SizedBox(height: 24),
          ],
          if (!widget.isCollaborative && widget.conducteurPosition == 'A') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.directions_car_filled, color: _currentPositionColor, size: 20), const SizedBox(width: 8), const Text('Nombre de véhicules impliqués', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)))]),
                const SizedBox(height: 12),
                const Text('Sélectionnez le nombre total de véhicules impliqués dans l\'accident', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [2, 3, 4, 5, 6].map((nombre) => GestureDetector(onTap: () => setState(() => _nombreVehiculesPourInitiation = nombre), child: Container(width: 48, height: 48, decoration: BoxDecoration(color: _nombreVehiculesPourInitiation == nombre ? _currentPositionColor : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _nombreVehiculesPourInitiation == nombre ? _currentPositionColor : const Color(0xFFE5E7EB), width: 2), boxShadow: _nombreVehiculesPourInitiation == nombre ? [BoxShadow(color: _currentPositionColor.withAlpha(77), blurRadius: 8, offset: const Offset(0, 2))] : null), child: Center(child: Text('$nombre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _nombreVehiculesPourInitiation == nombre ? Colors.white : const Color(0xFF6B7280))))))).toList()),
              ]),
            ),
            const SizedBox(height: 24),
          ],
          GestureDetector(
            onTap: _selectDateTime,
            child: AbsorbPointer( 
              child: Row(children: [
                Expanded(child: CustomTextField(controller: _dateAccidentController, label: 'Date', prefixIcon: Icons.calendar_today, readOnly: true, validator: (v) => v!.isEmpty ? 'Requis':null)),
                const SizedBox(width: 8),
                Expanded(child: CustomTextField(controller: _heureAccidentController, label: 'Heure', prefixIcon: Icons.access_time, readOnly: true, validator: (v) => v!.isEmpty ? 'Requis':null)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(controller: _lieuController, label: 'Lieu de l\'accident', hintText: 'Adresse ou description du lieu', prefixIcon: Icons.location_on, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null, suffixIcon: IconButton(icon: Icon(Icons.my_location, color: _currentPositionColor), onPressed: _obtenirPositionActuelle)),
          const SizedBox(height: 20),
          _buildCheckboxSection(),
          const SizedBox(height: 20),
          _buildTemoinsSection(),
          if (!widget.isCollaborative && widget.conducteurPosition == 'A' && _nombreVehiculesPourInitiation > 1) ...[
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
      CustomTextField(controller: _telephoneController, label: 'Téléphone', prefixIcon: Icons.phone, keyboardType: TextInputType.phone, validator: (v) => v?.isEmpty == true ? 'Champ requis' : null), const SizedBox(height: 20),
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
      _buildDocumentsSection(),
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
        Expanded(child: SizedBox(width: double.infinity, child: CustomButton(text: 'Aperçu', onPressed: () async { final signature = await _signatureController.toPngBytes(); if (signature != null && mounted) { showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Aperçu de la signature'), content: Image.memory(signature), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fermer'))])); }}, color: _currentPositionColor, isOutlined: true))),
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
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Informations de la session'),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Code de session: ${_session!.sessionCode ?? "N/A"}'), const SizedBox(height: 8),
        Text('Nombre de conducteurs: ${_session!.nombreVehicules}'), const SizedBox(height: 16),
        const Text('État des conducteurs:', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        ..._session!.parties.map((partie) {
          final position = partie.role; final color = SessionUtils.getPositionColor(position);
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(77))), child: Row(children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: Center(child: Text(position, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Conducteur $position (${partie.userId.isNotEmpty ? '${partie.userId.substring(0, (partie.userId.length > 6 ? 6 : partie.userId.length))}...' : "N/A"})', style: const TextStyle(fontWeight: FontWeight.w600)), 
              Text(partie.isSubmitted ? 'Terminé' : 'En cours', style: TextStyle(fontSize: 12, color: partie.isSubmitted ? Colors.green : Colors.orange)),
            ])),
            Icon(partie.isSubmitted ? Icons.check_circle : Icons.access_time, color: color, size: 20),
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
    return Column(children: [
       _buildPermisSection(), const SizedBox(height: 16), _buildCarteGriseSection(), const SizedBox(height: 16), _buildAttestationSection()
    ]);
  }
}

class _TemoinDialog extends StatefulWidget { 
  final Function(TemoinModel) onAjouter;
  final Color positionColor;
  const _TemoinDialog({required this.onAjouter, required this.positionColor});
  @override State<_TemoinDialog> createState() => _TemoinDialogState();
}

class _TemoinDialogState extends State<_TemoinDialog> {
  final _nomController = TextEditingController(); final _adresseController = TextEditingController(); final _telephoneController = TextEditingController();
  bool _estPassagerA = false; bool _estPassagerB = false;
  final _formKeyDialog = GlobalKey<FormState>();

  @override void dispose() { _nomController.dispose(); _adresseController.dispose(); _telephoneController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: Form(
        key: _formKeyDialog,
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CustomTextField(controller: _nomController, label: 'Nom complet', prefixIcon: Icons.person, validator: (v) => v!.isEmpty ? 'Nom requis':null), const SizedBox(height: 16),
          CustomTextField(controller: _adresseController, label: 'Adresse', prefixIcon: Icons.home, maxLines: 2, validator: (v) => v!.isEmpty ? 'Adresse requise':null), const SizedBox(height: 16),
          CustomTextField(controller: _telephoneController, label: 'Téléphone', prefixIcon: Icons.phone, keyboardType: TextInputType.phone), const SizedBox(height: 16),
          CheckboxListTile(value: _estPassagerA, onChanged: (v) => setState(() { _estPassagerA = v ?? false; if (_estPassagerA) _estPassagerB = false; }), title: const Text('Passager du véhicule A'), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: widget.positionColor),
          CheckboxListTile(value: _estPassagerB, onChanged: (v) => setState(() { _estPassagerB = v ?? false; if (_estPassagerB) _estPassagerA = false; }), title: const Text('Passager du véhicule B'), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: widget.positionColor),
        ])),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.positionColor),
          onPressed: () {
            if (_formKeyDialog.currentState!.validate()) {
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