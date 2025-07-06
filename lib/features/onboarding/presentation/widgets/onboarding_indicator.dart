import 'package:flutter/material.dart';

/// 🔘 Indicateur de pages pour l'onboarding
class OnboardingIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;
  final Color? activeColor;
  final Color? inactiveColor;

  const OnboardingIndicator({
    Key? key,
    required this.currentIndex,
    required this.totalPages,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => _buildDot(index),
      ),
    );
  }

  /// 🔘 Construire un point indicateur
  Widget _buildDot(int index) {
    final isActive = index == currentIndex;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? (activeColor ?? Colors.white)
            : (inactiveColor ?? Colors.white.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
