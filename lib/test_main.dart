import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/vehicules/screens/vehicle_selection_screen.dart';
import 'features/admin/screens/test_data_screen.dart';
import 'features/admin/screens/mass_data_screen.dart';
import 'features/admin/screens/data_verification_screen.dart';
import 'features/assurance/screens/assureur_dashboard_screen.dart';
import 'features/assurance/services/auto_data_service.dart';
import 'firebase_options.dart';

/// 🧪 Application de test pour développement
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('❌ Erreur Firebase: $e');
  }
  
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Test Constat Tunisie',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
        ),
        home: const TestHomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// 🏠 Écran d'accueil de test
class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🧪 Test Constat Tunisie'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Tests disponibles
            const Text(
              '🧪 Tests Disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cartes de test
            _buildTestCard(
              context,
              title: '🗄️ Gestion Données de Test',
              description: 'Créer et gérer les données de test dans Firestore',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TestDataScreen(),
                ),
              ),
              color: Colors.blue,
            ),

            const SizedBox(height: 12),

            _buildTestCard(
              context,
              title: '🏭 Base de Données Massive',
              description: 'Générer des milliers de contrats réalistes pour votre PFE',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MassDataScreen(),
                ),
              ),
              color: Colors.deepPurple,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestCard(
              context,
              title: '🚗 Sélection Véhicule',
              description: 'Tester la sélection de véhicule avec vérification contrat',
              onTap: () => _testVehicleSelection(context),
              color: Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestCard(
              context,
              title: '📋 Déclaration Accident',
              description: 'Tester le processus complet de déclaration',
              onTap: () => _testAccidentDeclaration(context),
              color: Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestCard(
              context,
              title: '🔍 Vérification Contrat',
              description: 'Tester la vérification de contrat d\'assurance',
              onTap: () => _testContractVerification(context),
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            _buildTestCard(
              context,
              title: '📊 Vérification Données',
              description: 'Vérifier les données dans Firestore et tester les requêtes',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DataVerificationScreen(),
                ),
              ),
              color: Colors.green,
            ),

            const SizedBox(height: 12),

            _buildTestCard(
              context,
              title: '🏢 Dashboard Assureur',
              description: 'Interface complète pour les compagnies d\'assurance',
              onTap: () => _testAssureurDashboard(context),
              color: Colors.indigo,
            ),

            const SizedBox(height: 12),

            _buildTestCard(
              context,
              title: '🏭 Génération Auto Assurance',
              description: 'Générer automatiquement toutes les données d\'assurance',
              onTap: () => _generateInsuranceData(context),
              color: Colors.deepOrange,
            ),
            
            const SizedBox(height: 24),
            
            // Informations de développement
            _buildDevInfo(),
          ],
        ),
      ),
    );
  }

  /// 📋 En-tête
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environnement de Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      'Testez toutes les fonctionnalités de l\'application',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '🎯 Cet environnement vous permet de tester toutes les fonctionnalités '
            'développées pour votre PFE. Commencez par créer des données de test.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 🎯 Carte de test
  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Informations de développement
  Widget _buildDevInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations de Développement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Version', '1.0.0 (Test)'),
          _buildInfoRow('Firebase', 'Configuré ✅'),
          _buildInfoRow('Collections', 'vehicules_assures, constats, analytics'),
          _buildInfoRow('Rôles', 'Conducteur, Assureur, Expert'),
          _buildInfoRow('Fonctionnalités', 'Vérification contrat, IA, BI'),
        ],
      ),
    );
  }

  /// 📊 Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚗 Tester la sélection de véhicule
  void _testVehicleSelection(BuildContext context) {
    // Simuler un utilisateur connecté
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Créer un utilisateur de test temporaire
    authProvider.setTestUser();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VehicleSelectionScreen(),
      ),
    );
  }

  /// 📋 Tester la déclaration d'accident
  void _testAccidentDeclaration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Sélectionnez d\'abord un véhicule pour tester la déclaration'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 🔍 Tester la vérification de contrat
  void _testContractVerification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔍 Utilisez la sélection de véhicule pour tester la vérification'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 🏢 Tester le dashboard assureur
  void _testAssureurDashboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏢 Choisir une Compagnie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sélectionnez une compagnie d\'assurance pour tester le dashboard:'),
            const SizedBox(height: 16),
            ...[
              {'id': 'STAR', 'nom': 'STAR Assurances', 'color': Colors.orange},
              {'id': 'MAGHREBIA', 'nom': 'Maghrebia Assurances', 'color': Colors.blue},
              {'id': 'GAT', 'nom': 'GAT Assurances', 'color': Colors.green},
              {'id': 'LLOYD', 'nom': 'Lloyd Tunisien', 'color': Colors.purple},
            ].map((company) => ListTile(
              leading: CircleAvatar(
                backgroundColor: (company['color'] as Color).withValues(alpha: 0.2),
                child: Text(
                  (company['id'] as String).substring(0, 1),
                  style: TextStyle(
                    color: company['color'] as Color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(company['nom'] as String),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AssureurDashboardScreen(
                      compagnieId: company['id'] as String,
                    ),
                  ),
                );
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  /// 🏭 Générer les données d'assurance
  void _generateInsuranceData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏭 Génération Automatique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Génération des données d\'assurance en cours...'),
            const SizedBox(height: 8),
            Text(
              'Cela peut prendre quelques minutes',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    try {
      final autoDataService = AutoDataService();
      await autoDataService.generateAllInsuranceData(
        nombreVehicules: 1500,
        nombreConstats: 300,
        nombreClients: 1000,
        showProgress: true,
      );

      Navigator.of(context).pop(); // Fermer le dialog de chargement

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Succès !'),
            ],
          ),
          content: const Text(
            '🎉 Données d\'assurance générées avec succès !\n\n'
            '• 8 compagnies d\'assurance\n'
            '• 1000 clients\n'
            '• 1500 véhicules assurés\n'
            '• 300 constats\n'
            '• Analytics complètes\n\n'
            'Vous pouvez maintenant tester le dashboard assureur !',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Parfait !'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _testAssureurDashboard(context);
              },
              child: const Text('Tester Dashboard'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le dialog de chargement

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Erreur'),
            ],
          ),
          content: Text('Erreur lors de la génération:\n\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }
  }
}
