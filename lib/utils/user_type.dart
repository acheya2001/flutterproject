import 'package:flutter/material.dart';

enum UserType {
  conducteur,
  assureur,
  expert,
  administrateur,
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.conducteur:
        return 'Conducteur';
      case UserType.assureur:
        return 'Assureur';
      case UserType.expert:
        return 'Expert';
      case UserType.administrateur:
        return 'Administrateur';
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
      case UserType.administrateur:
        return 'Administrez et supervisez le système';
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
      case UserType.administrateur:
        return [
          'Validation des comptes',
          'Supervision du système',
          'Gestion des utilisateurs',
        ];
    }
  }

  IconData get icon {
    switch (this) {
      case UserType.conducteur:
        return Icons.directions_car;
      case UserType.assureur:
        return Icons.business;
      case UserType.expert:
        return Icons.engineering;
      case UserType.administrateur:
        return Icons.admin_panel_settings;
    }
  }

  Color get color {
    switch (this) {
      case UserType.conducteur:
        return Colors.blue;
      case UserType.assureur:
        return Colors.green;
      case UserType.expert:
        return Colors.orange;
      case UserType.administrateur:
        return Colors.red;
    }
  }
}