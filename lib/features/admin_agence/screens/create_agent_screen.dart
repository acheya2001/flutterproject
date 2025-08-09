import 'package:flutter/material.dart';
import '../../../services/admin_agence_service.dart';
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
  String _generatedEmail = '';
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    // Écouter les changements de prénom et nom pour générer l'email
    _prenomController.addListener(_generateEmailAndPassword);
    _nomController.addListener(_generateEmailAndPassword);
  }

  /// 🔄 Générer automatiquement email et mot de passe
  void _generateEmailAndPassword() {
    final prenom = _prenomController.text.trim();
    final nom = _nomController.text.trim();

    if (prenom.isNotEmpty && nom.isNotEmpty) {
      // Générer email : prenom.nom.agence@compagnie.tn
      final agenceNom = widget.agenceData['nom']?.toString().replaceAll(' ', '').toLowerCase() ?? 'agence';
      final compagnieNom = widget.agenceData['compagnieNom']?.toString().replaceAll(' ', '').toLowerCase() ?? 'assurance';

      _generatedEmail = '${prenom.toLowerCase()}.${nom.toLowerCase()}.$agenceNom@$compagnieNom.tn';

      // Générer mot de passe aléatoire de 8 caractères
      _generatedPassword = _generateRandomPassword();

      // Mettre à jour le champ email
      _emailController.text = _generatedEmail;

      setState(() {});

      debugPrint('[CREATE_AGENT] 📧 Email généré: $_generatedEmail');
      debugPrint('[CREATE_AGENT] 🔑 Mot de passe généré: $_generatedPassword');
    }
  }

  /// 🔑 Générer un mot de passe aléatoire
  String _generateRandomPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(random % chars.length)));
  }

  @override
  void dispose() {
    _prenomController.removeListener(_generateEmailAndPassword);
    _nomController.removeListener(_generateEmailAndPassword);
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
          
          // Email généré automatiquement
          _buildGeneratedEmailField(),
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
          
          // Mot de passe généré automatiquement
          _buildGeneratedPasswordField(),
        ],
      ),
    );
  }

  /// 📧 Champ email généré automatiquement
  Widget _buildGeneratedEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email (généré automatiquement)',
          style: FormStyles.getLabelStyle(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.email_rounded, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _generatedEmail.isEmpty ? 'Saisissez le prénom et nom pour générer l\'email' : _generatedEmail,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _generatedEmail.isEmpty ? Colors.grey.shade600 : Colors.green.shade800,
                  ),
                ),
              ),
              if (_generatedEmail.isNotEmpty)
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔑 Champ mot de passe généré automatiquement
  Widget _buildGeneratedPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe (généré automatiquement)',
          style: FormStyles.getLabelStyle(),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _generatedPassword.isEmpty ? 'Sera généré automatiquement' : _generatedPassword,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _generatedPassword.isEmpty ? Colors.grey.shade600 : Colors.orange.shade800,
                    fontFamily: 'monospace', // Police monospace pour le mot de passe
                  ),
                ),
              ),
              if (_generatedPassword.isNotEmpty)
                Icon(Icons.visibility_off, color: Colors.orange.shade600, size: 20),
            ],
          ),
        ),
        if (_generatedPassword.isNotEmpty) ...[
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
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ce mot de passe sera envoyé à l\'agent par email',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  /// ➕ Créer l'agent
  Future<void> _createAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AdminAgenceService.createAgent(
        agenceId: widget.agenceData['id'],
        agenceNom: widget.agenceData['nom'],
        compagnieId: widget.agenceData['compagnieId'],
        compagnieNom: widget.agenceData['compagnieNom'],
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim(),
        cin: _cinController.text.trim().isEmpty ? null : _cinController.text.trim(),
        adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        // Naviguer vers l'écran d'affichage des identifiants
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AgentCredentialsDisplay(
              email: result['email'],
              password: result['password'],
              codeAgent: result['codeAgent'] ?? 'AG${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              agentName: result['displayName'],
              agenceName: widget.agenceData['nom'],
              companyName: widget.agenceData['compagnieInfo']?['nom'] ?? 'Compagnie',
            ),
          ),
        );
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
