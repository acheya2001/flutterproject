import 'package:flutter/material.dart';

/// 🚨 Bouton d'urgence global pour accès rapide aux fonctions admin
class GlobalEmergencyFAB extends StatelessWidget {
  const GlobalEmergencyFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.red.shade600,
      foregroundColor: Colors.white,
      onPressed: () => _showEmergencyMenu(context),
      child: const Icon(Icons.emergency, size: 20),
    );
  }

  void _showEmergencyMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🚨 Accès Rapide Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
              title: const Text('Super Admin'),
              subtitle: const Text('Accès administrateur'),
              onTap: () {
                Navigator.pop(context);
                // Navigation vers super admin
              },
            ),
            ListTile(
              leading: const Icon(Icons.business, color: Colors.blue),
              title: const Text('Admin Compagnie'),
              subtitle: const Text('Gestion compagnie'),
              onTap: () {
                Navigator.pop(context);
                // Navigation vers admin compagnie
              },
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Colors.green),
              title: const Text('Admin Agence'),
              subtitle: const Text('Gestion agence'),
              onTap: () {
                Navigator.pop(context);
                // Navigation vers admin agence
              },
            ),
          ],
        ),
      ),
    );
  }
}