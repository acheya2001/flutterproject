import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'modern_accident_type_screen.dart';
import 'join_session_screen.dart';

  /// 🎯 Écran de choix moderne entre créer une session ou rejoindre une session
class AccidentSessionChoiceScreen extends StatefulWidget {
  const AccidentSessionChoiceScreen({Key? key}) : super(key: key);

  @override
  State<AccidentSessionChoiceScreen> createState() => _AccidentSessionChoiceScreenState();
}

class _AccidentSessionChoiceScreenState extends State<AccidentSessionChoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _cardStaggerAnimation;

  @override
  void initState() {
    super.initState();

    // Animation principale
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animation des cartes
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _cardStaggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Démarrer les animations
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            'Déclarer un Accident',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
              Color(0xFF000DFF),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isSmallScreen ? 10 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 20 : 40),

                      // Icône principale avec animation
                      _buildAnimatedIcon(),

                      SizedBox(height: isSmallScreen ? 20 : 30),

                      // Titre principal avec effet de gradient
                      _buildGradientTitle(),

                      SizedBox(height: isSmallScreen ? 8 : 16),

                      // Sous-titre élégant
                      _buildSubtitle(),

                      SizedBox(height: isSmallScreen ? 30 : 50),

                      // Cartes d'options avec animation décalée
                      _buildAnimatedChoiceCards(),

                      SizedBox(height: isSmallScreen ? 20 : 30),

                      // Information en bas avec design moderne
                      _buildModernInfoCard(),

                      SizedBox(height: isSmallScreen ? 10 : 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 Icône principale animée
  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: (0.8 + (_scaleAnimation.value.clamp(0.0, 1.0) * 0.2)).clamp(0.1, 2.0),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 40,
            ),
          ),
        );
      },
    );
  }

  /// 🎨 Titre avec effet de gradient
  Widget _buildGradientTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFE0E7FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: const Text(
        'Comment souhaitez-vous\nprocéder ?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  /// 🎨 Sous-titre élégant
  Widget _buildSubtitle() {
    return Text(
      'Choisissez votre mode de déclaration d\'accident',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.85),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
    );
  }

  /// 🎨 Cartes d'options avec animation décalée
  Widget _buildAnimatedChoiceCards() {
    return AnimatedBuilder(
      animation: _cardStaggerAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Première carte avec délai
            Transform.translate(
              offset: Offset(0, 50 * (1 - _cardStaggerAnimation.value.clamp(0.0, 1.0))),
              child: Opacity(
                opacity: _cardStaggerAnimation.value.clamp(0.0, 1.0),
                child: _buildModernChoiceCard(
                  icon: Icons.add_circle_outline,
                  title: 'Créer une Session',
                  subtitle: 'Démarrer un nouveau constat\net inviter d\'autres conducteurs',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _creerNouvelleSession(),
                  delay: 0,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Deuxième carte avec délai plus long
            Transform.translate(
              offset: Offset(0, 50 * (1 - _cardStaggerAnimation.value.clamp(0.0, 1.0))),
              child: Opacity(
                opacity: _cardStaggerAnimation.value.clamp(0.0, 1.0),
                child: _buildModernChoiceCard(
                  icon: Icons.login,
                  title: 'Rejoindre une Session',
                  subtitle: 'Participer à un constat\ndéjà créé par un autre conducteur',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _rejoindreSession(),
                  delay: 200,
                ),
              ),
            ),


          ],
        );
      },
    );
  }

  /// 🎨 Carte de choix moderne avec glassmorphism
  Widget _buildModernChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icône avec gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 20),

                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Flèche avec animation
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 Carte d'information moderne
  Widget _buildModernInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Les deux options permettent de créer un constat officiel valide',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 Créer une nouvelle session avec animation
  void _creerNouvelleSession() {
    try {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ModernAccidentTypeScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: animation.drive(Tween(begin: 0.0, end: 1.0)),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('❌ Erreur navigation vers ModernAccidentTypeScreen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔗 Rejoindre une session existante avec animation
  void _rejoindreSession() {
    try {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const JoinSessionScreen(isRegisteredUser: true),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: animation.drive(Tween(begin: 0.0, end: 1.0)),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('❌ Erreur navigation vers JoinSessionScreen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
