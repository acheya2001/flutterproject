import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../screens/login_screen.dart';
import 'professional_account_request_screen.dart';
import '../../../features/conducteur/screens/guest_join_session_screen.dart';

/// 👥 Écran de sélection du type d'utilisateur
class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F5F9), // Gris très clair
              Color(0xFFFFFFFF), // Blanc pur
              Color(0xFFF8FAFC), // Gris ultra-clair
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo moderne
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2563EB), // Bleu moderne
                        Color(0xFF1D4ED8), // Bleu foncé
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Titre de l'application
                const Text(
                  'Constat Tunisie',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B), // Gris foncé très lisible
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Assistant Intelligent d\'Assurance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Section titre avec fond
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Choisissez votre profil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B), // Très lisible
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez le type de compte qui correspond à votre profil',
                        style: TextStyle(
                          fontSize: 15,
                          color: const Color(0xFF64748B), // Gris moyen très lisible
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Options de types d'utilisateurs
                Expanded(
                  child: ListView(
                    children: [
                      _buildModernUserTypeCard(
                        context,
                        icon: Icons.person_outline,
                        title: 'Conducteur',
                        subtitle: '',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        onTap: () => _showConducteurOptions(context),
                      ),

                      const SizedBox(height: 16),

                      // Agent d'assurance
                      _buildModernUserTypeCard(
                        context,
                        icon: Icons.business_center_outlined,
                        title: 'Agent d\'Assurance',
                        subtitle: 'Gérer les contrats et les clients',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        onTap: () => _navigateToLogin(context, 'agent'),
                      ),

                      const SizedBox(height: 16),

                      // Expert automobile
                      _buildModernUserTypeCard(
                        context,
                        icon: Icons.engineering_outlined,
                        title: 'Expert Automobile',
                        subtitle: 'Évaluer les sinistres et rédiger des rapports',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                        ),
                        onTap: () => _navigateToLogin(context, 'expert'),
                      ),

                      const SizedBox(height: 16),

                      // Administrateur
                      _buildModernUserTypeCard(
                        context,
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Administrateur',
                        subtitle: 'Gérer le système et les utilisateurs',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        ),
                        onTap: () => _navigateToLogin(context, 'admin'),
                      ),

                      // Espace final pour éviter l'overflow
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Barre d'actions moderne
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.help_outline,
                        label: 'Aide',
                        onTap: () => _showHelpDialog(context),
                      ),
                      _buildActionButton(
                        icon: Icons.description_outlined,
                        label: 'Conditions',
                        onTap: () => _showTermsDialog(context),
                      ),
                      _buildActionButton(
                        icon: Icons.contact_support_outlined,
                        label: 'Contact',
                        onTap: () => _showContactDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Accès admin discret
                GestureDetector(
                  onTap: () => _handleSuperAdminAccess(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Accès Super Admin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                // Version de l'application
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(userType: userType),
      ),
    );
  }

  /// 🚗 Afficher les options pour les conducteurs
  void _showConducteurOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Choisissez votre situation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 20),

            // Option 1: Conducteur inscrit
            _buildConducteurOption(
              context,
              icon: Icons.account_circle,
              title: 'Conducteur',
              subtitle: 'J\'ai un compte et je veux déclarer un sinistre',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _navigateToLogin(context, 'driver');
              },
            ),

            const SizedBox(height: 16),

            // Option 2: Rejoindre en tant qu'invité
            _buildConducteurOption(
              context,
              icon: Icons.person_add,
              title: 'Rejoindre en tant qu\'Invité',
              subtitle: 'Je n\'ai pas de compte, rejoindre une session existante',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _navigateToGuestJoin(context);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToProfessionalRequest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfessionalAccountRequestScreen(),
      ),
    );
  }

  /// 🚗 Construire une option de conducteur
  Widget _buildConducteurOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎯 Naviguer vers l'écran de rejoindre en tant qu'invité
  void _navigateToGuestJoin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GuestJoinSessionScreen(),
      ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

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
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nous contacter'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pour toute question ou assistance :'),
            SizedBox(height: 16),
            Text('📧 Email: support@constat-tunisie.tn'),
            Text('📞 Téléphone: +216 XX XXX XXX'),
            Text('🌐 Site web: www.constat-tunisie.tn'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 🔐 Gérer l'accès Super Admin
  void _handleSuperAdminAccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Accès Super Admin'),
          ],
        ),
        content: const Text(
          'Accès réservé aux super administrateurs uniquement.\n\n'
          'Cet accès permet de gérer l\'ensemble du système.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/super-admin-dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accéder'),
          ),
        ],
      ),
    );
  }

  /// 🎨 Carte moderne de type d'utilisateur
  Widget _buildModernUserTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Icône avec fond blanc
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: const Color(0xFF1E293B), // Couleur foncée pour contraste
                  ),
                ),

                const SizedBox(width: 20),

                // Texte avec meilleur contraste
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Flèche avec fond
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔘 Bouton d'action moderne
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B), // Texte foncé très lisible
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}