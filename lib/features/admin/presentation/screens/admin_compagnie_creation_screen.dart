import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/admin_compagnie_service.dart';
import '../../../../services/insurance_company_service.dart';
import '../../../../models/insurance_company.dart';
import '../../../../services/company_structure_service.dart';
import '../../../../services/company_management_service.dart';
import 'admin_credentials_display.dart';

/// 🏢 Écran de création d'Admin Compagnie - Design moderne et élégant
class AdminCompagnieCreationScreen extends StatefulWidget {
  final InsuranceCompany? preSelectedCompany;
  
  const AdminCompagnieCreationScreen({
    Key? key,
    this.preSelectedCompany,
  }) : super(key: key);

  @override
  State<AdminCompagnieCreationScreen> createState() => _AdminCompagnieCreationScreenState();
}

class _AdminCompagnieCreationScreenState extends State<AdminCompagnieCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  
  bool _isLoading = false;
  List<InsuranceCompany> _companies = [];
  List<InsuranceCompany> _filteredCompanies = [];
  InsuranceCompany? _selectedCompany;
  String? _selectedCompanyId;
  String _generatedEmail = '';

  // 🔧 Nouvelles fonctionnalités (méthode hybride automatique)
  String _searchQuery = '';
  bool _showOnlyAvailable = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCompany = widget.preSelectedCompany;
    _selectedCompanyId = widget.preSelectedCompany?.id;
    _loadCompanies();
    _prenomController.addListener(_updateGeneratedEmail);
    _nomController.addListener(_updateGeneratedEmail);
    _searchController.addListener(_filterCompanies);
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    try {
      // Nettoyer les doublons d'abord
      await CompanyManagementService.cleanDuplicates();

      // Charger toutes les compagnies avec le nouveau service centralisé
      final companiesData = await CompanyManagementService.getCompaniesForAdminSelection();

      // Convertir en objets InsuranceCompany
      final enrichedCompanies = <InsuranceCompany>[];

      for (var companyData in companiesData) {
        final enrichedCompany = InsuranceCompany.forSelection(
          id: companyData['id'],
          nom: companyData['nom'],
          code: companyData['code'],
          type: companyData['type'],
          hasAdmin: companyData['hasAdmin'],
        );

        enrichedCompanies.add(enrichedCompany);
      }

      setState(() {
        _companies = enrichedCompanies;
        _filteredCompanies = enrichedCompanies;

        // Vérifier si la compagnie pré-sélectionnée existe dans la liste
        if (_selectedCompanyId != null) {
          final foundCompany = enrichedCompanies.where((c) => c.id == _selectedCompanyId).toList();
          if (foundCompany.isNotEmpty) {
            _selectedCompany = foundCompany.first;
            _updateGeneratedEmail();
          } else {
            // Réinitialiser si la compagnie n'est pas trouvée
            _selectedCompany = null;
            _selectedCompanyId = null;
          }
        }

        // Appliquer le filtrage initial
        _filterCompanies();
      });

      debugPrint('[ADMIN_COMPAGNIE_CREATION] ✅ ${enrichedCompanies.length} compagnies chargées');
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_CREATION] ❌ Erreur chargement: $e');
      _showErrorSnackBar('Erreur lors du chargement des compagnies: $e');
    }
  }

  /// 🔍 Filtrer les compagnies selon les critères
  void _filterCompanies() {
    _searchQuery = _searchController.text;
    setState(() {
      _filteredCompanies = _companies.where((company) {
        // Filtrer par disponibilité
        if (_showOnlyAvailable && (company.hasAdmin ?? false)) {
          return false;
        }

        // Filtrer par recherche
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final nom = company.nom.toLowerCase();
          final code = company.code?.toLowerCase() ?? '';

          return nom.contains(query) || code.contains(query);
        }

        return true;
      }).toList();
    });
  }

  void _updateGeneratedEmail() {
    if (_prenomController.text.isNotEmpty && 
        _nomController.text.isNotEmpty && 
        _selectedCompany != null) {
      final prenom = _cleanString(_prenomController.text);
      final nom = _cleanString(_nomController.text);
      final compagnie = _cleanString(_selectedCompany!.nom);
      setState(() {
        _generatedEmail = '$prenom.$nom@$compagnie.com';
      });
    } else {
      setState(() {
        _generatedEmail = '';
      });
    }
  }

  String _cleanString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Créer Admin Compagnie',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
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
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: _createAdminCompagnie,
                icon: const Icon(Icons.business_center, color: Colors.white, size: 18),
                label: const Text(
                  'Créer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildFormCard(),
            const SizedBox(height: 20),
            _buildEmailPreviewCard(),
          ],
        ),
      ),
    );
  }

  /// 🎨 En-tête compact et moderne
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouvel Admin Compagnie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assignation d\'un administrateur',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'NOUVEAU',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Formulaire compact et moderne
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 Barre de recherche et filtres
              _buildSearchAndFilters(),
              const SizedBox(height: 16),

              // 🎯 Indicateur de méthode automatique
              _buildAutoMethodIndicator(),
              const SizedBox(height: 24),

              // En-tête simple
              Container(
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Informations Personnelles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Champs simples
              Row(
                children: [
                  Expanded(
                    child: _buildSimpleTextField(
                      controller: _prenomController,
                      label: 'Prénom',
                      hint: 'Mohamed',
                      icon: Icons.person_outline_rounded,
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le prénom est requis';
                        }
                        if (value.length < 2) {
                          return 'Minimum 2 caractères';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSimpleTextField(
                      controller: _nomController,
                      label: 'Nom',
                      hint: 'Ben Ali',
                      icon: Icons.badge_outlined,
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        if (value.length < 2) {
                          return 'Minimum 2 caractères';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              _buildSimpleTextField(
                controller: _telephoneController,
                label: 'Téléphone',
                hint: '+216 XX XXX XXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le téléphone est requis';
                  }
                  if (!RegExp(r'^\+?[0-9\s\-\(\)]{8,}$').hasMatch(value)) {
                    return 'Format de téléphone invalide';
                  }
                  return null;
                },
              ),

              _buildSimpleCompanyDropdown(),
            ],
          ),
        ),
      ),
    );
  }

  /// 📝 Champ de texte simple et propre
  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label *' : label,
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
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
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

  /// 🏢 Dropdown simple pour les compagnies
  Widget _buildSimpleCompanyDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compagnie d\'assurance *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCompanyId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Sélectionnez une compagnie',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.business_rounded,
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _filteredCompanies.map((company) {
              final hasAdmin = company.hasAdmin ?? false;
              return DropdownMenuItem<String>(
                value: company.id,
                enabled: !hasAdmin,
                child: Row(
                  children: [
                    Icon(
                      hasAdmin ? Icons.lock_rounded : Icons.business_rounded,
                      color: hasAdmin ? Colors.grey : const Color(0xFF059669),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        company.nom,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: hasAdmin ? Colors.grey : const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OCCUPÉ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
              onChanged: (companyId) {
                if (companyId == null) return;

                // Trouver la compagnie correspondante
                final company = _companies.firstWhere(
                  (c) => c.id == companyId,
                  orElse: () => throw Exception('Compagnie non trouvée'),
                );

                if (company.hasAdmin ?? false) {
                  // Empêcher la sélection de compagnies avec admin
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚠️ ${company.nom} a déjà un administrateur assigné',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  return; // Ne pas sélectionner
                }

                setState(() {
                  _selectedCompanyId = companyId;
                  _selectedCompany = company;
                  _updateGeneratedEmail();
                });

                // Debug: afficher les infos de la compagnie sélectionnée
                print('🏢 Compagnie sélectionnée:');
                print('  - ID: ${company.id}');
                print('  - Nom: ${company.nom}');
                print('  - Code: ${company.code}');
                print('  - Type: ${company.type}');
                print('  - Has Admin: ${company.hasAdmin}');
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner une compagnie d\'assurance';
                }
                return null;
              },
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  /// 🎨 Aperçu email ultra-moderne avec animations
  Widget _buildEmailPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: _generatedEmail.isNotEmpty
              ? [
                  const Color(0xFF059669).withOpacity(0.1),
                  const Color(0xFF047857).withOpacity(0.05),
                ]
              : [
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _generatedEmail.isNotEmpty
              ? const Color(0xFF059669).withOpacity(0.3)
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _generatedEmail.isNotEmpty
                ? const Color(0xFF059669).withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec animation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _generatedEmail.isNotEmpty
                        ? [
                            const Color(0xFF059669).withOpacity(0.2),
                            const Color(0xFF047857).withOpacity(0.1)
                          ]
                        : [Colors.grey.shade200, Colors.grey.shade100],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _generatedEmail.isNotEmpty
                        ? const Color(0xFF059669).withOpacity(0.3)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: _generatedEmail.isNotEmpty
                            ? const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF047857)],
                              )
                            : LinearGradient(
                                colors: [Colors.grey.shade400, Colors.grey.shade500],
                              ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (_generatedEmail.isNotEmpty
                                ? const Color(0xFF059669)
                                : Colors.grey.shade400).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.email_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Automatique',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _generatedEmail.isNotEmpty
                                  ? const Color(0xFF059669)
                                  : Colors.grey.shade600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Format: prénom.nom@compagnie.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: _generatedEmail.isNotEmpty
                                  ? const Color(0xFF047857)
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_generatedEmail.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'GÉNÉRÉ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_generatedEmail.isNotEmpty) ...[
                // Email généré avec style glassmorphism
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF059669).withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF047857)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.alternate_email_rounded,
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
                              'Adresse email générée',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              _generatedEmail,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                fontFamily: 'monospace',
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF059669).withOpacity(0.2),
                              const Color(0xFF047857).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedEmail));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      '📧 Email copié dans le presse-papiers',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF059669),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: Color(0xFF059669),
                            size: 24,
                          ),
                          tooltip: 'Copier l\'email',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Informations sur le mot de passe
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.3)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade700],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
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
                              'Mot de passe temporaire',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Un mot de passe sécurisé (8-12 caractères) sera généré automatiquement et affiché après la création.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade600,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Message d'attente moderne
                Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade200, Colors.grey.shade100],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Remplissez les champs ci-dessus',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'L\'email sera généré automatiquement au format\nprénom.nom@compagnie.com',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Champ de texte ultra-moderne avec glassmorphism
  Widget _buildUltraModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label moderne avec badge requis
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'REQUIS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Champ avec effet glassmorphism
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF059669).withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  width: 48,
                  height: 48,
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
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF059669),
                    width: 2.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFFDC2626),
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFFDC2626),
                    width: 2.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAdminCompagnie() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCompany == null) {
      _showErrorSnackBar('Veuillez sélectionner une compagnie d\'assurance');
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      // 🎯 Utiliser UNIQUEMENT la méthode alternative (contourne SSL)
      result = await AdminCompagnieService.createAdminCompagnieAlternative(
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        compagnieId: _selectedCompany!.id,
        compagnieNom: _selectedCompany!.nom,
      );

      if (result['success']) {
        _navigateToCredentialsDisplay(result);
      } else {
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la création: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔄 Naviguer vers l'écran d'affichage des identifiants
  void _navigateToCredentialsDisplay(Map<String, dynamic> result) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCredentialsDisplay(
          email: result['email'] ?? 'Email non disponible',
          password: result['password'] ?? 'Mot de passe non disponible',
          companyName: result['compagnieNom'] ?? _selectedCompany?.nom ?? 'Compagnie',
          adminName: result['displayName'] ?? '${_prenomController.text} ${_nomController.text}',
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }



  /// 🔍 Barre de recherche et filtres
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                '🔍 Recherche et filtres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une compagnie...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterCompanies();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filtres
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Seulement disponibles'),
                  subtitle: Text('${_filteredCompanies.where((c) => !(c.hasAdmin ?? false)).length} compagnies'),
                  value: _showOnlyAvailable,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyAvailable = value!;
                      _filterCompanies();
                    });
                  },
                  activeColor: Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📊 ${_filteredCompanies.length} résultat(s)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎯 Indicateur de méthode automatique
  Widget _buildAutoMethodIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.green, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '🎯 Création automatique optimisée - Le système choisit la meilleure méthode',
              style: TextStyle(
                fontSize: 13,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
