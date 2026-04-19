// lib/view/recycle/qr_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
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

  // ── 用工厂方法方便重建 ────────────────────────────────────────
  MobileScannerController _cameraController = _buildController();

  static MobileScannerController _buildController() =>
      MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

  bool _torchOn  = false;
  bool _scanned  = false;
  bool _started  = false;

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
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _cameraController.start();
      _started = true;
    }
  }

  // ── 核心修复：dispose + 重建，替代 stop/start ─────────────────
  Future<void> refreshCamera() async {
    if (!mounted) return;

    // 1. 释放旧 controller
    try { _cameraController.stop(); } catch (_) {}
    try { _cameraController.dispose(); } catch (_) {}

    // 2. 给硬件时间完全释放
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // 3. 重建
    setState(() {
      _cameraController = _buildController();
      _scanned = false;
      _torchOn = false;
      _started = false;
    });

    // 4. 等 widget rebuild 后启动
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    try {
      await _cameraController.start();
      if (mounted) setState(() => _started = true);
    } catch (e) {
      debugPrint('QR camera restart error: $e');
    }
  }

  void stopCamera() {
    try { _cameraController.stop(); } catch (_) {}
  }

  void startCamera() {
    try { _cameraController.start(); } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    try { _cameraController.stop(); } catch (_) {}
    try { _cameraController.dispose(); } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    switch (state) {
      case AppLifecycleState.resumed:
        try { _cameraController.start(); } catch (_) {}
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        try { _cameraController.stop(); } catch (_) {}
        break;
      default:
        break;
    }
  }

  // ── GPS ───────────────────────────────────────────────────────
  Future<bool> _isNearStation(double lat, double lng) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 8));
      return Geolocator.distanceBetween(
          pos.latitude, pos.longitude, lat, lng) <= 50;
    } catch (e) {
      debugPrint('GPS error: $e');
      return false;
    }
  }

  // ── QR detect ─────────────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    setState(() => _scanned = true);
    try { _cameraController.stop(); } catch (_) {}

    final qrValue = capture.barcodes.firstOrNull?.rawValue;
    if (qrValue == null) {
      setState(() => _scanned = false);
      try { _cameraController.start(); } catch (_) {}
      return;
    }

    debugPrint('SCANNED => $qrValue');

    try {
      final res = await Supabase.instance.client
          .from('recyclestation')
          .select()
          .eq('qr_code_value', qrValue)
          .maybeSingle();

      if (res == null) { _showError('Invalid QR Code ❌'); return; }

      final isNear = await _isNearStation(
          (res['latitude'] as num).toDouble(),
          (res['longitude'] as num).toDouble());

      if (!isNear) { _showError('You are too far from this station 📍'); return; }

      _showSuccessSheet(res);
    } catch (e) {
      _showError('Scan failed: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _scanned = false);
              try { _cameraController.start(); } catch (_) {}
            },
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  void _showSuccessSheet(Map<String, dynamic> station) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _ScanSuccessSheet(
        station: station,
        onContinue: () async {
          Navigator.pop(context);
          try { _cameraController.stop(); } catch (_) {}
          station['verified_at'] = DateTime.now().toIso8601String();
          await LocalStorageService.saveStation(station);
          await Navigator.pushNamed(context, Routes.scanRecycleItem,
              arguments: station);
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          await refreshCamera();
        },
        onRetry: () {
          Navigator.pop(context);
          setState(() => _scanned = false);
          try { _cameraController.start(); } catch (_) {}
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        MobileScanner(
          key: ValueKey(_cameraController), // ⭐ 核心
          controller: _cameraController,
          onDetect: _onDetect,
        ),
        _ScanOverlay(scanLineAnim: _scanLine),

        // Instruction label
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('ALIGN QR CODE ON THE RECYCLE BIN',
                  style: TextStyle(color: Colors.white70, fontSize: 12,
                      fontWeight: FontWeight.w600, letterSpacing: 1)),
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ControlButton(
                  icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                  onTap: () async {
                    try {
                      await _cameraController.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    } catch (e) {
                      debugPrint('Torch error: $e');
                    }
                  },
                ),
                _ManualEntryButton(onTap: _showManualEntryDialog),
                _ControlButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _showManualEntryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enter Station ID',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl, autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. ECO-0824-LX', filled: true,
            fillColor: const Color(0xFFF4F7F4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isEmpty) return;
              try {
                final res = await Supabase.instance.client
                    .from('recyclestation').select()
                    .eq('qr_code_value', ctrl.text.trim()).maybeSingle();
                if (res == null) { _showError('Invalid Station ID ❌'); }
                else { _showSuccessSheet(res); }
              } catch (e) { _showError('Failed: $e'); }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Overlay ─────────────────────────────────────────────────────────
class _ScanOverlay extends StatelessWidget {
  final Animation<double> scanLineAnim;
  const _ScanOverlay({required this.scanLineAnim});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const fs = 260.0;
    return AnimatedBuilder(
      animation: scanLineAnim,
      builder: (_, __) => CustomPaint(
        size: Size(size.width, size.height),
        painter: _OverlayPainter(
          frameRect: Rect.fromLTWH(
              (size.width - fs) / 2, (size.height - fs) / 2 - 40, fs, fs),
          scanProgress: scanLineAnim.value,
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect frameRect;
  final double scanProgress;
  const _OverlayPainter({required this.frameRect, required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(20)))
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withOpacity(0.55),
    );
    final p = Paint()
      ..color = const Color(0xFF1DB954)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const c = 28.0;
    final r = const Radius.circular(10);
    final l = frameRect.left, t = frameRect.top,
        rr = frameRect.right, b = frameRect.bottom;
    for (final path in [
      Path()..moveTo(l, t+c)..arcToPoint(Offset(l+c, t), radius: r)..lineTo(l+c, t),
      Path()..moveTo(rr-c, t)..arcToPoint(Offset(rr, t+c), radius: r)..lineTo(rr, t+c),
      Path()..moveTo(l, b-c)..arcToPoint(Offset(l+c, b), radius: r)..lineTo(l+c, b),
      Path()..moveTo(rr-c, b)..arcToPoint(Offset(rr, b-c), radius: r)..lineTo(rr, b-c),
    ]) { canvas.drawPath(path, p); }
    final scanY = frameRect.top + frameRect.height * scanProgress;
    canvas.drawLine(
      Offset(frameRect.left + 8, scanY),
      Offset(frameRect.right - 8, scanY),
      Paint()
        ..strokeWidth = 2
        ..shader = LinearGradient(colors: [
          Colors.transparent,
          const Color(0xFF1DB954).withOpacity(0.8),
          Colors.transparent,
        ]).createShader(Rect.fromLTWH(
            frameRect.left, scanY, frameRect.width, 3)),
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter o) => o.scanProgress != scanProgress;
}

// ─── Success sheet ────────────────────────────────────────────────────
class _ScanSuccessSheet extends StatelessWidget {
  final Map<String, dynamic> station;
  final VoidCallback onContinue, onRetry;
  const _ScanSuccessSheet(
      {required this.station, required this.onContinue, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64,
          decoration: const BoxDecoration(
              color: Color(0xFFEAF7EE), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline,
              color: Color(0xFF1DB954), size: 36)),
      const SizedBox(height: 16),
      const Text('Station Verified!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: Color(0xFF0D1F0D))),
      const SizedBox(height: 6),
      Text(station['station_name']?.toString() ?? '',
          style: const TextStyle(color: Color(0xFF888), fontSize: 13)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(8)),
        child: const Text('GPS location confirmed ✓',
            style: TextStyle(color: Color(0xFF1DB954), fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDD)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFF555))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 2,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954), elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Start Recycling',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ]),
  );
}

class _ControlButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 52, height: 52,
        decoration: const BoxDecoration(
            color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22)),
  );
}

class _ManualEntryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManualEntryButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: Colors.black54,
          borderRadius: BorderRadius.circular(16)),
      child: const Row(children: [
        Icon(Icons.keyboard_outlined, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text('MANUAL ENTRY', style: TextStyle(color: Colors.white,
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ]),
    ),
  );
}