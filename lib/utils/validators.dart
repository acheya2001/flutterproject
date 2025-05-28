// lib/utils/validators.dart
class Validators {
  // Valider une plaque d'immatriculation tunisienne
  static bool isTunisianLicensePlate(String value) {
    // Format: 123 TUN 4567 ou 123TUN4567 ou 123 TUN 456
    final regex = RegExp(r'^(\d{1,3})\s*(TUN|تونس)\s*(\d{3,4})$', caseSensitive: false);
    return regex.hasMatch(value.trim());
  }

  // Valider un numéro de téléphone tunisien
  static bool isTunisianPhoneNumber(String value) {
    // Format: +216 12 345 678 ou 12345678
    final regex = RegExp(r'^(?:\+216)?\s*\d{2}\s*\d{3}\s*\d{3}$');
    return regex.hasMatch(value.trim());
  }

  // Valider un email
  static bool isValidEmail(String value) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(value.trim());
  }

  // Valider une date future
  static bool isFutureDate(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(now);
  }

  // Valider une date passée
  static bool isPastDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }

  // Valider un intervalle de dates
  static bool isValidDateRange(DateTime startDate, DateTime endDate) {
    return endDate.isAfter(startDate);
  }
}