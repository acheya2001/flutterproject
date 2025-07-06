import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/app_router.dart';

/// 👥 Écran de sélection du type d'utilisateur moderne
class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: Column(
          children: [
            // SafeArea top
            SizedBox(height: safeAreaTop),

            // En-tête avec logo et titre - hauteur fixe
            SizedBox(
              height: 140,
              child: _buildHeader(context),
            ),

            // Contenu principal - hauteur calculée
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Titre de sélection - hauteur fixe
                    SizedBox(
                      height: 80,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: _buildSelectionTitle(context),
                      ),
                    ),

                    // Options de connexion - hauteur flexible
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildUserTypeOptions(context),
                      ),
                    ),

                    // Footer - hauteur fixe
                    SizedBox(
                      height: 120,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: _buildFooter(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SafeArea bottom
            SizedBox(height: safeAreaBottom),
          ],
        ),
      ),
    );
  }

  /// 📱 En-tête avec logo et titre
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo de l'application
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.security,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Titre de l'application
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Sous-titre
          Text(
            'Application d\'assurance automobile digitalisée',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🎯 Titre de sélection
  Widget _buildSelectionTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez votre profil',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez le type de compte qui correspond à votre profil',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 👥 Options de types d'utilisateurs - Version optimisée
  Widget _buildUserTypeOptions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // Conducteur/Client
              _buildUserTypeCard(
                context,
                icon: Icons.directions_car,
                title: 'Conducteur / Client',
                subtitle: 'Déclarer un sinistre, consulter mes contrats',
                color: AppTheme.driverColor,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.login,
                  arguments: {'userType': 'driver'},
                ),
              ),

              const SizedBox(height: 12),

              // Agent d'assurance
              _buildUserTypeCard(
                context,
                icon: Icons.business_center,
                title: 'Agent d\'Assurance',
                subtitle: 'Gérer les contrats et les clients',
                color: AppTheme.agentColor,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.login,
                  arguments: {'userType': 'agent'},
                ),
              ),

              const SizedBox(height: 12),

              // Expert automobile
              _buildUserTypeCard(
                context,
                icon: Icons.engineering,
                title: 'Expert Automobile',
                subtitle: 'Évaluer les sinistres et rédiger des rapports',
                color: AppTheme.expertColor,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.login,
                  arguments: {'userType': 'expert'},
                ),
              ),

              const SizedBox(height: 12),

              // Administrateur
              _buildUserTypeCard(
                context,
                icon: Icons.admin_panel_settings,
                title: 'Administrateur',
                subtitle: 'Gérer le système et les utilisateurs',
                color: AppTheme.adminColor,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.login,
                  arguments: {'userType': 'admin'},
                ),
              ),

              const SizedBox(height: 16),

              // 📋 Bouton demande de compte professionnel
              _buildProfessionalRequestButton(context),

              // Espace final pour éviter l'overflow
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 📋 Bouton pour demander un compte professionnel
  Widget _buildProfessionalRequestButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRouter.professionalAccountRequest,
        ),
        icon: const Icon(Icons.business_center_outlined),
        label: const Text('Demander un Compte Professionnel'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: BorderSide(color: AppTheme.primaryColor, width: 2),
          foregroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// 🎴 Carte de type d'utilisateur
  Widget _buildUserTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icône
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🦶 Footer avec informations
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        
        // Boutons d'aide - Version responsive
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextButton.icon(
                  onPressed: () {
                    // Ouvrir l'aide
                    _showHelpDialog(context);
                  },
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text(
                    'Aide',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextButton.icon(
                  onPressed: () {
                    // Ouvrir les conditions
                    _showTermsDialog(context);
                  },
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text(
                    'Conditions',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextButton.icon(
                  onPressed: () {
                    // Contacter le support
                    _showContactDialog(context);
                  },
                  icon: const Icon(Icons.contact_support_outlined, size: 18),
                  label: const Text(
                    'Contact',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Version de l'application
        Text(
          'Version ${AppConstants.appVersion}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textHint,
          ),
        ),

        const SizedBox(height: 8),

        // 🔐 Accès Super Admin (discret)
        _buildSuperAdminAccess(context),
      ],
    );
  }

  /// ❓ Dialog d'aide
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const Text(
          'Choisissez votre profil selon votre rôle :\n\n'
          '• Conducteur : Si vous êtes assuré et souhaitez déclarer un sinistre\n'
          '• Agent : Si vous travaillez pour une compagnie d\'assurance\n'
          '• Expert : Si vous êtes expert automobile\n'
          '• Administrateur : Si vous gérez le système',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// 📄 Dialog des conditions
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conditions d\'utilisation'),
        content: const Text(
          'En utilisant cette application, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.\n\n'
          'Cette application est destinée aux professionnels de l\'assurance et aux assurés en Tunisie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 📞 Dialog de contact
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nous contacter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pour toute question ou assistance :'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.email, size: 20),
                const SizedBox(width: 8),
                Text(AppConstants.supportEmail),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.web, size: 20),
                const SizedBox(width: 8),
                Text(AppConstants.helpUrl),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 🔐 Accès Super Admin discret
  Widget _buildSuperAdminAccess(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Accès Super Admin
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/super-admin-login');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              '🔐',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Interface de nettoyage (développement uniquement)
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/clean-firestore');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              '🧹',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
