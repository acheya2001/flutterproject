import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase极Auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core极widgets/custom_button.dart';
import '../../../services/cloudinary_storage_service.dart';
import '../../../services/complete_insurance_workflow_service.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/services/logging_service.dart';
import '../../common/mixins/safe_state_mixin.dart';

/// 🚗 Écran complet de demande d'assurance avec tous les champs nécessaires
/// Combine les fonctionnalités d'ajout de véhicule et de demande d'assurance
class CompleteInsuranceRequestScreen extends StatefulWidget {
  const CompleteInsuranceRequestScreen({super.key});

  @override
  State<CompleteInsuranceRequestScreen> createState() => _CompleteInsuranceRequestScreenState();
}

class _CompleteInsuranceRequest极ScreenState extends State<CompleteInsuranceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Contrôleurs de formulaire - Véhicule
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController极 = TextEditingController();
  final _yearController = TextEditingController();
 极final _colorController = TextEditingController();
  final _carteGriseNumberController = TextEditingController();
  final _vinController = TextEditingController();
  String _fuelType = 'essence'; // essence, diesel, hybride, electrique, gpl
  DateTime? _firstRegistrationDate;

  // Contrôleurs de formulaire - Conducteur
  final _conducteurNameController = TextEditingController();
  final _conducteurPrenomController = TextEditingController();
  final _conducteurAddressController = TextEditingController();
  final _conducteurPhoneController = TextEditingController();
  final _conducteurEmailController = TextEditingController();
  final _permisNumberController = TextEditingController();
  DateTime? _permisDeliveryDate;

  // Propriétaire
  bool _isConducteurOwner = true;
  final _ownerNameController = TextEditingController();
  final _ownerCinController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  String _relationToConducteur = 'parent';

  // Documents
  File? _carteGriseFile;
  File? _permisFile;
  File? _carteIdentiteFile;
  List<File> _vehiclePhotos = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _yearController.text = DateTime.now().year.toString();
    _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final user极Data = userDoc.data() ?? {};
      
      if (mounted) setState(() {
        _conducteurNameController.text = userData['nom'] ?? '';
        _conducteurPrenomController.text = userData['prenom'] ?? '';
        _conducteurPhoneController.text = userData['telephone'] ?? '';
        _conducteurEmailController.text = userData['email'] ?? user.email ?? '';
        _conducteurAddressController.text = userData['adresse'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Demande d\'Assurance Complète',
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),

