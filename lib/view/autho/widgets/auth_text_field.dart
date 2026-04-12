import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? borderColor;
  final String? errorText;
  final Function(String)? onChanged;
  final bool? readOnly;
  final bool? filled;
  final Color? fillColor;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.borderColor,
    this.errorText,
    this.onChanged,
    this.readOnly, this.filled,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadow.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            readOnly: readOnly ?? false,
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextDesign.normalText(fontSize: 14),
            decoration: InputDecoration(
              filled: filled ?? false,
              fillColor: fillColor ?? theme.surface,
              hintText: hintText,
              hintStyle: TextDesign.hintText(color: theme.onHint, fontSize: 14),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: borderColor ?? theme.border),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.primary, width: 1.2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.error_outline_rounded, color: theme.error, size: 12),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: TextDesign.smallText(color: theme.error, fontSize: 11),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
