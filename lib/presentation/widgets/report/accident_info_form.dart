// lib/presentation/widgets/report/accident_info_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccidentInfoForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onSaved;
  final Map<String, dynamic> initialData;

  const AccidentInfoForm({
    super.key,
    required this.formKey,
    required this.onSaved,
    required this.initialData,
  });

  @override
  State<AccidentInfoForm> createState() => _AccidentInfoFormState();
}

class _AccidentInfoFormState extends State<AccidentInfoForm> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  GeoPoint? _location;
  bool _hasInjuries = false;
  bool _hasOtherDamage = false;
  bool _isLoadingLocation = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser avec les données existantes si disponibles
    if (widget.initialData.containsKey('accidentDate')) {
      final date = widget.initialData['accidentDate'] as DateTime;
      _selectedDate = date;
      _dateController.text = DateFormat('dd/MM/yyyy').format(date);
      _selectedTime = TimeOfDay.fromDateTime(date);
      _timeController.text = _selectedTime!.format(context);
    }
    
    if (widget.initialData.containsKey('accidentAddress')) {
      _addressController.text = widget.initialData['accidentAddress'];
    }
    
    if (widget.initialData.containsKey('accidentLocation')) {
      _location = widget.initialData['accidentLocation'];
    }
    
    if (widget.initialData.containsKey('hasInjuries')) {
      _hasInjuries = widget.initialData['hasInjuries'];
    }
    
    if (widget.initialData.containsKey('hasOtherDamage')) {
      _hasOtherDamage = widget.initialData['hasOtherDamage'];
    }
    
    // Si aucune date n'est définie, utiliser la date et l'heure actuelles
    if (_selectedDate == null) {
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      _selectedTime = TimeOfDay.now();
      _timeController.text = _selectedTime!.format(context);
    }
    
    // Si aucune localisation n'est définie, essayer de l'obtenir automatiquement
    if (_location == null) {
      _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date et heure de l'accident
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date de l\'accident',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une date';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'Heure',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectTime(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez sélectionner une heure';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lieu de l'accident
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Lieu de l\'accident',
              prefixIcon: const Icon(Icons.location_on),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _getCurrentLocation,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez indiquer le lieu de l\'accident';
              }
              return null;
            },
          ),
          
          if (_isLoadingLocation)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(),
            ),
          
          const SizedBox(height: 16),
          
          // Blessés
          SwitchListTile(
            title: const Text('Blessés (même légers)'),
            value: _hasInjuries,
            onChanged: (value) {
              setState(() {
                _hasInjuries = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          // Dégâts matériels autres
          SwitchListTile(
            title: const Text('Dégâts matériels autres qu\'aux véhicules'),
            value: _hasOtherDamage,
            onChanged: (value) {
              setState(() {
                _hasOtherDamage = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }
      
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Convertir les coordonnées en adresse
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.locality,
          placemark.postalCode,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        setState(() {
          _location = GeoPoint(position.latitude, position.longitude);
          _addressController.text = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de localisation: $e')),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}