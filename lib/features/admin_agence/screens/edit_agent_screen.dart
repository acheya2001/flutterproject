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
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _cinController = TextEditingController();
  final _adresseController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAgentData();
    });
  }

  /// 📋 Charger les données de l'agent
  void _loadAgentData() {
    _prenomController.text = widget.agentData['prenom'] ?? '';
    _nomController.text = widget.agentData['nom'] ?? '';
    _emailController.text = widget.agentData['email'] ?? '';
    _telephoneController.text = widget.agentData['telephone'] ?? '';
    _cinController.text = widget.agentData['cin'] ?? '';
    _adresseController.text = widget.agentData['adresse'] ?? '';
    _isActive = widget.agentData['isActive'] ?? true;
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
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
                  labelText: 'Email',
                  controller: _emailController,
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'email est requis';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Format d\'email invalide';
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

            // Section statut
            FormStyles.buildFormSection(
              title: 'Statut de l\'Agent',
              icon: Icons.toggle_on_rounded,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isActive ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _isActive ? Colors.green.shade600 : Colors.red.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isActive ? 'Agent Actif' : 'Agent Inactif',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isActive ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isActive
                                  ? 'L\'agent peut se connecter et créer des constats'
                                  : 'L\'agent ne peut pas se connecter',
                              style: TextStyle(
                                fontSize: 14,
                                color: _isActive ? Colors.green.shade600 : Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          if (mounted) setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: Colors.green.shade600,
                      ),
                    ],
                  ),
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
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'cin': _cinController.text.trim().isEmpty ? null : _cinController.text.trim(),
        'adresse': _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        'isActive': _isActive,
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

