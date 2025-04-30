import 'package:flutter/material.dart'; // Ajout de cet import pour Color et Colors

enum UserRole {
  driver,
  insurance,
  expert,
  admin,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.driver:
        return 'conducteur';
      case UserRole.insurance:
        return 'assurance';
      case UserRole.expert:
        return 'expert';
      case UserRole.admin:
        return 'admin';
    }
  }
  
  String get displayName {
    switch (this) {
      case UserRole.driver:
        return 'Conducteur';
      case UserRole.insurance:
        return 'Assurance';
      case UserRole.expert:
        return 'Expert';
      case UserRole.admin:
        return 'Administrateur';
    }
  }
  
  Color get color {
    switch (this) {
      case UserRole.driver:
        return Colors.blue;
      case UserRole.insurance:
        return Colors.green;
      case UserRole.expert:
        return Colors.orange;
      case UserRole.admin:
        return Colors.purple;
    }
  }
}