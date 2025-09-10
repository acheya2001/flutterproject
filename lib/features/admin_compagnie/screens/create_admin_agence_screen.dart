import 'package:flutter/material.dart';
import '../../../services/admin_compagnie_agence_service.dart';
import 'admin_agence_credentials_display.dart';

/// 👨‍💼 Écran de création d'admin agence avec affectation d'agence
class CreateAdminAgenceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CreateAdminAgenceScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<CreateAdminAgenceScreen> createState() => _CreateAdminAgenceScreenState();
}

class _CreateAdminAgenceScreenState extends State<CreateAdminAgenceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingAgences = true;

  // Contrôleurs pour l'admin agence
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _cinController = TextEditingController();

  // Liste des agences non affectées
  List<Map<String, dynamic>> _agencesNonAffectees = [];
  String? _selectedAgenceId;

  @override
  void initState() {
    super.initState();
    
    // Utiliser WidgetsBinding pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgencesNonAffectees();

      // Listeners pour mettre à jour l'aperçu email
      _prenomController.addListener(() => setState(() {}));
      _nomController.addListener(() => setState(() {}));
    });
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _cinController.dispose();
    super.dispose();
  }

  /// 📋 Charger les agences non affectées
  Future<void> _loadAgencesNonAffectees() async {
    try {
      final compagnieId = widget.userData['compagnieId'];
      final allAgences = await AdminCompagnieAgenceService.getAgencesWithAdminStatus(compagnieId);

      // Filtrer les agences sans admin
      _agencesNonAffectees = allAgences.where((agence) => agence['hasAdminAgence'] != true).toList();

      setState(() => _isLoadingAgences = false);
    } catch (e) {
      setState(() => _isLoadingAgences = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des agences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer un Admin Agence',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoadingAgences
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    _buildSectionHeader(),
                    const SizedBox(height: 24),

                    // Vérification des agences disponibles
                    if (_agencesNonAffectees.isEmpty) ...[
                      _buildNoAgencesAvailable(),
                    ] else ...[
                      // Sélection d'agence
                      _buildAgenceSelection(),
                      const SizedBox(height: 24),

                      // Informations de l'admin
                      _buildAdminForm(),
                      const SizedBox(height: 24),

                      // Note informative
                      _buildInfoNote(),
                      const SizedBox(height: 32),

                      // Bouton de création
                      _buildCreateButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader() {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouvel Admin Agence',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compagnie: ${widget.userData['compagnieNom']}',
                  style: const TextStyle(
                    fontSize: 14,
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

  Widget _buildNoAgencesAvailable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_rounded, color: Colors.orange.shade700, size: 48),
          const SizedBox(height: 16),
          Text(
            'Aucune agence disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toutes vos agences ont déjà un admin affecté, ou vous n\'avez pas encore créé d\'agences.',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgenceSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Sélectionner une agence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedAgenceId,
            decoration: InputDecoration(
              labelText: 'Agence à affecter *',
              prefixIcon: const Icon(Icons.business_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF059669)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _agencesNonAffectees.map((agence) {
              return DropdownMenuItem<String>(
                value: agence['id'],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agence['nom'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${agence['gouvernorat']} - ${agence['adresse']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              _selectedAgenceId = value;
              // Mettre à jour l'aperçu email
            }),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner une agence';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text(
            '${_agencesNonAffectees.length} agence(s) sans admin disponible(s)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Informations de l\'admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Prénom et Nom
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _prenomController,
                  label: 'Prénom',
                  hint: 'Ex: Sami',
                  icon: Icons.person_outline_rounded,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _nomController,
                  label: 'Nom',
                  hint: 'Ex: Ben Youssef',
                  icon: Icons.person_rounded,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email (lecture seule - généré automatiquement)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_rounded, color: Color(0xFF059669)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email professionnel',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _generateEmailPreview(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.auto_awesome_rounded, color: Colors.amber.shade600),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Téléphone et CIN
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _telephoneController,
                  label: 'Téléphone mobile',
                  hint: 'Ex: 98 123 456',
                  icon: Icons.smartphone_rounded,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _cinController,
                  label: 'Numéro CIN',
                  hint: 'Optionnel',
                  icon: Icons.credit_card_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Un mot de passe sera généré automatiquement et affiché après la création. L\'admin sera automatiquement lié à l\'agence sélectionnée.',
              style: TextStyle(
                color: Colors.amber.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _createAdminAgence,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_rounded),
        label: Text(_isLoading ? 'Création en cours...' : 'Créer l\'Admin Agence'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est obligatoire';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _createAdminAgence() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Vérifier que tous les champs requis sont présents
      final compagnieId = widget.userData['compagnieId'];
      final compagnieNom = widget.userData['compagnieNom'];
      final createdByEmail = widget.userData['email'];

      if (compagnieId == null || compagnieNom == null || createdByEmail == null) {
        throw Exception('Données utilisateur incomplètes. Veuillez vous reconnecter.');
      }

      if (_selectedAgenceId == null) {
        throw Exception('Veuillez sélectionner une agence.');
      }

      // Trouver l'agence sélectionnée
      final selectedAgence = _agencesNonAffectees.firstWhere(
        (agence) => agence['id'] == _selectedAgenceId,
        orElse: () => throw Exception('Agence sélectionnée non trouvée.'),
      );

      final agenceNom = selectedAgence['nom'];
      if (agenceNom == null) {
        throw Exception('Nom de l\'agence non défini.');
      }

      // Créer l'admin agence avec email généré automatiquement
      final result = await AdminCompagnieAgenceService.createAdminAgence(
        agenceId: _selectedAgenceId!,
        agenceNom: agenceNom,
        compagnieId: compagnieId,
        compagnieNom: compagnieNom,
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        email: _generateEmailPreview(), // Email généré automatiquement
        createdByEmail: createdByEmail,
      );

      if (!mounted) return;

      if (result['success']) {
        // Naviguer vers l'écran d'affichage des identifiants
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminAgenceCredentialsDisplay(
              email: result['email'] ?? 'Email non défini',
              password: result['password'] ?? 'Mot de passe non défini',
              agenceName: agenceNom,
              adminName: result['displayName'] ?? 'Admin non défini',
              companyName: compagnieNom,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la création'),
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

  /// 📧 Générer un aperçu de l'email automatique
  String _generateEmailPreview() {
    if (_prenomController.text.isEmpty || _nomController.text.isEmpty || _selectedAgenceId == null) {
      return 'Email généré automatiquement...';
    }

    // Vérifier que les données de la compagnie sont disponibles
    final compagnieNom = widget.userData['compagnieNom'];
    if (compagnieNom == null) {
      return 'Email généré automatiquement...';
    }

    final selectedAgence = _agencesNonAffectees.firstWhere(
      (agence) => agence['id'] == _selectedAgenceId,
      orElse: () => {'nom': 'agence'},
    );

    final agenceNomValue = selectedAgence['nom'];
    if (agenceNomValue == null) {
      return 'Email généré automatiquement...';
    }

    final prenom = _prenomController.text.toLowerCase().replaceAll(' ', '');
    final nom = _nomController.text.toLowerCase().replaceAll(' ', '');
    final agenceNom = agenceNomValue.toString().toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('agence', '')
        .trim();

    final compagnieNomClean = compagnieNom.toString().toLowerCase().replaceAll(' ', '');

    return '$prenom.$nom.$agenceNom@$compagnieNomClean.tn';
  }
}
