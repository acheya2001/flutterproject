class EmailValidator {
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    return emailRegex.hasMatch(email);
  }

  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email requis';
    }
    
    if (!isValid(email)) {
      return 'Format d\'email invalide';
    }
    
    return null;
  }
}
