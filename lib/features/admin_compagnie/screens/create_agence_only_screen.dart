import 'package:flutter/material.dart';
import '../../../services/admin_compagnie_agence_service.dart';

/// 🏢 Écran de création d'agence UNIQUEMENT (sans admin)
class CreateAgenceOnlyScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CreateAgenceOnlyScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<CreateAgenceOnlyScreen> createState() => _CreateAgenceOnlyScreenState();
}

class _CreateAgenceOnlyScreenState extends State<CreateAgenceOnlyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs pour les informations de l'agence UNIQUEMENT
  final _nomAgenceController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _telephoneFixeController = TextEditingController();
  final _telephoneMobileController = TextEditingController();
  final _emailContactController = TextEditingController();

  String _selectedGouvernorat = 'Tunis';

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
              // En-tête
              _buildSectionHeader(),
              const SizedBox(height: 24),

              // Nom de l'agence
              _buildTextField(
                controller: _nomAgenceController,
                label: 'Nom de l\'agence',
                hint: 'Ex: Agence Ariana Nord',
                icon: Icons.business_rounded,
                isRequired: true,
              ),
              const SizedBox(height: 16),

              // Adresse complète
              _buildTextField(
                controller: _adresseController,
                label: 'Adresse complète',
                hint: 'Ex: Rue de l\'indépendance, Ariana 2080',
                icon: Icons.location_on_rounded,
                isRequired: true,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Gouvernorat et Ville
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

              // Téléphones
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

              // Email de contact
              _buildTextField(
                controller: _emailContactController,
                label: 'Email de contact',
                hint: 'Ex: ariana.nord@compagnie-assurance.tn',
                icon: Icons.email_rounded,
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // Note informative
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Après création de l\'agence, vous pourrez lui affecter un admin agence depuis l\'onglet "Admins Agences".',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouvelle Agence',
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

    setState(() => _isLoading = true);

    try {
      // Créer UNIQUEMENT l'agence (sans admin)
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

      if (!mounted) return;

      // Retourner le résultat
      Navigator.pop(context, {
        'success': true,
        'agence': agenceResult,
        'message': 'Agence créée avec succès ! Vous pouvez maintenant lui affecter un admin depuis l\'onglet "Admins Agences".',
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
