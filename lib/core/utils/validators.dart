class Validators {
  static String? Function(String?) required(String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return message;
      }
      return null;
    };
  }

  static String? Function(String?) integer(String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      if (int.tryParse(value) == null) {
        return message;
      }
      return null;
    };
  }

  static String? Function(String?) min(int minValue, String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final intValue = int.tryParse(value);
      if (intValue == null || intValue < minValue) {
        return message;
      }
      return null;
    };
  }

  static String? Function(String?) max(int maxValue, String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final intValue = int.tryParse(value);
      if (intValue == null || intValue > maxValue) {
        return message;
      }
      return null;
    };
  }

  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  static String? Function(String?) email(String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';      final phoneRegex = RegExp(r'^\+?[0-9]{8,}$';}