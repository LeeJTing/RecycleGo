import 'package:flutter/material.dart';
class AppColors {
  final Color appbarBackground;
  final Color appbarTitle;

  final Color primary;
  final Color secondary;
  final Color background;
  final Color hint;
  final Color surface;
  final Color error;

  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onHint;
  final Color onSurface;
  final Color onError;

  final Color border;
  final Color shadow;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
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
    required this.appbarBackground,
    required this.appbarTitle,
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
    hint: Color(0xFF878787),
    error: Color(0xFFB00020),

    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xDD000000),
    onSurface: Color(0xDD000000),
    onError: Color(0xFFD30000),
    onHint: Color(0xFF878787),
    border: Color(0xFFDFE2DF),
    shadow: Color(0xFFB00020),
  );

  static const _dark = AppColors(
    appbarBackground: Color(0xFFFFFFFF),
    appbarTitle: Color(0xFF000000),

    primary: Color(0xFF1B5E20),
    secondary: Color(0xFF4FC3F7),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    hint: Color(0xFF878787),
    error: Color(0xFFCF6679),

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


