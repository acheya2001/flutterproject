import 'package:flutter/material.dart';

enum UserType {
  conducteur,
  assureur,
  expert,
}

extension UserTypeExtension on UserType {
  String get name {
    switch (this) {
      case UserType.conducteur:
        return 'Conducteur';
      case UserType.assureur:
        return 'Assureur';
      case UserType.expert:
        return 'Expert';
    }
  }

  IconData get icon {
    switch (this) {
      case UserType.conducteur:
        return Icons.drive_eta;
      case UserType.assureur:
        return Icons.business;
      case UserType.expert:
        return Icons.engineering;
    }
  }

  String get description {
    switch (this) {
      case UserType.conducteur:
        return 'Déclarez vos accidents et gérez vos véhicules';
      case UserType.assureur:
        return 'Gérez les dossiers de sinistres';
      case UserType.expert:
        return 'Réalisez des expertises de véhicules';
    }
  }

  List<String> get features {
    switch (this) {
      case UserType.conducteur:
        return [
          'Déclaration d\'accident',
          'Gestion de véhicules',
          'Suivi de dossiers',
        ];
      case UserType.assureur:
        return [
          'Gestion des sinistres',
          'Validation des déclarations',
          'Communication avec experts',
        ];
      case UserType.expert:
        return [
          'Expertise de véhicules',
          'Rapports d\'expertise',
          'Estimation des dommages',
        ];
    }
  }
}
