import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/view/voucher/voucher_use_confirmation_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasPermission = true;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      await controller.start();
    } catch (e) {
      if (mounted) {
        setState(() => _hasPermission = false);
      }
    }
  }

  Future<void> _handleQRCodeDetected(BarcodeCapture barcode) async {
    if (!_isScanning) return;

    try {
      setState(() => _isScanning = false);

      final voucherCode = barcode.barcodes.first.displayValue ?? '';

      if (voucherCode.isEmpty) {
        _showError('Invalid QR code');
        setState(() => _isScanning = true);
        return;
      }

      // Navigate to confirmation screen to use the voucher
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoucherUseConfirmationScreen(
              voucherCode: voucherCode,
              onSuccess: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Error processing QR code: $e');
      setState(() => _isScanning = true);
    }
  }

  void _showError(String message) {
    if (mounted) {
      final theme = AppThemes.color;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: theme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _requestPermission() async {
    // mobile_scanner 3.5+ handles permissions automatically
    // Just try to reinitialize the scanner
    setState(() => _hasPermission = true);
    _initializeScanner();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    controller.stop();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Scan Voucher QR Code', style: TextDesign.normalText()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.appbarBackground, height: 1),
        ),
      ),
      body: !_hasPermission
          ? _buildPermissionDenied(theme)
          : _buildScannerView(theme),
    );
  }

  Widget _buildPermissionDenied(AppColors theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 80, color: theme.error),
            const SizedBox(height: 16),
            Text(
              'Camera Not Available',
              style: TextDesign.headingTwo(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to access camera. Please check your permissions and try again.',
              textAlign: TextAlign.center,
              style: TextDesign.smallText(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView(AppColors theme) {
    return Stack(
      children: [
        // Scanner View
        MobileScanner(controller: controller, onDetect: _handleQRCodeDetected),

        // Overlay with scanning frame
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 0),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Transparent center with border
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: 280,
                  height: 280,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.green, width: 4),
                        left: BorderSide(color: Colors.green, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.green, width: 4),
                        right: BorderSide(color: Colors.green, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.green, width: 4),
                        left: BorderSide(color: Colors.green, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.green, width: 4),
                        right: BorderSide(color: Colors.green, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom overlay with instructions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Position the QR code inside the frame',
                  textAlign: TextAlign.center,
                  style: TextDesign.normalText(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cameraswitch, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.switchCamera(),
                      child: Text(
                        'Switch Camera',
                        style: TextDesign.smallText(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Toggle Flashlight
        Positioned(
          top: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                return IconButton(
                  icon: Icon(
                    state == TorchState.off
                        ? Icons.flashlight_off
                        : Icons.flashlight_on,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => controller.toggleTorch(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
