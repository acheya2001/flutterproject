import 'package:flutter/material.dart';
import '../../../models/admin_models.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../utils/user_type.dart';
import '../../../services/admin_service.dart';

class CompagniesManagementScreen extends StatefulWidget {
  const CompagniesManagementScreen({super.key});

  @override
  State<CompagniesManagementScreen> createState() => _CompagniesManagementScreenState();
}

class _CompagniesManagementScreenState extends State<CompagniesManagementScreen> {
  final AdminService _adminService = AdminService();
  List<CompagnieAssurance> _compagnies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerCompagnies();
  }

  Future<void> _chargerCompagnies() async {
    try {
      setState(() => _isLoading = true);
      final compagnies = await _adminService.obtenirCompagnies();
      setState(() {
        _compagnies = compagnies;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Compagnies'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterCompagnie,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _compagnies.isEmpty
              ? _buildEmptyState()
              : _buildCompagniesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune compagnie d\'assurance',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez la première compagnie pour commencer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _ajouterCompagnie,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une compagnie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompagniesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _compagnies.length,
      itemBuilder: (context, index) {
        final compagnie = _compagnies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                compagnie.nom.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              compagnie.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIRET: ${compagnie.siret}'),
                Text('Email: ${compagnie.email}'),
                Text('Téléphone: ${compagnie.telephone}'),
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
                  value: 'agences',
                  child: Row(
                    children: [
                      Icon(Icons.store),
                      SizedBox(width: 8),
                      Text('Agences'),
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
                    _modifierCompagnie(compagnie);
                    break;
                  case 'agences':
                    _voirAgences(compagnie);
                    break;
                  case 'delete':
                    _supprimerCompagnie(compagnie);
                    break;
                }
              },
            ),
            onTap: () => _voirDetailsCompagnie(compagnie),
          ),
        );
      },
    );
  }

  void _ajouterCompagnie() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AjouterCompagnieScreen(),
      ),
    ).then((_) => _chargerCompagnies());
  }

  void _modifierCompagnie(CompagnieAssurance compagnie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierCompagnieScreen(compagnie: compagnie),
      ),
    ).then((_) => _chargerCompagnies());
  }

  void _voirAgences(CompagnieAssurance compagnie) {
    Navigator.pushNamed(
      context,
      '/admin/agences',
      arguments: {'compagnieId': compagnie.id},
    );
  }

  void _voirDetailsCompagnie(CompagnieAssurance compagnie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(compagnie.nom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('SIRET', compagnie.siret),
            _buildDetailRow('Adresse', compagnie.adresseSiege),
            _buildDetailRow('Email', compagnie.email),
            _buildDetailRow('Téléphone', compagnie.telephone),
            _buildDetailRow('Statut', compagnie.active ? 'Active' : 'Inactive'),
            _buildDetailRow('Date de création', 
                '${compagnie.dateCreation.day}/${compagnie.dateCreation.month}/${compagnie.dateCreation.year}'),
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

  void _supprimerCompagnie(CompagnieAssurance compagnie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la compagnie "${compagnie.nom}" ?'),
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
class AjouterCompagnieScreen extends StatelessWidget {
  const AjouterCompagnieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une Compagnie'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Formulaire d\'ajout en cours de développement'),
      ),
    );
  }
}

class ModifierCompagnieScreen extends StatelessWidget {
  final CompagnieAssurance compagnie;

  const ModifierCompagnieScreen({super.key, required this.compagnie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la Compagnie'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Formulaire de modification en cours de développement'),
      ),
    );
  }
}
