import 'package:flutter/material.dart';
import '../../../models/admin_models.dart';
import '../../../services/admin_service.dart';

class AgencesManagementScreen extends StatefulWidget {
  final String? compagnieId;

  const AgencesManagementScreen({super.key, this.compagnieId});

  @override
  State<AgencesManagementScreen> createState() => _AgencesManagementScreenState();
}

class _AgencesManagementScreenState extends State<AgencesManagementScreen> {
  final AdminService _adminService = AdminService();
  List<AgenceAssurance> _agences = [];
  List<CompagnieAssurance> _compagnies = [];
  String? _selectedCompagnieId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCompagnieId = widget.compagnieId;
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      setState(() => _isLoading = true);
      
      // Charger les compagnies
      final compagnies = await _adminService.obtenirCompagnies();
      setState(() => _compagnies = compagnies);

      // Charger les agences si une compagnie est sélectionnée
      if (_selectedCompagnieId != null) {
        await _chargerAgences(_selectedCompagnieId!);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _chargerAgences(String compagnieId) async {
    try {
      final agences = await _adminService.obtenirAgences(compagnieId);
      setState(() => _agences = agences);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des agences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Agences'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          if (_selectedCompagnieId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _ajouterAgence,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCompagnieSelector(),
                Expanded(
                  child: _selectedCompagnieId == null
                      ? _buildSelectCompagnieMessage()
                      : _agences.isEmpty
                          ? _buildEmptyState()
                          : _buildAgencesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildCompagnieSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionner une compagnie:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCompagnieId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Choisir une compagnie'),
            items: _compagnies.map((compagnie) {
              return DropdownMenuItem(
                value: compagnie.id,
                child: Text(compagnie.nom),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCompagnieId = value;
                _agences.clear();
              });
              if (value != null) {
                _chargerAgences(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCompagnieMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez une compagnie',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez une compagnie pour voir ses agences',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final compagnieNom = _compagnies
        .firstWhere((c) => c.id == _selectedCompagnieId)
        .nom;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune agence',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune agence trouvée pour $compagnieNom',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _ajouterAgence,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une agence'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _agences.length,
      itemBuilder: (context, index) {
        final agence = _agences[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Text(
                agence.code,
                style: TextStyle(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              agence.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${agence.code}'),
                Text('${agence.ville}, ${agence.gouvernorat}'),
                Text('Email: ${agence.email}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'agents',
                  child: Row(
                    children: [
                      Icon(Icons.people),
                      SizedBox(width: 8),
                      Text('Agents'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _modifierAgence(agence);
                    break;
                  case 'agents':
                    _voirAgents(agence);
                    break;
                  case 'delete':
                    _supprimerAgence(agence);
                    break;
                }
              },
            ),
            onTap: () => _voirDetailsAgence(agence),
          ),
        );
      },
    );
  }

  void _ajouterAgence() {
    if (_selectedCompagnieId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterAgenceScreen(compagnieId: _selectedCompagnieId!),
      ),
    ).then((_) => _chargerAgences(_selectedCompagnieId!));
  }

  void _modifierAgence(AgenceAssurance agence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierAgenceScreen(agence: agence),
      ),
    ).then((_) => _chargerAgences(_selectedCompagnieId!));
  }

  void _voirAgents(AgenceAssurance agence) {
    Navigator.pushNamed(
      context,
      '/admin/agents',
      arguments: {
        'compagnieId': agence.compagnieId,
        'agenceId': agence.id,
      },
    );
  }

  void _voirDetailsAgence(AgenceAssurance agence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(agence.nom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Code', agence.code),
            _buildDetailRow('Adresse', agence.adresse),
            _buildDetailRow('Ville', agence.ville),
            _buildDetailRow('Gouvernorat', agence.gouvernorat),
            _buildDetailRow('Email', agence.email),
            _buildDetailRow('Téléphone', agence.telephone),
            _buildDetailRow('Statut', agence.active ? 'Active' : 'Inactive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _supprimerAgence(AgenceAssurance agence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'agence "${agence.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la suppression
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suppression en cours de développement'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// Écrans d'ajout et modification (à implémenter)
class AjouterAgenceScreen extends StatelessWidget {
  final String compagnieId;

  const AjouterAgenceScreen({super.key, required this.compagnieId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une Agence'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Formulaire d\'ajout en cours de développement'),
      ),
    );
  }
}

class ModifierAgenceScreen extends StatelessWidget {
  final AgenceAssurance agence;

  const ModifierAgenceScreen({super.key, required this.agence});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'Agence'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Formulaire de modification en cours de développement'),
      ),
    );
  }
}
