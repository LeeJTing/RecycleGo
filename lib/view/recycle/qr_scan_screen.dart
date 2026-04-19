//qr_scan_screen
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/services/LocalStorageService.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => QrScanScreenState();
}

class QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _torchOn = false;
  bool _scanned = false;
  bool _hasPermission = true;

  // Scan-frame animation
  late AnimationController _animController;
  late Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraController.start();

      // Give it a moment to actually start and detect any permission issues
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() => _hasPermission = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasPermission = false);
      }
    }
  }

  void _requestPermission() {
    // Reset to false first to show we're trying
    setState(() => _hasPermission = false);
    // Give a brief moment for UI to update
    Future.delayed(const Duration(milliseconds: 100), () {
      _initializeCamera();
    });
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _cameraController.start();
      _started = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _cameraController.stop();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    setState(() {
      _scanned = false;
      _torchOn = false;
    });
    _initializeCamera();
  }

  /// Public method to refresh camera when Scan tab is tapped
  void refreshCamera() {
    setState(() {
      _scanned = false;
      _torchOn = false;
      _hasPermission = true;
    });
    _initializeCamera();
  }

  Future<bool> _isNearStation(double lat, double lng) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    final pos = await Geolocator.getCurrentPosition();

    double distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      lat,
      lng,
    );

    return distance <= 50;
  }

  void _showError(String msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _scanned = false);
                _cameraController.start();
              },
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final qrValue = barcode?.rawValue;

    if (qrValue == null) return;

    setState(() => _scanned = true);
    _cameraController.stop();

    try {
      final client = Supabase.instance.client;

      // ✅ 1. 先查数据库
      final res = await client
          .from('recyclestation')
          .select()
          .eq('qr_code_value', qrValue)
          .maybeSingle();

      if (res == null) {
        setState(() => _scanned = false);
        _cameraController.start();
        _showError("Invalid QR Code ❌");
        return;
      }

      // ✅ 2. 再检查 GPS
      final isNear = await _isNearStation(res['latitude'], res['longitude']);

      if (!isNear) {
        setState(() => _scanned = false);
        _cameraController.start();
        _showError("You are too far from this station 📍");
        return;
      }

      // ✅ 3. 成功
      _showSuccessSheet(res);
    } catch (e) {
      _showError("Scan failed: $e");
    }
  }

  void _showSuccessSheet(Map<String, dynamic> station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _ScanSuccessSheet(
        station: station,
        onContinue: () async {
          Navigator.pop(context);

          _cameraController.stop();

          // ✅ 加这个：记录验证时间
          station['verified_at'] = DateTime.now().toIso8601String();

          // ✅ 存 local
          await LocalStorageService.saveStation(station);

          // ✅ 跳去队友页面 + 传 data
          await Navigator.pushNamed(
            context,
            Routes.scanRecycleItem,
            arguments: station,
          );

          if (!mounted) return;

          setState(() => _scanned = false);
          await _cameraController.start();
        },
        onRetry: () {
          Navigator.pop(context);
          setState(() => _scanned = false);
          _cameraController.start();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_hasPermission
          ? _buildPermissionDenied()
          : Stack(
              children: [
                // ── Camera feed ─────────────────────────────────────────────
                MobileScanner(
                  controller: _cameraController,
                  onDetect: _onDetect,
                ),

                // ── Dark overlay with cut-out ────────────────────────────────
                _ScanOverlay(scanLineAnim: _scanLine),

                const SizedBox(height: 30),
                // ── Instruction label ────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ALIGN QR CODE ON THE RECYCLE BIN',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom controls ──────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Control row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Torch
                            _ControlButton(
                              icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                              onTap: () {
                                _cameraController.toggleTorch();
                                setState(() => _torchOn = !_torchOn);
                              },
                            ),

                            // Manual entry
                            _ManualEntryButton(
                              onTap: () => _showManualEntryDialog(),
                            ),

                            // Close
                            _ControlButton(
                              icon: Icons.close,
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Not Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to access camera. Please check your permissions and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
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
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Station ID',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. ECO-0824-LX',
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
            onPressed: () async {
              Navigator.pop(ctx);

              if (controller.text.isEmpty) return;

              final client = Supabase.instance.client;

              try {
                final res = await client
                    .from('recyclestation')
                    .select()
                    .eq('qr_code_value', controller.text)
                    .maybeSingle();

                if (res == null) {
                  _showError("Invalid Station ID ❌");
                  return;
                }

                // ✅ 成功 → 传整 row
                final isNear = await _isNearStation(
                  res['latitude'],
                  res['longitude'],
                );

                if (!isNear) {
                  _showError("You are too far from this station 📍");
                  return;
                }

                _showSuccessSheet(res);
              } catch (e) {
                _showError("Failed: $e");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
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
}

// ─────────────────────────────────────────────────────────────────────
// Scan overlay with animated green border + scan line
// ─────────────────────────────────────────────────────────────────────
class _ScanOverlay extends StatelessWidget {
  final Animation<double> scanLineAnim;
  const _ScanOverlay({required this.scanLineAnim});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const frameSize = 260.0;
    final frameTop = (size.height - frameSize) / 2 - 40;
    final frameLeft = (size.width - frameSize) / 2;

    return AnimatedBuilder(
      animation: scanLineAnim,
      builder: (_, __) {
        return CustomPaint(
          size: Size(size.width, size.height),
          painter: _OverlayPainter(
            frameRect: Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize),
            scanProgress: scanLineAnim.value,
          ),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect frameRect;
  final double scanProgress;

  _OverlayPainter({required this.frameRect, required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent dark overlay
    final overlay = Paint()..color = Colors.black.withOpacity(0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlay);

    // Green corner brackets
    final corner = Paint()
      ..color = const Color(0xFF1DB954)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const c = 28.0;
    final r = const Radius.circular(10);
    final l = frameRect.left;
    final t = frameRect.top;
    final rr = frameRect.right;
    final b = frameRect.bottom;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(l, t + c)
        ..arcToPoint(Offset(l + c, t), radius: r)
        ..lineTo(l + c, t),
      corner,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rr - c, t)
        ..arcToPoint(Offset(rr, t + c), radius: r)
        ..lineTo(rr, t + c),
      corner,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(l, b - c)
        ..arcToPoint(Offset(l + c, b), radius: r)
        ..lineTo(l + c, b),
      corner,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rr - c, b)
        ..arcToPoint(Offset(rr, b - c), radius: r)
        ..lineTo(rr, b - c),
      corner,
    );

    // Animated scan line
    final scanY = frameRect.top + frameRect.height * scanProgress;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF1DB954).withOpacity(0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(frameRect.left, scanY, frameRect.width, 3));
    canvas.drawLine(
      Offset(frameRect.left + 8, scanY),
      Offset(frameRect.right - 8, scanY),
      scanPaint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress;
}

// ─────────────────────────────────────────────────────────────────────
// Success / result bottom sheet
// ─────────────────────────────────────────────────────────────────────
class _ScanSuccessSheet extends StatelessWidget {
  final Map<String, dynamic> station;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const _ScanSuccessSheet({
    required this.station,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF1DB954),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Station Verified!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1F0D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Station ID: ${station['qr_code_value']}',
            style: const TextStyle(color: Color(0xFF888), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'GPS location confirmed ✓',
              style: TextStyle(
                color: Color(0xFF1DB954),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Color(0xFF555)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Start Recycling',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Reusable bottom control buttons
// ─────────────────────────────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ManualEntryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManualEntryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.keyboard_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'MANUAL ENTRY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavHint({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: active ? const Color(0xFF1DB954) : Colors.white54,
          size: 22,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF1DB954) : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
