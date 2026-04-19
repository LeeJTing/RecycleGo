import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/redeemed_voucher/redeemed_voucher_ctrl.dart';
import 'package:recycle_go/view/voucher/voucher_use_confirmation_screen.dart';
import 'package:recycle_go/view/voucher/qr_code_helpers.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  bool _hasPermission = true;
  bool _isScanning = true;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      await controller.start();
      if (mounted) {
        setState(() => _hasPermission = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasPermission = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      controller.start();
      _started = true;
    }
  }

  Future<void> _handleQRCodeDetected(BarcodeCapture barcode) async {
    if (!_isScanning) return;

    try {
      setState(() => _isScanning = false);

      final qrData = barcode.barcodes.first.displayValue ?? '';

      if (qrData.isEmpty) {
        _showError('Invalid QR code');
        setState(() => _isScanning = true);
        return;
      }

      // Parse QR data using QRCodeHelpers
      String voucherCode;
      try {
        final parsedData = QRCodeHelpers.parseQRData(qrData);
        voucherCode = parsedData['voucherCode'] ?? '';
      } catch (e) {
        // If parsing fails, assume the QR data is just the voucher code
        voucherCode = qrData;
      }

      if (voucherCode.isEmpty) {
        _showError('Invalid voucher code in QR');
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

  void _showManualEntryDialog() {
    final codeController = TextEditingController();
    final theme = AppThemes.color;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Voucher Code',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: codeController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter voucher code',
            filled: true,
            fillColor: const Color(0xFFF4F7F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (codeController.text.isNotEmpty) {
                setState(() => _isScanning = false);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VoucherUseConfirmationScreen(
                      voucherCode: codeController.text,
                      onSuccess: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
                setState(() => _isScanning = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void activate() {
    super.activate();
    setState(() {
      _isScanning = true;
      _hasPermission = true;
    });
    _initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        MobileScanner(
          controller: controller,
          onDetect: _handleQRCodeDetected,
          errorBuilder: (context, error, child) {
            return Center(child: Text('Error: ${error.errorCode}'));
          },
        ),

        // Dark overlay with semi-transparent corners and scanning frame
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent, width: 0),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dark overlay outside scan area
                Container(color: Colors.black.withOpacity(0.5)),
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

        // Bottom overlay with instructions and capture button
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
                ),                const SizedBox(height: 8),
                Text(
                  'The camera will automatically detect the QR code',
                  textAlign: TextAlign.center,
                  style: TextDesign.smallText(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isScanning ? _showManualEntryDialog : null,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Manual Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
