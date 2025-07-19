import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/insurance_company.dart';
import '../../../../services/insurance_company_service.dart';
import 'company_form_screen.dart';
import 'company_details_screen.dart';
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
          IconButton(
            onPressed: () => _showAddCompanyDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une compagnie',
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCompanyDetails(company),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo/Icône
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? const Color(0xFF3B82F6).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      color: isActive ? const Color(0xFF3B82F6) : Colors.grey,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Nom et statut
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.nom,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: company.type == 'Takaful'
                                    ? const Color(0xFF7C3AED).withOpacity(0.1)
                                    : const Color(0xFF059669).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                company.type,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: company.type == 'Takaful'
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Menu actions
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleCompanyAction(value, company),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18),
                            SizedBox(width: 8),
                            Text('Voir détails'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.block : Icons.check_circle,
                              size: 18,
                              color: isActive ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(isActive ? 'Désactiver' : 'Activer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations de contact
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(Icons.email, company.email),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoItem(Icons.phone, company.telephone),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(Icons.location_on, company.adresse),
                  ),
                  if (company.code != null) ...[
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Code: ${company.code}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Admin assigné
              if (company.adminCompagnieNom != null) ...[
                const SizedBox(height: 8),
                _buildInfoItem(
                  Icons.person,
                  'Admin: ${company.adminCompagnieNom}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAddCompanyDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyFormScreen(),
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
