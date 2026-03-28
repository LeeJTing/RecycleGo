import 'package:flutter/material.dart';
class AppColors {
  final Color appbarBackground;
  final Color appbarTitle;

  final Color primary;
  final Color secondary;
  final Color background;
  final Color hint;
  final Color surface;
  final Color surfaceVariant;
  final Color error;
  final Color warning;

  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onHint;
  final Color onSurface;
  final Color onError;

  final Color border;
  final Color shadow;

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warningContainer;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.onError,
    required this.border,
    required this.shadow,
    required this.hint,
    required this.onHint,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer
  });
}

class AppThemes {

  static String _currentTheme = 'light';

  static final AppThemes _instance = AppThemes._internal();

  static AppColors get color => (_currentTheme == 'light' ? _light : _dark);

  factory AppThemes() {
    return _instance;
  }

  AppThemes._internal();


  void toggleTheme() {
    _currentTheme = _currentTheme == 'light' ? 'dark' : 'light';
  }

  static const _light = AppColors(
    appbarBackground: Color(0xFFB5B5B5),
    appbarTitle: Color(0xFFFFFFFF),

    primary: Color(0xFF0BB110),
    secondary: Color(0xFF0288D1),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F1F1),
    hint: Color(0xFF878787),
    error: Color(0xFFB00020),
    success: Color(0xFF22C55E),
    successContainer: Color(0xFFDCFCE7),
    onSuccessContainer: Color(0xFF15803D),
    warning: Color(0xFFF59E0B),

    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xDD000000),
    onSurface: Color(0xDD000000),
    onError: Color(0xFFD30000),
    onHint: Color(0xFF878787),
    border: Color(0xFFDFE2DF),
    shadow: Color(0xFFB00020),
    warningContainer: Color(0xFFFEF3C7),
  );

  static const _dark = AppColors(
    warning: Color(0xFFFBBF24),
    primary: Color(0xFF1B5E20),
    secondary: Color(0xFF4FC3F7),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2C2C2C),
    hint: Color(0xFF878787),
    error: Color(0xFFCF6679),
    success: Color(0xFF22C55E),
    successContainer: Color(0xFF064E3B),
    onSuccessContainer: Color(0xFF34D399),
    warningContainer: Color(0xFF451A03),

    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),
    onBackground: Color(0xFFFFFFFF),
    onSurface: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
    onHint: Color(0xFF878787),
    border: Color(0xFF2E2E2E),
    shadow: Color(0xFF8C001C),
  );
}


