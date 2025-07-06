import 'package:flutter/material.dart';

import '../../models/onboarding_page_model.dart';

/// 📄 Widget pour une page d'onboarding
class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPageModel page;
  final bool isActive;

  const OnboardingPageWidget({
    Key? key,
    required this.page,
    required this.isActive,
  }) : super(key: key);

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _featuresController;
  
  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _featuresOpacity;
  late Animation<Offset> _featuresSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.isActive) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(OnboardingPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    } else if (!widget.isActive && oldWidget.isActive) {
      _resetAnimations();
    }
  }

  /// 🎬 Initialisation des animations
  void _initializeAnimations() {
    // Animation de l'icône
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _iconRotation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOut,
    ));

    // Animation du texte
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Animation des fonctionnalités
    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _featuresOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _featuresController,
      curve: Curves.easeIn,
    ));

    _featuresSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _featuresController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// 🎭 Démarrer les animations
  void _startAnimations() async {
    _iconController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _featuresController.forward();
  }

  /// 🔄 Réinitialiser les animations
  void _resetAnimations() {
    _iconController.reset();
    _textController.reset();
    _featuresController.reset();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          
          // 🎯 Icône animée
          _buildAnimatedIcon(),
          
          const SizedBox(height: 48),
          
          // 📝 Titre et description
          _buildAnimatedText(),
          
          const SizedBox(height: 32),
          
          // ✨ Liste des fonctionnalités
          if (widget.page.features != null)
            _buildAnimatedFeatures(),
          
          const Spacer(),
        ],
      ),
    );
  }

  /// 🎯 Icône animée
  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Transform.scale(
          scale: _iconScale.value,
          child: Transform.rotate(
            angle: _iconRotation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                widget.page.icon,
                size: 64,
                color: widget.page.iconColor,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 📝 Texte animé
  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: Opacity(
            opacity: _textOpacity.value,
            child: Column(
              children: [
                Text(
                  widget.page.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.page.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✨ Fonctionnalités animées
  Widget _buildAnimatedFeatures() {
    return AnimatedBuilder(
      animation: _featuresController,
      builder: (context, child) {
        return SlideTransition(
          position: _featuresSlide,
          child: Opacity(
            opacity: _featuresOpacity.value,
            child: Column(
              children: widget.page.features!.asMap().entries.map((entry) {
                final index = entry.key;
                final feature = entry.value;
                
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween<double>(
                    begin: widget.isActive ? 0.0 : 1.0,
                    end: widget.isActive ? 1.0 : 0.0,
                  ),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * 20),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
