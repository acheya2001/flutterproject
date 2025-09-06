import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏢 Écran de gestion des compagnies d'assurance
class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({Key? key}) : super(key: key);

  @override
  State<CompanyManagementScreen> createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tous';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des Compagnies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCompanyDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildCompanyList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une compagnie...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFilterChip('tous', 'Toutes'),
              const SizedBox(width: 8),
              _buildFilterChip('actif', 'Actives'),
              const SizedBox(width: 8),
              _buildFilterChip('inactif', 'Inactives'),
              const SizedBox(width: 8),
              _buildFilterChip('suspendu', 'Suspendues'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedFilter = value),
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
      checkmarkColor: const Color(0xFF3B82F6),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildCompanyList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .orderBy('nom')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          );
        }

        final companies = snapshot.data?.docs ?? [];
        final filteredCompanies = companies.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nom = (data['nom'] ?? '').toString().toLowerCase();
          final statut = data['statut'] ?? 'actif';

          // Filtrer par recherche
          if (_searchQuery.isNotEmpty && !nom.contains(_searchQuery)) {
            return false;
          }

          // Filtrer par statut
          if (_selectedFilter != 'tous' && statut != _selectedFilter) {
            return false;
          }

          return true;
        }).toList();

        if (filteredCompanies.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredCompanies.length,
          itemBuilder: (context, index) {
            final doc = filteredCompanies[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildCompanyCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune compagnie trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première compagnie d\'assurance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCompanyDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une compagnie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(String id, Map<String, dynamic> data) {
    final nom = data['nom'] ?? 'Compagnie';
    final code = data['code'] ?? 'N/A';
    final statut = data['statut'] ?? 'actif';
    final adresse = data['adresse'] ?? '';
    final telephone = data['telephone'] ?? '';
    final email = data['email'] ?? '';
    final dateCreation = data['dateCreation'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: _getStatusColor(statut),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Code: $code',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(statut),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (adresse.isNotEmpty) ...[
            _buildInfoRow(Icons.location_on, 'Adresse', adresse),
            const SizedBox(height: 8),
          ],
          
          if (telephone.isNotEmpty) ...[
            _buildInfoRow(Icons.phone, 'Téléphone', telephone),
            const SizedBox(height: 8),
          ],
          
          if (email.isNotEmpty) ...[
            _buildInfoRow(Icons.email, 'Email', email),
            const SizedBox(height: 8),
          ],
          
          if (dateCreation != null) ...[
            _buildInfoRow(
              Icons.calendar_today,
              'Créée le',
              _formatDate(dateCreation.toDate()),
            ),
          ],
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCompanyDetails(id, data),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Voir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditCompanyDialog(id, data),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, id, data),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: statut == 'actif' ? 'desactiver' : 'activer',
                    child: Row(
                      children: [
                        Icon(
                          statut == 'actif' ? Icons.pause : Icons.play_arrow,
                          size: 18,
                          color: statut == 'actif' ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(statut == 'actif' ? 'Désactiver' : 'Activer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String statut) {
    Color color;
    String text;

    switch (statut.toLowerCase()) {
      case 'actif':
        color = const Color(0xFF10B981);
        text = 'Actif';
        break;
      case 'inactif':
        color = const Color(0xFFEF4444);
        text = 'Inactif';
        break;
      case 'suspendu':
        color = const Color(0xFFF59E0B);
        text = 'Suspendu';
        break;
      default:
        color = Colors.grey;
        text = statut;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'actif':
        return const Color(0xFF10B981);
      case 'inactif':
        return const Color(0xFFEF4444);
      case 'suspendu':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action, String id, Map<String, dynamic> data) {
    switch (action) {
      case 'activer':
      case 'desactiver':
        _toggleCompanyStatus(id, action == 'activer');
        break;
      case 'supprimer':
        _showDeleteConfirmation(id, data['nom'] ?? 'cette compagnie');
        break;
    }
  }

  Future<void> _toggleCompanyStatus(String id, bool activate) async {
    try {
      await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .doc(id)
          .update({
        'statut': activate ? 'actif' : 'inactif',
        'dateModification': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate ? 'Compagnie activée avec succès' : 'Compagnie désactivée avec succès',
          ),
          backgroundColor: activate ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String id, String nom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$nom" ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCompany(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCompany(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .doc(id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compagnie supprimée avec succès'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCompanyDetails(String id, Map<String, dynamic> data) {
    // TODO: Implémenter les détails de la compagnie
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Détails de la compagnie - À implémenter')),
    );
  }

  void _showEditCompanyDialog(String id, Map<String, dynamic> data) {
    // TODO: Implémenter l'édition de compagnie
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modification de compagnie - À implémenter')),
    );
  }

  void _showAddCompanyDialog() {
    // TODO: Implémenter l'ajout de compagnie
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout de compagnie - À implémenter')),
    );
  }
}
