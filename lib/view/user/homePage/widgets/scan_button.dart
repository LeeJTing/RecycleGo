import 'package:flutter/material.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';

class ScanButton extends StatelessWidget {
  const ScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, Routes.scanRecycleItem),  //Routes.qrScan
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.02, horizontal: size.width * 0.05),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primary, theme.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Recyclable',
                  style: TextDesign.buttonText(fontSize: size.width * 0.045),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-powered identification',
                  style: TextDesign.smallText(color: theme.onPrimary.withOpacity(0.8), fontSize: size.width * 0.035),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.onPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_scanner, color: theme.onPrimary, size: size.width * 0.08),
            ),
          ],
        ),
      ),
    );
  }
}
