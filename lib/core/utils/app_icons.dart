import 'package:flutter/material.dart';
import 'package:constat_tunisie/data/enums/user_role.dart';

class AppIcons {
  // Icônes pour les rôles
  static IconData getIconForRole(UserRole role) {
    switch (role) {
      case UserRole.driver:  // Changé de driver à conducteur
        return Icons.drive_eta;
      case UserRole.insurance:   // Changé de insurance à assurance
        return Icons.security;
      case UserRole.expert:
        return Icons.engineering;
      case UserRole.admin:       // Ajouté pour gérer tous les cas de l'enum
        return Icons.admin_panel_settings;
    }
  }

  // Icônes pour les actions
  static const IconData newReport = Icons.add_circle_outline;
  static const IconData myReports = Icons.history;
  static const IconData profile = Icons.person;
  static const IconData help = Icons.help_outline;
  static const IconData settings = Icons.settings;
  static const IconData logout = Icons.logout;
  static const IconData camera = Icons.camera_alt;
  static const IconData gallery = Icons.photo_library;
  static const IconData document = Icons.description;
  static const IconData location = Icons.location_on;
  static const IconData car = Icons.directions_car;
  static const IconData insurance = Icons.security;
  static const IconData expert = Icons.engineering;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData share = Icons.share;
  static const IconData download = Icons.download;
  static const IconData send = Icons.send;
  static const IconData notification = Icons.notifications;
  static const IconData info = Icons.info;
  static const IconData warning = Icons.warning;
  static const IconData success = Icons.check_circle;
  static const IconData error = Icons.error;
}