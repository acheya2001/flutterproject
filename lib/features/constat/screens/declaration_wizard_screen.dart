import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/sinistre_model.dart';
import '../services/sinistre_service.dart';
import 'wizard_steps/step_1_basic_info.dart';
import 'wizard_steps/step_2_vehicles.dart';
import 'wizard_steps/step_3_participants.dart';
import 'wizard_steps/step_4_attachments.dart';
import 'wizard_steps/step_5_signature.dart';
import 'wizard_steps/step_6_confirmation.dart';

/// 🧙‍♂️ Wizard de déclaration de sinistre en 6 étapes
class DeclarationWizardScreen extends StatefulWidget {
  const DeclarationWizardScreen({super.key});

  @override
  State<DeclarationWizardScreen> createState() => _DeclarationWizardScreenState();
}

class _DeclarationWizardScreenState extends State<DeclarationWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Données du wizard
  final WizardData _wizardData = WizardData();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _wizardData.location = SinistreLocation(
          lat: position.latitude,
          lng: position.longitude,
          address: 'Position actuelle', // TODO: Géocodage inverse
        );
      });
    } catch (e) {
      print('Erreur géolocalisation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Déclaration d\'accident',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu des étapes
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1BasicInfo(
                  wizardData: _wizardData,
                  onNext: () => _nextStep(),
                ),
                Step2Vehicles(
                  wizardData: _wizardData,
                  onNext: () => _nextStep(),
                  onPrevious: () => _previousStep(),
                ),
                Step3Participants(
                  wizardData: _wizardData,
                  onNext: () => _nextStep(),
                  onPrevious: () => _previousStep(),
                ),
                Step4Attachments(
                  wizardData: _wizardData,
                  onNext: () => _nextStep(),
                  onPrevious: () => _previousStep(),
                ),
                Step5Signature(
                  wizardData: _wizardData,
                  onNext: () => _nextStep(),
                  onPrevious: () => _previousStep(),
                ),
                Step6Confirmation(
                  wizardData: _wizardData,
                  onSubmit: () => _submitDeclaration(),
                  onPrevious: () => _previousStep(),
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(6, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      const SizedBox(width: 4),
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? const Color(0xFF3B82F6) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitDeclaration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Créer le sinistre
      final sinistreId = await SinistreService.createSinistre(
        location: _wizardData.location!,
        dateAccident: _wizardData.dateAccident!,
        vehicles: _wizardData.vehicles,
        description: _wizardData.description,
      );

      // Ajouter les participants invités
      for (final participant in _wizardData.participants) {
        await SinistreService.addParticipant(
          sinistreId: sinistreId,
          emailOrPhone: participant['emailOrPhone'],
          role: participant['role'],
          vehicleRef: participant['vehicleRef'],
          isOwner: participant['isOwner'] ?? false,
        );
      }

      // Uploader les pièces jointes
      for (final attachment in _wizardData.attachments) {
        await SinistreService.uploadAttachment(
          sinistreId: sinistreId,
          file: attachment['file'],
          type: attachment['type'],
        );
      }

      // Succès - naviguer vers la vue collaborative
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/constat/collaborative',
          arguments: {'sinistreId': sinistreId},
        );
      }
    } catch (e) {
      // Erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
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

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la déclaration'),
        content: const Text('Êtes-vous sûr de vouloir quitter ? Vos données seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// 📋 Classe pour stocker les données du wizard
class WizardData {
  // Étape 1: Infos de base
  SinistreLocation? location;
  DateTime? dateAccident;
  String? description;

  // Étape 2: Véhicules
  List<SinistreVehicleRef> vehicles = [];

  // Étape 3: Participants
  List<Map<String, dynamic>> participants = [];

  // Étape 4: Pièces jointes
  List<Map<String, dynamic>> attachments = [];

  // Étape 5: Signature
  String? signature;

  // Validation
  bool get isStep1Valid => location != null && dateAccident != null;
  bool get isStep2Valid => vehicles.isNotEmpty;
  bool get isStep3Valid => true; // Participants optionnels
  bool get isStep4Valid => true; // Pièces jointes optionnelles
  bool get isStep5Valid => signature != null;
}
