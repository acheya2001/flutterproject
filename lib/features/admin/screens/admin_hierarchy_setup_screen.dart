import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_hierarchy_service.dart';
import '../../../core/models/admin_hierarchy_model.dart';
import 'hierarchical_admin_demandes_screen.dart';

/// 🏗️ Écran pour initialiser et tester la hiérarchie d'admins
class AdminHierarchySetupScreen extends StatefulWidget {
  const AdminHierarchySetupScreen({Key? key}) : super(key: key);

  @override
  State<AdminHierarchySetupScreen> createState() => _AdminHierarchySetupScreenState();
}

class _AdminHierarchySetupScreenState extends State<AdminHierarchySetupScreen> {
  bool _isLoading = false;
  String _message = '';
  List<AdminHierarchyModel> _admins = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Admin Hiérarchique'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête explicatif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏢 Système d\'Approbation Hiérarchique',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ce système crée une hiérarchie d\'administrateurs pour approuver les demandes d\'inscription des agents d\'assurance.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📋 Hiérarchie:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('• Super Admin - Gère tout l\'application'),
                  const Text('• Admin Compagnie - Gère une compagnie'),
                  const Text('• Admin Agence - Gère une agence'),
                  const Text('• Admin Régional - Gère un gouvernorat'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Boutons d'action
            _buildActionButton(
              'Initialiser la Hiérarchie',
              'Créer tous les admins par défaut',
              Icons.build,
              Colors.green,
              _initialiserHierarchie,
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              'Lister les Admins',
              'Voir tous les admins créés',
              Icons.list,
              Colors.blue,
              _listerAdmins,
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              'Tester Super Admin',
              'Se connecter comme Super Admin',
              Icons.admin_panel_settings,
              Colors.purple,
              _testerSuperAdmin,
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              'Nettoyer les Données',
              'Supprimer tous les admins de test',
              Icons.delete_sweep,
              Colors.red,
              _nettoyerDonnees,
            ),
            const SizedBox(height: 24),

            // Zone de messages
            if (_message.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.contains('✅') ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _message.contains('✅') ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('✅') ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Liste des admins
            if (_admins.isNotEmpty) ...[
              Text(
                'Admins Créés (${_admins.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._admins.map((admin) => _buildAdminCard(admin)).toList(),
            ],

            // Instructions de test
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🧪 Instructions de Test',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Cliquez "Initialiser la Hiérarchie"'),
                  const Text('2. Inscrivez un agent avec l\'interface normale'),
                  const Text('3. Connectez-vous comme admin pour approuver'),
                  const Text('4. L\'agent peut maintenant se connecter'),
                  const SizedBox(height: 12),
                  Text(
                    '📧 Comptes Admin Créés:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                  const Text('• constat.tunisie.app@gmail.com (Super Admin)'),
                  const Text('• admin@star.tn (Admin STAR)'),
                  const Text('• admin@gat.tn (Admin GAT)'),
                  const Text('• admin.nord@constat.tn (Admin Nord)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(AdminHierarchyModel admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForType(admin.typeAdmin),
          child: Icon(
            _getIconForType(admin.typeAdmin),
            color: Colors.white,
          ),
        ),
        title: Text('${admin.prenom} ${admin.nom}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(admin.email),
            Text(
              admin.typeAdminNom,
              style: TextStyle(
                color: _getColorForType(admin.typeAdmin),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _testerAdmin(admin),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getColorForType(admin.typeAdmin),
            foregroundColor: Colors.white,
          ),
          child: const Text('Tester'),
        ),
      ),
    );
  }

  Color _getColorForType(TypeAdmin type) {
    switch (type) {
      case TypeAdmin.superAdmin:
        return Colors.purple;
      case TypeAdmin.adminCompagnie:
        return Colors.blue;
      case TypeAdmin.adminAgence:
        return Colors.green;
      case TypeAdmin.adminRegional:
        return Colors.orange;
    }
  }

  IconData _getIconForType(TypeAdmin type) {
    switch (type) {
      case TypeAdmin.superAdmin:
        return Icons.admin_panel_settings;
      case TypeAdmin.adminCompagnie:
        return Icons.business;
      case TypeAdmin.adminAgence:
        return Icons.store;
      case TypeAdmin.adminRegional:
        return Icons.map;
    }
  }

  Future<void> _initialiserHierarchie() async {
    setState(() {
      _isLoading = true;
      _message = '🔄 Initialisation en cours...';
    });

    try {
      await AdminHierarchyService.initialiserHierarchieAdmins();
      setState(() {
        _message = '✅ Hiérarchie d\'admins initialisée avec succès !\n'
            'Vous pouvez maintenant tester le système d\'approbation.';
      });
      await _listerAdmins();
    } catch (e) {
      setState(() {
        _message = '❌ Erreur lors de l\'initialisation: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _listerAdmins() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer tous les admins depuis Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('admins_hierarchy')
          .get();

      final admins = snapshot.docs
          .map((doc) => AdminHierarchyModel.fromFirestore(doc))
          .toList();

      setState(() {
        _admins = admins;
        _message = admins.isNotEmpty 
            ? '✅ ${admins.length} admins trouvés'
            : '⚠️ Aucun admin trouvé. Initialisez d\'abord la hiérarchie.';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erreur lors de la récupération: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testerSuperAdmin() async {
    final superAdmin = _admins.firstWhere(
      (admin) => admin.typeAdmin == TypeAdmin.superAdmin,
      orElse: () => throw Exception('Super Admin non trouvé'),
    );

    await _testerAdmin(superAdmin);
  }

  Future<void> _testerAdmin(AdminHierarchyModel admin) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HierarchicalAdminDemandesScreen(admin: admin),
      ),
    );
  }

  Future<void> _nettoyerDonnees() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer tous les admins de test ?\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _message = '🧹 Nettoyage en cours...';
      });

      try {
        await AdminHierarchyService.nettoyerDonneesTest();
        setState(() {
          _admins.clear();
          _message = '✅ Données nettoyées avec succès';
        });
      } catch (e) {
        setState(() {
          _message = '❌ Erreur lors du nettoyage: $e';
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
