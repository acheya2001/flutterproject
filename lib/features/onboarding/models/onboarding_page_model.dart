import 'package:flutter/material.dart';

/// 📄 Modèle pour une page d'onboarding
class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String? imagePath;
  final List<String>? features;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.imagePath,
    this.features,
  });

  /// 📊 Données des pages d'onboarding
  static List<OnboardingPageModel> get pages => [
    // Page 1: Bienvenue
    const OnboardingPageModel(
      title: 'Bienvenue sur Constat Tunisie',
      description: 'L\'application qui simplifie la déclaration d\'accidents et la gestion de vos assurances en Tunisie.',
      icon: Icons.waving_hand,
      backgroundColor: Color(0xFF6366F1), // Indigo
      iconColor: Colors.white,
      features: [
        'Déclaration d\'accidents rapide',
        'Gestion des contrats d\'assurance',
        'Suivi des sinistres en temps réel',
      ],
    ),

    // Page 2: Déclaration d'accidents
    const OnboardingPageModel(
      title: 'Déclaration d\'Accidents Simplifiée',
      description: 'Déclarez vos accidents en quelques minutes avec notre interface intuitive et nos formulaires pré-remplis.',
      icon: Icons.car_crash,
      backgroundColor: Color(0xFF10B981), // Emerald
      iconColor: Colors.white,
      features: [
        'Formulaires intelligents',
        'Photos et géolocalisation',
        'Envoi automatique aux assureurs',
      ],
    ),

    // Page 3: Collaboration
    const OnboardingPageModel(
      title: 'Collaboration en Temps Réel',
      description: 'Invitez les autres conducteurs impliqués pour compléter le constat ensemble, où qu\'ils soient.',
      icon: Icons.people,
      backgroundColor: Color(0xFF8B5CF6), // Violet
      iconColor: Colors.white,
      features: [
        'Invitations par email',
        'Édition collaborative',
        'Validation mutuelle',
      ],
    ),

    // Page 4: Gestion des contrats
    const OnboardingPageModel(
      title: 'Gestion Complète des Contrats',
      description: 'Centralisez tous vos contrats d\'assurance et véhicules dans une seule application sécurisée.',
      icon: Icons.description,
      backgroundColor: Color(0xFFF59E0B), // Amber
      iconColor: Colors.white,
      features: [
        'Stockage sécurisé',
        'Rappels d\'échéances',
        'Historique complet',
      ],
    ),

    // Page 5: Expertise
    const OnboardingPageModel(
      title: 'Expertise Professionnelle',
      description: 'Bénéficiez de l\'expertise de professionnels qualifiés pour l\'évaluation de vos sinistres.',
      icon: Icons.verified,
      backgroundColor: Color(0xFFEF4444), // Red
      iconColor: Colors.white,
      features: [
        'Experts certifiés',
        'Évaluations précises',
        'Rapports détaillés',
      ],
    ),

    // Page 6: Commencer
    const OnboardingPageModel(
      title: 'Prêt à Commencer ?',
      description: 'Rejoignez des milliers d\'utilisateurs qui font confiance à Constat Tunisie pour leurs assurances.',
      icon: Icons.rocket_launch,
      backgroundColor: Color(0xFF06B6D4), // Cyan
      iconColor: Colors.white,
      features: [
        'Inscription gratuite',
        'Interface intuitive',
        'Support client 24/7',
      ],
    ),
  ];

  /// 🎨 Couleurs de gradient pour chaque page
  static List<Color> getGradientColors(int index) {
    final page = pages[index];
    return [
      page.backgroundColor,
      page.backgroundColor.withValues(alpha: 0.8),
    ];
  }

  /// 📱 Obtenir la page par index
  static OnboardingPageModel getPage(int index) {
    if (index >= 0 && index < pages.length) {
      return pages[index];
    }
    return pages[0];
  }

  /// 📊 Nombre total de pages
  static int get totalPages => pages.length;

  /// 🔍 Vérifier si c'est la dernière page
  static bool isLastPage(int index) => index == pages.length - 1;

  /// 🔍 Vérifier si c'est la première page
  static bool isFirstPage(int index) => index == 0;
}
