import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/insurance_company.dart';
import '../../../../services/insurance_company_service.dart';
import 'company_form_screen.dart';
import 'company_details_screen.dart';
import 'super_admin_company_form.dart';
import 'admin_compagnie_creation_screen.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// 🏢 Écran de gestion des compagnies d'assurance
class CompaniesManagementScreen extends StatefulWidget {
  const CompaniesManagementScreen({Key? key}) : super(key: key);

  @override
  State<CompaniesManagementScreen> createState() => _CompaniesManagementScreenState();
}

class _CompaniesManagementScreenState extends State<CompaniesManagementScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des Compagnies',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_codes') {
                _addCodesToExistingCompanies();
              } else if (value == 'add_company') {
                _showAddCompanyDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_company',
                child: Row(
                  children: [
                    Icon(Icons.add_business, size: 18, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('Ajouter une compagnie'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_codes',
                child: Row(
                  children: [
                    Icon(Icons.qr_code, size: 18, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Text('Ajouter codes aux existantes'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres et recherche
          _buildFiltersSection(),
          
          // Liste des compagnies
          Expanded(
            child: _buildCompaniesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher une compagnie...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtres de statut
          Row(
            children: [
              const Text(
                'Statut:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Toutes', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Actives', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactives', 'inactive'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _statusFilter = value),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF3B82F6).withOpacity(0.1),
      checkmarkColor: const Color(0xFF3B82F6),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCompaniesList() {
    return StreamBuilder<List<InsuranceCompany>>(
      stream: InsuranceCompanyService.getAllCompanies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Impossible de charger les compagnies',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final companies = snapshot.data ?? [];
        final filteredCompanies = _filterCompanies(companies);

        if (filteredCompanies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 64,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune compagnie trouvée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez votre première compagnie',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddCompanyDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une compagnie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredCompanies.length,
          itemBuilder: (context, index) {
            final company = filteredCompanies[index];
            return _buildCompanyCard(company);
          },
        );
      },
    );
  }

  List<InsuranceCompany> _filterCompanies(List<InsuranceCompany> companies) {
    return companies.where((company) {
      // Filtre par recherche
      final matchesSearch = _searchQuery.isEmpty ||
          company.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          company.email.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtre par statut
      final matchesStatus = _statusFilter == 'all' ||
          company.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildCompanyCard(InsuranceCompany company) {
    final isActive = company.status == 'active';

    // Couleurs dynamiques selon le type et statut
    final Color primaryColor = _getCompanyColor(company.nom);
    final Color backgroundColor = isActive
        ? primaryColor.withOpacity(0.05)
        : Colors.grey.withOpacity(0.05);
    final Color borderColor = isActive
        ? primaryColor.withOpacity(0.2)
        : Colors.grey.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCompanyDetails(company),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo/Icône amélioré
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Nom et informations
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.nom,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isActive ? const Color(0xFF1E293B) : Colors.grey.shade600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Statut avec design amélioré
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Type avec design amélioré
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: company.type == 'Takaful'
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  company.type,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menu actions moderne
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) => _handleCompanyAction(value, company),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_rounded, size: 18, color: primaryColor),
                                const SizedBox(width: 12),
                                const Text('Voir détails', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18, color: Colors.orange.shade600),
                                const SizedBox(width: 12),
                                const Text('Modifier', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: isActive ? 'deactivate' : 'activate',
                            child: Row(
                              children: [
                                Icon(
                                  isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                                  size: 18,
                                  color: isActive ? Colors.red.shade600 : Colors.green.shade600,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isActive ? 'Désactiver' : 'Activer',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 18, color: Colors.red.shade600),
                                const SizedBox(width: 12),
                                Text(
                                  'Supprimer',
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations de contact avec design amélioré
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(Icons.email_rounded, company.email, primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoItem(Icons.phone_rounded, company.telephone, primaryColor),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(Icons.location_on_rounded, company.adresse, primaryColor),
                          ),
                          if (company.code != null) ...[
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Code: ${company.code}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Admin assigné avec design amélioré
                      if (company.adminCompagnieNom != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded, color: Colors.green.shade600, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Admin: ${company.adminCompagnieNom}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 Obtenir une couleur unique pour chaque compagnie
  Color _getCompanyColor(String companyName) {
    final colors = [
      const Color(0xFF3B82F6), // Bleu
      const Color(0xFF10B981), // Vert
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFEF4444), // Rouge
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF84CC16), // Lime
      const Color(0xFFEC4899), // Rose
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
    ];

    final hash = companyName.hashCode;
    return colors[hash.abs() % colors.length];
  }

  /// 🔄 Actualiser les données
  void _refreshData() {
    setState(() {
      // Déclencher une reconstruction pour recharger les données
    });
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAddCompanyDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SuperAdminCompanyForm(),
      ),
    );

    // Si une compagnie a été ajoutée, proposer d'affecter un admin
    if (result != null && result['success'] == true) {
      _showAssignAdminDialog(result);
    }
  }

  /// 👤 Proposer d'affecter un admin après ajout de compagnie
  void _showAssignAdminDialog(Map<String, dynamic> companyResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF059669)),
            SizedBox(width: 12),
            Text('Affecter un admin ?'),
          ],
        ),
        content: Text(
          'Compagnie "${companyResult['companyName']}" créée avec succès !\n\n'
          'Voulez-vous maintenant créer et affecter un administrateur '
          'à cette compagnie ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAdminCreation(companyResult);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer Admin'),
          ),
        ],
      ),
    );
  }

  /// 🔄 Naviguer vers la création d'admin compagnie
  void _navigateToAdminCreation(Map<String, dynamic> companyResult) {
    // Créer un objet InsuranceCompany pour pré-sélection
    final preSelectedCompany = InsuranceCompany(
      id: companyResult['companyId'],
      nom: companyResult['companyName'],
      code: companyResult['companyData']['numeroAgrement'] ?? '',
      type: companyResult['companyData']['type'] ?? 'Classique',
      email: companyResult['companyData']['email'] ?? '',
      telephone: companyResult['companyData']['telephone'] ?? '',
      adresse: companyResult['companyData']['adresse'] ?? '',
      siteWeb: companyResult['companyData']['siteWeb'],
      status: companyResult['companyData']['status'] ?? 'actif',
      adminCompagnieId: null,
      adminCompagnieNom: null,
      adminCompagnieEmail: null,
      createdAt: DateTime.now(),
      hasAdmin: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCompagnieCreationScreen(
          preSelectedCompany: preSelectedCompany,
        ),
      ),
    );
  }

  void _navigateToCompanyDetails(InsuranceCompany company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailsScreen(company: company),
      ),
    );
  }

  void _handleCompanyAction(String action, InsuranceCompany company) {
    switch (action) {
      case 'view':
        _navigateToCompanyDetails(company);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyFormScreen(company: company),
          ),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleCompanyStatus(company);
        break;
      case 'delete':
        _confirmDeleteCompany(company);
        break;
    }
  }

  void _toggleCompanyStatus(InsuranceCompany company) {
    final newStatus = company.status == 'active' ? 'inactive' : 'active';
    final actionText = newStatus == 'active' ? 'activer' : 'désactiver';

    showDialog(
      context: context,
      builder: (context) => StatusChangeDialog(
        title: '${actionText.capitalize()} la compagnie',
        content: 'Êtes-vous sûr de vouloir $actionText cette compagnie ?\n\n'
            '${newStatus == 'inactive'
                ? 'Tous les utilisateurs liés seront également désactivés.'
                : 'Les utilisateurs précédemment désactivés seront réactivés.'}',
        itemName: company.nom,
        newStatus: newStatus,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await InsuranceCompanyService.toggleCompanyStatus(
              company.id,
              newStatus,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Compagnie ${actionText}e avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDeleteCompany(InsuranceCompany company) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Supprimer la compagnie',
        content: 'Êtes-vous sûr de vouloir supprimer cette compagnie ?',
        itemName: company.nom,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await InsuranceCompanyService.deleteCompany(company.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Compagnie supprimée avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// 🔢 Ajouter des codes aux compagnies existantes
  Future<void> _addCodesToExistingCompanies() async {
    try {
      // Afficher un dialog de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.qr_code, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Ajouter des codes'),
            ],
          ),
          content: const Text(
            'Cette action va ajouter automatiquement des codes uniques aux compagnies qui n\'en ont pas encore.\n\nContinuer ?',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Ajout des codes en cours...'),
            ],
          ),
        ),
      );

      // Appeler le service
      await InsuranceCompanyService.addCodesToExistingCompanies();

      // Fermer le dialog de chargement
      Navigator.pop(context);

      // Actualiser les données
      _refreshData();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Codes ajoutés avec succès !'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
