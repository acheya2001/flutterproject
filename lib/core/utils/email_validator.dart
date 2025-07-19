class EmailValidator {
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';      return 'Email requis';      return 'Format d\'email invalide';