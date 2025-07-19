import 'package:flutter/material.dart';

/// 🏢 Écran de gestion des compagnies - Version Simple
class CompaniesManagementScreen extends StatelessWidget {
  const CompaniesManagementScreen({Key? key}) : super(key: key);

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
            onPressed: () => _showAddCompanyDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une compagnie',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Message de succès
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'GESTION DES COMPAGNIES',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fonctionnalité accessible avec succès !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Liste des compagnies tunisiennes
            Expanded(
              child: ListView(
                children: [
                  _buildCompanyCard(
                    'STAR Assurances',
                    'Leader du marché tunisien',
                    'contact@star.com.tn',
                    '+216 70 255 000',
                    Colors.blue,
                    true,
                  ),
                  _buildCompanyCard(
                    'COMAR Assurances',
                    'Compagnie historique',
                    'info@comar.tn',
                    '+216 71 340 899',
                    Colors.green,
                    true,
                  ),
                  _buildCompanyCard(
                    'MAGHREBIA',
                    'Assurance moderne',
                    'contact@assurancesmaghrebia.com',
                    '+216 71 788 800',
                    Colors.orange,
                    true,
                  ),
                  _buildCompanyCard(
                    'GAT Assurances',
                    'Service de qualité',
                    'contact@gat.com.tn',
                    '+216 31 350 000',
                    Colors.purple,
                    false,
                  ),
                  _buildCompanyCard(
                    'Zitouna Takaful',
                    'Assurance participative',
                    'contact@zitounatakaful.com',
                    '+216 71 19 80 80',
                    Colors.teal,
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard(
    String name,
    String description,
    String email,
    String phone,
    Color color,
    bool isActive,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business,
                    color: color,
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
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Statut
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informations de contact
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(Icons.email, email),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(Icons.phone, phone),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCompanyDetails(name),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Voir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editCompany(name),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAddCompanyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une compagnie'),
        content: const Text('Fonctionnalité de création de compagnie - En cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompanyDetails(String name) {
    // Fonctionnalité à implémenter
    print('Voir détails de $name');
  }

  void _editCompany(String name) {
    // Fonctionnalité à implémenter
    print('Modifier $name');
  }
}
