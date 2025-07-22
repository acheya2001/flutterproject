import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/company_management_service.dart';

/// 🏢 Formulaire Super Admin pour création de compagnie d'assurance
class SuperAdminCompanyForm extends StatefulWidget {
  const SuperAdminCompanyForm({Key? key}) : super(key: key);

  @override
  State<SuperAdminCompanyForm> createState() => _SuperAdminCompanyFormState();
}

class _SuperAdminCompanyFormState extends State<SuperAdminCompanyForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour tous les champs
  final _nomController = TextEditingController();
  final _numeroAgrementController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _siteWebController = TextEditingController();
  
  // Variables d'état
  String _selectedGouvernorat = 'Tunis';
  bool _isActive = true;
  bool _isLoading = false;

  // Liste des gouvernorats tunisiens
  final List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse',
    'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _numeroAgrementController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _siteWebController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer une Compagnie',
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
              _buildHeaderCard(),
              const SizedBox(height: 24),
              _buildFormCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 En-tête avec informations
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle Compagnie d\'Assurance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Remplissez tous les champs obligatoires',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Formulaire principal
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom de la compagnie
            _buildTextField(
              controller: _nomController,
              label: 'Nom de la compagnie *',
              hint: 'Ex: STAR Assurances',
              icon: Icons.business_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le nom de la compagnie est requis';
                }
                if (value.length < 3) {
                  return 'Minimum 3 caractères';
                }
                return null;
              },
            ),
            
            // Numéro d'agrément
            _buildTextField(
              controller: _numeroAgrementController,
              label: 'Numéro d\'agrément *',
              hint: 'Ex: AGR-2024-001',
              icon: Icons.verified_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le numéro d\'agrément est requis';
                }
                return null;
              },
            ),
            
            // Adresse complète
            _buildTextField(
              controller: _adresseController,
              label: 'Adresse complète *',
              hint: 'Ex: Avenue Habib Bourguiba, Tunis',
              icon: Icons.location_on_rounded,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'L\'adresse est requise';
                }
                return null;
              },
            ),
            
            // Gouvernorat
            _buildDropdownField(),
            
            // Téléphone et Email en ligne
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _telephoneController,
                    label: 'Téléphone *',
                    hint: '+216 XX XXX XXX',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le téléphone est requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email professionnel *',
                    hint: 'contact@compagnie.tn',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'email est requis';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            // Site web (facultatif)
            _buildTextField(
              controller: _siteWebController,
              label: 'Site web (facultatif)',
              hint: 'https://www.compagnie.tn',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
            ),
            
            // Statut actif/inactif
            _buildStatusToggle(),
          ],
        ),
      ),
    );
  }

  /// 📝 Champ de texte réutilisable
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E293B), // Couleur plus foncée pour meilleure lisibilité
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF059669), size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌍 Dropdown pour les gouvernorats
  Widget _buildDropdownField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gouvernorat *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedGouvernorat,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.location_city_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _gouvernorats.map((gouvernorat) {
              return DropdownMenuItem<String>(
                value: gouvernorat,
                child: Text(
                  gouvernorat,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B), // Couleur plus foncée
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGouvernorat = value!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le gouvernorat est requis';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// 🔄 Toggle pour le statut actif/inactif
  Widget _buildStatusToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF059669).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.toggle_on_rounded,
            color: Color(0xFF059669),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut de la compagnie',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Activez pour permettre les opérations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeColor: const Color(0xFF059669),
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
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF059669)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createCompany,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Créer la Compagnie',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// 💾 Créer la compagnie
  Future<void> _createCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer la compagnie avec tous les champs
      final companyData = {
        'nom': _nomController.text.trim(),
        'code': _numeroAgrementController.text.trim(), // Utiliser 'code' au lieu de 'numeroAgrement'
        'numeroAgrement': _numeroAgrementController.text.trim(), // Garder aussi pour compatibilité
        'adresse': _adresseController.text.trim(),
        'gouvernorat': _selectedGouvernorat,
        'telephone': _telephoneController.text.trim(),
        'email': _emailController.text.trim(),
        'siteWeb': _siteWebController.text.trim().isEmpty
            ? null
            : _siteWebController.text.trim(),
        'status': _isActive ? 'active' : 'inactive',
        'type': 'Classique', // Par défaut
        'adminCompagnieId': null,
        'adminCompagnieNom': null,
        'adminCompagnieEmail': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': 'super_admin',
      };

      // Ajouter à Firestore dans la collection unifiée
      final docRef = await FirebaseFirestore.instance
          .collection('compagnies')
          .add(companyData);

      if (mounted) {
        // Afficher le succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Compagnie "${_nomController.text}" créée avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Retourner avec les données de la compagnie créée
        Navigator.pop(context, {
          'success': true,
          'companyId': docRef.id,
          'companyName': _nomController.text.trim(),
          'companyData': companyData,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
