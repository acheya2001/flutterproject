import 'package:flutter/material.dart';
import '../../../services/admin_agence_service.dart';
import '../../../core/theme/form_styles.dart';

/// 🏢 Écran de gestion des informations de l'agence
class AgenceInfoScreen extends StatefulWidget {
  final Map<String, dynamic> agenceData;
  final VoidCallback onAgenceUpdated;

  const AgenceInfoScreen({
    Key? key,
    required this.agenceData,
    required this.onAgenceUpdated,
  }) : super(key: key);

  @override
  State<AgenceInfoScreen> createState() => _AgenceInfoScreenState();
}

class _AgenceInfoScreenState extends State<AgenceInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAgenceData();
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 📊 Charger les données de l'agence
  void _loadAgenceData() {
    _nomController.text = widget.agenceData['nom'] ?? '';
    _adresseController.text = widget.agenceData['adresse'] ?? '';
    _telephoneController.text = widget.agenceData['telephone'] ?? '';
    _emailController.text = widget.agenceData['email'] ?? '';
    _descriptionController.text = widget.agenceData['description'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading ? _buildLoadingContent() : _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations de l\'Agence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.agenceData['nom'] ?? 'Mon Agence',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!_isEditing) ...[
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Modifier',
            ),
          ],
        ],
      ),
    );
  }

  /// 🔄 Contenu de chargement
  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF10B981)),
          SizedBox(height: 20),
          Text(
            'Mise à jour en cours...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de la compagnie (lecture seule)
            _buildCompanyInfoCard(),
            const SizedBox(height: 24),
            
            // Informations de l'agence (modifiables)
            _buildAgenceInfoCard(),
            
            if (_isEditing) ...[
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  /// 🏢 Carte informations compagnie (lecture seule)
  Widget _buildCompanyInfoCard() {
    final compagnieInfo = widget.agenceData['compagnieInfo'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.domain_rounded,
                color: Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Compagnie Mère',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField('Nom', compagnieInfo?['nom'] ?? 'Non défini'),
          _buildReadOnlyField('Code', compagnieInfo?['code'] ?? 'Non défini'),
          _buildReadOnlyField('Type', compagnieInfo?['type'] ?? 'Non défini'),
        ],
      ),
    );
  }

  /// 🏪 Carte informations agence (modifiables)
  Widget _buildAgenceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Informations de l\'Agence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Champs modifiables
          _buildTextField(
            controller: _nomController,
            label: 'Nom de l\'agence',
            icon: Icons.business_rounded,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom de l\'agence est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _adresseController,
            label: 'Adresse',
            icon: Icons.location_on_rounded,
            enabled: _isEditing,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'adresse est requise';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            icon: Icons.phone_rounded,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le téléphone est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email (optionnel)',
            icon: Icons.email_rounded,
            enabled: _isEditing,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _descriptionController,
            label: 'Description (optionnel)',
            icon: Icons.description_rounded,
            enabled: _isEditing,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// 📝 Champ de texte avec style amélioré
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return FormStyles.buildTextFormField(
      labelText: label,
      controller: controller,
      prefixIcon: icon,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      isRequired: false,
    );
  }

  /// 📖 Champ lecture seule avec style amélioré
  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000), // Noir pur pour maximum de lisibilité
              letterSpacing: 0.3,
              height: 1.4,
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
            onPressed: _cancelEditing,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// ❌ Annuler les modifications
  void _cancelEditing() {
    if (mounted) setState(() {
      _isEditing = false;
      _loadAgenceData(); // Recharger les données originales
    });
  }

  /// 💾 Sauvegarder les modifications
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AdminAgenceService.updateAgenceInfo(
        agenceId: widget.agenceData['id'],
        nom: _nomController.text.trim(),
        adresse: _adresseController.text.trim(),
        telephone: _telephoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() => _isEditing = false);
        widget.onAgenceUpdated(); // Notifier le parent pour recharger les données
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

