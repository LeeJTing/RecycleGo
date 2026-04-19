class Validators {
  /// Validates full name: Only letters and spaces allowed.
  static bool isValidName(String name) {
    if (name.isEmpty || name.trim().isEmpty) return false;
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    return nameRegExp.hasMatch(name);
  }

  /// Validates email format.
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  /// Calculates password strength (0-4) based on criteria.
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int points = 0;

    // 1. Length 7-12
    if (password.length >= 7 && password.length <= 12) points++;

    // 2. Both Uppercase and Lowercase
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) points++;

    // 3. Including number
    if (password.contains(RegExp(r'[0-9]'))) points++;

    // 4. Including special character
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) points++;

    return points;
  }

  /// Checks if all password criteria are met (at least strength 3).
  static bool isPasswordSecure(String password) {
    return getPasswordStrength(password) >= 3;
  }

  /// Validates phone number based on country code.
  /// If phone is empty, it's considered valid (as it's optional).
  static bool isValidPhoneNumber(String phone, String countryCode) {
    if (phone.isEmpty) return true;

    // Remove any non-digit characters
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    // Handle leading zero if present (common in Malaysia +60)
    if (countryCode == '+60' && cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }

    switch (countryCode) {
      case '+60': // Malaysia: Mobile numbers are usually 9 or 10 digits after prefix
        return cleanPhone.length == 9 || cleanPhone.length == 10;
      case '+65': // Singapore: 8 digits
        return cleanPhone.length == 8;
      case '+1':  // USA/Canada: 10 digits
        return cleanPhone.length == 10;
      case '+44': // UK: 10 digits (mobile)
        return cleanPhone.length == 10;
      case '+86': // China: 11 digits
        return cleanPhone.length == 11;
      case '+91': // India: 10 digits
        return cleanPhone.length == 10;
      default:
        return cleanPhone.length >= 8 && cleanPhone.length <= 15;
    }
  }

  static String? requiredText(String? val) {
    if (val == null || val.trim().isEmpty) return "This field is required";
    return null;
  }

  static String? requiredNumber(String? val) {
    if (val == null || val.trim().isEmpty) return "Required";
    final number = double.tryParse(val.trim());
    if (number == null) return "Invalid number format";
    if (number < 0) return "Cannot be negative";
    return null;
  }

  static String? optionalNumber(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final number = double.tryParse(val.trim());
    if (number == null) return "Invalid number format";
    if (number < 0) return "Cannot be negative";
    return null;
  }

}
