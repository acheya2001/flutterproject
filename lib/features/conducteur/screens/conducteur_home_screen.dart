import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../vehicule/screens/notification_history_screen.dart';

class ConducteurHomeScreen extends StatefulWidget {
  const ConducteurHomeScreen({Key? key}) : super(key: key);

  @override
  State<ConducteurHomeScreen> createState() => _ConducteurHomeScreenState();
}

class _ConducteurHomeScreenState extends State<ConducteurHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser les données de localisation pour le français
    initializeDateFormatting('fr_FR', null);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    // Formater la date du jour
    final dateFormat = DateFormat.yMMMMd('fr_FR');
    final today = dateFormat.format(DateTime.now());
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de bord',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Naviguer vers l'écran des notifications
              debugPrint('[ConducteurHomeScreen] Navigation vers NotificationHistoryScreen');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec salutation et date
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      // Correction de la vérification des valeurs nullables
                      (user?.prenom != null && user!.prenom.isNotEmpty && 
                       user.nom != null && user.nom.isNotEmpty)
                          ? '${user.prenom[0]}${user.nom[0]}'
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${user?.prenom ?? ''} ${user?.nom ?? ''}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          today,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Carte d'action principale
              InkWell(
                onTap: () {
                  // Naviguer vers l'écran de création de constat
                  Navigator.pushNamed(context, AppRoutes.conducteurDeclaration);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(77),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nouveau constat',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Déclarer un accident et créer un constat amiable',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Titre de section
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Grille de fonctionnalités
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildFeatureCard(
                    context,
                    'Mes véhicules',
                    Icons.directions_car,
                    Colors.green,
                    () {
                      Navigator.pushNamed(context, AppRoutes.conducteurVehicules);
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Historique',
                    Icons.history,
                    Colors.orange,
                    () {
                      Navigator.pushNamed(context, AppRoutes.conducteurAccidents);
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Documents',
                    Icons.description,
                    Colors.purple,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité à venir')),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Profil',
                    Icons.person,
                    Colors.red,
                    () {
                      Navigator.pushNamed(context, AppRoutes.conducteurProfile);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Titre de section
              const Text(
                'Conseils et astuces',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Liste de conseils
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final tips = [
                    {
                      'title': 'Que faire en cas d\'accident ?',
                      'description': 'Découvrez les étapes à suivre immédiatement après un accident.',
                      'icon': Icons.help_outline,
                    },
                    {
                      'title': 'Préparer vos documents',
                      'description': 'Assurez-vous d\'avoir tous les documents nécessaires à portée de main.',
                      'icon': Icons.file_copy_outlined,
                    },
                    {
                      'title': 'Utiliser l\'application',
                      'description': 'Guide d\'utilisation de l\'application pour déclarer un accident.',
                      'icon': Icons.phone_android,
                    },
                  ];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Icon(
                        tips[index]['icon'] as IconData,
                        color: Colors.blue,
                        size: 28,
                      ),
                      title: Text(
                        tips[index]['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(tips[index]['description'] as String),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Naviguer vers l'écran de conseil correspondant
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Conseil: ${tips[index]['title']}')),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Véhicules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Déjà sur l'écran d'accueil
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.conducteurVehicules);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.conducteurAccidents);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.conducteurProfile);
              break;
          }
        },
      ),
    );
  }
  
  // Méthode pour construire une carte de fonctionnalité
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
