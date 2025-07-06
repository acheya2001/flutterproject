import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 🎯 Logo animé pour l'application
class AnimatedLogo extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool autoStart;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;

  const AnimatedLogo({
    Key? key,
    this.size = 120.0,
    this.backgroundColor,
    this.iconColor,
    this.autoStart = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.autoStart) {
      _startAnimation();
    }
  }

  /// 🎬 Initialisation des animations
  void _initializeAnimations() {
    // Animation principale
    _mainController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: widget.backgroundColor ?? AppTheme.primaryColor,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    // Animation de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animation de rotation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // Écouter la fin de l'animation principale
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
        _startContinuousAnimations();
      }
    });
  }

  /// 🎭 Démarrer l'animation
  void _startAnimation() {
    _mainController.forward();
  }

  /// 🔄 Démarrer les animations continues
  void _startContinuousAnimations() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat(reverse: true);
  }

  /// ⏹️ Arrêter toutes les animations
  void stopAnimations() {
    _mainController.stop();
    _pulseController.stop();
    _rotationController.stop();
  }

  /// 🔄 Redémarrer l'animation
  void restartAnimation() {
    _mainController.reset();
    _pulseController.reset();
    _rotationController.reset();
    _startAnimation();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _pulseController,
        _rotationController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  borderRadius: BorderRadius.circular(widget.size * 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? AppTheme.primaryColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _colorAnimation.value ?? AppTheme.primaryColor,
                      (_colorAnimation.value ?? AppTheme.primaryColor)
                          .withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.directions_car,
                  size: widget.size * 0.5,
                  color: widget.iconColor ?? Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 🌟 Logo avec effet de particules
class ParticleAnimatedLogo extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const ParticleAnimatedLogo({
    Key? key,
    this.size = 120.0,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  State<ParticleAnimatedLogo> createState() => _ParticleAnimatedLogoState();
}

class _ParticleAnimatedLogoState extends State<ParticleAnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late List<Animation<Offset>> _particleAnimations;
  late List<Animation<double>> _particleOpacities;

  @override
  void initState() {
    super.initState();
    _initializeParticleAnimations();
    _particleController.repeat();
  }

  /// 🌟 Initialisation des animations de particules
  void _initializeParticleAnimations() {
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _particleAnimations = List.generate(8, (index) {
      final angle = (index * 45) * (3.14159 / 180); // Convertir en radians
      return Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          0.5 * (widget.size / 120) * (index % 2 == 0 ? 1 : -1),
          0.5 * (widget.size / 120) * (index % 3 == 0 ? 1 : -1),
        ),
      ).animate(CurvedAnimation(
        parent: _particleController,
        curve: Interval(
          index * 0.1,
          0.8 + (index * 0.02),
          curve: Curves.easeOut,
        ),
      ));
    });

    _particleOpacities = List.generate(8, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _particleController,
        curve: Interval(
          index * 0.1,
          0.5 + (index * 0.05),
          curve: Curves.easeInOut,
        ),
      ));
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particules
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _particleAnimations[index].value * 50,
                  child: Opacity(
                    opacity: _particleOpacities[index].value,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ?? AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Logo principal
          AnimatedLogo(
            size: widget.size,
            backgroundColor: widget.backgroundColor,
            iconColor: widget.iconColor,
          ),
        ],
      ),
    );
  }
}
