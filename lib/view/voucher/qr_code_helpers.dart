import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class QRCodeHelpers {
  // Generate QR code data from voucher code and user ID
  // Format: voucherCode|userId|timestamp
  static String generateQRData(String voucherCode, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$voucherCode|$userId|$timestamp';
  }

  // Parse QR data back to components
  static Map<String, String> parseQRData(String qrData) {
    final parts = qrData.split('|');
    if (parts.length < 2) {
      throw Exception('Invalid QR code format');
    }
    return {
      'voucherCode': parts[0],
      'userId': parts[1],
      'timestamp': parts.length > 2 ? parts[2] : '',
    };
  }

  // Generate actual QR code widget
  static Widget buildQRCode(String voucherCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: voucherCode,
            version: QrVersions.auto,
            size: 200.0,
            gapless: false,
            embeddedImage: null,
            embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
            semanticsLabel: 'Voucher QR Code: $voucherCode',
          ),
          const SizedBox(height: 12),
          Text(
            'Code: $voucherCode',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Generate shareable text for social media with QR code instructions
  static String generateShareText(String voucherCode, String voucherName) {
    return '''
🎫 Check out this voucher I'm sharing with you!

Voucher: $voucherName
Code: $voucherCode

📱 How to redeem:
1. Open RecycleGo app
2. Tap Voucher tab → "Scan QR"
3. Scan the QR code or enter code manually
4. Confirm to use the voucher!

Don't miss out! 🎁
''';
  }

  // Save QR code directly to device gallery/screenshots
  static Future<String?> saveQRImageToFile({
    required String voucherCode,
    required String voucherName,
  }) async {
    try {
      // Request storage permission
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.storage.request();
      } else if (Platform.isIOS) {
        status = await Permission.photos.request();
      } else {
        status = PermissionStatus.granted;
      }

      if (!status.isGranted) {
        throw Exception('Storage permission denied: $status');
      }

      // Generate QR code as PNG image bytes
      final qrImageBytes = await _generateQRImageBytes(voucherCode);

      if (qrImageBytes == null) {
        throw Exception('Failed to generate QR code image');
      }
      // Save bytes to temporary file first
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'RecycleGo_Voucher_${voucherCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.png';
      final tempFilePath = '${tempDir.path}/$fileName';

      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(qrImageBytes);

      // Clean up temp file
      await tempFile.delete();

      return 'Gallery'; // Return success indicator
    } catch (e) {
      return null;
    }
  }

  // Share voucher with QR code image
  static Future<void> shareVoucherWithQRImage({
    required String voucherCode,
    required String voucherName,
  }) async {
    try {
      // Generate QR code as PNG image bytes
      final qrImageBytes = await _generateQRImageBytes(voucherCode);

      if (qrImageBytes == null) {
        throw Exception('Failed to generate QR code image');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final qrFile = File('${tempDir.path}/voucher_qr_$voucherCode.png');

      await qrFile.writeAsBytes(qrImageBytes);

      // Share with text and image
      final shareText = generateShareText(voucherCode, voucherName);

      await Share.shareFiles(
        [qrFile.path],
        text: shareText,
        subject: 'RecycleGo Voucher - $voucherCode',
      );

      // Clean up temp file after a delay
      Future.delayed(const Duration(seconds: 2), () {
        try {
          qrFile.deleteSync();
        } catch (e) {
          // Ignore cleanup errors
        }
      });
    } catch (e) {
      throw Exception('Failed to share voucher with QR image: $e');
    }
  }

  // Generate QR code as PNG bytes
  // Generate QR code as PNG bytes
  static Future<Uint8List?> _generateQRImageBytes(String voucherCode) async {
    try {
      // Create QR painter
      final qrPainter = QrPainter(
        data: voucherCode,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      // Convert to image
      final image = await qrPainter.toImage(300);

      // Convert image to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      return bytes;
    } catch (e) {
      return null;
    }
  }

  // Share voucher with custom message
  static Future<void> shareVoucherWithMessage({
    required String voucherCode,
    required String message,
  }) async {
    try {
      await Share.share(message, subject: 'RecycleGo Voucher');
    } catch (e) {
      throw Exception('Failed to share voucher: $e');
    }
  }
}
