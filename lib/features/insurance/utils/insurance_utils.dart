import 'package:flutter/material.dart';
import 'insurance_colors.dart';

/// 🛠️ Utilitaires pour l'assurance
class InsuranceUtils {
  /// Formater un montant en dinars tunisiens
  static String formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} TND';
  }

  /// Formater une date
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Calculer les jours restants
  static int daysRemaining(DateTime endDate) {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  /// Vérifier si un contrat expire bientôt
  static bool isExpiringSoon(DateTime endDate, {int daysThreshold = 30}) {
    final remaining = daysRemaining(endDate);
    return remaining <= daysThreshold && remaining > 0;
  }

  /// Obtenir la couleur de statut
  static Color getStatusColor(bool isActive, bool isExpiring) {
    if (!isActive) return InsuranceColors.error;
    if (isExpiring) return InsuranceColors.warning;
    return InsuranceColors.success;
  }

  /// Obtenir le texte de statut
  static String getStatusText(bool isActive, bool isExpiring) {
    if (!isActive) return 'Expiré';
    if (isExpiring) return 'Expire bientôt';
    return 'Actif';
  }
}
