import 'package:flutter/material.dart';
import '../services/auto_fill_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/elegant_form_widgets.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// 📋 Exemple d'utilisation du formulaire optimisé avec pré-remplissage
class OptimizedAccidentFormExample extends StatefulWidget {
  const OptimizedAccidentFormExample({Key? key}) : super(key: key);

  @override
  State<OptimizedAccidentFormExample> createState() => _OptimizedAccidentFormExampleState();
}

class _OptimizedAccidentFormExampleState extends State<OptimizedAccidentFormExample> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour les champs
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _lieuController = TextEditingController();
  final _descriptionController = TextEditingController();

  // État
  bool _isLoading = false;
  bool _isPreFilled = false;
  List<String> _photos = [];
  Map<String, dynamic>? _vehiculeSelectionne;
  List<Map<String, dynamic>> _vehiculesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _loadPreFilledData();
  }

  /// 🔄 Charger les données pré-remplies
  Future<void> _loadPreFilledData() async {
    setState(() => _isLoading = true);

    try {
      final preFilledData = await AutoFillService.getCompletePreFilledData();
      
      if (preFilledData['isPreFilled'] == true) {
        _applyPreFilledData(preFilledData);
        setState(() => _isPreFilled = true);
        
        _showSuccessMessage('✅ Formulaire pré-rempli automatiquement !');
      }
    } catch (e) {
      _showErrorMessage('Erreur lors du pré-remplissage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📝 Appliquer les données pré-remplies
  void _applyPreFilledData(Map<String, dynamic> data) {
    final conducteur = data['conducteur'] ?? {};
    final dateTime = data['dateTime'] ?? {};
    final location = data['location'] ?? {};
    final vehicules = data['vehicules'] ?? [];

    // Données du conducteur
    _nomController.text = conducteur['nom'] ?? '';
    _prenomController.text = conducteur['prenom'] ?? '';
    _emailController.text = conducteur['email'] ?? '';
    _telephoneController.text = conducteur['telephone'] ?? '';

    // Date et heure
    _dateController.text = dateTime['dateFormatted'] ?? '';
    _heureController.text = dateTime['heure'] ?? '';

    // Localisation
    _lieuController.text = location['adresse'] ?? '';

    // Véhicules
    _vehiculesDisponibles = List<Map<String, dynamic>>.from(vehicules);
    if (_vehiculesDisponibles.isNotEmpty) {
      _vehiculeSelectionne = _vehiculesDisponibles.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Déclaration d\'Accident Optimisée'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Indicateur de pré-remplissage
                    ElegantFormWidgets.buildPreFilledIndicator(
                      isPreFilled: _isPreFilled,
                      message: 'Vos informations ont été pré-remplies automatiquement',
                    ),

                    // Section informations personnelles
                    ElegantFormWidgets.buildFormSection(
                      title: 'Informations Personnelles',
                      icon: Icons.person,
                      iconColor: Colors.blue[600],
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElegantFormWidgets.buildElegantTextField(
                                label: 'Nom',
                                controller: _nomController,
                                isRequired: true,
                                validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElegantFormWidgets.buildElegantTextField(
                                label: 'Prénom',
                                controller: _prenomController,
                                isRequired: true,
                                validator: (value) => value?.isEmpty == true ? 'Prénom requis' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElegantFormWidgets.buildElegantTextField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          isRequired: true,
                          validator: (value) => value?.contains('@') != true ? 'Email invalide' : null,
                        ),
                        const SizedBox(height: 16),
                        ElegantFormWidgets.buildElegantTextField(
                          label: 'Téléphone',
                          controller: _telephoneController,
                          keyboardType: TextInputType.phone,
                          isRequired: true,
                          validator: (value) => value?.isEmpty == true ? 'Téléphone requis' : null,
                        ),
                      ],
                    ),

                    // Section véhicule
                    if (_vehiculesDisponibles.isNotEmpty)
                      ElegantFormWidgets.buildFormSection(
                        title: 'Véhicule Impliqué',
                        icon: Icons.directions_car,
                        iconColor: Colors.green[600],
                        children: [
                          ElegantFormWidgets.buildElegantDropdown<Map<String, dynamic>>(
                            label: 'Sélectionner un véhicule',
                            value: _vehiculeSelectionne,
                            items: _vehiculesDisponibles.map((vehicule) {
                              return DropdownMenuItem(
                                value: vehicule,
                                child: Text('${vehicule['marque']} ${vehicule['modele']} - ${vehicule['immatriculation']}'),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _vehiculeSelectionne = value),
                            isRequired: true,
                          ),
                          if (_vehiculeSelectionne != null) ...[
                            const SizedBox(height: 16),
                            _buildVehiculeInfo(),
                          ],
                        ],
                      ),

                    // Section accident
                    ElegantFormWidgets.buildFormSection(
                      title: 'Détails de l\'Accident',
                      icon: Icons.warning,
                      iconColor: Colors.orange[600],
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElegantFormWidgets.buildDatePicker(
                                label: 'Date',
                                controller: _dateController,
                                context: context,
                                isRequired: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElegantFormWidgets.buildTimePicker(
                                label: 'Heure',
                                controller: _heureController,
                                context: context,
                                isRequired: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElegantFormWidgets.buildElegantTextField(
                          label: 'Lieu de l\'accident',
                          controller: _lieuController,
                          hint: 'Adresse précise ou point de repère',
                          isRequired: true,
                          validator: (value) => value?.isEmpty == true ? 'Lieu requis' : null,
                        ),
                        const SizedBox(height: 16),
                        ElegantFormWidgets.buildElegantTextField(
                          label: 'Description de l\'accident',
                          controller: _descriptionController,
                          hint: 'Décrivez ce qui s\'est passé...',
                          maxLines: 4,
                          isRequired: true,
                          validator: (value) => value?.isEmpty == true ? 'Description requise' : null,
                        ),
                      ],
                    ),

                    // Section photos
                    ElegantFormWidgets.buildFormSection(
                      title: 'Photos de l\'Accident',
                      icon: Icons.camera_alt,
                      iconColor: Colors.purple[600],
                      children: [
                        _buildPhotosSection(),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElegantFormWidgets.buildElegantButton(
                            text: 'Ajouter Photo',
                            onPressed: _ajouterPhoto,
                            backgroundColor: Colors.grey[600],
                            icon: Icons.add_a_photo,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElegantFormWidgets.buildElegantButton(
                            text: 'Soumettre',
                            onPressed: _soumettre,
                            isLoading: _isLoading,
                            icon: Icons.send,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 🚗 Widget d'informations du véhicule
  Widget _buildVehiculeInfo() {
    final vehicule = _vehiculeSelectionne!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vehicule['marque']} ${vehicule['modele']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Immatriculation: ${vehicule['immatriculation']}'),
          Text('Couleur: ${vehicule['couleur']}'),
          if (vehicule['numeroContrat'] != null)
            Text('Contrat: ${vehicule['numeroContrat']}'),
        ],
      ),
    );
  }

  /// 📸 Section photos
  Widget _buildPhotosSection() {
    return Column(
      children: [
        if (_photos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return _buildPhotoCard(_photos[index], index);
            },
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '${_photos.length}/5 photos ajoutées',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 🖼️ Carte de photo
  Widget _buildPhotoCard(String photoUrl, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Image.network(
              photoUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                );
              },
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _supprimerPhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📸 Ajouter une photo
  Future<void> _ajouterPhoto() async {
    if (_photos.length >= 5) {
      _showErrorMessage('Maximum 5 photos autorisées');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        final photoUrl = await CloudinaryService.uploadImage(
          File(image.path),
          'accidents',
        );

        if (photoUrl != null) {
          setState(() {
            _photos.add(photoUrl);
            _isLoading = false;
          });
          _showSuccessMessage('Photo ajoutée avec succès !');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Erreur lors de l\'ajout: $e');
    }
  }

  /// 🗑️ Supprimer une photo
  void _supprimerPhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
    _showSuccessMessage('Photo supprimée');
  }

  /// 📤 Soumettre le formulaire
  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Simuler l'envoi
      await Future.delayed(const Duration(seconds: 2));
      
      _showSuccessMessage('✅ Déclaration soumise avec succès !');
      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage('Erreur lors de la soumission: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Message de succès
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ❌ Message d'erreur
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _dateController.dispose();
    _heureController.dispose();
    _lieuController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
