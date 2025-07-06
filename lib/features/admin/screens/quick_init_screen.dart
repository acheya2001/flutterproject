import 'package:flutter/material.dart';
import '../services/global_admin_setup.dart';

/// 🚀 Écran d'initialisation rapide
class QuickInitScreen extends StatefulWidget {
  const QuickInitScreen({super.key});

  @override
  State<QuickInitScreen> createState() => _QuickInitScreenState();
}

class _QuickInitScreenState extends State<QuickInitScreen> {
  bool _isInitializing = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 Initialisation Rapide'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rocket_launch,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Initialisation du Système',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cliquez pour initialiser toutes les compagnies d\'assurance et le système admin',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            if (_status.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isInitializing ? null : _initializeSystem,
                icon: _isInitializing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(_isInitializing ? 'Initialisation...' : 'Initialiser le Système'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Cette action va créer :\n'
              '• 12 compagnies d\'assurance tunisiennes\n'
              '• Toutes les agences\n'
              '• Tous les comptes admin\n'
              '• Données de test',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeSystem() async {
    setState(() {
      _isInitializing = true;
      _status = 'Initialisation en cours...';
    });

    try {
      final success = await GlobalAdminSetup.initializeCompleteSystem();
      
      setState(() {
        _isInitializing = false;
        _status = success 
            ? '✅ Système initialisé avec succès !\n\nVous pouvez maintenant tester l\'inscription agent avec les 12 compagnies disponibles.'
            : '❌ Erreur lors de l\'initialisation';
      });

      if (success) {
        // Afficher les emails créés après un délai
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showAdminEmails();
          }
        });
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _status = '❌ Erreur: $e';
      });
    }
  }

  void _showAdminEmails() {
    final emails = GlobalAdminSetup.getAllAdminEmails();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Comptes Admin Créés'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Identifiants admin disponibles :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...emails.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map((email) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                )),
                const Divider(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: const Text(
                    '🎉 Maintenant vous pouvez :\n'
                    '1. Tester l\'inscription agent avec les 12 compagnies\n'
                    '2. Se connecter comme admin pour gérer les demandes\n'
                    '3. Voir les nouvelles agences créées automatiquement',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Parfait !'),
          ),
        ],
      ),
    );
  }
}
