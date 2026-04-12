import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class SocialAuthButton extends StatelessWidget {
  final String text;
  final String assetIcon;
  final VoidCallback onPressed;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.assetIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: theme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetIcon,
              height: 20,
              errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, color: Colors.red),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextDesign.mediumText(color: theme.onSurface, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
