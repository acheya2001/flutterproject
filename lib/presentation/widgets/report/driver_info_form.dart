// lib/presentation/widgets/report/driver_info_form.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:constat_tunisie/data/services/ocr_service.dart';
import 'package:logger/logger.dart';

class DriverInfoForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onSaved;
  final Map<String, dynamic> initialData;
  final bool useOCR;

  const DriverInfoForm({
    super.key,
    required this.formKey,
    required this.onSaved,
    required this.initialData,
    this.useOCR = false,
  });

  @override
  State<DriverInfoForm> createState() => _DriverInfoFormState();
}

class _DriverInfoFormState extends State<DriverInfoForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _licenseDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  DateTime? _licenseDate;
  bool _isProcessingOCR = false;
  final OCRService _ocrService = OCRService();
  final Logger _logger = Logger();
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser avec les données existantes si disponibles
    if (widget.initialData.containsKey('driverName')) {
      _nameController.text = widget.initialData['driverName'] ?? '';
    }
    
    if (widget.initialData.containsKey('driverAddress')) {
      _addressController.text = widget.initialData['driverAddress'] ?? '';
    }
    
    if (widget.initialData.containsKey('driverLicenseNumber')) {
      _licenseNumberController.text = widget.initialData['driverLicenseNumber'] ?? '';
    }
    
    if (widget.initialData.containsKey('driverLicenseDate')) {
      _licenseDate = widget.initialData['driverLicenseDate'];
      if (_licenseDate != null) {
        _licenseDateController.text = DateFormat('dd/MM/yyyy').format(_licenseDate!);
      }
    }
    
    if (widget.initialData.containsKey('driverPhone')) {
      _phoneController.text = widget.initialData['driverPhone'] ?? '';
    }
    
    if (widget.initialData.containsKey('driverEmail')) {
      _emailController.text = widget.initialData['driverEmail'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.useOCR) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scanner votre permis de conduire',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Prenez une photo de votre permis pour remplir automatiquement vos informations.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isProcessingOCR ? null : () => _scanLicense(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Appareil photo'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isProcessingOCR ? null : () => _scanLicense(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galerie'),
                        ),
                      ],
                    ),
                    if (_isProcessingOCR)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Analyse du permis en cours...'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Nom du conducteur
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom et prénom',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre nom';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Adresse
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre adresse';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Numéro de permis
          TextFormField(
            controller: _licenseNumberController,
            decoration: const InputDecoration(
              labelText: 'Numéro de permis',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre numéro de permis';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Date du permis
          TextFormField(
            controller: _licenseDateController,
            decoration: const InputDecoration(
              labelText: 'Date du permis',
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () => _selectLicenseDate(context),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner la date de votre permis';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Téléphone
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre numéro de téléphone';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Veuillez entrer un email valide';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectLicenseDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _licenseDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _licenseDate) {
      setState(() {
        _licenseDate = picked;
        _licenseDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _scanLicense(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image == null) return;
      
      setState(() {
        _isProcessingOCR = true;
      });
      
      // Analyser l'image avec OCR - Correction du nom de la méthode
      final result = await _ocrService.extractDriverLicenseInfo(File(image.path));
      
      // Remplir les champs avec les données extraites
      if (result.containsKey('nom')) {
        _nameController.text = result['nom'] ?? '';
        if (result.containsKey('prenom')) {
          _nameController.text += ' ${result['prenom'] ?? ''}';
        }
      }
      
      if (result.containsKey('adresse')) {
        _addressController.text = result['adresse'] ?? '';
      }
      
      if (result.containsKey('numeroPermis')) {
        _licenseNumberController.text = result['numeroPermis'] ?? '';
      }
      
      if (result.containsKey('dateDelivrance')) {
        try {
          // Convertir la chaîne de date en objet DateTime
          final dateStr = result['dateDelivrance'];
          if (dateStr != null) {
            final parts = dateStr.split('/');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              _licenseDate = DateTime(year, month, day);
              _licenseDateController.text = dateStr;
            }
          }
        } catch (e) {
          // Utiliser Logger au lieu de print
          _logger.e('Erreur de conversion de date: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations extraites avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'analyse: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOCR = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    _licenseDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  // Cette méthode est appelée lorsque le formulaire est soumis
  void save() {
    final data = {
      'driverName': _nameController.text,
      'driverAddress': _addressController.text,
      'driverLicenseNumber': _licenseNumberController.text,
      'driverLicenseDate': _licenseDate,
      'driverPhone': _phoneController.text,
      'driverEmail': _emailController.text,
    };
    widget.onSaved(data);
  }
}