class Validators {
  /// Validates full name: Only letters and spaces allowed.
  static bool isValidName(String name) {
    if (name.isEmpty) return false;
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

  /// Checks if all password criteria are met (strength 4).
  static bool isPasswordSecure(String password) {
    return getPasswordStrength(password) == 4;
  }
}
