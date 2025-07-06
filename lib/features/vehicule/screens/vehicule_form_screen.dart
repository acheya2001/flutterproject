import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


import '../../../utils/connectivity_utils.dart';
import '../models/vehicule_model.dart';
import '../providers/vehicule_provider.dart';
import '../../auth/providers/auth_provider.dart';


class VehiculeFormScreen extends ConsumerStatefulWidget {
  final VehiculeModel? vehicule;

  const VehiculeFormScreen({Key? key, this.vehicule}) : super(key: key);

  @override
  ConsumerState<VehiculeFormScreen> createState() => _VehiculeFormScreenState();
}

class _VehiculeFormScreenState extends ConsumerState<VehiculeFormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _compagnieAssuranceController = TextEditingController();
  final _numeroContratController = TextEditingController();
  final _quittanceController = TextEditingController();
  final _agenceController = TextEditingController();

  DateTime? _dateDebutValidite;
  DateTime? _dateFinValidite;

  File? _photoRectoFile;
  File? _photoVersoFile;
  bool _photoRectoChanged = false;
  bool _photoVersoChanged = false;

  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Couleurs pastel modernes
  static const Color _primaryPastel = Color(0xFF6B73FF);
  static const Color _secondaryPastel = Color(0xFF9B59B6);
  static const Color _accentPastel = Color(0xFF3498DB);
  static const Color _successPastel = Color(0xFF2ECC71);

  static const Color _backgroundPastel = Color(0xFFF8F9FA);
  static const Color _cardPastel = Color(0xFFFFFFFF);

  // Listes d'exemples
  final List<String> _marquesExemples = [
    'Renault', 'Peugeot', 'Citroën', 'Volkswagen', 'BMW', 'Mercedes', 
    'Audi', 'Toyota', 'Hyundai', 'Kia', 'Nissan', 'Ford', 'Opel',
    'Fiat', 'Seat', 'Skoda', 'Dacia', 'Suzuki', 'Mazda', 'Honda'
  ];

  final List<String> _assurancesExemples = [
    'STAR', 'GAT', 'COMAR', 'MAGHREBIA', 'LLOYD TUNISIEN', 
    'ASTREE', 'CTAMA', 'ZITOUNA TAKAFUL', 'SALIM', 'CARTE'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _initializeForm() {
    if (widget.vehicule != null) {
      _immatriculationController.text = widget.vehicule!.immatriculation;
      _marqueController.text = widget.vehicule!.marque;
      _modeleController.text = widget.vehicule!.modele;
      _compagnieAssuranceController.text = widget.vehicule!.compagnieAssurance;
      _numeroContratController.text = widget.vehicule!.numeroContrat;
      _quittanceController.text = widget.vehicule!.quittance;
      _agenceController.text = widget.vehicule!.agence;
      _dateDebutValidite = widget.vehicule!.dateDebutValidite;
      _dateFinValidite = widget.vehicule!.dateFinValidite;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _compagnieAssuranceController.dispose();
    _numeroContratController.dispose();
    _quittanceController.dispose();
    _agenceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isRecto) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          if (isRecto) {
            _photoRectoFile = File(pickedFile.path);
            _photoRectoChanged = true;
          } else {
            _photoVersoFile = File(pickedFile.path);
            _photoVersoChanged = true;
          }
        });
      }
    } catch (e) {
      debugPrint('[VehiculeFormScreen] Erreur lors de la sélection de l\'image: $e');
      if (mounted) {
        _showSnackBar('Erreur lors de la sélection de l\'image', isError: true);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _dateDebutValidite ?? DateTime.now()
          : _dateFinValidite ?? (DateTime.now().add(const Duration(days: 365))),
      firstDate: isStartDate ? DateTime(2000) : (_dateDebutValidite ?? DateTime.now()),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryPastel,
              onPrimary: Colors.white,
              surface: _cardPastel,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _dateDebutValidite = picked;
          if (_dateFinValidite != null && _dateFinValidite!.isBefore(_dateDebutValidite!)) {
            _dateFinValidite = _dateDebutValidite!.add(const Duration(days: 365));
          }
        } else {
          _dateFinValidite = picked;
        }
      });
    }
  }

  void _showImageSourceDialog(bool isRecto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryPastel.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_camera, color: _primaryPastel),
              ),
              const SizedBox(width: 12),
              const Text('Sélectionner une source'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSourceOption(
                icon: Icons.photo_library,
                title: 'Galerie',
                subtitle: 'Choisir depuis la galerie',
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, isRecto);
                },
              ),
              const SizedBox(height: 12),
              _buildSourceOption(
                icon: Icons.photo_camera,
                title: 'Appareil photo',
                subtitle: 'Prendre une nouvelle photo',
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, isRecto);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentPastel.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _accentPastel),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade400 : _successPastel,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateDebutValidite == null || _dateFinValidite == null) {
      _showSnackBar('Veuillez sélectionner les dates de validité', isError: true);
      return;
    }

    // Réinitialiser l'état du provider avant de commencer
    final vehiculeProviderInstance = ref.read(vehiculeProvider);
    vehiculeProviderInstance.resetForNewOperation();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final connectivityUtils = ConnectivityUtils();
      bool isConnected = await connectivityUtils.checkConnection();
      if (!isConnected) {
        throw Exception('Pas de connexion internet. Veuillez vérifier votre connexion et réessayer.');
      }
      
      final authProviderInstance = ref.read(authProvider);
      if (!mounted) return;

      if (authProviderInstance.currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final vehiculeProviderInstance = ref.read(vehiculeProvider);
      
      final vehicule = VehiculeModel(
        proprietaireId: authProviderInstance.currentUser!.id,
        immatriculation: _immatriculationController.text.trim(),
        marque: _marqueController.text.trim(),
        modele: _modeleController.text.trim(),
        compagnieAssurance: _compagnieAssuranceController.text.trim(),
        numeroContrat: _numeroContratController.text.trim(),
        quittance: _quittanceController.text.trim(),
        agence: _agenceController.text.trim(),
        dateDebutValidite: _dateDebutValidite,
        dateFinValidite: _dateFinValidite,
        photoCarteGriseRecto: widget.vehicule?.photoCarteGriseRecto,
        photoCarteGriseVerso: widget.vehicule?.photoCarteGriseVerso,
      );
      
      if (widget.vehicule == null) {
        await vehiculeProviderInstance.addVehicule(
          vehicule: vehicule,
          photoRecto: _photoRectoFile,
          photoVerso: _photoVersoFile,
        );
      } else {
        await vehiculeProviderInstance.updateVehicule(
          vehicule: vehicule.copyWith(id: widget.vehicule!.id),
          photoRecto: _photoRectoChanged ? _photoRectoFile : null,
          photoVerso: _photoVersoChanged ? _photoVersoFile : null,
        );
      }
      
      if (mounted) {
        _showSnackBar(widget.vehicule == null 
            ? 'Véhicule ajouté avec succès' 
            : 'Véhicule mis à jour avec succès');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });

        // Personnaliser le message d'erreur selon le type d'erreur
        String userFriendlyMessage;
        if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
          userFriendlyMessage = 'Le téléchargement prend trop de temps.\n\nConseils :\n• Vérifiez votre connexion internet\n• Utilisez des images plus petites\n• Réessayez dans quelques instants';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          userFriendlyMessage = 'Problème de connexion internet.\nVeuillez vérifier votre connexion et réessayer.';
        } else if (e.toString().contains('permission') || e.toString().contains('denied')) {
          userFriendlyMessage = 'Vous n\'avez pas les autorisations nécessaires.\nVeuillez contacter l\'administrateur.';
        } else {
          userFriendlyMessage = 'Une erreur est survenue.\nVeuillez réessayer.';
        }

        _showSnackBar(userFriendlyMessage, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicule != null;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _backgroundPastel,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le véhicule' : 'Ajouter un véhicule'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryPastel, _secondaryPastel],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final vehiculeProviderInstance = ref.watch(vehiculeProvider);

          if (_isLoading || vehiculeProviderInstance.isLoading) {
            return _buildLoadingState(vehiculeProviderInstance);
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'Informations du véhicule',
                      icon: Icons.directions_car,
                      children: [
                        _buildModernTextField(
                          controller: _immatriculationController,
                          label: 'Immatriculation',
                          hint: 'Ex: 123 TUN 9815',
                          icon: Icons.confirmation_number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer l\'immatriculation';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildAutocompleteField(
                          controller: _marqueController,
                          label: 'Marque',
                          hint: 'Ex: Renault, Peugeot, BMW...',
                          icon: Icons.branding_watermark,
                          suggestions: _marquesExemples,
                        ),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _modeleController,
                          label: 'Modèle',
                          hint: 'Ex: 208, Clio, Golf...',
                          icon: Icons.model_training,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le modèle';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Photos de la carte grise',
                      icon: Icons.photo_camera,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildPhotoCard(
                                title: 'Recto',
                                photoFile: _photoRectoFile,
                                networkUrl: widget.vehicule?.photoCarteGriseRecto,
                                onTap: () => _showImageSourceDialog(true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPhotoCard(
                                title: 'Verso',
                                photoFile: _photoVersoFile,
                                networkUrl: widget.vehicule?.photoCarteGriseVerso,
                                onTap: () => _showImageSourceDialog(false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: 'Informations d\'assurance',
                      icon: Icons.security,
                      children: [
                        _buildAutocompleteField(
                          controller: _compagnieAssuranceController,
                          label: 'Compagnie d\'assurance',
                          hint: 'Ex: STAR, GAT, COMAR...',
                          icon: Icons.business,
                          suggestions: _assurancesExemples,
                        ),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _numeroContratController,
                          label: 'Numéro de contrat',
                          hint: 'Ex: CT123456789',
                          icon: Icons.numbers,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le numéro de contrat';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _quittanceController,
                          label: 'Quittance',
                          hint: 'Ex: QP2024N000042230',
                          icon: Icons.receipt,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer la quittance';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _agenceController,
                          label: 'Agence',
                          hint: 'Ex: Tunis Centre, Sfax...',
                          icon: Icons.location_city,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer l\'agence';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: 'Début de validité',
                                date: _dateDebutValidite,
                                onTap: () => _selectDate(context, true),
                                dateFormat: dateFormat,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateField(
                                label: 'Fin de validité',
                                date: _dateFinValidite,
                                onTap: () => _selectDate(context, false),
                                dateFormat: dateFormat,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSubmitButton(isEditing),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(VehiculeProvider vehiculeProvider) {
    final progress = vehiculeProvider.uploadProgress;
    final progressPercentage = (progress * 100).toInt();

    String statusMessage;
    if (progress < 0.2) {
      statusMessage = 'Compression des images...';
    } else if (progress < 0.8) {
      statusMessage = 'Téléchargement des photos...';
    } else if (progress < 0.9) {
      statusMessage = 'Enregistrement du véhicule...';
    } else {
      statusMessage = 'Finalisation...';
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_backgroundPastel, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicateur de progression circulaire
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: _primaryPastel.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(_primaryPastel),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        size: 32,
                        color: _primaryPastel,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$progressPercentage%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryPastel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                statusMessage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Veuillez patienter, cela peut prendre quelques instants...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Conseils pour l'utilisateur
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryPastel.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryPastel.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _primaryPastel,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Conseils',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primaryPastel,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Gardez une connexion internet stable\n• Ne fermez pas l\'application\n• Le téléchargement peut prendre du temps selon la taille des images',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Bouton d'annulation si le processus prend trop de temps
              if (progress > 0.1) // Afficher seulement après avoir commencé
                ElevatedButton(
                  onPressed: () {
                    vehiculeProvider.cancelVehiculeOperation();
                    vehiculeProvider.resetForNewOperation();
                    setState(() {
                      _isLoading = false;
                      _errorMessage = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Annuler et réessayer'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardPastel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryPastel, _secondaryPastel],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _primaryPastel),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _primaryPastel, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: const TextStyle(color: Colors.black87),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> suggestions,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return suggestions.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        if (controller.text.isNotEmpty && fieldController.text != controller.text) {
          fieldController.text = controller.text;
        }
        
        fieldController.addListener(() {
          if (controller.text != fieldController.text) {
            controller.text = fieldController.text;
          }
        });
        
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: _primaryPastel),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _primaryPastel, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            labelStyle: const TextStyle(color: Colors.black87),
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer $label';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required File? photoFile,
    required String? networkUrl,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _primaryPastel.withValues(alpha: 0.3),
                width: 2,
              ),
              gradient: LinearGradient(
                colors: [
                  _primaryPastel.withValues(alpha: 0.05),
                  _secondaryPastel.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: photoFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(
                      photoFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : networkUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(
                          networkUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(color: _primaryPastel),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _primaryPastel.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              size: 32,
                              color: _primaryPastel,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ajouter une photo',
                            style: TextStyle(
                              color: _primaryPastel,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required DateFormat dateFormat,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: _primaryPastel,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? dateFormat.format(date)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null ? Colors.black87 : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryPastel, _secondaryPastel],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryPastel.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submitForm,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEditing ? Icons.update : Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isEditing ? 'Mettre à jour' : 'Ajouter le véhicule',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
