import 'package:flutter/material.dart';
import '../../../services/admin_compagnie_agence_service.dart';

/// 🏢 Écran moderne de création d'agence
class CreateAgenceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CreateAgenceScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<CreateAgenceScreen> createState() => _CreateAgenceScreenState();
}

class _CreateAgenceScreenState extends State<CreateAgenceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs pour les informations de l'agence
  final _nomAgenceController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _telephoneFixeController = TextEditingController();
  final _telephoneMobileController = TextEditingController();
  final _emailContactController = TextEditingController();

  // Contrôleurs pour l'admin agence
  final _nomAdminController = TextEditingController();
  final _prenomAdminController = TextEditingController();
  final _emailAdminController = TextEditingController();
  final _cinAdminController = TextEditingController();
  final _telephoneAdminController = TextEditingController();

  String _selectedGouvernorat = 'Tunis';
  bool _createAdminAgence = true;

  final List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 'Bizerte',
    'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse', 'Monastir', 'Mahdia',
    'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès', 'Médenine',
    'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];

  @override
  void dispose() {
    _nomAgenceController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _telephoneFixeController.dispose();
    _telephoneMobileController.dispose();
    _emailContactController.dispose();
    _nomAdminController.dispose();
    _prenomAdminController.dispose();
    _emailAdminController.dispose();
    _cinAdminController.dispose();
    _telephoneAdminController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer une Agence',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête agence
              _buildSectionHeader(
                'Informations de l\'Agence',
                'Renseignez les coordonnées complètes',
                Icons.business_rounded,
              ),
              const SizedBox(height: 24),

              // Formulaire agence
              _buildTextField(
                controller: _nomAgenceController,
                label: 'Nom de l\'agence',
                hint: 'Ex: Agence Ariana Nord',
                icon: Icons.business_rounded,
                isRequired: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _adresseController,
                label: 'Adresse complète',
                hint: 'Ex: Rue de l\'indépendance, Ariana 2080',
                icon: Icons.location_on_rounded,
                isRequired: true,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildDropdownField(
                      value: _selectedGouvernorat,
                      label: 'Gouvernorat',
                      icon: Icons.map_rounded,
                      items: _gouvernorats,
                      onChanged: (value) => setState(() => _selectedGouvernorat = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _villeController,
                      label: 'Ville/Délégation',
                      hint: 'Optionnel',
                      icon: Icons.location_city_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _telephoneFixeController,
                      label: 'Téléphone fixe',
                      hint: 'Ex: 71 123 456',
                      icon: Icons.phone_rounded,
                      isRequired: true,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _telephoneMobileController,
                      label: 'Téléphone mobile',
                      hint: 'Optionnel',
                      icon: Icons.smartphone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailContactController,
                label: 'Email de contact',
                hint: 'Ex: ariana.nord@compagnie-assurance.tn',
                icon: Icons.email_rounded,
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),

              // En-tête admin
              _buildSectionHeader(
                'Admin de l\'Agence',
                'Créez le compte administrateur (optionnel)',
                Icons.person_rounded,
              ),
              const SizedBox(height: 16),

              // Checkbox pour créer admin
              CheckboxListTile(
                value: _createAdminAgence,
                onChanged: (value) => setState(() => _createAdminAgence = value!),
                title: const Text('Créer un admin agence'),
                subtitle: const Text('Un compte administrateur sera créé pour gérer cette agence'),
                activeColor: const Color(0xFF059669),
              ),
              const SizedBox(height: 16),

              if (_createAdminAgence) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _prenomAdminController,
                        label: 'Prénom',
                        hint: 'Ex: Sami',
                        icon: Icons.person_outline_rounded,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _nomAdminController,
                        label: 'Nom',
                        hint: 'Ex: Ben Youssef',
                        icon: Icons.person_rounded,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailAdminController,
                  label: 'Email professionnel',
                  hint: 'Laissez vide pour génération automatique',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cinAdminController,
                        label: 'Numéro CIN',
                        hint: 'Optionnel',
                        icon: Icons.credit_card_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _telephoneAdminController,
                        label: 'Téléphone mobile',
                        hint: 'Ex: 98 123 456',
                        icon: Icons.smartphone_rounded,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
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
                          'Le mot de passe sera généré automatiquement et affiché après la création.',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createAgence,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isLoading ? 'Création en cours...' : 'Créer l\'Agence'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
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
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
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
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _createAgence() async {
    if (!_formKey.currentState!.validate()) return;

    if (_createAdminAgence) {
      if (_prenomAdminController.text.isEmpty ||
          _nomAdminController.text.isEmpty ||
          _telephoneAdminController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires de l\'admin'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Créer l'agence
      final agenceResult = await AdminCompagnieAgenceService.createAgence(
        compagnieId: widget.userData['compagnieId'],
        compagnieNom: widget.userData['compagnieNom'],
        nom: _nomAgenceController.text,
        adresse: _adresseController.text,
        telephone: _telephoneFixeController.text,
        gouvernorat: _selectedGouvernorat,
        emailContact: _emailContactController.text,
        createdByEmail: widget.userData['email'],
      );

      if (!agenceResult['success']) {
        throw Exception(agenceResult['message']);
      }

      Map<String, dynamic>? adminResult;

      // Créer l'admin agence si demandé
      if (_createAdminAgence) {
        adminResult = await AdminCompagnieAgenceService.createAdminAgence(
          agenceId: agenceResult['agenceId'],
          agenceNom: _nomAgenceController.text,
          compagnieId: widget.userData['compagnieId'],
          compagnieNom: widget.userData['compagnieNom'],
          prenom: _prenomAdminController.text,
          nom: _nomAdminController.text,
          telephone: _telephoneAdminController.text,
          email: _emailAdminController.text.isEmpty ? null : _emailAdminController.text,
          createdByEmail: widget.userData['email'],
        );

        if (!adminResult['success']) {
          throw Exception(adminResult['message']);
        }
      }

      if (!mounted) return;

      // Retourner les résultats
      Navigator.pop(context, {
        'success': true,
        'agence': agenceResult,
        'admin': adminResult,
      });

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