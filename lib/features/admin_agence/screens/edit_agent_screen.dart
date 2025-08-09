import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/form_styles.dart';

/// ✏️ Écran de modification d'un agent
class EditAgentScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;

  const EditAgentScreen({
    Key? key,
    required this.agentData,
  }) : super(key: key);

  @override
  State<EditAgentScreen> createState() => _EditAgentScreenState();
}

class _EditAgentScreenState extends State<EditAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _cinController = TextEditingController();
  final _adresseController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  /// 📋 Charger les données de l'agent
  void _loadAgentData() {
    _prenomController.text = widget.agentData['prenom'] ?? '';
    _nomController.text = widget.agentData['nom'] ?? '';
    _telephoneController.text = widget.agentData['telephone'] ?? '';
    _cinController.text = widget.agentData['cin'] ?? '';
    _adresseController.text = widget.agentData['adresse'] ?? '';
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _cinController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Modifier Agent'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
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
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Modification en cours...'),
        ],
      ),
    );
  }

  /// 📝 Formulaire de modification
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations de l'agent
            _buildAgentHeader(),
            const SizedBox(height: 30),
            
            // Formulaire de modification
            FormStyles.buildFormSection(
              title: 'Informations Personnelles',
              icon: Icons.person_rounded,
              children: [
                FormStyles.buildTextFormField(
                  labelText: 'Prénom',
                  controller: _prenomController,
                  prefixIcon: Icons.person_outline,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prénom est requis';
                    }
                    return null;
                  },
                ),
                FormStyles.fieldSpacing,
                
                FormStyles.buildTextFormField(
                  labelText: 'Nom',
                  controller: _nomController,
                  prefixIcon: Icons.person_outline,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                FormStyles.fieldSpacing,
                
                FormStyles.buildTextFormField(
                  labelText: 'Téléphone',
                  controller: _telephoneController,
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
                  labelText: 'CIN',
                  controller: _cinController,
                  prefixIcon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                ),
                FormStyles.fieldSpacing,
                
                FormStyles.buildTextFormField(
                  labelText: 'Adresse',
                  controller: _adresseController,
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

  /// 👤 En-tête avec informations de l'agent
  Widget _buildAgentHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.agentData['prenom']} ${widget.agentData['nom']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.agentData['email'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.agentData['agenceNom'] ?? 'Agence',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
            onPressed: _saveChanges,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Enregistrer'),
            style: FormStyles.getPrimaryButtonStyle(),
          ),
        ),
      ],
    );
  }

  /// 💾 Enregistrer les modifications
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Préparer les données mises à jour
      final updatedData = {
        'prenom': _prenomController.text.trim(),
        'nom': _nomController.text.trim(),
        'displayName': '${_prenomController.text.trim()} ${_nomController.text.trim()}',
        'telephone': _telephoneController.text.trim(),
        'cin': _cinController.text.trim().isEmpty ? null : _cinController.text.trim(),
        'adresse': _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.agentData['uid'])
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Agent modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer une modification
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la modification: $e'),
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
