import 'package:flutter/material.dart';

import 'app_theme.dart';

class TextDesign {
  static final TextDesign _instance = TextDesign._internal();

  TextDesign._internal();

  factory TextDesign() => _instance;

  static final AppColors theme = AppThemes.color;

  static TextStyle headingOne({Color? color, double fontSize = 24, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? theme.onSurface,
  );

  static TextStyle headingTwo({Color? color, double fontSize = 22, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w600,
    color: color ?? theme.onSurface,
  );

  static TextStyle headingThree({Color? color, double fontSize = 20, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w600,
    color: color ?? theme.onSurface,
  );

  static TextStyle largeText({Color? color, double fontSize = 18, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w500,
    color: color ?? theme.onSurface,
  );

  static TextStyle normalText({Color? color, double fontSize = 16, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color ?? theme.onSurface,
  );

  static TextStyle smallText({Color? color, double fontSize = 14, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color ?? theme.onSurface.withOpacity(0.7),
  );

  static TextStyle appBarTitle({Color? color, double fontSize = 18, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w600,
    color: color ?? theme.onSurface,
    letterSpacing: 0.2,
  );

  static TextStyle mediumText({Color? color, double fontSize = 16, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w500, // Medium weight
    color: color ?? theme.onSurface,
  );

  // For the RM 45.00 price display in your History Cards
  static TextStyle priceText({Color? color, double fontSize = 18, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? theme.primary, // Defaults to your Eco-Green
    letterSpacing: 0.5,
  );

  // For "Plastic", "Metal", or "Completed" status chips
  static TextStyle badgeText({Color? color, double fontSize = 12, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? theme.onSurface,
    letterSpacing: 0.8,
  );

  static TextStyle hintText({Color? color, double fontSize = 14, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: color ?? theme.hint,
  );

  static TextStyle buttonText({Color? color, double fontSize = 16, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle label({Color? color, double fontSize = 12, FontWeight? fontWeight}) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.bold,
    color: color ?? theme.onSurface.withOpacity(0.5),
    letterSpacing: 1.1, // Spaced out for a modern "Label" look
  );
}