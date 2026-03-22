import 'package:flutter/material.dart';

import 'app_theme.dart';

class TextDesign {
  static final AppColors theme = AppThemes.color;

  TextStyle headingOne(Color? color, double? fontSize) => TextStyle(
    fontSize: fontSize ?? 24,
    fontWeight: FontWeight.bold,
    color: color ?? theme.onSurface,
  );

  TextStyle headingTwo(Color? color, double? fontSize) => TextStyle(
    fontSize: fontSize ?? 22,
    fontWeight: FontWeight.w600,
    color: color ?? theme.onSurface,
  );

  TextStyle headingThree(Color? color, double? fontSize) => TextStyle(
    fontSize: fontSize ?? 20,
    fontWeight: FontWeight.w600,
    color: color ?? theme.onSurface,
  );

  TextStyle largeText(Color? color, double? fontSize) => TextStyle(
    fontSize: fontSize ?? 18,
    fontWeight: FontWeight.w500,
    color: color ?? theme.onSurface,
  );

  TextStyle normalText(Color? color, double? fontSize) => TextStyle(
    fontSize: fontSize ?? 16,
    fontWeight: FontWeight.w400,
    color: color ?? theme.onSurface,
  );

  TextStyle smallText(Color? color, double? fontSize) => TextStyle(
    fontSize: fontSize ?? 14,
    fontWeight: FontWeight.w400,
    color: color ?? theme.onSurface.withOpacity(0.7),
  );


}