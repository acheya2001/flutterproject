// lib/presentation/widgets/report/vehicle_info_form.dart

import 'package:flutter/material.dart';
import 'package:constat_tunisie/data/services/ocr_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class VehicleInfoForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onSaved;
  final Map<String, dynamic> initialData;
  final bool useOCR;

  const VehicleInfoForm({
    super.key, // Utilisation de super.key au lieu de key: key
    required this.formKey,
    required this.onSaved,
    required this.initialData,
    this.useOCR = false,
  });

  @override
  State<VehicleInfoForm> createState() => _VehicleInfoFormState();
}

class _VehicleInfoFormState extends State<VehicleInfoForm> {
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les données existantes
    _makeController.text = widget.initialData['vehicleMake'] ?? '';
    _modelController.text = widget.initialData['vehicleModel'] ?? '';
    _plateNumberController.text = widget.initialData['vehiclePlateNumber'] ?? '';
    _registrationNumberController.text = widget.initialData['vehicleRegistrationNumber'] ?? '';
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _plateNumberController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  Future<void> _scanRegistrationCard() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isProcessing = true;
      });

      final File imageFile = File(image.path);
      // Utilisation de extractTextFromImage au lieu de extractVehicleRegistrationInfo
      final String extractedText = await _ocrService.extractTextFromImage(imageFile);
      
      // Analyse du texte extrait pour trouver les informations du véhicule
      final Map<String, String> extractedInfo = _parseVehicleInfo(extractedText);

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _makeController.text = extractedInfo['marque'] ?? _makeController.text;
          _modelController.text = extractedInfo['modele'] ?? _modelController.text;
          _plateNumberController.text = extractedInfo['immatriculation'] ?? _plateNumberController.text;
          _registrationNumberController.text = extractedInfo['numeroSerie'] ?? _registrationNumberController.text;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la numérisation: $e')),
        );
      }
    }
  }

  // Méthode pour analyser le texte extrait et trouver les informations du véhicule
  Map<String, String> _parseVehicleInfo(String text) {
    final Map<String, String> result = {};
    
    // Recherche de la marque (généralement après "MARQUE:" ou similaire)
    final marqueRegex = RegExp(r'(?:MARQUE|Marque)[:\s]+([A-Za-z0-9]+)');
    final marqueMatch = marqueRegex.firstMatch(text);
    if (marqueMatch != null && marqueMatch.groupCount >= 1) {
      result['marque'] = marqueMatch.group(1)!.trim();
    }
    
    // Recherche du modèle (généralement après "MODELE:" ou similaire)
    final modeleRegex = RegExp(r'(?:MODELE|Modèle|Type)[:\s]+([A-Za-z0-9]+)');
    final modeleMatch = modeleRegex.firstMatch(text);
    if (modeleMatch != null && modeleMatch.groupCount >= 1) {
      result['modele'] = modeleMatch.group(1)!.trim();
    }
    
    // Recherche du numéro d'immatriculation (format tunisien)
    final immatRegex = RegExp(r'(\d{1,3})\s*(?:TUN|تونس)\s*(\d{1,4})');
    final immatMatch = immatRegex.firstMatch(text);
    if (immatMatch != null && immatMatch.groupCount >= 2) {
      result['immatriculation'] = '${immatMatch.group(1)} TUN ${immatMatch.group(2)}';
    }
    
    // Recherche du numéro de série (VIN)
    final vinRegex = RegExp(r'(?:VIN|N°\s*Chassis|Numéro\s*de\s*série)[:\s]+([A-Z0-9]{17})');
    final vinMatch = vinRegex.firstMatch(text);
    if (vinMatch != null && vinMatch.groupCount >= 1) {
      result['numeroSerie'] = vinMatch.group(1)!.trim();
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      onChanged: () {
        widget.formKey.currentState?.validate();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.useOCR) ...[
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _scanRegistrationCard,
              icon: const Icon(Icons.document_scanner),
              label: Text(_isProcessing 
                ? 'Analyse en cours...' 
                : 'Scanner la carte grise'),
            ),
            const SizedBox(height: 16),
          ],
          
          TextFormField(
            controller: _makeController,
            decoration: const InputDecoration(
              labelText: 'Marque du véhicule *',
              hintText: 'Ex: Renault, Peugeot, etc.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer la marque du véhicule';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Modèle du véhicule *',
              hintText: 'Ex: Clio, 208, etc.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le modèle du véhicule';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _plateNumberController,
            decoration: const InputDecoration(
              labelText: 'Numéro d\'immatriculation *',
              hintText: 'Ex: 123 TUN 4567',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le numéro d\'immatriculation';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _registrationNumberController,
            decoration: const InputDecoration(
              labelText: 'Numéro de série du véhicule',
              hintText: 'Ex: VF1RFA00066123456',
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Cette méthode est appelée lorsque le formulaire est soumis
  void save() {
    final data = {
      'vehicleMake': _makeController.text,
      'vehicleModel': _modelController.text,
      'vehiclePlateNumber': _plateNumberController.text,
      'vehicleRegistrationNumber': _registrationNumberController.text,
    };
    widget.onSaved(data);
  }
}