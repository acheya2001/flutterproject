import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../models/collaborative_session_model.dart';
import '../../../models/guest_participant_model.dart';
import '../../../services/collaborative_session_service.dart';
import '../../../services/guest_participant_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../services/insurance_data_service.dart';
import '../../../features/insurance/widgets/company_agency_selector.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/logging_service.dart';
import '../../../services/pdf_generation_service.dart';

/// 📝 Formulaire pour conducteur invité avec sauvegarde automatique
class GuestCombinedFormScreen extends StatefulWidget {
  final CollaborativeSession session;

  const GuestCombinedFormScreen({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  State<GuestCombinedFormScreen> createState() => _GuestCombinedFormScreenState();
}

class _GuestCombinedFormScreenState extends State<GuestCombinedFormScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();
  final _pageController = PageController();

  int _currentStep = 0;
  final int _totalSteps = 10;
  bool _isLoading = false;
  String _roleVehicule = 'A';

  // === CONTRÔLEURS POUR TOUTES LES ÉTAPES ===
  
  // 1. Informations personnelles
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _cinController = TextEditingController();
  DateTime? _dateNaissance;
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _professionController = TextEditingController();
  
  // Informations du permis
  final _numeroPermisController = TextEditingController();
  final _categoriePermisController = TextEditingController();
  DateTime? _dateDelivrancePermis;
  
  // 2. Informations du véhicule
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _couleurController = TextEditingController();
  int? _anneeConstruction;
  final _vinController = TextEditingController();
  final _carteGriseController = TextEditingController();
  final _carburantController = TextEditingController();
  final _puissanceController = TextEditingController();
  final _usageController = TextEditingController();
  DateTime? _datePremiereMiseEnCirculation;
  
  // 3. Informations d'assurance
  String? _selectedCompanyId;
  String? _selectedAgencyId;
  final _numeroContratController = TextEditingController();
  final _numeroAttestationController = TextEditingController();
  final _typeContratController = TextEditingController();
  DateTime? _dateDebutContrat;
  DateTime? _dateFinContrat;
  bool _assuranceValide = true;
  
  // 4. Informations de l'assuré
  bool _conducteurEstAssure = true;
  final _assureNomController = TextEditingController();
  final _assurePrenomController = TextEditingController();
  final _assureCinController = TextEditingController();
  final _assureAdresseController = TextEditingController();
  final _assureTelephoneController = TextEditingController();
  
  // 5. Informations de l'accident
  final _lieuAccidentController = TextEditingController();
  final _villeAccidentController = TextEditingController();
  DateTime? _dateAccident;
  TimeOfDay? _heureAccident;
  final _descriptionAccidentController = TextEditingController();
  
  // 6. Dégâts et circonstances
  List<String> _pointsChocSelectionnes = [];
  List<String> _degatsApparents = [];
  final _descriptionDegatsController = TextEditingController();
  List<String> _circonstancesSelectionnees = [];
  final _observationsController = TextEditingController();
  
  // Témoins
  List<Map<String, dynamic>> _temoins = [];

  // 7. Informations partagées
  bool _hasSharedInfo = false;
  Map<String, dynamic>? _croquisData;

  // 8. Photos et documents
  List<String> _photosAccident = [];
  String? _photoPermis;
  String? _photoCarteGrise;
  String? _photoAttestation;

  // 9. Description personnelle et finalisation
  final _descriptionPersonnelleController = TextEditingController();

  // 10. Navigation et état (déjà déclaré plus haut)

  // 11. Sauvegarde automatique
  static const String _autoSavePrefix = 'guest_form_autosave_';
  String get _autoSaveKey => '${_autoSavePrefix}${widget.session.id}';
  bool _isLoadingAutoSave = false;

  // 12. ID du participant invité
  String? _participantId;

  @override
  void initState() {
    super.initState();
    _assignerRoleVehicule();
    _loadCompagnies();
    _loadSharedAccidentInfo();
    _loadAutoSavedData();
    _setupAutoSaveListeners();
    _registerGuestParticipant();
  }

  /// 🎯 Assigner automatiquement le rôle du véhicule
  void _assignerRoleVehicule() {
    _roleVehicule = 'A';
    print('🎯 Rôle véhicule assigné: $_roleVehicule');
  }

  /// 🏢 Charger les compagnies d'assurance
  Future<void> _loadCompagnies() async {
    try {
      await InsuranceDataService.getCompagnies();
    } catch (e) {
      LoggingService.error('GuestCombinedForm', 'Erreur chargement compagnies', e);
    }
  }

  /// 🔄 Charger les informations partagées de l'accident
  Future<void> _loadSharedAccidentInfo() async {
    try {
      print('🔄 Chargement des informations partagées de la session ${widget.session.id}');

      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        
        setState(() {
          // Charger depuis donneesCommunes (structure principale)
          if (sessionData['donneesCommunes'] != null) {
            final donneesCommunes = sessionData['donneesCommunes'] as Map<String, dynamic>;

            print('📋 Données communes trouvées: ${donneesCommunes.keys}');

            // Date de l'accident
            if (donneesCommunes['dateAccident'] != null) {
              try {
                final dateStr = donneesCommunes['dateAccident'] as String;
                _dateAccident = DateTime.parse(dateStr);
                _hasSharedInfo = true;
                print('✅ Date accident chargée: $_dateAccident');
              } catch (e) {
                print('⚠️ Erreur parsing date: $e');
              }
            }

            // Heure de l'accident
            if (donneesCommunes['heureAccident'] != null) {
              try {
                final heureStr = donneesCommunes['heureAccident'] as String;
                final heureParts = heureStr.split(':');
                if (heureParts.length >= 2) {
                  _heureAccident = TimeOfDay(
                    hour: int.parse(heureParts[0]),
                    minute: int.parse(heureParts[1]),
                  );
                  _hasSharedInfo = true;
                  print('✅ Heure accident chargée: $_heureAccident');
                }
              } catch (e) {
                print('⚠️ Erreur parsing heure: $e');
              }
            }

            // Lieu de l'accident
            if (donneesCommunes['lieuAccident'] != null) {
              _lieuAccidentController.text = donneesCommunes['lieuAccident'];
              _hasSharedInfo = true;
              print('✅ Lieu accident chargé: ${donneesCommunes['lieuAccident']}');
            }

            // Ville de l'accident - CORRECTION IMPORTANTE
            if (donneesCommunes['villeAccident'] != null) {
              _villeAccidentController.text = donneesCommunes['villeAccident'];
              _hasSharedInfo = true;
              print('✅ Ville accident chargée: ${donneesCommunes['villeAccident']}');
            } else if (donneesCommunes['ville'] != null) {
              _villeAccidentController.text = donneesCommunes['ville'];
              _hasSharedInfo = true;
              print('✅ Ville accident chargée (fallback): ${donneesCommunes['ville']}');
            }

            // Témoins
            if (donneesCommunes['temoins'] != null) {
              final temoinsData = donneesCommunes['temoins'] as List<dynamic>;
              _temoins = temoinsData.map((temoin) {
                final temoinMap = Map<String, dynamic>.from(temoin as Map);
                temoinMap['isShared'] = true;
                return temoinMap;
              }).toList();
              _hasSharedInfo = true;
              print('✅ ${_temoins.length} témoins chargés');
            }
          }

          // Fallback vers les champs directs de la session
          if (!_hasSharedInfo) {
            print('📋 Tentative de chargement depuis les champs directs de la session');

            if (sessionData['dateAccident'] != null) {
              try {
                if (sessionData['dateAccident'] is Timestamp) {
                  _dateAccident = (sessionData['dateAccident'] as Timestamp).toDate();
                } else if (sessionData['dateAccident'] is String) {
                  _dateAccident = DateTime.parse(sessionData['dateAccident']);
                }
                _hasSharedInfo = true;
                print('✅ Date accident chargée (fallback): $_dateAccident');
              } catch (e) {
                print('⚠️ Erreur parsing date (fallback): $e');
              }
            }

            if (sessionData['heureAccident'] != null) {
              try {
                if (sessionData['heureAccident'] is Map) {
                  final heureData = sessionData['heureAccident'] as Map<String, dynamic>;
                  _heureAccident = TimeOfDay(
                    hour: heureData['hour'] ?? 0,
                    minute: heureData['minute'] ?? 0,
                  );
                } else if (sessionData['heureAccident'] is String) {
                  final heureStr = sessionData['heureAccident'] as String;
                  final heureParts = heureStr.split(':');
                  if (heureParts.length >= 2) {
                    _heureAccident = TimeOfDay(
                      hour: int.parse(heureParts[0]),
                      minute: int.parse(heureParts[1]),
                    );
                  }
                }
                _hasSharedInfo = true;
                print('✅ Heure accident chargée (fallback): $_heureAccident');
              } catch (e) {
                print('⚠️ Erreur parsing heure (fallback): $e');
              }
            }

            if (sessionData['lieuAccident'] != null) {
              _lieuAccidentController.text = sessionData['lieuAccident'];
              _hasSharedInfo = true;
              print('✅ Lieu accident chargé (fallback): ${sessionData['lieuAccident']}');
            }

            if (sessionData['localisation'] != null) {
              final localisation = sessionData['localisation'] as Map<String, dynamic>;
              if (localisation['adresse'] != null) {
                _lieuAccidentController.text = localisation['adresse'];
                _hasSharedInfo = true;
              }
              if (localisation['ville'] != null) {
                _villeAccidentController.text = localisation['ville'];
                _hasSharedInfo = true;
              }
              print('✅ Localisation chargée (fallback)');
            }

            if (sessionData['temoins'] != null) {
              final temoinsData = sessionData['temoins'] as List<dynamic>;
              _temoins = temoinsData.map((temoin) {
                final temoinMap = Map<String, dynamic>.from(temoin as Map);
                temoinMap['isShared'] = true;
                return temoinMap;
              }).toList();
              _hasSharedInfo = true;
              print('✅ ${_temoins.length} témoins chargés (fallback)');
            }
          }
        });

        // Charger le croquis depuis la sous-collection
        await _loadSharedSketch();

        print('✅ Informations partagées chargées avec succès');
      } else {
        print('⚠️ Session non trouvée dans Firestore');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des informations partagées: $e');
      LoggingService.error('GuestCombinedForm', 'Erreur chargement infos partagées', e);
    }
  }

  /// 🎨 Charger le croquis partagé
  Future<void> _loadSharedSketch() async {
    try {
      final croquisDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .collection('croquis')
          .doc('principal')
          .get();

      if (croquisDoc.exists) {
        setState(() {
          _croquisData = croquisDoc.data();
          _hasSharedInfo = true;
        });
        print('✅ Croquis partagé chargé');
      }
    } catch (e) {
      print('⚠️ Erreur chargement croquis: $e');
    }
  }

  /// 👤 Enregistrer le conducteur non inscrit dans la session
  Future<void> _registerGuestParticipant() async {
    try {
      print('👤 Enregistrement du conducteur non inscrit dans la session ${widget.session.id}');

      final participantId = 'guest_${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id)
          .update({
        'participants_en_attente': FieldValue.arrayUnion([{
          'participantId': participantId,
          'type': 'conducteur_non_inscrit',
          'statut': 'en_cours_saisie',
          'dateDebut': DateTime.now().toIso8601String(),
          'roleVehicule': _roleVehicule,
        }]),
        'derniere_modification': DateTime.now().toIso8601String(),
      });

      // Stocker l'ID du participant pour la soumission finale
      _participantId = participantId;

      print('✅ Conducteur non inscrit enregistré avec ID: $participantId');
    } catch (e) {
      print('⚠️ Erreur enregistrement conducteur non inscrit: $e');
      // Ne pas faire échouer l'initialisation pour cette erreur
    }
  }

  /// 💾 Charger les données sauvegardées automatiquement
  Future<void> _loadAutoSavedData() async {
    try {
      setState(() => _isLoadingAutoSave = true);

      final prefs = await SharedPreferences.getInstance();
      final autoSavedJson = prefs.getString(_autoSaveKey);

      if (autoSavedJson != null) {
        print('🔄 Chargement des données sauvegardées pour la session ${widget.session.id}');

        final autoSavedData = json.decode(autoSavedJson) as Map<String, dynamic>;

        setState(() {
          // Restaurer les informations personnelles
          if (autoSavedData['nom'] != null) _nomController.text = autoSavedData['nom'];
          if (autoSavedData['prenom'] != null) _prenomController.text = autoSavedData['prenom'];
          if (autoSavedData['cin'] != null) _cinController.text = autoSavedData['cin'];
          if (autoSavedData['telephone'] != null) _telephoneController.text = autoSavedData['telephone'];
          if (autoSavedData['email'] != null) _emailController.text = autoSavedData['email'];
          if (autoSavedData['adresse'] != null) _adresseController.text = autoSavedData['adresse'];
          if (autoSavedData['ville'] != null) _villeController.text = autoSavedData['ville'];
          if (autoSavedData['codePostal'] != null) _codePostalController.text = autoSavedData['codePostal'];
          if (autoSavedData['profession'] != null) _professionController.text = autoSavedData['profession'];
          if (autoSavedData['numeroPermis'] != null) _numeroPermisController.text = autoSavedData['numeroPermis'];
          if (autoSavedData['categoriePermis'] != null) _categoriePermisController.text = autoSavedData['categoriePermis'];

          // Restaurer les informations véhicule
          if (autoSavedData['immatriculation'] != null) _immatriculationController.text = autoSavedData['immatriculation'];
          if (autoSavedData['marque'] != null) _marqueController.text = autoSavedData['marque'];
          if (autoSavedData['modele'] != null) _modeleController.text = autoSavedData['modele'];
          if (autoSavedData['couleur'] != null) _couleurController.text = autoSavedData['couleur'];
          if (autoSavedData['anneeConstruction'] != null) _anneeConstruction = autoSavedData['anneeConstruction'];
          if (autoSavedData['vin'] != null) _vinController.text = autoSavedData['vin'];
          if (autoSavedData['carteGrise'] != null) _carteGriseController.text = autoSavedData['carteGrise'];
          if (autoSavedData['puissance'] != null) _puissanceController.text = autoSavedData['puissance'];

          // Restaurer les informations assurance
          if (autoSavedData['selectedCompanyId'] != null) _selectedCompanyId = autoSavedData['selectedCompanyId'];
          if (autoSavedData['selectedAgencyId'] != null) _selectedAgencyId = autoSavedData['selectedAgencyId'];
          if (autoSavedData['numeroContrat'] != null) _numeroContratController.text = autoSavedData['numeroContrat'];
          if (autoSavedData['numeroAttestation'] != null) _numeroAttestationController.text = autoSavedData['numeroAttestation'];
          if (autoSavedData['conducteurEstAssure'] != null) _conducteurEstAssure = autoSavedData['conducteurEstAssure'];
          if (autoSavedData['assureNom'] != null) _assureNomController.text = autoSavedData['assureNom'];
          if (autoSavedData['assurePrenom'] != null) _assurePrenomController.text = autoSavedData['assurePrenom'];
          if (autoSavedData['assureCin'] != null) _assureCinController.text = autoSavedData['assureCin'];
          if (autoSavedData['assureAdresse'] != null) _assureAdresseController.text = autoSavedData['assureAdresse'];
          if (autoSavedData['assureTelephone'] != null) _assureTelephoneController.text = autoSavedData['assureTelephone'];

          // Restaurer les informations accident
          if (autoSavedData['lieuAccident'] != null) _lieuAccidentController.text = autoSavedData['lieuAccident'];
          if (autoSavedData['villeAccident'] != null) _villeAccidentController.text = autoSavedData['villeAccident'];
          if (autoSavedData['descriptionAccident'] != null) _descriptionAccidentController.text = autoSavedData['descriptionAccident'];
          if (autoSavedData['descriptionDegats'] != null) _descriptionDegatsController.text = autoSavedData['descriptionDegats'];
          if (autoSavedData['observations'] != null) _observationsController.text = autoSavedData['observations'];
          if (autoSavedData['pointsChocSelectionnes'] != null) _pointsChocSelectionnes = List<String>.from(autoSavedData['pointsChocSelectionnes']);
          if (autoSavedData['degatsApparents'] != null) _degatsApparents = List<String>.from(autoSavedData['degatsApparents']);
          if (autoSavedData['circonstancesSelectionnees'] != null) _circonstancesSelectionnees = List<String>.from(autoSavedData['circonstancesSelectionnees']);
          if (autoSavedData['temoins'] != null) _temoins = List<Map<String, dynamic>>.from(autoSavedData['temoins']);

          // Restaurer les dates
          if (autoSavedData['dateNaissance'] != null) {
            _dateNaissance = DateTime.parse(autoSavedData['dateNaissance']);
          }
          if (autoSavedData['dateDelivrancePermis'] != null) {
            _dateDelivrancePermis = DateTime.parse(autoSavedData['dateDelivrancePermis']);
          }
          if (autoSavedData['dateAccident'] != null) {
            _dateAccident = DateTime.parse(autoSavedData['dateAccident']);
          }
          if (autoSavedData['heureAccident'] != null) {
            final heureData = autoSavedData['heureAccident'] as Map<String, dynamic>;
            _heureAccident = TimeOfDay(
              hour: heureData['hour'] ?? 0,
              minute: heureData['minute'] ?? 0,
            );
          }

          // Restaurer l'étape actuelle
          if (autoSavedData['currentStep'] != null) {
            _currentStep = autoSavedData['currentStep'];
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pageController.animateToPage(
                _currentStep,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          }
        });

        print('✅ Données sauvegardées restaurées avec succès');

        // Afficher un message à l'utilisateur
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.restore, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Données précédentes restaurées'),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Effacer',
                textColor: Colors.white,
                onPressed: _clearAutoSavedData,
              ),
            ),
          );
        });
      } else {
        print('ℹ️ Aucune donnée sauvegardée trouvée pour cette session');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données sauvegardées: $e');
      LoggingService.error('GuestCombinedForm', 'Erreur chargement auto-save', e);
    } finally {
      setState(() => _isLoadingAutoSave = false);
    }
  }

  /// 🔧 Configurer les listeners pour la sauvegarde automatique
  void _setupAutoSaveListeners() {
    // Informations personnelles
    _nomController.addListener(_autoSaveData);
    _prenomController.addListener(_autoSaveData);
    _cinController.addListener(_autoSaveData);
    _telephoneController.addListener(_autoSaveData);
    _emailController.addListener(_autoSaveData);
    _adresseController.addListener(_autoSaveData);
    _villeController.addListener(_autoSaveData);
    _codePostalController.addListener(_autoSaveData);
    _professionController.addListener(_autoSaveData);
    _numeroPermisController.addListener(_autoSaveData);
    _categoriePermisController.addListener(_autoSaveData);

    // Informations véhicule
    _immatriculationController.addListener(_autoSaveData);
    _marqueController.addListener(_autoSaveData);
    _modeleController.addListener(_autoSaveData);
    _couleurController.addListener(_autoSaveData);
    _vinController.addListener(_autoSaveData);
    _carteGriseController.addListener(_autoSaveData);
    _puissanceController.addListener(_autoSaveData);

    // Informations assurance
    _numeroContratController.addListener(_autoSaveData);
    _numeroAttestationController.addListener(_autoSaveData);
    _assureNomController.addListener(_autoSaveData);
    _assurePrenomController.addListener(_autoSaveData);
    _assureCinController.addListener(_autoSaveData);
    _assureAdresseController.addListener(_autoSaveData);
    _assureTelephoneController.addListener(_autoSaveData);

    // Informations accident
    _lieuAccidentController.addListener(_autoSaveData);
    _villeAccidentController.addListener(_autoSaveData);
    _descriptionAccidentController.addListener(_autoSaveData);
    _descriptionDegatsController.addListener(_autoSaveData);
    _observationsController.addListener(_autoSaveData);

    print('🔧 Listeners de sauvegarde automatique configurés pour tous les champs');
  }

  /// 💾 Sauvegarder automatiquement les données
  Future<void> _autoSaveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final dataToSave = {
        // Informations personnelles
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'cin': _cinController.text,
        'telephone': _telephoneController.text,
        'email': _emailController.text,
        'adresse': _adresseController.text,
        'ville': _villeController.text,
        'codePostal': _codePostalController.text,
        'profession': _professionController.text,
        'numeroPermis': _numeroPermisController.text,
        'categoriePermis': _categoriePermisController.text,

        // Informations véhicule
        'immatriculation': _immatriculationController.text,
        'marque': _marqueController.text,
        'modele': _modeleController.text,
        'couleur': _couleurController.text,
        'anneeConstruction': _anneeConstruction,
        'vin': _vinController.text,
        'carteGrise': _carteGriseController.text,
        'puissance': _puissanceController.text,

        // Informations assurance
        'selectedCompanyId': _selectedCompanyId,
        'selectedAgencyId': _selectedAgencyId,
        'numeroContrat': _numeroContratController.text,
        'numeroAttestation': _numeroAttestationController.text,
        'conducteurEstAssure': _conducteurEstAssure,
        'assureNom': _assureNomController.text,
        'assurePrenom': _assurePrenomController.text,
        'assureCin': _assureCinController.text,
        'assureAdresse': _assureAdresseController.text,
        'assureTelephone': _assureTelephoneController.text,

        // Informations accident
        'lieuAccident': _lieuAccidentController.text,
        'villeAccident': _villeAccidentController.text,
        'descriptionAccident': _descriptionAccidentController.text,
        'descriptionDegats': _descriptionDegatsController.text,
        'observations': _observationsController.text,
        'pointsChocSelectionnes': _pointsChocSelectionnes,
        'degatsApparents': _degatsApparents,
        'circonstancesSelectionnees': _circonstancesSelectionnees,
        'temoins': _temoins,

        // Dates
        'dateNaissance': _dateNaissance?.toIso8601String(),
        'dateDelivrancePermis': _dateDelivrancePermis?.toIso8601String(),
        'dateAccident': _dateAccident?.toIso8601String(),
        'heureAccident': _heureAccident != null ? {
          'hour': _heureAccident!.hour,
          'minute': _heureAccident!.minute,
        } : null,

        // Métadonnées
        'currentStep': _currentStep,
        'lastSaved': DateTime.now().toIso8601String(),
        'sessionId': widget.session.id,
      };

      await prefs.setString(_autoSaveKey, json.encode(dataToSave));
      print('💾 Données sauvegardées automatiquement (étape $_currentStep)');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde automatique: $e');
      LoggingService.error('GuestCombinedForm', 'Erreur auto-save', e);
    }
  }

  /// 🗑️ Effacer les données sauvegardées
  Future<void> _clearAutoSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_autoSaveKey);
      print('🗑️ Données sauvegardées effacées');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text('Données sauvegardées effacées'),
            ],
          ),
          backgroundColor: Colors.orange[600],
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Erreur lors de l\'effacement des données: $e');
    }
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs
    _nomController.dispose();
    _prenomController.dispose();
    _cinController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _professionController.dispose();
    _numeroPermisController.dispose();
    _categoriePermisController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _couleurController.dispose();
    _vinController.dispose();
    _carteGriseController.dispose();
    _carburantController.dispose();
    _puissanceController.dispose();
    _usageController.dispose();
    _numeroContratController.dispose();
    _numeroAttestationController.dispose();
    _typeContratController.dispose();
    _assureNomController.dispose();
    _assurePrenomController.dispose();
    _assureCinController.dispose();
    _assureAdresseController.dispose();
    _assureTelephoneController.dispose();
    _lieuAccidentController.dispose();
    _villeAccidentController.dispose();
    _descriptionAccidentController.dispose();
    _descriptionDegatsController.dispose();
    _observationsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Constat d\'Accident - Conducteur Invité',
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),

          // Contenu du formulaire
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1PersonalInfo(),           // 1. Informations personnelles
                _buildStep2VehicleInfo(),            // 2. Informations véhicule
                _buildStep3InsuranceInfo(),          // 3. Informations assurance
                _buildStep4AssuredInfo(),            // 4. Informations assuré
                _buildStep5AccidentInfo(),           // 5. Informations accident (partagées)
                _buildStep6LocationDateTime(),       // 6. Lieu, date et heure
                _buildStep7DamagePoints(),           // 7. Points de choc et dégâts
                _buildStep8Circumstances(),          // 8. Circonstances
                _buildStep9Witnesses(),              // 9. Témoins
                _buildStep10PhotosDocuments(),       // 10. Photos et documents
                _buildStep10Finalization(),          // 10. Description personnelle et finalisation
              ],
            ),
          ),

          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  /// 📊 Indicateur de progression avec sauvegarde automatique
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Indicateur de sauvegarde automatique
          if (_hasSharedInfo || _isLoadingAutoSave) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _hasSharedInfo ? Colors.blue[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasSharedInfo ? Colors.blue[200]! : Colors.green[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _hasSharedInfo ? Icons.cloud_download : Icons.save,
                    size: 16,
                    color: _hasSharedInfo ? Colors.blue[700] : Colors.green[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hasSharedInfo
                        ? 'Informations partagées chargées'
                        : _isLoadingAutoSave
                            ? 'Chargement...'
                            : 'Sauvegarde automatique active',
                    style: TextStyle(
                      fontSize: 12,
                      color: _hasSharedInfo ? Colors.blue[700] : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Barre de progression des étapes
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF3B82F6) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : isActive
                                  ? const Color(0xFF3B82F6)
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          size: 12,
                          color: isActive || isCompleted ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 👤 ÉTAPE 1: Informations personnelles
  Widget _buildStep1PersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
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
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👤 Informations Personnelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Renseignez vos informations personnelles et votre permis de conduire',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informations de base
            const Text(
              'Informations de base',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Nom et Prénom
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      hintText: 'Votre nom de famille',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est obligatoire';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      hintText: 'Votre prénom',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le prénom est obligatoire';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CIN et Date de naissance
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cinController,
                    decoration: const InputDecoration(
                      labelText: 'CIN *',
                      hintText: '12345678',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le CIN est obligatoire';
                      }
                      if (value.length != 8) {
                        return 'Le CIN doit contenir 8 chiffres';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'naissance'),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de naissance *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dateNaissance != null
                            ? '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}'
                            : 'Sélectionner une date',
                        style: TextStyle(
                          color: _dateNaissance != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Téléphone et Email
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _telephoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      hintText: '12345678',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le téléphone est obligatoire';
                      }
                      if (value.length != 8) {
                        return 'Le téléphone doit contenir 8 chiffres';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'exemple@email.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'email est obligatoire';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Format d\'email invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Adresse
            const Text(
              'Adresse',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse complète *',
                hintText: 'Rue, avenue, numéro...',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'adresse est obligatoire';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Ville et Code postal
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _villeController,
                    decoration: const InputDecoration(
                      labelText: 'Ville *',
                      hintText: 'Tunis',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La ville est obligatoire';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _codePostalController,
                    decoration: const InputDecoration(
                      labelText: 'Code postal',
                      hintText: '1000',
                      prefixIcon: Icon(Icons.markunread_mailbox),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Profession
            TextFormField(
              controller: _professionController,
              decoration: const InputDecoration(
                labelText: 'Profession *',
                hintText: 'Votre profession',
                prefixIcon: Icon(Icons.work),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La profession est obligatoire';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Informations du permis de conduire
            const Text(
              'Permis de conduire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Numéro et catégorie du permis
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _numeroPermisController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de permis',
                      hintText: '123456789',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _categoriePermisController,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      hintText: 'B',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Date de délivrance du permis
            InkWell(
              onTap: () => _selectDate(context, 'permis'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de délivrance',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _dateDelivrancePermis != null
                      ? '${_dateDelivrancePermis!.day}/${_dateDelivrancePermis!.month}/${_dateDelivrancePermis!.year}'
                      : 'Sélectionner une date',
                  style: TextStyle(
                    color: _dateDelivrancePermis != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 🚗 ÉTAPE 2: Informations du véhicule
  Widget _buildStep2VehicleInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
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
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚗 Informations du Véhicule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Renseignez les informations de votre véhicule',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Informations principales
          const Text(
            'Informations principales',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Immatriculation
          TextFormField(
            controller: _immatriculationController,
            decoration: const InputDecoration(
              labelText: 'Immatriculation *',
              hintText: '123 TUN 456',
              prefixIcon: Icon(Icons.confirmation_number),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'immatriculation est obligatoire';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Marque et Modèle
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _marqueController,
                  decoration: const InputDecoration(
                    labelText: 'Marque *',
                    hintText: 'Peugeot',
                    prefixIcon: Icon(Icons.branding_watermark),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La marque est obligatoire';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _modeleController,
                  decoration: const InputDecoration(
                    labelText: 'Modèle *',
                    hintText: '208',
                    prefixIcon: Icon(Icons.model_training),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le modèle est obligatoire';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Couleur et Année
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _couleurController,
                  decoration: const InputDecoration(
                    labelText: 'Couleur *',
                    hintText: 'Blanc',
                    prefixIcon: Icon(Icons.palette),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La couleur est obligatoire';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Année *',
                    hintText: '2020',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _anneeConstruction = int.tryParse(value);
                      _autoSaveData();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'année est obligatoire';
                    }
                    final year = int.tryParse(value);
                    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                      return 'Année invalide';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Informations techniques
          const Text(
            'Informations techniques (optionnel)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // VIN
          TextFormField(
            controller: _vinController,
            decoration: const InputDecoration(
              labelText: 'Numéro de châssis (VIN)',
              hintText: 'VF3XXXXXXXXXXXXXXX',
              prefixIcon: Icon(Icons.qr_code),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),

          const SizedBox(height: 16),

          // Carte grise et Puissance
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _carteGriseController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro carte grise',
                    hintText: 'CG123456',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _puissanceController,
                  decoration: const InputDecoration(
                    labelText: 'Puissance (CV)',
                    hintText: '5',
                    prefixIcon: Icon(Icons.speed),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 🏢 ÉTAPE 3: Informations d'assurance
  Widget _buildStep3InsuranceInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyStep3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[50]!, Colors.orange[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.orange[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🏢 Informations d\'Assurance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sélectionnez votre compagnie et agence d\'assurance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sélecteur de compagnie et agence
            CompanyAgencySelector(
              selectedCompanyId: _selectedCompanyId,
              selectedAgencyId: _selectedAgencyId,
              onSelectionChanged: (companyId, agencyId) {
                setState(() {
                  _selectedCompanyId = companyId;
                  _selectedAgencyId = agencyId;
                });
                _autoSaveData();
              },
            ),

            const SizedBox(height: 24),

            // Informations du contrat
            const Text(
              'Informations du contrat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Numéro de contrat
            TextFormField(
              controller: _numeroContratController,
              decoration: const InputDecoration(
                labelText: 'Numéro de contrat *',
                hintText: 'CT123456789',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le numéro de contrat est obligatoire';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Numéro d'attestation
            TextFormField(
              controller: _numeroAttestationController,
              decoration: const InputDecoration(
                labelText: 'Numéro d\'attestation',
                hintText: 'AT123456789',
                prefixIcon: Icon(Icons.verified),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 👥 ÉTAPE 4: Informations de l'assuré
  Widget _buildStep4AssuredInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.purple[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.purple[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👥 Informations de l\'Assuré',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Précisez si vous êtes l\'assuré ou une autre personne',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Question principale
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Êtes-vous l\'assuré de ce véhicule ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Oui, je suis l\'assuré'),
                        value: true,
                        groupValue: _conducteurEstAssure,
                        onChanged: (value) {
                          setState(() {
                            _conducteurEstAssure = value!;
                          });
                          _autoSaveData();
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Non, autre personne'),
                        value: false,
                        groupValue: _conducteurEstAssure,
                        onChanged: (value) {
                          setState(() {
                            _conducteurEstAssure = value!;
                          });
                          _autoSaveData();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Informations de l'assuré (si différent du conducteur)
          if (!_conducteurEstAssure) ...[
            const Text(
              'Informations de l\'assuré',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Nom et Prénom de l'assuré
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _assureNomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'assuré *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: !_conducteurEstAssure ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est obligatoire';
                      }
                      return null;
                    } : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _assurePrenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom de l\'assuré *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: !_conducteurEstAssure ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le prénom est obligatoire';
                      }
                      return null;
                    } : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CIN de l'assuré
            TextFormField(
              controller: _assureCinController,
              decoration: const InputDecoration(
                labelText: 'CIN de l\'assuré *',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: !_conducteurEstAssure ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le CIN est obligatoire';
                }
                if (value.length != 8) {
                  return 'Le CIN doit contenir 8 chiffres';
                }
                return null;
              } : null,
            ),

            const SizedBox(height: 16),

            // Adresse de l'assuré
            TextFormField(
              controller: _assureAdresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse de l\'assuré *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: !_conducteurEstAssure ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'adresse est obligatoire';
                }
                return null;
              } : null,
            ),

            const SizedBox(height: 16),

            // Téléphone de l'assuré
            TextFormField(
              controller: _assureTelephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone de l\'assuré *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: !_conducteurEstAssure ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le téléphone est obligatoire';
                }
                if (value.length != 8) {
                  return 'Le téléphone doit contenir 8 chiffres';
                }
                return null;
              } : null,
            ),
          ] else ...[
            // Message si le conducteur est l'assuré
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Parfait ! Vos informations personnelles seront utilisées comme informations de l\'assuré.',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 🚨 ÉTAPE 5: Informations de l'accident (Partagées)
  Widget _buildStep5AccidentInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut de partage
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hasSharedInfo
                    ? [Colors.blue[50]!, Colors.blue[100]!]
                    : [Colors.red[50]!, Colors.red[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasSharedInfo ? Colors.blue[200]! : Colors.red[200]!,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _hasSharedInfo ? Icons.cloud_download : Icons.warning,
                      color: _hasSharedInfo ? Colors.blue[700] : Colors.red[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasSharedInfo
                                ? '🔗 Informations Partagées de l\'Accident'
                                : '🚨 Informations de l\'Accident',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasSharedInfo
                                ? 'Informations automatiquement synchronisées avec la session'
                                : 'Renseignez les détails de l\'accident',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Résumé des informations partagées
                if (_hasSharedInfo) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📋 Résumé des informations partagées:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_dateAccident != null)
                          _buildInfoRow('📅', 'Date', '${_dateAccident!.day}/${_dateAccident!.month}/${_dateAccident!.year}'),
                        if (_heureAccident != null)
                          _buildInfoRow('🕐', 'Heure', _heureAccident!.format(context)),
                        if (_lieuAccidentController.text.isNotEmpty)
                          _buildInfoRow('📍', 'Lieu', _lieuAccidentController.text),
                        if (_villeAccidentController.text.isNotEmpty)
                          _buildInfoRow('🏙️', 'Ville', _villeAccidentController.text),
                        if (_temoins.isNotEmpty)
                          _buildInfoRow('👥', 'Témoins', '${_temoins.length} témoin(s) enregistré(s)'),
                        if (_croquisData != null)
                          _buildInfoRow('🎨', 'Croquis', 'Croquis partagé disponible'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section informations détaillées
          if (_hasSharedInfo) ...[
            // Mode lecture seule pour les informations partagées
            _buildSharedInfoSection(),
          ] else ...[
            // Mode saisie pour les informations manquantes
            _buildAccidentInputSection(),
          ],

          const SizedBox(height: 24),

          // Section témoins (toujours visible)
          _buildTemoinsSharedSection(),

          const SizedBox(height: 24),

          // Section croquis (si disponible)
          if (_croquisData != null) _buildCroquisSharedSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 📋 Widget pour afficher une ligne d'information
  Widget _buildInfoRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔗 Section des informations partagées (lecture seule)
  Widget _buildSharedInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Informations synchronisées',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Ces informations ont été renseignées par le créateur de la session et sont automatiquement partagées avec tous les participants.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Affichage des informations en lecture seule
          _buildReadOnlyField('Lieu de l\'accident', _lieuAccidentController.text, Icons.location_on),
          const SizedBox(height: 12),
          _buildReadOnlyField('Ville', _villeAccidentController.text, Icons.location_city),
          const SizedBox(height: 12),
          _buildReadOnlyField(
            'Date et heure',
            _dateAccident != null && _heureAccident != null
                ? '${_dateAccident!.day}/${_dateAccident!.month}/${_dateAccident!.year} à ${_heureAccident!.format(context)}'
                : 'Non renseigné',
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  /// ✏️ Section de saisie des informations d'accident
  Widget _buildAccidentInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails de l\'accident',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),

        // Lieu de l'accident
        TextFormField(
          controller: _lieuAccidentController,
          decoration: const InputDecoration(
            labelText: 'Lieu de l\'accident *',
            hintText: 'Rue, avenue, intersection...',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le lieu de l\'accident est obligatoire';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Ville et Date
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _villeAccidentController,
                decoration: const InputDecoration(
                  labelText: 'Ville *',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La ville est obligatoire';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, 'accident'),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date accident *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dateAccident != null
                        ? '${_dateAccident!.day}/${_dateAccident!.month}/${_dateAccident!.year}'
                        : 'Sélectionner',
                    style: TextStyle(
                      color: _dateAccident != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Heure de l'accident
        InkWell(
          onTap: () => _selectTime(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Heure de l\'accident *',
              prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(),
            ),
            child: Text(
              _heureAccident != null
                  ? _heureAccident!.format(context)
                  : 'Sélectionner l\'heure',
              style: TextStyle(
                color: _heureAccident != null ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 📖 Widget pour afficher un champ en lecture seule
  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
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
                  value.isNotEmpty ? value : 'Non renseigné',
                  style: TextStyle(
                    fontSize: 14,
                    color: value.isNotEmpty ? const Color(0xFF1E293B) : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Section des témoins partagés
  Widget _buildTemoinsSharedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Témoins de l\'accident',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (!_hasSharedInfo || _temoins.where((t) => t['isShared'] != true).isEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _ajouterTemoin,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          if (_temoins.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Aucun témoin enregistré',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Témoins partagés
            if (_temoins.where((t) => t['isShared'] == true).isNotEmpty) ...[
              const Text(
                '🔗 Témoins partagés par le créateur:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              ..._temoins.where((t) => t['isShared'] == true).map((temoin) =>
                _buildTemoinCard(temoin, true)
              ),
              const SizedBox(height: 16),
            ],

            // Témoins ajoutés par l'utilisateur
            if (_temoins.where((t) => t['isShared'] != true).isNotEmpty) ...[
              const Text(
                '➕ Témoins que vous avez ajoutés:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              ..._temoins.where((t) => t['isShared'] != true).map((temoin) =>
                _buildTemoinCard(temoin, false)
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// 👤 Widget pour afficher une carte de témoin
  Widget _buildTemoinCard(Map<String, dynamic> temoin, bool isShared) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isShared ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isShared ? Colors.blue[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // Icône de statut
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isShared ? Colors.blue[100] : Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isShared ? Icons.cloud_download : Icons.person_add,
              size: 16,
              color: isShared ? Colors.blue[700] : Colors.green[700],
            ),
          ),
          const SizedBox(width: 12),

          // Informations du témoin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${temoin['nom']} ${temoin['prenom']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (temoin['telephone'] != null && temoin['telephone'].toString().isNotEmpty)
                  Text(
                    'Tél: ${temoin['telephone']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),

          // Badge de statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isShared ? Colors.blue[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isShared ? 'Partagé' : 'Ajouté',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isShared ? Colors.blue[700] : Colors.green[700],
              ),
            ),
          ),

          // Bouton de suppression (seulement pour les témoins ajoutés)
          if (!isShared) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _supprimerTemoin(_temoins.indexOf(temoin)),
              icon: const Icon(Icons.delete, size: 18),
              color: Colors.red[600],
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎨 Section du croquis partagé
  Widget _buildCroquisSharedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw, color: Colors.purple[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Croquis de l\'accident',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Croquis partagé disponible',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Le créateur de la session a réalisé un croquis de l\'accident. Ce croquis sera automatiquement inclus dans votre déclaration.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),

                // Bouton pour voir le croquis (optionnel)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implémenter la visualisation du croquis
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Visualisation du croquis - À implémenter'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Voir le croquis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple[700],
                      side: BorderSide(color: Colors.purple[300]!),
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

  /// 📍 ÉTAPE 6: Lieu, date et heure de l'accident
  Widget _buildStep6LocationDateTime() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 Lieu, Date et Heure de l\'Accident',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Précisez où et quand l\'accident s\'est produit',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Date de l'accident
          const Text(
            'Date de l\'accident *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: () => _selectDate(context, 'accident'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateAccident != null
                          ? '${_dateAccident!.day}/${_dateAccident!.month}/${_dateAccident!.year}'
                          : 'Sélectionner la date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dateAccident != null ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Heure de l'accident
          const Text(
            'Heure de l\'accident *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _heureAccident != null
                          ? _heureAccident!.format(context)
                          : 'Sélectionner l\'heure',
                      style: TextStyle(
                        fontSize: 16,
                        color: _heureAccident != null ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lieu de l'accident
          const Text(
            'Lieu de l\'accident *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _lieuAccidentController,
            decoration: const InputDecoration(
              labelText: 'Adresse précise',
              hintText: 'Ex: Avenue Habib Bourguiba, devant la poste',
              prefixIcon: Icon(Icons.place),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le lieu de l\'accident est obligatoire';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Ville
          const Text(
            'Ville *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _villeAccidentController,
            decoration: const InputDecoration(
              labelText: 'Ville',
              hintText: 'Ex: Tunis',
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La ville est obligatoire';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 💥 ÉTAPE 7: Points de choc et dégâts
  Widget _buildStep7DamagePoints() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[50]!, Colors.amber[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.build, color: Colors.amber[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💥 Points de Choc et Dégâts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Indiquez les points d\'impact et les dégâts visibles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Points de choc
          const Text(
            'Points de choc sur votre véhicule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          _buildPointsChocSelector(),

          const SizedBox(height: 24),

          // Dégâts apparents
          const Text(
            'Dégâts apparents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          _buildDegatsSelector(),

          const SizedBox(height: 24),

          // Description des dégâts
          const Text(
            'Description détaillée des dégâts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionDegatsController,
            decoration: const InputDecoration(
              labelText: 'Décrivez les dégâts en détail',
              hintText: 'Rayures, bosses, vitres cassées...',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 🎯 Sélecteur de points de choc
  Widget _buildPointsChocSelector() {
    final pointsChoc = [
      'Avant gauche', 'Avant centre', 'Avant droit',
      'Côté gauche', 'Côté droit',
      'Arrière gauche', 'Arrière centre', 'Arrière droit',
      'Toit', 'Dessous'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pointsChoc.map((point) {
        final isSelected = _pointsChocSelectionnes.contains(point);
        return FilterChip(
          label: Text(point),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _pointsChocSelectionnes.add(point);
              } else {
                _pointsChocSelectionnes.remove(point);
              }
            });
            _autoSaveData();
          },
          selectedColor: Colors.red[100],
          checkmarkColor: Colors.red[700],
        );
      }).toList(),
    );
  }

  /// 🔧 Sélecteur de dégâts
  Widget _buildDegatsSelector() {
    final degats = [
      'Rayures', 'Bosses', 'Éraflures', 'Vitres cassées',
      'Phares cassés', 'Pare-chocs endommagé', 'Portières enfoncées',
      'Capot déformé', 'Coffre endommagé', 'Rétroviseurs cassés'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: degats.map((degat) {
        final isSelected = _degatsApparents.contains(degat);
        return FilterChip(
          label: Text(degat),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _degatsApparents.add(degat);
              } else {
                _degatsApparents.remove(degat);
              }
            });
            _autoSaveData();
          },
          selectedColor: Colors.orange[100],
          checkmarkColor: Colors.orange[700],
        );
      }).toList(),
    );
  }

  /// ⚠️ Sélecteur de circonstances
  Widget _buildCirconstancesSelector() {
    final circonstances = [
      'Collision frontale', 'Collision arrière', 'Collision latérale',
      'Sortie de route', 'Stationnement', 'Marche arrière',
      'Changement de voie', 'Dépassement', 'Intersection',
      'Conditions météo', 'Obstacle sur route', 'Animal'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: circonstances.map((circonstance) {
        final isSelected = _circonstancesSelectionnees.contains(circonstance);
        return FilterChip(
          label: Text(circonstance),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _circonstancesSelectionnees.add(circonstance);
              } else {
                _circonstancesSelectionnees.remove(circonstance);
              }
            });
            _autoSaveData();
          },
          selectedColor: Colors.blue[100],
          checkmarkColor: Colors.blue[700],
        );
      }).toList(),
    );
  }

  /// 👥 Section des témoins
  Widget _buildTemoinsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Témoins',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            TextButton.icon(
              onPressed: _ajouterTemoin,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un témoin'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_temoins.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text(
                'Aucun témoin ajouté',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ...List.generate(_temoins.length, (index) {
            final temoin = _temoins[index];
            final isShared = temoin['isShared'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isShared ? Colors.blue[50] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isShared ? Colors.blue[200]! : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  if (isShared) ...[
                    Icon(Icons.cloud_download, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${temoin['nom']} ${temoin['prenom']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (temoin['telephone'] != null)
                          Text(
                            'Tél: ${temoin['telephone']}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isShared)
                    IconButton(
                      onPressed: () => _supprimerTemoin(index),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  /// ⚠️ ÉTAPE 8: Circonstances de l'accident
  Widget _buildStep8Circumstances() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
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
            child: Row(
              children: [
                Icon(Icons.traffic, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Circonstances de l\'Accident',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sélectionnez les circonstances qui s\'appliquent',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Circonstances
          const Text(
            'Circonstances de l\'accident',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          _buildCirconstancesSelector(),

          const SizedBox(height: 24),

          // Observations
          const Text(
            'Observations supplémentaires',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _observationsController,
            decoration: const InputDecoration(
              labelText: 'Observations (optionnel)',
              hintText: 'Toute information supplémentaire...',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 👥 ÉTAPE 9: Témoins
  Widget _buildStep9Witnesses() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.purple[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.purple[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👥 Témoins de l\'Accident',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ajoutez les témoins présents lors de l\'accident',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section témoins partagés et personnels
          _buildTemoinsSharedSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 📸 ÉTAPE 10: Photos et documents
  Widget _buildStep10PhotosDocuments() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[50]!, Colors.teal[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.teal[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📸 Photos et Documents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ajoutez des photos et documents (optionnel)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Photos de l'accident
          const Text(
            'Photos de l\'accident (optionnel)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.add_a_photo, color: Colors.grey[600], size: 48),
                const SizedBox(height: 12),
                Text(
                  'Ajoutez des photos de l\'accident',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Photos des véhicules, des dégâts, de la scène...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter l'ajout de photos
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité à venir')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Ajouter des photos'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Documents
          const Text(
            'Documents (optionnel)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Permis de conduire
          _buildDocumentCard(
            'Permis de conduire',
            Icons.credit_card,
            _photoPermis,
            () {
              // TODO: Implémenter l'ajout de photo du permis
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),

          const SizedBox(height: 16),

          // Carte grise
          _buildDocumentCard(
            'Carte grise',
            Icons.description,
            _photoCarteGrise,
            () {
              // TODO: Implémenter l'ajout de photo de la carte grise
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),

          const SizedBox(height: 16),

          // Attestation d'assurance
          _buildDocumentCard(
            'Attestation d\'assurance',
            Icons.shield,
            _photoAttestation,
            () {
              // TODO: Implémenter l'ajout de photo de l'attestation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 📝 ÉTAPE 10: Finalisation et soumission
  Widget _buildStep10Finalization() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête pour description personnelle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[50]!, Colors.orange[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: Colors.orange[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📝 Votre Version des Faits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Décrivez l\'accident selon votre point de vue',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Description personnelle
          const Text(
            'Votre description de l\'accident',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Expliquez ce qui s\'est passé selon votre point de vue. Cette description sera ajoutée aux informations partagées.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionAccidentController,
            decoration: const InputDecoration(
              labelText: 'Votre version des faits *',
              hintText: 'Décrivez précisément ce qui s\'est passé selon vous...',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Votre description est obligatoire';
              }
              if (value.trim().length < 20) {
                return 'Veuillez fournir une description plus détaillée (minimum 20 caractères)';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Section de finalisation
          Container(
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
                    Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      '✅ Finalisation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vérifiez vos informations avant soumission',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Résumé des informations
          const Text(
            'Résumé de votre déclaration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Cartes de résumé
          _buildSummaryCard('👤 Informations personnelles', [
            'Nom: ${_nomController.text}',
            'Prénom: ${_prenomController.text}',
            'Téléphone: ${_telephoneController.text}',
            'Email: ${_emailController.text}',
          ]),

          const SizedBox(height: 16),

          _buildSummaryCard('🚗 Véhicule', [
            'Marque: ${_marqueController.text}',
            'Modèle: ${_modeleController.text}',
            'Immatriculation: ${_immatriculationController.text}',
            'Couleur: ${_couleurController.text}',
          ]),

          const SizedBox(height: 16),

          _buildSummaryCard('🛡️ Assurance', [
            'Numéro contrat: ${_numeroContratController.text}',
            'Numéro attestation: ${_numeroAttestationController.text}',
            'Assurance valide: ${_assuranceValide ? 'Oui' : 'Non'}',
          ]),

          const SizedBox(height: 16),

          _buildSummaryCard('🚨 Accident', [
            'Lieu: ${_lieuAccidentController.text}',
            'Ville: ${_villeAccidentController.text}',
            'Date: ${_dateAccident != null ? '${_dateAccident!.day}/${_dateAccident!.month}/${_dateAccident!.year}' : 'Non renseignée'}',
            'Heure: ${_heureAccident != null ? _heureAccident!.format(context) : 'Non renseignée'}',
            'Témoins: ${_temoins.length} témoin(s)',
            if (_croquisData != null) 'Croquis: Disponible',
          ]),

          const SizedBox(height: 24),

          // Statut de participation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statut de participation',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Vous participez en tant que conducteur non inscrit. Votre déclaration sera ajoutée à la session existante.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bouton de soumission
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Rejoindre la session et soumettre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 🔄 Boutons de navigation
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Précédent
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _goToPreviousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Bouton Suivant/Terminer
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: CustomButton(
              text: _currentStep == _totalSteps - 1 ? 'Terminer' : 'Suivant',
              onPressed: _isLoading ? null : _goToNextStep,
              isLoading: _isLoading,
              icon: _currentStep == _totalSteps - 1 ? Icons.check : Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }

  /// ⬅️ Aller à l'étape précédente
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _autoSaveData();
    }
  }

  /// ➡️ Aller à l'étape suivante
  Future<void> _goToNextStep() async {
    print('🔄 Tentative de passage à l\'étape suivante depuis l\'étape $_currentStep');

    // Valider l'étape actuelle
    if (!await _validateCurrentStep()) {
      print('❌ Validation échouée pour l\'étape $_currentStep');
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _autoSaveData();
      print('✅ Passage à l\'étape $_currentStep réussi');
    } else {
      // Dernière étape - soumettre le formulaire
      await _submitForm();
    }
  }

  /// ✅ Valider l'étape actuelle
  Future<bool> _validateCurrentStep() async {
    switch (_currentStep) {
      case 0: // Informations personnelles
        return _validatePersonalInfo();
      case 1: // Informations véhicule
        return _validateVehicleInfo();
      case 2: // Informations assurance
        return _validateInsuranceInfo();
      case 3: // Informations assuré
        return _validateAssuredInfo();
      case 4: // Informations accident
        return _validateAccidentInfo();
      case 5: // Points de choc et dégâts
        return _validateDamageInfo();
      case 6: // Circonstances
        return _validateCircumstancesInfo();
      case 7: // Témoins
        return _validateWitnessesInfo();
      case 8: // Photos et documents
        return _validatePhotosInfo();
      case 9: // Finalisation et description personnelle
        return _validateFinalizationInfo();
      default:
        return true;
    }
  }

  /// 👤 Valider les informations personnelles
  bool _validatePersonalInfo() {
    print('🔍 DEBUG - Validation informations personnelles:');
    print('  - Nom: "${_nomController.text}"');
    print('  - Prénom: "${_prenomController.text}"');
    print('  - CIN: "${_cinController.text}"');
    print('  - Date naissance: $_dateNaissance');
    print('  - Téléphone: "${_telephoneController.text}"');
    print('  - Email: "${_emailController.text}"');
    print('  - Adresse: "${_adresseController.text}"');
    print('  - Ville: "${_villeController.text}"');
    print('  - Code postal: "${_codePostalController.text}"');
    print('  - Profession: "${_professionController.text}"');
    print('  - Numéro permis: "${_numeroPermisController.text}"');
    print('  - Catégorie permis: "${_categoriePermisController.text}"');
    print('  - Date délivrance permis: $_dateDelivrancePermis');

    final isFormValid = _formKeyStep1.currentState?.validate() ?? false;
    print('  - Validation FormKeyStep1: $isFormValid');

    if (!isFormValid) {
      print('❌ Validation FormKey échouée - vérifiez les champs du formulaire');
      return false;
    }

    // Validation manuelle des champs obligatoires
    if (_nomController.text.trim().isEmpty) {
      print('❌ Nom vide');
      _showValidationError('Le nom est obligatoire');
      return false;
    }

    if (_prenomController.text.trim().isEmpty) {
      print('❌ Prénom vide');
      _showValidationError('Le prénom est obligatoire');
      return false;
    }

    if (_cinController.text.trim().isEmpty || _cinController.text.length != 8) {
      print('❌ CIN invalide');
      _showValidationError('Le CIN doit contenir 8 chiffres');
      return false;
    }

    if (_dateNaissance == null) {
      print('❌ Date de naissance manquante');
      _showValidationError('La date de naissance est obligatoire');
      return false;
    }

    if (_telephoneController.text.trim().isEmpty || _telephoneController.text.length != 8) {
      print('❌ Téléphone invalide');
      _showValidationError('Le téléphone doit contenir 8 chiffres');
      return false;
    }

    if (_emailController.text.trim().isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      print('❌ Email invalide');
      _showValidationError('L\'email est obligatoire et doit être valide');
      return false;
    }

    if (_adresseController.text.trim().isEmpty) {
      print('❌ Adresse vide');
      _showValidationError('L\'adresse est obligatoire');
      return false;
    }

    if (_villeController.text.trim().isEmpty) {
      print('❌ Ville vide');
      _showValidationError('La ville est obligatoire');
      return false;
    }

    if (_professionController.text.trim().isEmpty) {
      print('❌ Profession vide');
      _showValidationError('La profession est obligatoire');
      return false;
    }

    print('✅ Validation informations personnelles réussie');
    return true;
  }

  /// 🚗 Valider les informations du véhicule
  bool _validateVehicleInfo() {
    if (_immatriculationController.text.trim().isEmpty) {
      _showValidationError('L\'immatriculation est obligatoire');
      return false;
    }
    if (_marqueController.text.trim().isEmpty) {
      _showValidationError('La marque est obligatoire');
      return false;
    }
    if (_modeleController.text.trim().isEmpty) {
      _showValidationError('Le modèle est obligatoire');
      return false;
    }
    if (_couleurController.text.trim().isEmpty) {
      _showValidationError('La couleur est obligatoire');
      return false;
    }
    if (_anneeConstruction == null) {
      _showValidationError('L\'année de construction est obligatoire');
      return false;
    }
    return true;
  }

  /// 🏢 Valider les informations d'assurance
  bool _validateInsuranceInfo() {
    final isFormValid = _formKeyStep3.currentState?.validate() ?? false;
    if (!isFormValid) {
      return false;
    }
    if (_selectedCompanyId == null) {
      _showValidationError('Veuillez sélectionner une compagnie d\'assurance');
      return false;
    }
    if (_selectedAgencyId == null) {
      _showValidationError('Veuillez sélectionner une agence d\'assurance');
      return false;
    }
    return true;
  }

  /// 👥 Valider les informations de l'assuré
  bool _validateAssuredInfo() {
    if (!_conducteurEstAssure) {
      if (_assureNomController.text.trim().isEmpty ||
          _assurePrenomController.text.trim().isEmpty ||
          _assureCinController.text.trim().isEmpty ||
          _assureAdresseController.text.trim().isEmpty ||
          _assureTelephoneController.text.trim().isEmpty) {
        _showValidationError('Toutes les informations de l\'assuré sont obligatoires');
        return false;
      }
      if (_assureCinController.text.length != 8) {
        _showValidationError('Le CIN de l\'assuré doit contenir 8 chiffres');
        return false;
      }
      if (_assureTelephoneController.text.length != 8) {
        _showValidationError('Le téléphone de l\'assuré doit contenir 8 chiffres');
        return false;
      }
    }
    return true;
  }

  /// 🚨 Valider les informations de l'accident
  bool _validateAccidentInfo() {
    if (_lieuAccidentController.text.trim().isEmpty) {
      _showValidationError('Le lieu de l\'accident est obligatoire');
      return false;
    }
    if (_villeAccidentController.text.trim().isEmpty) {
      _showValidationError('La ville de l\'accident est obligatoire');
      return false;
    }
    if (_dateAccident == null) {
      _showValidationError('La date de l\'accident est obligatoire');
      return false;
    }
    if (_heureAccident == null) {
      _showValidationError('L\'heure de l\'accident est obligatoire');
      return false;
    }
    if (_descriptionAccidentController.text.trim().isEmpty) {
      _showValidationError('La description de l\'accident est obligatoire');
      return false;
    }
    return true;
  }

  /// 💥 Valider les informations de dégâts
  bool _validateDamageInfo() {
    // Cette étape est optionnelle, toujours valide
    return true;
  }

  /// ⚠️ Valider les informations de circonstances
  bool _validateCircumstancesInfo() {
    // Cette étape est optionnelle, toujours valide
    return true;
  }

  /// 👥 Valider les informations de témoins
  bool _validateWitnessesInfo() {
    // Cette étape est optionnelle, toujours valide
    return true;
  }

  /// 📸 Valider les photos et documents
  bool _validatePhotosInfo() {
    // Cette étape est optionnelle, toujours valide
    return true;
  }

  /// 📝 Valider les informations de finalisation
  bool _validateFinalizationInfo() {
    if (_descriptionAccidentController.text.trim().isEmpty) {
      _showValidationError('Votre description de l\'accident est obligatoire');
      return false;
    }
    if (_descriptionAccidentController.text.trim().length < 20) {
      _showValidationError('Veuillez fournir une description plus détaillée (minimum 20 caractères)');
      return false;
    }
    return true;
  }

  /// 📄 Construire une carte de document
  Widget _buildDocumentCard(String title, IconData icon, String? photoPath, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  photoPath != null ? 'Photo ajoutée' : 'Aucune photo',
                  style: TextStyle(
                    fontSize: 14,
                    color: photoPath != null ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            child: Text(photoPath != null ? 'Modifier' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  /// 📋 Construire une carte de résumé
  Widget _buildSummaryCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// ⚠️ Afficher une erreur de validation
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 📅 Sélectionner une date
  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime? initialDate;
    DateTime firstDate;
    DateTime lastDate;

    switch (type) {
      case 'naissance':
        initialDate = _dateNaissance ?? DateTime(1990);
        firstDate = DateTime(1920);
        lastDate = DateTime.now().subtract(const Duration(days: 365 * 16)); // 16 ans minimum
        break;
      case 'permis':
        initialDate = _dateDelivrancePermis ?? DateTime(2010);
        firstDate = DateTime(1980);
        lastDate = DateTime.now();
        break;
      case 'accident':
        initialDate = _dateAccident ?? DateTime.now();
        firstDate = DateTime.now().subtract(const Duration(days: 30)); // 30 jours max
        lastDate = DateTime.now();
        break;
      default:
        return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'naissance':
            _dateNaissance = picked;
            break;
          case 'permis':
            _dateDelivrancePermis = picked;
            break;
          case 'accident':
            _dateAccident = picked;
            break;
        }
      });
      _autoSaveData();
    }
  }

  /// 🕐 Sélectionner une heure
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _heureAccident ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _heureAccident = picked;
      });
      _autoSaveData();
    }
  }

  /// 👥 Ajouter un témoin
  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => _TemoinDialog(
        onTemoinAdded: (temoin) {
          setState(() {
            _temoins.add(temoin);
          });
          _autoSaveData();
        },
      ),
    );
  }

  /// 🗑️ Supprimer un témoin
  void _supprimerTemoin(int index) {
    setState(() {
      _temoins.removeAt(index);
    });
    _autoSaveData();
  }

  /// 📤 Soumettre le formulaire
  Future<void> _submitForm() async {
    try {
      setState(() => _isLoading = true);

      print('📤 Soumission du formulaire pour la session ${widget.session.id}');

      // Créer l'objet participant invité selon le modèle existant
      final participantId = DateTime.now().millisecondsSinceEpoch.toString();

      final guestParticipant = GuestParticipant(
        sessionId: widget.session.id,
        participantId: participantId,
        roleVehicule: _roleVehicule,

        // Informations personnelles
        infosPersonnelles: PersonalInfo(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          cin: _cinController.text.trim(),
          dateNaissance: _dateNaissance!,
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim(),
          adresse: _adresseController.text.trim(),
          ville: _villeController.text.trim(),
          codePostal: _codePostalController.text.trim(),
          profession: _professionController.text.trim(),
          numeroPermis: _numeroPermisController.text.trim(),
          categoriePermis: _categoriePermisController.text.trim(),
          dateDelivrancePermis: _dateDelivrancePermis,
        ),

        // Informations du véhicule
        infosVehicule: VehicleInfo(
          immatriculation: _immatriculationController.text.trim(),
          marque: _marqueController.text.trim(),
          modele: _modeleController.text.trim(),
          couleur: _couleurController.text.trim(),
          anneeConstruction: _anneeConstruction!,
          numeroSerie: _vinController.text.trim(),
          puissanceFiscale: int.tryParse(_puissanceController.text.trim()),
          pointsChoc: _pointsChocSelectionnes,
          degatsApparents: _degatsApparents,
          descriptionDegats: _descriptionDegatsController.text.trim(),
        ),

        // Informations d'assurance
        infosAssurance: InsuranceInfo(
          compagnieId: _selectedCompanyId!,
          compagnieNom: 'Compagnie', // TODO: Récupérer le vrai nom
          agenceId: _selectedAgencyId!,
          agenceNom: 'Agence', // TODO: Récupérer le vrai nom
          numeroContrat: _numeroContratController.text.trim(),
          numeroAttestation: _numeroAttestationController.text.trim(),
          assuranceValide: _assuranceValide,
          remarquesAssurance: _conducteurEstAssure
              ? 'Conducteur est assuré'
              : 'Assuré: ${_assureNomController.text.trim()} ${_assurePrenomController.text.trim()}, CIN: ${_assureCinController.text.trim()}, Tél: ${_assureTelephoneController.text.trim()}',
        ),

        // Circonstances et observations
        circonstances: [
          ..._circonstancesSelectionnees,
          'Lieu: ${_lieuAccidentController.text.trim()}',
          'Ville: ${_villeAccidentController.text.trim()}',
          'Date: ${_dateAccident!.day}/${_dateAccident!.month}/${_dateAccident!.year}',
          'Heure: ${_heureAccident!.format(context)}',
          'Description: ${_descriptionAccidentController.text.trim()}',
        ],
        observationsPersonnelles: _observationsController.text.trim(),

        // Photos (vide pour l'instant)
        photosUrls: [],

        // Métadonnées
        dateCreation: DateTime.now(),
        formulaireComplete: true,
      );

      // Sauvegarder dans Firestore
      await GuestParticipantService.ajouterParticipantInvite(guestParticipant);

      // Mettre à jour la session collaborative pour notifier la participation
      await _updateSessionWithGuestParticipation(participantId, guestParticipant);

      // Effacer les données sauvegardées
      await _clearAutoSavedData();

      print('✅ Formulaire soumis avec succès');

      // Afficher un message de succès avec animation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Participation enregistrée !',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Vous avez rejoint la session collaborative',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.people, color: Colors.white),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Retourner à l'écran précédent avec résultat
        Navigator.of(context).pop({
          'success': true,
          'participantId': participantId,
          'participantName': '${_prenomController.text.trim()} ${_nomController.text.trim()}',
          'roleVehicule': _roleVehicule,
        });
      }
    } catch (e) {
      print('❌ Erreur lors de la soumission: $e');
      LoggingService.error('GuestCombinedForm', 'Erreur soumission', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur lors de la soumission: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 🔄 Mettre à jour la session avec la participation de l'invité
  Future<void> _updateSessionWithGuestParticipation(String participantId, GuestParticipant guestParticipant) async {
    try {
      final sessionRef = FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.session.id);

      // Récupérer la session actuelle pour mettre à jour les participants
      final sessionDoc = await sessionRef.get();
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;

        // Récupérer la liste actuelle des participants
        List<dynamic> participants = List.from(sessionData['participants'] ?? []);

        // Ajouter le nouveau participant invité à la liste principale
        // IMPORTANT: Utiliser le format exact attendu par SessionParticipant.fromMap()
        final nouveauParticipant = {
          'userId': participantId,
          'nom': guestParticipant.infosPersonnelles.nom,
          'prenom': guestParticipant.infosPersonnelles.prenom,
          'email': guestParticipant.infosPersonnelles.email,
          'telephone': guestParticipant.infosPersonnelles.telephone,
          'roleVehicule': guestParticipant.roleVehicule,
          'type': 'invite_guest', // IMPORTANT: Utiliser l'enum ParticipantType
          'statut': 'formulaire_fini', // IMPORTANT: Utiliser l'enum ParticipantStatus
          'formulaireStatus': 'termine', // IMPORTANT: Utiliser l'enum FormulaireStatus
          'estCreateur': false,
          'dateRejoint': Timestamp.fromDate(DateTime.now()), // IMPORTANT: Format Timestamp
          'dateFormulaireFini': Timestamp.fromDate(DateTime.now()), // IMPORTANT: Format Timestamp
          'adresse': guestParticipant.infosPersonnelles.adresse,
          'cin': guestParticipant.infosPersonnelles.cin,
        };

        participants.add(nouveauParticipant);

        // Calculer la nouvelle progression
        final participantsRejoints = participants.length;
        final formulairesTermines = participants.where((p) =>
          p['statut'] == 'formulaire_fini' ||
          p['formulaireStatus'] == 'termine'
        ).length;

        final progression = {
          'participantsRejoints': participantsRejoints,
          'formulairesTermines': formulairesTermines,
          'croquisValides': 0, // Sera mis à jour plus tard
          'signaturesEffectuees': 0, // Sera mis à jour plus tard
          'croquisCree': false,
          'peutFinaliser': false,
          'pourcentage': participantsRejoints > 0 ? ((formulairesTermines / participantsRejoints) * 100).round() : 0,
        };

        // Déterminer le nouveau statut de session
        String nouveauStatut = sessionData['statut'] ?? 'en_cours';
        final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

        if (participantsRejoints >= nombreVehicules) {
          if (formulairesTermines >= nombreVehicules) {
            nouveauStatut = 'validation_croquis';
          } else {
            nouveauStatut = 'en_cours';
          }
        } else {
          nouveauStatut = 'attente_participants';
        }

        // Mettre à jour la session
        await sessionRef.update({
          'participants': participants,
          'progression': progression,
          'statut': nouveauStatut,
          'dateModification': Timestamp.fromDate(DateTime.now()),
        });

        print('✅ Session mise à jour avec la participation de l\'invité');
        print('📊 Progression: $participantsRejoints/$nombreVehicules participants, $formulairesTermines formulaires terminés');
        print('🔄 Nouveau statut: $nouveauStatut');
      }

      print('✅ Session mise à jour avec la participation de l\'invité');
    } catch (e) {
      print('⚠️ Erreur lors de la mise à jour de la session: $e');
      // Ne pas faire échouer la soumission pour cette erreur
    }
  }


}

/// 👥 Dialog pour ajouter un témoin
class _TemoinDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onTemoinAdded;

  const _TemoinDialog({required this.onTemoinAdded});

  @override
  State<_TemoinDialog> createState() => _TemoinDialogState();
}

class _TemoinDialogState extends State<_TemoinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le prénom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final temoin = {
                'nom': _nomController.text.trim(),
                'prenom': _prenomController.text.trim(),
                'telephone': _telephoneController.text.trim(),
                'isShared': false,
              };
              widget.onTemoinAdded(temoin);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
