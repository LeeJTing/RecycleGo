import 'package:flutter/material.dart';

class AppThemes {
  // ========== LIGHT THEME ==========
  // Used when the device is in light mode or user explicitly selects light theme.
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    // Primary color: Forest Green (#2E7D32)
    // Represents nature, recycling, and sustainability. Used for:
    // - App bar background
    // - FAB (Floating Action Button)
    // - Selected tab indicators
    // - Primary buttons
    primaryColor: const Color(0xFF2E7D32),

    // ColorScheme is the modern theming system in Flutter.
    // It defines a set of colors that work together harmoniously.
    colorScheme: const ColorScheme.light(
      // Main brand color – green for eco-friendliness
      primary: Color(0xFF2E7D32),

      // Secondary color – ocean blue (#0288D1)
      // Symbolizes clean water and environment. Used for:
      // - Secondary buttons
      // - Links
      // - Selection controls (checkboxes, switches)
      secondary: Color(0xFF0288D1),

      // Background color – light gray (#F5F5F5)
      // Used behind scrollable content (scaffold background)
      background: Color(0xFFF5F5F5),

      // Surface color – pure white (#FFFFFF)
      // Used for cards, dialogs, menus, and bottom sheets
      surface: Color(0xFFFFFFFF),

      // Error color – standard Material red (#B00020)
      error: Color(0xFFB00020),

      // ===== "on" colors =====
      // These are foreground colors (text/icons) painted on top of the corresponding background.
      // They must have enough contrast for readability.

      // Text/icons on primary-colored surfaces (e.g., app bar title)
      onPrimary: Colors.white,

      // Text/icons on secondary-colored surfaces
      onSecondary: Colors.white,

      // Text/icons on background (e.g., body text)
      onBackground: Colors.black87, // High-emphasis text

      // Text/icons on surface (cards, dialogs)
      onSurface: Colors.black87,

      // Text/icons on error color (e.g., error message inside a red toast)
      onError: Colors.white,
    ),

    // AppBar theme – applies to all AppBars unless overridden
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E7D32), // Same as primary
      foregroundColor: Colors.white,      // Title and icons
      elevation: 0, // Optional: removes shadow for cleaner look
    ),

    // You can also customize:
    // - TextTheme (font sizes, weights)
    // - Button themes
    // - Input decoration themes
  );

  // ========== DARK THEME ==========
  // Used when the device is in dark mode or user selects dark theme.
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    // Primary color in dark mode: lighter green (#4CAF50)
    // Brighter colors work better on dark backgrounds while keeping the eco identity.
    primaryColor: const Color(0xFF4CAF50),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4CAF50),   // Lighter green
      secondary: Color(0xFF4FC3F7), // Sky blue – brighter for dark mode
      background: Color(0xFF121212), // Standard dark background (Material Design)
      surface: Color(0xFF1E1E1E),    // Slightly lighter than background for cards
      error: Color(0xFFCF6679),      // Recommended error color for dark themes

      // "on" colors for dark mode:
      onPrimary: Colors.black,       // Dark text on light green primary
      onSecondary: Colors.black,     // Dark text on secondary
      onBackground: Colors.white,    // Light text on dark background
      onSurface: Colors.white,       // Light text on surface
      onError: Colors.black,         // Dark text on error color
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E), // Surface color for app bar
      foregroundColor: Colors.white,
    ),
  );
}