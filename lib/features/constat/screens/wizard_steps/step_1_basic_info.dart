import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../models/sinistre_model.dart';
import '../declaration_wizard_screen.dart';

/// 📍 Étape 1: Informations de base (date, lieu, description)
class Step1BasicInfo extends StatefulWidget {
  final WizardData wizardData;
  final VoidCallback onNext;

  const Step1BasicInfo({
    super.key,
    required this.wizardData,
    required this.onNext,
  });

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.wizardData.dateAccident ?? DateTime.now();
    _selectedTime = TimeOfDay.now();
    _descriptionController.text = widget.wizardData.description ?? '';
    _addressController.text = widget.wizardData.location?.address ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de l'étape
            const Text(
              'Informations de base',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Renseignez les informations principales de l\'accident',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date et heure
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),

                    // Localisation
                    _buildLocationSection(),
                    const SizedBox(height: 24),

                    // Description
                    _buildDescriptionSection(),
                  ],
                ),
              ),
            ),

            // Bouton suivant
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Suivant',
                onPressed: _canProceed() ? _handleNext : null,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date et heure de l\'accident',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            // Date
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Sélectionner',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Heure
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Heure',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _selectedTime != null
                                ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                : 'Sélectionner',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lieu de l\'accident',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Adresse',
            hintText: 'Saisissez l\'adresse de l\'accident',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: IconButton(
              icon: _isLoadingLocation 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir l\'adresse';
            }
            return null;
          },
          onChanged: (value) {
            widget.wizardData.location = SinistreLocation(
              lat: widget.wizardData.location?.lat ?? 0,
              lng: widget.wizardData.location?.lng ?? 0,
              address: value,
            );
          },
        ),
        
        if (widget.wizardData.location?.lat != null && widget.wizardData.location?.lng != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Coordonnées: ${widget.wizardData.location!.lat.toStringAsFixed(6)}, ${widget.wizardData.location!.lng.toStringAsFixed(6)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description de l\'accident',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Décrivez brièvement les circonstances de l\'accident',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ex: Collision à un carrefour, véhicule A n\'a pas respecté le stop...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            widget.wizardData.description = value;
          },
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _updateDateTime();
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
      _updateDateTime();
    }
  }

  void _updateDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      widget.wizardData.dateAccident = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition();
      
      setState(() {
        widget.wizardData.location = SinistreLocation(
          lat: position.latitude,
          lng: position.longitude,
          address: _addressController.text.isEmpty 
              ? 'Position actuelle' 
              : _addressController.text,
        );
      });

      if (_addressController.text.isEmpty) {
        _addressController.text = 'Position actuelle';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de géolocalisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  bool _canProceed() {
    return _selectedDate != null && 
           _selectedTime != null && 
           _addressController.text.isNotEmpty;
  }

  void _handleNext() {
    if (_formKey.currentState!.validate() && _canProceed()) {
      _updateDateTime();
      widget.onNext();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
