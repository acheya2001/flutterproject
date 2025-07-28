import 'package:flutter/material.dart';
import '../../../../services/admin_compagnie_service.dart';

class AgencesSectionWidget extends StatefulWidget {
  final String compagnieId;
  final VoidCallback onRefresh;

  const AgencesSectionWidget({
    Key? key,
    required this.compagnieId,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<AgencesSectionWidget> createState() => _AgencesSectionWidgetState();
}

class _AgencesSectionWidgetState extends State<AgencesSectionWidget> {
  List<Map<String, dynamic>> _agences = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAgences();
  }

  /// 🏢 Charger les agences
  Future<void> _loadAgences() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final agences = await AdminCompagnieService.getAgences(widget.compagnieId);
      
      setState(() {
        _agences = agences;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget()
                  : _buildAgencesList(),
        ),
      ],
    );
  }

  /// 📋 En-tête avec bouton d'ajout
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.business_rounded, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            'Gestion des Agences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showCreateAgenceDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nouvelle Agence'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ❌ Widget d'erreur
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(fontSize: 18, color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Erreur inconnue',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAgences,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des agences
  Widget _buildAgencesList() {
    if (_agences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune agence créée',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par créer votre première agence',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateAgenceDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer une agence'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAgences,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _agences.length,
        itemBuilder: (context, index) {
          final agence = _agences[index];
          return _buildAgenceCard(agence);
        },
      ),
    );
  }

  /// 🏢 Carte d'agence
  Widget _buildAgenceCard(Map<String, dynamic> agence) {
    final hasAdmin = agence['adminAgenceId'] != null;
    final isActive = agence['isActive'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: isActive ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agence['nom'] ?? 'Agence sans nom',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        agence['adresse'] ?? 'Adresse non renseignée',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAgenceAction(value, agence),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    if (!hasAdmin)
                      const PopupMenuItem(
                        value: 'add_admin',
                        child: Row(
                          children: [
                            Icon(Icons.person_add_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Ajouter Admin'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Désactiver' : 'Activer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.phone_rounded,
                  label: agence['telephone'] ?? 'N/A',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                if (hasAdmin)
                  _buildInfoChip(
                    icon: Icons.admin_panel_settings_rounded,
                    label: agence['adminNom'] ?? 'Admin',
                    color: Colors.green,
                  )
                else
                  _buildInfoChip(
                    icon: Icons.warning_rounded,
                    label: 'Pas d\'admin',
                    color: Colors.orange,
                  ),
              ],
            ),
            if (hasAdmin) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_rounded, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      agence['adminEmail'] ?? 'Email non renseigné',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (agence['adminActif'] ?? false) ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (agence['adminActif'] ?? false) ? 'Actif' : 'Inactif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
    );
  }

  /// 🏷️ Chip d'information
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Gérer les actions sur les agences
  void _handleAgenceAction(String action, Map<String, dynamic> agence) {
    switch (action) {
      case 'edit':
        _showEditAgenceDialog(agence);
        break;
      case 'add_admin':
        _showCreateAdminDialog(agence);
        break;
      case 'activate':
      case 'deactivate':
        _toggleAgenceStatus(agence);
        break;
    }
  }

  /// ➕ Dialogue de création d'agence
  void _showCreateAgenceDialog() {
    // TODO: Implémenter le dialogue de création
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Création d\'agence - À implémenter')),
    );
  }

  /// ✏️ Dialogue de modification d'agence
  void _showEditAgenceDialog(Map<String, dynamic> agence) {
    // TODO: Implémenter le dialogue de modification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modification agence ${agence['nom']} - À implémenter')),
    );
  }

  /// 👤 Dialogue de création d'admin
  void _showCreateAdminDialog(Map<String, dynamic> agence) {
    // TODO: Implémenter le dialogue de création d'admin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Création admin pour ${agence['nom']} - À implémenter')),
    );
  }

  /// 🔄 Basculer le statut de l'agence
  void _toggleAgenceStatus(Map<String, dynamic> agence) {
    // TODO: Implémenter le changement de statut
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Changement statut ${agence['nom']} - À implémenter')),
    );
  }
}
