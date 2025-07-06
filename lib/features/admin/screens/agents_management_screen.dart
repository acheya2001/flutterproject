import 'package:flutter/material.dart';
import '../../../models/admin_models.dart';
import '../../../services/admin_service.dart';

class AgentsManagementScreen extends StatefulWidget {
  final String? compagnieId;
  final String? agenceId;

  const AgentsManagementScreen({
    super.key, 
    this.compagnieId, 
    this.agenceId,
  });

  @override
  State<AgentsManagementScreen> createState() => _AgentsManagementScreenState();
}

class _AgentsManagementScreenState extends State<AgentsManagementScreen> {
  final AdminService _adminService = AdminService();
  List<AgentAssurance> _agents = [];
  List<CompagnieAssurance> _compagnies = [];
  List<AgenceAssurance> _agences = [];
  String? _selectedCompagnieId;
  String? _selectedAgenceId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCompagnieId = widget.compagnieId;
    _selectedAgenceId = widget.agenceId;
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

      // Charger les agents si une agence est sélectionnée
      if (_selectedAgenceId != null) {
        await _chargerAgents(_selectedAgenceId!);
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

  Future<void> _chargerAgents(String agenceId) async {
    try {
      final agents = await _adminService.obtenirAgents(agenceId);
      setState(() => _agents = agents);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des agents: $e'),
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
        title: const Text('Gestion des Agents'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        actions: [
          if (_selectedAgenceId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _ajouterAgent,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSelectors(),
                Expanded(
                  child: _selectedAgenceId == null
                      ? _buildSelectAgenceMessage()
                      : _agents.isEmpty
                          ? _buildEmptyState()
                          : _buildAgentsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSelectors() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de compagnie
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
                _selectedAgenceId = null;
                _agences.clear();
                _agents.clear();
              });
              if (value != null) {
                _chargerAgences(value);
              }
            },
          ),
          
          if (_selectedCompagnieId != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Sélectionner une agence:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAgenceId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Choisir une agence'),
              items: _agences.map((agence) {
                return DropdownMenuItem(
                  value: agence.id,
                  child: Text('${agence.nom} (${agence.code})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAgenceId = value;
                  _agents.clear();
                });
                if (value != null) {
                  _chargerAgents(value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectAgenceMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez une agence',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez une compagnie et une agence pour voir les agents',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final agenceNom = _agences
        .firstWhere((a) => a.id == _selectedAgenceId)
        .nom;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun agent',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun agent trouvé pour l\'agence $agenceNom',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _ajouterAgent,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _agents.length,
      itemBuilder: (context, index) {
        final agent = _agents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: Text(
                '${agent.prenom.substring(0, 1)}${agent.nom.substring(0, 1)}',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              agent.nomComplet,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Matricule: ${agent.matricule}'),
                Text('Poste: ${agent.poste}'),
                Text('Email: ${agent.email}'),
                Text('Téléphone: ${agent.telephone}'),
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
                  value: 'contracts',
                  child: Row(
                    children: [
                      Icon(Icons.description),
                      SizedBox(width: 8),
                      Text('Contrats'),
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
                    _modifierAgent(agent);
                    break;
                  case 'contracts':
                    _voirContrats(agent);
                    break;
                  case 'delete':
                    _supprimerAgent(agent);
                    break;
                }
              },
            ),
            onTap: () => _voirDetailsAgent(agent),
          ),
        );
      },
    );
  }

  void _ajouterAgent() {
    if (_selectedAgenceId == null || _selectedCompagnieId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterAgentScreen(
          compagnieId: _selectedCompagnieId!,
          agenceId: _selectedAgenceId!,
        ),
      ),
    ).then((_) => _chargerAgents(_selectedAgenceId!));
  }

  void _modifierAgent(AgentAssurance agent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierAgentScreen(agent: agent),
      ),
    ).then((_) => _chargerAgents(_selectedAgenceId!));
  }

  void _voirContrats(AgentAssurance agent) {
    Navigator.pushNamed(
      context,
      '/admin/contrats',
      arguments: {'agentId': agent.id},
    );
  }

  void _voirDetailsAgent(AgentAssurance agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(agent.nomComplet),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Matricule', agent.matricule),
            _buildDetailRow('Poste', agent.poste),
            _buildDetailRow('Email', agent.email),
            _buildDetailRow('Téléphone', agent.telephone),
            _buildDetailRow('Statut', agent.active ? 'Actif' : 'Inactif'),
            if (agent.dateEmbauche != null)
              _buildDetailRow('Date d\'embauche', 
                  '${agent.dateEmbauche!.day}/${agent.dateEmbauche!.month}/${agent.dateEmbauche!.year}'),
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
            width: 100,
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

  void _supprimerAgent(AgentAssurance agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'agent "${agent.nomComplet}" ?'),
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
class AjouterAgentScreen extends StatelessWidget {
  final String compagnieId;
  final String agenceId;

  const AjouterAgentScreen({
    super.key, 
    required this.compagnieId, 
    required this.agenceId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Agent'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Formulaire d\'ajout en cours de développement'),
      ),
    );
  }
}

class ModifierAgentScreen extends StatelessWidget {
  final AgentAssurance agent;

  const ModifierAgentScreen({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'Agent'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Formulaire de modification en cours de développement'),
      ),
    );
  }
}
