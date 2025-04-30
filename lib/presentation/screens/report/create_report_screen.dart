// lib/presentation/screens/report/create_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';
import 'package:constat_tunisie/data/models/accident_report_model.dart';
import 'package:constat_tunisie/data/services/report_service.dart';
import 'package:constat_tunisie/presentation/widgets/report/accident_info_form.dart';
import 'package:constat_tunisie/presentation/widgets/report/driver_info_form.dart';
import 'package:constat_tunisie/presentation/widgets/report/vehicle_info_form.dart';
import 'package:constat_tunisie/presentation/widgets/report/insurance_info_form.dart';
import 'package:constat_tunisie/presentation/widgets/report/circumstances_form.dart';
import 'package:constat_tunisie/presentation/widgets/report/sketch_editor.dart';
import 'package:constat_tunisie/presentation/widgets/report/signature_pad.dart';
import 'package:logger/logger.dart';

class CreateReportScreen extends StatefulWidget {
  // Rendre le paramètre optionnel avec une valeur par défaut
  final String invitationCode;
  
  const CreateReportScreen({
    Key? key,
    this.invitationCode = '',  // Paramètre optionnel avec valeur par défaut
  }) : super(key: key);

  static void navigateTo(BuildContext context, {String invitationCode = ''}) {
    Navigator.of(context).pushNamed(
      '/report/create',
      arguments: {'invitationCode': invitationCode},
    );
  }

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final ReportService _reportService = ReportService();
  final Logger _logger = Logger();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isInitialized = false;
  String _errorMessage = '';
  
  // Données du formulaire
  final _formData = <String, dynamic>{};
  
  // Contrôleurs pour les formulaires
  final _accidentInfoFormKey = GlobalKey<FormState>();
  final _driverInfoFormKey = GlobalKey<FormState>();
  final _vehicleInfoFormKey = GlobalKey<FormState>();
  final _insuranceInfoFormKey = GlobalKey<FormState>();
  final _circumstancesFormKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    _logger.d("CreateReportScreen - initState appelé");
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      _logger.d("CreateReportScreen - Initialisation de l'écran");
      setState(() {
        _isLoading = true;
      });
      
      // Si un code d'invitation est fourni, essayez de charger les données existantes
      if (widget.invitationCode.isNotEmpty) {
        _logger.d("Code d'invitation trouvé: ${widget.invitationCode}");
        // Vous pourriez charger des données existantes ici si nécessaire
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      _logger.e("Erreur lors de l'initialisation: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erreur lors de l'initialisation: $e";
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    _logger.d("CreateReportScreen - build appelé");

    // Afficher un écran de chargement pendant l'initialisation
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Créer un constat'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Afficher un message d'erreur si l'initialisation a échoué
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = '';
                    _isLoading = true;
                  });
                  _initializeScreen();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un constat'),
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _handleContinue,
          onStepCancel: _handleCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 6 ? 'Soumettre' : 'Continuer'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Retour'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: _buildSteps(),
        ),
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Informations sur l\'accident'),
        content: _buildAccidentInfoForm(),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Informations conducteur'),
        content: _buildDriverInfoForm(),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('Informations véhicule'),
        content: _buildVehicleInfoForm(),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('Informations assurance'),
        content: _buildInsuranceInfoForm(),
        isActive: _currentStep >= 3,
      ),
      Step(
        title: const Text('Circonstances'),
        content: _buildCircumstancesForm(),
        isActive: _currentStep >= 4,
      ),
      Step(
        title: const Text('Croquis de l\'accident'),
        content: _buildSketchEditor(),
        isActive: _currentStep >= 5,
      ),
      Step(
        title: const Text('Signature'),
        content: _buildSignaturePad(),
        isActive: _currentStep >= 6,
      ),
    ];
  }

  // Méthodes pour construire les formulaires
  Widget _buildAccidentInfoForm() {
    return AccidentInfoForm(
      formKey: _accidentInfoFormKey,
      onSaved: (data) => _formData.addAll(data),
      initialData: _formData,
    );
  }

  Widget _buildDriverInfoForm() {
    return DriverInfoForm(
      formKey: _driverInfoFormKey,
      onSaved: (data) => _formData.addAll(data),
      initialData: _formData,
      useOCR: true,
    );
  }

  Widget _buildVehicleInfoForm() {
    return VehicleInfoForm(
      formKey: _vehicleInfoFormKey,
      onSaved: (data) => _formData.addAll(data),
      initialData: _formData,
      useOCR: true,
    );
  }

  Widget _buildInsuranceInfoForm() {
    return InsuranceInfoForm(
      formKey: _insuranceInfoFormKey,
      onSaved: (data) => _formData.addAll(data),
      initialData: _formData,
    );
  }

  Widget _buildCircumstancesForm() {
    return CircumstancesForm(
      formKey: _circumstancesFormKey,
      onSaved: (data) => _formData.addAll(data),
      initialData: _formData,
    );
  }

  Widget _buildSketchEditor() {
    return SketchEditor(
      onSaved: (imageUrl, sketchData) {
        _formData['sketchImageUrl'] = imageUrl;
        _formData['sketchData'] = sketchData;
      },
    );
  }

  Widget _buildSignaturePad() {
    return SignaturePad(
      onSaved: (signatureUrl) {
        _formData['signatureAUrl'] = signatureUrl;
      },
    );
  }

  void _handleContinue() async {
    _logger.d("Étape actuelle: $_currentStep");
    
    try {
      switch (_currentStep) {
        case 0:
          if (_accidentInfoFormKey.currentState?.validate() ?? false) {
            _accidentInfoFormKey.currentState?.save();
            setState(() => _currentStep += 1);
          }
          break;
        case 1:
          if (_driverInfoFormKey.currentState?.validate() ?? false) {
            _driverInfoFormKey.currentState?.save();
            setState(() => _currentStep += 1);
          }
          break;
        case 2:
          if (_vehicleInfoFormKey.currentState?.validate() ?? false) {
            _vehicleInfoFormKey.currentState?.save();
            setState(() => _currentStep += 1);
          }
          break;
        case 3:
          if (_insuranceInfoFormKey.currentState?.validate() ?? false) {
            _insuranceInfoFormKey.currentState?.save();
            setState(() => _currentStep += 1);
          }
          break;
        case 4:
          if (_circumstancesFormKey.currentState?.validate() ?? false) {
            _circumstancesFormKey.currentState?.save();
            setState(() => _currentStep += 1);
          }
          break;
        case 5:
          // Le croquis est sauvegardé via le callback onSaved
          setState(() => _currentStep += 1);
          break;
        case 6:
          // Soumission du constat
          await _submitReport();
          break;
      }
    } catch (e) {
      _logger.e("Erreur lors de la validation de l'étape $_currentStep: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _handleCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _submitReport() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _logger.d("Soumission du rapport");
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Créer l'objet PartyInformation pour le conducteur A
      final partyA = PartyInformation(
        userId: user.uid,
        driverName: _formData['driverName'] ?? '',
        driverAddress: _formData['driverAddress'] ?? '',
        driverLicenseNumber: _formData['driverLicenseNumber'] ?? '',
        driverLicenseDate: _formData['driverLicenseDate'],
        driverPhone: _formData['driverPhone'] ?? '',
        driverEmail: _formData['driverEmail'] ?? '',
        vehicleId: _formData['vehicleId'] ?? '',
        vehicleMake: _formData['vehicleMake'] ?? '',
        vehicleModel: _formData['vehicleModel'] ?? '',
        vehiclePlateNumber: _formData['vehiclePlateNumber'] ?? '',
        vehicleRegistrationNumber: _formData['vehicleRegistrationNumber'] ?? '',
        insuranceCompanyId: _formData['insuranceCompanyId'] ?? '',
        insuranceAgencyId: _formData['insuranceAgencyId'] ?? '',
        insuranceContractNumber: _formData['insuranceContractNumber'] ?? '',
        insuranceValidFrom: _formData['insuranceValidFrom'],
        insuranceValidTo: _formData['insuranceValidTo'],
        visibleDamages: _formData['visibleDamages'] ?? [],
        damagePhotoUrls: _formData['damagePhotoUrls'] ?? [],
        initialImpact: _formData['initialImpact'] ?? ImpactPoint.front,
      );
      
      // Créer l'objet AccidentReport
      final report = AccidentReport(
        id: '', // Sera généré par Firestore
        date: _formData['accidentDate'] ?? DateTime.now(),
        location: _formData['accidentLocation'] ?? const GeoPoint(0, 0),
        address: _formData['accidentAddress'] ?? '',
        hasInjuries: _formData['hasInjuries'] ?? false,
        hasOtherDamage: _formData['hasOtherDamage'] ?? false,
        witnesses: _formData['witnesses'] ?? [],
        partyA: partyA,
        partyB: null, // Sera rempli par l'autre conducteur
        circumstancesA: _formData['circumstancesA'] ?? [],
        circumstancesB: [], // Sera rempli par l'autre conducteur
        sketchImageUrl: _formData['sketchImageUrl'] ?? '',
        sketchData: _formData['sketchData'] ?? {},
        observationsA: _formData['observationsA'] ?? '',
        observationsB: '', // Sera rempli par l'autre conducteur
        signatureAUrl: _formData['signatureAUrl'] ?? '',
        signatureBUrl: '', // Sera rempli par l'autre conducteur
        status: ReportStatus.pendingPartyB,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
        invitationCode: widget.invitationCode.isEmpty 
            ? _generateInvitationCode() 
            : widget.invitationCode,
      );
      
      // Enregistrer le constat dans Firestore
      final reportId = await _reportService.createReport(report);
      _logger.d("Rapport créé avec ID: $reportId");
      
      // Vérifier si le widget est toujours monté avant d'utiliser setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Afficher un message de succès et naviguer vers l'écran de détails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Constat créé avec succès')),
        );
        
        Navigator.of(context).pushReplacementNamed(
          '/report/details',
          arguments: {'reportId': reportId},
        );
      }
    } catch (e) {
      _logger.e("Erreur lors de la soumission du rapport: $e");
      // Vérifier si le widget est toujours monté avant d'utiliser setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
  
  // Générer un code d'invitation aléatoire
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }
}

// Ajout d'une classe GeoPoint si elle n'existe pas déjà dans votre modèle
class GeoPoint {
  final double latitude;
  final double longitude;
  
  const GeoPoint(this.latitude, this.longitude);
}
