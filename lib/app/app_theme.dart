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

  final Color errorContainer;
  final Color onErrorContainer;

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
    required this.warningContainer,
    required this.appbarBackground,
    required this.appbarTitle,
    required this.errorContainer,
    required this.onErrorContainer,
  });
}

class AppThemes extends ChangeNotifier {
  static String _currentTheme = 'light';
  static final AppThemes _instance = AppThemes._internal();

  static AppColors get color => (_currentTheme == 'light' ? _light : _dark);

  static String get currentTheme => _currentTheme;

  factory AppThemes() {
    return _instance;
  }

  AppThemes._internal();

  void setTheme(String theme) {
    if (theme == 'light mode') theme = 'light';
    if (theme == 'dark mode') theme = 'dark';

    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _currentTheme = _currentTheme == 'light' ? 'dark' : 'light';
    notifyListeners();
  }

  static const _light = AppColors(
    appbarBackground: Color(0xFFB5B5B5),
    appbarTitle: Color(0xFFFFFFFF),

    primary: Color(0xFF1DC964),
    secondary: Color(0xFF0288D1),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF8F8F8),
    hint: Color(0xFFBDBDBD),
    error: Color(0xFFE53935),
    success: Color(0xFF1DC964),
    successContainer: Color(0xFFDCFCE7),
    onSuccessContainer: Color(0xFF15803D),
    warning: Color(0xFFFFA000),

    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF212121),
    onSurface: Color(0xFF212121),
    onError: Color(0xFFFFFFFF),
    onHint: Color(0xFF757575),
    border: Color(0xFFEEEEEE),
    shadow: Color(0x1F000000),
    warningContainer: Color(0xFFFEF3C7),

    errorContainer: Color(0xFFFFE4E6),
    onErrorContainer: Color(0xFF7F1D1D),
  );

  static const _dark = AppColors(
    appbarBackground: Color(0xFF333333),
    appbarTitle: Color(0xFFFFFFFF),

    primary: Color(0xFF1DC964),
    secondary: Color(0xFF4FC3F7),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2C2C2C),
    hint: Color(0xFF757575),
    error: Color(0xFFCF6679),
    success: Color(0xFF1DC964),
    successContainer: Color(0xFF064E3B),
    onSuccessContainer: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),

    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFECACA),

    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),
    onBackground: Color(0xFFFFFFFF),
    onSurface: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
    onHint: Color(0xFF878787),
    border: Color(0xFF2E2E2E),
    shadow: Color(0xFF000000),
    warningContainer: Color(0xFF451A03),
  );
}