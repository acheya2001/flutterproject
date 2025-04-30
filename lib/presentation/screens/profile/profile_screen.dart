import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:constat_tunisie/core/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  final Logger _logger = Logger();
  
  ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _logger.d('Affichage du profil utilisateur');
    
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mon profil'),
      ),
      body: user == null
          ? Center(child: Text('Utilisateur non connecté'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildProfileItem('Nom', user.displayName ?? 'Non défini'),
                  _buildProfileItem('Email', user.email ?? 'Non défini'),
                  _buildProfileItem('Téléphone', user.phoneNumber ?? 'Non défini'),
                  SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Retour'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18),
          ),
          Divider(),
        ],
      ),
    );
  }
}
