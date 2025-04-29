import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';

enum UserRole {
  driver,
  insurance,
  expert;
  
  String get displayName {
    switch (this) {
      case UserRole.driver:
        return 'Conducteur';
      case UserRole.insurance:
        return 'Assurance';
      case UserRole.expert:
        return 'Expert';
    }
  }
  
  Color get color {
    switch (this) {
      case UserRole.driver:
        return AppTheme.driverColor;
      case UserRole.insurance:
        return AppTheme.insuranceColor;
      case UserRole.expert:
        return AppTheme.expertColor;
    }
  }
  
  IconData get icon {
    switch (this) {
      case UserRole.driver:
        return Icons.drive_eta;
      case UserRole.insurance:
        return Icons.security;
      case UserRole.expert:
        return Icons.engineering;
    }
  }
}