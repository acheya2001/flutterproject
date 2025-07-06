import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Change to Riverpod
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/models/user_model.dart';
import '../widgets/modern_join_session_dialog.dart';
import 'invitations_screen.dart';
import '../../constat/screens/ai_demo_screen.dart';
import '../../insurance/widgets/insurance_navigation.dart';
import '../../auth/screens/admin_login_simple.dart';

class ConducteurHomeScreen extends ConsumerStatefulWidget { // Change to ConsumerStatefulWidget
  const ConducteurHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConducteurHomeScreen> createState() => _ConducteurHomeScreenState(); // Change to ConsumerState
}

class _ConducteurHomeScreenState extends ConsumerState<ConducteurHomeScreen> { // Change to ConsumerState
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider); // Use Riverpod ref.watch instead of Provider.of
    final UserModel? user = authState.currentUser; 
    
    final dateFormat = DateFormat.yMMMMd('fr_FR');
    final today = dateFormat.format(DateTime.now());
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tableau de bord',
        actions: [
          // Bouton Admin (temporaire pour test)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
            tooltip: 'Administration',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminLoginSimple(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Écran de notifications à implémenter')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authState.signOut(); // Use authState instead of authProvider
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
              }
            },
          ),
        ],
      ),
      // Rest of the code remains the same
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      (user?.prenom.isNotEmpty == true && user?.nom.isNotEmpty == true)
                          ? '${user!.prenom[0]}${user.nom[0]}'.toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          today,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.declarationEntryPoint); // MODIFIÉ
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withAlpha(77),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
                      SizedBox(height: 16),
                      Text('Nouveau constat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 8),
                      Text('Déclarer un accident et créer un constat amiable', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
      // Bouton flottant admin (temporaire pour test)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminLoginSimple(),
            ),
          );
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Admin'),
        tooltip: 'Accès Administration',
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accès rapide', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(context, 'Mes véhicules', Icons.directions_car, AppRoutes.conducteurVehicules),
            _buildInsuranceCard(context),
            _buildTestMenuCard(context),
            _buildModernJoinCard(context),
            _buildInvitationsCard(context),
            _buildAIDemoCard(context),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, String route) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (route == AppRoutes.conducteurVehicules) {
             Navigator.pushNamed(context, route, arguments: {'selectionMode': false}); // Explicitement false
          } else if (route == '/settings_placeholder') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Écran Paramètres à implémenter')));
          }
          else {
            Navigator.pushNamed(context, route);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => InsuranceNavigation.navigateBasedOnRole(context),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Assurance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Mes véhicules',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestMenuCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚧 Menu test à implémenter')),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bug_report,
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Tests',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Menu Test',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernJoinCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _showJoinSessionDialog(),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_add,
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Rejoindre',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Session',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InvitationsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.mail_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Invitations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Reçues',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIDemoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _openAIDemo(),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'IA Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Analyse IA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAIDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIDemoScreen(),
      ),
    );
  }

  void _showJoinSessionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ModernJoinSessionDialog(),
    );
  }
}