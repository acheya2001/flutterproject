import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Logger _logger = Logger();
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'Français';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Notifications'),
            subtitle: Text('Activer les notifications push'),
            value: _notificationsEnabled,
            onChanged: (value) {
              _logger.d('Notifications: $value');
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Mode sombre'),
            subtitle: Text('Activer le thème sombre'),
            value: _darkModeEnabled,
            onChanged: (value) {
              _logger.d('Mode sombre: $value');
              setState(() {
                _darkModeEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fonctionnalité en cours de développement')),
              );
            },
          ),
          ListTile(
            title: Text('Langue'),
            subtitle: Text(_language),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              _logger.d('Sélection de la langue');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Fonctionnalité en cours de développement')),
              );
            },
          ),
          ListTile(
            title: Text('À propos'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              _logger.d('À propos');
              _showAboutDialog();
            },
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Retour'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('À propos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Constat Tunisie'),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text('Une application pour la gestion des constats amiables en Tunisie'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
