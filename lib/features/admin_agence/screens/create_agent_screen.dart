import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/admin_agence_service.dart';
import '../../../services/agent_email_service.dart';
import '../../../core/theme/form_styles.dart';
import 'agent_credentials_display.dart';

/// ➕ Écran de création d'agent
class CreateAgentScreen extends StatefulWidget {
  final Map<String, dynamic> agenceData;

  const CreateAgentScreen({
    Key? key,
    required this.agenceData,
  }) : super(key: key);

  @override
  State<CreateAgentScreen> createState() => _CreateAgentScreenState();
}

class _CreateAgentScreenState extends State<CreateAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _cinController = TextEditingController();
  final _adresseController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Plus besoin de génération automatique d'email
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer un Agent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ajouter un nouvel agent à votre agence',
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

  /// 🔄 Contenu de chargement
  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF10B981)),
          SizedBox(height: 20),
          Text(
            'Création de l\'agent en cours...',
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
            // Informations de l'agence
            _buildAgenceInfoCard(),
            const SizedBox(height: 24),
            
            // Formulaire de création d'agent
            _buildAgentForm(),
            const SizedBox(height: 30),
            
            // Boutons d'action
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 🏢 Carte informations agence
  Widget _buildAgenceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Agence de destination',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.agenceData['nom'] ?? 'Nom non défini',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.agenceData['adresse'] ?? 'Adresse non définie',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Formulaire de création d'agent
  Widget _buildAgentForm() {
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
          const Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informations de l\'Agent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Prénom et Nom
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _prenomController,
                  label: 'Prénom',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prénom est requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Email professionnel (obligatoire et réel)
          _buildRealEmailField(),
          const SizedBox(height: 16),
          
          // Téléphone
          _buildTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le téléphone est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // CIN (optionnel)
          _buildTextField(
            controller: _cinController,
            label: 'CIN (optionnel)',
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 16),
          
          // Adresse (optionnel)
          _buildTextField(
            controller: _adresseController,
            label: 'Adresse (optionnel)',
            icon: Icons.location_on_rounded,
            maxLines: 2,
          ),
          
          const SizedBox(height: 20),

          // Note sur la génération automatique du mot de passe
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Un mot de passe sécurisé sera généré automatiquement et envoyé par email à l\'agent.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📧 Champ email professionnel réel (obligatoire)
  Widget _buildRealEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email professionnel *',
          style: FormStyles.getLabelStyle(),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'agent@exemple.com',
            prefixIcon: const Icon(Icons.email_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            helperText: 'Email réel requis pour recevoir les identifiants',
            helperStyle: TextStyle(color: Colors.grey.shade600),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'email est obligatoire';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
              return 'Format d\'email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'L\'agent recevra automatiquement un email avec ses identifiants de connexion',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📝 Champ de texte
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
      isRequired: true,
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
            onPressed: _createAgent,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Créer l\'Agent'),
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

  /// ➕ Créer l'agent avec envoi d'email automatique
  Future<void> _createAgent() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier que l'email est réel (pas généré automatiquement)
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez saisir un email réel et valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Utiliser le service principal corrigé
      final result = await AgentEmailService.createAgentWithEmail(
        email: email,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        agenceId: widget.agenceData['id'],
        compagnieId: widget.agenceData['compagnieId'],
        adminAgenceId: widget.agenceData['adminId'] ?? '',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Succès - Naviguer vers l'écran de résultat élégant
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AgentCredentialsDisplay(
              email: email,
              password: result['password'] ?? '',
              codeAgent: result['agentId'] ?? '',
              agentName: '${_prenomController.text} ${_nomController.text}',
              agenceName: widget.agenceData['nom'] ?? 'Agence',
              companyName: widget.agenceData['compagnieNom'] ?? 'Compagnie',
            ),
          ),
        );

        _cinController.clear();
        _adresseController.clear();
      } else {
        // Erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message'] ?? 'Erreur inconnue'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
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
