import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_accounts_manager.dart';

/// 👨‍💼 Écran de gestion des comptes administrateurs
class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _creationResults;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// 📊 Charger les statistiques
  Future<void> _loadStats() async {
    final stats = await AdminAccountsManager.getAdminStats();
    setState(() => _stats = stats);
  }

  /// 🔧 Créer tous les comptes admin
  Future<void> _createAllAccounts() async {
    setState(() => _isLoading = true);

    try {
      final results = await AdminAccountsManager.createAllAdminAccounts();
      setState(() => _creationResults = results);
      await _loadStats(); // Recharger les stats
      
      _showResultsDialog(results);
    } catch (e) {
      _showErrorDialog('Erreur lors de la création des comptes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🧪 Tester un compte admin
  Future<void> _testAccount(String email, String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Test de connexion...'),
          ],
        ),
      ),
    );

    final result = await AdminAccountsManager.testAdminLogin(email, password);
    
    if (mounted) {
      Navigator.of(context).pop(); // Fermer le dialog de chargement
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result['success'] ? '✅ Test Réussi' : '❌ Test Échoué'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: $email'),
              const SizedBox(height: 8),
              Text('Résultat: ${result['message']}'),
              if (result['success']) ...[
                const SizedBox(height: 8),
                Text('Type: ${result['adminType']}'),
                Text('Nom: ${result['nom']}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// 📋 Afficher les résultats de création
  void _showResultsDialog(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Résultats de Création'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Créés: ${results['success'].length}'),
              Text('⚠️ Existants: ${results['existing'].length}'),
              Text('❌ Erreurs: ${results['errors'].length}'),
              
              if (results['success'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Comptes créés:', style: TextStyle(fontWeight: FontWeight.bold)),
                for (final email in results['success'])
                  Text('• $email', style: const TextStyle(color: Colors.green)),
              ],
              
              if (results['errors'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Erreurs:', style: TextStyle(fontWeight: FontWeight.bold)),
                for (final error in results['errors'])
                  Text('• $error', style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ⚠️ Afficher dialog d'erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 📋 Copier email et mot de passe
  void _copyCredentials(String email, String password) {
    Clipboard.setData(ClipboardData(text: 'Email: $email\nMot de passe: $password'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Identifiants copiés dans le presse-papiers'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍💼 Comptes Administrateurs'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statistiques
            if (_stats != null) _buildStatsCard(),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(child: _buildCreateButton()),
                const SizedBox(width: 12),
                Expanded(child: _buildSyncButton()),
              ],
            ),

            const SizedBox(height: 24),
            
            // Liste des comptes
            _buildAccountsList(),
          ],
        ),
      ),
    );
  }

  /// 📊 Card des statistiques
  Widget _buildStatsCard() {
    final stats = _stats!['stats'] as Map<String, int>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Statistiques',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', stats['total'] ?? 0, Colors.blue),
                _buildStatItem('Super Admin', stats['super_admin'] ?? 0, Colors.purple),
                _buildStatItem('Compagnies', stats['admin_compagnie'] ?? 0, Colors.orange),
                _buildStatItem('Agences', stats['admin_agence'] ?? 0, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📈 Item de statistique
  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// 🔧 Bouton de création
  Widget _buildCreateButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _createAllAccounts,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_circle),
      label: Text(_isLoading ? 'Création...' : 'Créer Comptes'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  /// 🔄 Bouton de synchronisation
  Widget _buildSyncButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _navigateToSync,
      icon: const Icon(Icons.sync),
      label: const Text('Synchroniser'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  /// 🔄 Naviguer vers l'écran de synchronisation
  void _navigateToSync() {
    // TODO: Implémenter la synchronisation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚧 Synchronisation à implémenter')),
    );
  }

  /// 📋 Liste des comptes
  Widget _buildAccountsList() {
    final accounts = AdminAccountsManager.getFormattedAdminEmails();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📧 Comptes Administrateurs Disponibles',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        for (final category in accounts.entries)
          _buildCategoryCard(category.key, category.value),
      ],
    );
  }

  /// 📂 Card de catégorie
  Widget _buildCategoryCard(String category, List<String> emails) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: emails.map((emailWithPassword) {
          final parts = emailWithPassword.split(' (');
          final email = parts[0];
          final password = parts[1].replaceAll(')', '');
          
          return ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: Text(email),
            subtitle: Text('Mot de passe: $password'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyCredentials(email, password),
                  tooltip: 'Copier les identifiants',
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _testAccount(email, password),
                  tooltip: 'Tester la connexion',
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
