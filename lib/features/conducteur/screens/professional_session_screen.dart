import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../constat/providers/collaborative_session_provider.dart';
import '../widgets/professional_join_session_widget.dart';

/// 🎯 Écran professionnel pour les sessions collaboratives
/// 
/// Interface moderne et intuitive pour rejoindre ou gérer les sessions
/// avec animations fluides et feedback utilisateur.
class ProfessionalSessionScreen extends StatefulWidget {
  final String? sessionCode;

  const ProfessionalSessionScreen({
    Key? key,
    this.sessionCode,
  }) : super(key: key);

  @override
  State<ProfessionalSessionScreen> createState() => _ProfessionalSessionScreenState();
}

class _ProfessionalSessionScreenState extends State<ProfessionalSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Session Collaborative',
        backgroundColor: Color(0xFF6366F1),
      ),
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF8FAFC),
                  Color.lerp(
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                    _backgroundAnimation.value,
                  )!,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 32),
                    _buildJoinSessionCard(),
                    const SizedBox(height: 24),
                    _buildFeaturesSection(),
                    const SizedBox(height: 24),
                    _buildStatusSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour ${user?.prenom ?? 'Conducteur'} !',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Prêt pour un constat collaboratif ?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Rejoignez une session existante ou attendez qu\'un autre conducteur vous invite.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJoinSessionCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ProfessionalJoinSessionWidget(
        initialSessionCode: widget.sessionCode,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avantages du Constat Collaboratif',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.speed,
          title: 'Plus Rapide',
          description: 'Chacun remplit sa partie simultanément',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.verified,
          title: 'Plus Précis',
          description: 'Validation croisée des informations',
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.cloud_sync,
          title: 'Synchronisé',
          description: 'Données sauvegardées en temps réel',
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Consumer<CollaborativeSessionProvider>(
      builder: (context, provider, child) {
        if (!provider.hasSession) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Session Active',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Code: ${provider.currentSession?.sessionCode ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.getSessionStatus(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
