import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class AuthLabel extends StatelessWidget {
  final String text;
  final bool isValid;

  const AuthLabel({
    super.key,
    required this.text,
    this.isValid = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextDesign.label(color: theme.onSurface, fontSize: 13).copyWith(fontWeight: FontWeight.w600),
          ),
          if (isValid)
            Icon(Icons.check_circle_outline_rounded, color: theme.primary, size: 18),
        ],
      ),
    );
  }
}
