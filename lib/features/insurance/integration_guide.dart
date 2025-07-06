import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/insurance_navigation.dart';
import 'utils/insurance_styles.dart';

/// 📱 Guide d'intégration simple pour le système d'assurance
class InsuranceIntegrationGuide extends StatelessWidget {
  const InsuranceIntegrationGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🛡️ Système d\'Assurance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section de bienvenue
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Section d'accès principal
            _buildMainAccessSection(context),
            const SizedBox(height: 24),

            // Section d'information
            _buildInfoSection(),
            const SizedBox(height: 24),

            // Section des fonctionnalités
            _buildFeaturesSection(),
          ],
        ),
      ),
    );
  }

  /// 👋 Section de bienvenue
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: InsuranceStyles.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛡️ Système d\'Assurance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gérez vos contrats d\'assurance et véhicules en toute simplicité',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Section d'accès principal
  Widget _buildMainAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Accès Principal',
          style: InsuranceStyles.titleMedium,
        ),
        const SizedBox(height: 16),
        
        // Carte d'accès à l'assurance
        InsuranceNavigation.buildInsuranceCard(context),
        
        const SizedBox(height: 16),
        
        // Boutons d'accès direct
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => InsuranceNavigation.navigateToMyVehicles(context),
                icon: const Icon(Icons.directions_car, size: 20),
                label: const Text('Mes Véhicules'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _checkUserRole(context),
                icon: const Icon(Icons.business, size: 20),
                label: const Text('Espace Agent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ℹ️ Section d'information
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Comment ça marche ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Les agents d\'assurance créent des contrats pour les conducteurs\n'
            '• Les conducteurs reçoivent des notifications automatiques\n'
            '• Les véhicules apparaissent dans "Mes Véhicules"\n'
            '• Gestion complète des contrats et notifications',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 Section des fonctionnalités
  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚀 Fonctionnalités',
          style: InsuranceStyles.titleMedium,
        ),
        const SizedBox(height: 16),
        
        // Fonctionnalités pour agents
        _buildFeatureGroup(
          title: '👨‍💼 Pour les Agents d\'Assurance',
          features: [
            'Tableau de bord avec statistiques',
            'Création de contrats en 3 étapes',
            'Recherche de conducteurs',
            'Gestion complète des contrats',
            'Notifications automatiques',
          ],
          color: Colors.green,
        ),
        
        const SizedBox(height: 16),
        
        // Fonctionnalités pour conducteurs
        _buildFeatureGroup(
          title: '🚗 Pour les Conducteurs',
          features: [
            'Visualisation des véhicules assurés',
            'Détails des contrats d\'assurance',
            'Notifications de nouveaux contrats',
            'Contact direct avec l\'agent',
            'Statut d\'expiration en temps réel',
          ],
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildFeatureGroup({
    required String title,
    required List<String> features,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  title.contains('Agent') ? Icons.business : Icons.directions_car,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// 🔍 Vérifier le rôle de l'utilisateur
  void _checkUserRole(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour accéder à l\'espace agent'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Logique simple basée sur l'email pour la démo
    final email = user.email ?? '';
    if (email.contains('agent') || email.contains('assurance')) {
      InsuranceNavigation.navigateToInsuranceDashboard(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Accès Restreint'),
          content: const Text(
            'L\'espace agent est réservé aux agents d\'assurance.\n\n'
            'Pour accéder à cette fonctionnalité, votre email doit contenir "agent" ou "assurance".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
    }
  }
}

/// 🔧 Exemple d'intégration dans main.dart
class MainAppExample extends StatelessWidget {
  const MainAppExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Constat Tunisie'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Autres fonctionnalités de l'app...
            
            const SizedBox(height: 20),
            
            // Intégration du système d'assurance
            InsuranceNavigation.buildInsuranceAccessButton(context),
            
            const SizedBox(height: 20),
            
            // Ou utiliser la carte
            InsuranceNavigation.buildInsuranceCard(context),
          ],
        ),
      ),
    );
  }
}
