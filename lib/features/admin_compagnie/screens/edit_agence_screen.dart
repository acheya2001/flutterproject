import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ✏️ Écran de modification d'une agence
class EditAgenceScreen extends StatefulWidget {
  final Map<String, dynamic> agenceData;
  final Map<String, dynamic> userData;

  const EditAgenceScreen({
    Key? key,
    required this.agenceData,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditAgenceScreen> createState() => _EditAgenceScreenState();
}

class _EditAgenceScreenState extends State<EditAgenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedGouvernorat = 'Tunis';
  bool _isLoading = false;
  
  final List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse', 'Monastir', 
    'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès', 
    'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  /// 🔧 Initialiser les champs avec les données existantes
  void _initializeFields() {
    _nomController.text = widget.agenceData['nom'] ?? '';
    _adresseController.text = widget.agenceData['adresse'] ?? '';
    _telephoneController.text = widget.agenceData['telephone'] ?? '';
    _emailController.text = widget.agenceData['emailContact'] ?? '';
    _descriptionController.text = widget.agenceData['description'] ?? '';
    _selectedGouvernorat = widget.agenceData['gouvernorat'] ?? 'Tunis';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 🎨 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Modifier l\'Agence',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  /// 📱 Corps principal
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations actuelles
            _buildCurrentInfoCard(),
            const SizedBox(height: 24),
            
            // Formulaire de modification
            _buildEditForm(),
            const SizedBox(height: 32),
            
            // Boutons d'action
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 📋 Carte informations actuelles
  Widget _buildCurrentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.agenceData['nom'] ?? 'Nom non défini',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Code: ${widget.agenceData['code'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  widget.agenceData['adresse'] ?? 'Adresse non définie',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Formulaire de modification
  Widget _buildEditForm() {
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
          const Text(
            'Informations de l\'Agence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          // Nom de l'agence
          _buildTextField(
            controller: _nomController,
            label: 'Nom de l\'agence',
            icon: Icons.business_rounded,
            validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
          ),
          const SizedBox(height: 16),
          
          // Adresse
          _buildTextField(
            controller: _adresseController,
            label: 'Adresse',
            icon: Icons.location_on_rounded,
            validator: (value) => value?.isEmpty == true ? 'Adresse requise' : null,
          ),
          const SizedBox(height: 16),
          
          // Gouvernorat
          DropdownButtonFormField<String>(
            value: _selectedGouvernorat,
            decoration: InputDecoration(
              labelText: 'Gouvernorat',
              prefixIcon: const Icon(Icons.map_rounded, color: Color(0xFF667EEA)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _gouvernorats.map((gouvernorat) => DropdownMenuItem(
              value: gouvernorat,
              child: Text(gouvernorat),
            )).toList(),
            onChanged: (value) => setState(() => _selectedGouvernorat = value!),
            validator: (value) => value == null ? 'Gouvernorat requis' : null,
          ),
          const SizedBox(height: 16),
          
          // Téléphone et Email
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty == true ? 'Téléphone requis' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _emailController,
                  label: 'Email de contact',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Email requis';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Description
          _buildTextField(
            controller: _descriptionController,
            label: 'Description (optionnelle)',
            icon: Icons.description_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// 📝 Champ de texte personnalisé
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveChanges,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isLoading ? 'Sauvegarde...' : 'Sauvegarder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 💾 Sauvegarder les modifications
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Données mises à jour
      final updatedData = {
        'nom': _nomController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'gouvernorat': _selectedGouvernorat,
        'emailContact': _emailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': widget.userData['email'],
      };

      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('agences')
          .doc(widget.agenceData['id'])
          .update(updatedData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Agence modifiée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, {'success': true, 'message': 'Agence modifiée avec succès'});

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
}
