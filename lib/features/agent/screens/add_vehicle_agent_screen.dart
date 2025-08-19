import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/form_styles.dart';

/// 🚗 Écran d'ajout de véhicule pour les agents
class AddVehicleAgentScreen extends StatefulWidget {
  const AddVehicleAgentScreen({Key? key}) : super(key: key);

  @override
  State<AddVehicleAgentScreen> createState() => _AddVehicleAgentScreenState();
}

class _AddVehicleAgentScreenState extends State<AddVehicleAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerCinController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _ownerNameController.dispose();
    _ownerCinController.dispose();
    _ownerPhoneController.dispose();
    _ownerAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Ajouter un Véhicule',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildForm(),
    );
  }

  /// 🔄 Écran de chargement
  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF10B981)),
          SizedBox(height: 20),
          Text(
            'Ajout du véhicule en cours...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// 📝 Formulaire d'ajout
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildHeader(),
            const SizedBox(height: 30),
            
            // Informations du véhicule
            FormStyles.buildFormSection(
              title: 'Informations du Véhicule',
              icon: Icons.directions_car_rounded,
              children: [
                FormStyles.buildTextFormField(
                  labelText: 'Numéro d\'immatriculation',
                  controller: _plateController,
                  prefixIcon: Icons.confirmation_number_rounded,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le numéro d\'immatriculation est requis';
                    }
                    return null;
                  },
                ),
                FormStyles.fieldSpacing,
                
                FormStyles.buildTextFormField(
                  labelText: 'Marque',
                  controller: _brandController,
                  prefixIcon: Icons.branding_watermark_rounded,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La marque est requise';
                    }
                    return null;
                  },
                ),
                FormStyles.fieldSpacing,
                
                FormStyles.buildTextFormField(
                  labelText: 'Modèle',
                  controller: _modelController,
                  prefixIcon: Icons.car_rental_rounded,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le modèle est requis';
                    }
                    return null;
                  },
                ),
                FormStyles.fieldSpacing,
                
                Row(
                  children: [
                    Expanded(
                      child: FormStyles.buildTextFormField(
                        labelText: 'Année',
                        controller: _yearController,
                        prefixIcon: Icons.calendar_today_rounded,
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L\'année est requise';
                          }
                          final year = int.tryParse(value);
                          if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                            return 'Année invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormStyles.buildTextFormField(
                        labelText: 'Couleur',
                        controller: _colorController,
                        prefixIcon: Icons.palette_rounded,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La couleur est requise';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Informations du propriétaire
            FormStyles.buildFormSection(
              title: 'Informations du Propriétaire',
              icon: Icons.person_rounded,
              children: [
                FormStyles.buildTextFormField(
                  labelText: 'Nom complet',
                  controller: _ownerNameController,
                  prefixIcon: Icons.person_outline_rounded,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom du propriétaire est requis';
                    }
                    return null;
                  },
                ),
                FormStyles.fieldSpacing,
                
                FormStyles.buildTextFormField(
                  labelText: 'CIN',
                  controller: _ownerCinController,
                  prefixIcon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le CIN est requis';
                    }
                    return null;
                  },
                ),
                FormStyles.fieldSpacing,
                
                FormStyles.buildTextFormField(
                  labelText: 'Téléphone',
                  controller: _ownerPhoneController,
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le téléphone est requis';
                    }
                    return null;
                  },
                ),
                FormStyles.fieldSpacing,
                
                FormStyles.buildTextFormField(
                  labelText: 'Adresse',
                  controller: _ownerAddressController,
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 3,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Boutons d'action
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 🎯 En-tête
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau Véhicule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ajoutez un véhicule pour créer des contrats',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Annuler'),
            style: FormStyles.getSecondaryButtonStyle(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveVehicle,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Ajouter'),
            style: FormStyles.getPrimaryButtonStyle().copyWith(
              backgroundColor: WidgetStateProperty.all(const Color(0xFF10B981)),
            ),
          ),
        ),
      ],
    );
  }

  /// 💾 Sauvegarder le véhicule
  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Créer le véhicule dans Firestore
      await FirebaseFirestore.instance.collection('vehicules').add({
        'plate': _plateController.text.trim(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'color': _colorController.text.trim(),
        'owner': {
          'name': _ownerNameController.text.trim(),
          'cin': _ownerCinController.text.trim(),
          'phone': _ownerPhoneController.text.trim(),
          'address': _ownerAddressController.text.trim().isEmpty 
              ? null : _ownerAddressController.text.trim(),
        },
        'status': 'pending_contract', // En attente de contrat
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'agent', // Créé par un agent
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Véhicule ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer un ajout
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
