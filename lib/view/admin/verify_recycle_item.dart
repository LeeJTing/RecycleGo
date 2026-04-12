import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../../app/TextDesign.dart';
import '../../app/app_theme.dart';
import '../../app/assets.dart';

class VerifyRecycleItem extends StatefulWidget {
  const VerifyRecycleItem({super.key});

  @override
  State<VerifyRecycleItem> createState() => _VerifyRecycleItemState();
}

class _VerifyRecycleItemState extends State<VerifyRecycleItem> {
  // --- STATE VARIABLES ---
  CameraController? controller;
  List<CameraDescription> cameras = [];
  Interpreter? interpreter;
  List<String> labels = [];

  File? capturedImage;
  List<Map<String, dynamic>> detections = [];

  bool isProcessing = false;
  bool isLoaded = false;
  bool isCameraInitialized = false;
  bool hasAnalyzed = false; // Tracks if the AI has finished running
  double userWallet = 0.0;

  // --- RECYCLING DATA ---
  final Map<String, double> materialDensity = {
    'plastic': 1.38, 'glass': 2.50, 'paper': 0.80, 'metal': 2.70, 'cardboard': 0.60,
  };

  final Map<String, double> baseWeights = {
    'plastic': 18.0, 'glass': 200.0, 'paper': 5.0, 'metal': 15.0, 'cardboard': 50.0,
  };

  final Map<String, int> pointValues = {
    'plastic': 10, 'glass': 15, 'paper': 5, 'metal': 20, 'cardboard': 8,
  };

  // --- LIFECYCLE ---
  @override
  void initState() {
    super.initState();
    _loadModel();
    initCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    interpreter?.close();
    super.dispose();
  }

  // --- SETUP METHODS ---
  Future<void> _loadModel() async {
    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      labels = labelsData.split('\n').map((e) => e.trim().toLowerCase()).toList();
      interpreter = await Interpreter.fromAsset('assets/models/model.tflite');

      setState(() => isLoaded = true);
    } catch (e) {
      debugPrint("Model Load Error: $e");
    }
  }

  Future<void> initCamera() async {
    try {
      // 1. Fetch the list of available cameras first
      cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint("No cameras found on this device.");
        return;
      }

      // 2. Initialize the controller with the first camera (usually back camera)
      controller = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false
      );

      await controller!.initialize();

      // 3. Update the state so the UI knows to drop the loading screen
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> captureImage() async {
    debugPrint("📸 Capture button pressed!");
    debugPrint("👉 Camera controller ready? ${controller != null}");
    debugPrint("👉 AI Model loaded? $isLoaded");

    // 1. The Guard Clause
    if (controller == null || !isLoaded) {
      debugPrint("🚨 ABORTING: Cannot take picture because camera or model isn't ready.");
      return;
    }

    // 2. Taking the Picture
    try {
      debugPrint("📸 Taking picture now...");
      XFile file = await controller!.takePicture();
      debugPrint("✅ Picture successfully taken at: ${file.path}");

      // 3. Updating the UI
      setState(() {
        capturedImage = File(file.path);
        hasAnalyzed = false;
        detections = [];
      });
      debugPrint("🔄 State updated! The UI should switch to Confirmation Mode now.");

    } catch (e) {
      debugPrint("❌ Capture error: $e");
    }
  }

  // 2. Pick from gallery and show the confirmation screen
  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          capturedImage = File(pickedFile.path);
          hasAnalyzed = false;
          detections = [];
        });
      }
    } catch (e) {
      debugPrint("Error picking from gallery: $e");
    }
  }

  // 3. User tapped 'X'
  void retakeImage() {
    setState(() {
      capturedImage = null;
      hasAnalyzed = false;
      detections = [];
    });
  }

  // 4. User tapped '✓' -> Run the AI
  Future<void> confirmAndDetect() async {
    if (capturedImage == null) return;
    setState(() => isProcessing = true);
    await _runDetection(capturedImage!);
  }

  // --- MACHINE LEARNING LOGIC ---
  Future<void> _runDetection(File imageFile) async {
    if (interpreter == null) {
      setState(() => isProcessing = false);
      return;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? imgData = img.decodeImage(bytes);

      if (imgData != null) {
        // Change from 640 to 300 to match the model!
        img.Image resized = img.copyResize(imgData, width: 300, height: 300);
        var input = _processImage(resized);

        // Build the safe output container for exactly 6 numbers
        var output = List<double>.filled(1 * 6, 0.0).reshape([1, 6]);

        interpreter!.run(input, output);
        _parseResults(output[0]); // Pass the 6 numbers to the parser
      }
    } catch (e) {
      debugPrint("🚨 Detection Crash: $e");
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
          hasAnalyzed = true; // Mark as successfully analyzed!
        });
      }
    }
  }

  void _parseResults(List<double> scores) {
    List<Map<String, dynamic>> temp = [];

    // Find the highest score among the 6 numbers
    double highestScore = 0.0;
    int highestIndex = -1;

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > highestScore) {
        highestScore = scores[i];
        highestIndex = i;
      }
    }

    // If it's confident (> 45%) and the index exists in your labels list
    if (highestScore > 0.45 && highestIndex < labels.length) {
      temp.add({
        "tag": labels[highestIndex],
        "w": 200.0, // Arbitrary size to feed your weight calculations
        "h": 200.0,
        "box": [0.0, 0.0, 300.0, 300.0]
      });
    }

    detections = temp;
  }

  dynamic _processImage(img.Image imgData) {
    // Change buffer size from 640 to 300
    var buffer = Float32List(1 * 300 * 300 * 3);
    int idx = 0;
    for (var y = 0; y < 300; y++) {
      for (var x = 0; x < 300; x++) {
        var p = imgData.getPixel(x, y);
        buffer[idx++] = p.r / 255.0;
        buffer[idx++] = p.g / 255.0;
        buffer[idx++] = p.b / 255.0;
      }
    }
    return buffer.reshape([1, 300, 300, 3]);
  }

  // --- CALCULATION LOGIC ---
  Map<String, Map<String, dynamic>> _calculateStats() {
    Map<String, Map<String, dynamic>> results = {};

    for (var det in detections) {
      String label = det["tag"];
      double w = det["w"];
      double h = det["h"];

      double estimatedDepth = w * 0.6;
      double volumePixels = w * h * estimatedDepth;
      double individualWeight = volumePixels * 0.0008 * (materialDensity[label] ?? 1.0);
      double finalWeight = individualWeight > 2.0 ? individualWeight : (baseWeights[label] ?? 5.0);

      if (!results.containsKey(label)) {
        results[label] = {
          'count': 0,
          'weight': 0.0,
          'weightKg': 0.0,
          'points': 0.0    // Initialized as double
        };
      }

      results[label]!['count'] = (results[label]!['count'] as int) + 1;
      results[label]!['weight'] = (results[label]!['weight'] as double) + finalWeight;
    }

    results.forEach((label, data) {
      double totalWeightGrams = data['weight'] as double;
      double totalWeightKg = totalWeightGrams / 1000.0;
      data['weightKg'] = totalWeightKg;

      int multiplier = pointValues[label] ?? 1;
      // Result is a double (e.g., 0.054 * 10 = 0.54)
      data['points'] = totalWeightKg * multiplier;
    });

    return results;
  }
  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    if (!isCameraInitialized || !isLoaded) {
      return Scaffold(
        backgroundColor: theme.background,
        body: Center(child: CircularProgressIndicator(color: theme.primary)),
      );
    }

    final stats = _calculateStats();
    double currentPoints = stats.values.fold(
        0.0, (sum, item) => sum + (double.tryParse(item['points']?.toString() ?? '0') ?? 0.0));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // --- 1. CAMERA MODE (No image captured yet) ---
          if (capturedImage == null) ...[
            CameraPreview(controller!),
            _buildCameraGrid(),
            _buildTranslucentHeader(context, theme),
            _buildCameraControls(context, theme),
          ],

          // --- 2. CONFIRMATION MODE (Image captured, waiting for User) ---
          if (capturedImage != null && !hasAnalyzed && !isProcessing)
            _buildConfirmationUI(),

          // --- 3. PROCESSING MODE (AI is running) ---
          if (isProcessing)
            _buildProcessingOverlay(theme),

          // --- 4. RESULTS MODE (AI is done, show points) ---
          if (capturedImage != null && hasAnalyzed && !isProcessing) ...[
            Positioned.fill(
              child: Image.file(capturedImage!, fit: BoxFit.cover),
            ),
            _buildCalculationBreakdown(currentPoints, stats, theme),
          ]
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildTranslucentHeader(BuildContext context, AppColors theme) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
        color: Colors.black38,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraGrid() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          children: [
            Expanded(child: Row(children: [Expanded(child: _gridBox()), Expanded(child: _gridBox()), Expanded(child: _gridBox())])),
            Expanded(child: Row(children: [Expanded(child: _gridBox()), Expanded(child: _gridBox()), Expanded(child: _gridBox())])),
            Expanded(child: Row(children: [Expanded(child: _gridBox()), Expanded(child: _gridBox()), Expanded(child: _gridBox())])),
          ],
        ),
      ),
    );
  }

  Widget _gridBox() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 0.5)),
    );
  }

  Widget _buildCameraControls(BuildContext context, AppColors theme) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.only(bottom: 50, left: 24, right: 24, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                // Capture Button -> Calls captureImage now!
                GestureDetector(
                  onTap: captureImage,
                  child: Container(
                    height: 80, width: 80,
                    decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 6)),
                    child: Center(
                      child: Container(height: 50, width: 50, decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle)),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 50.0),
                      // Gallery Button -> Calls pickImageFromGallery now!
                      child: GestureDetector(
                        onTap: pickImageFromGallery,
                        child: CircleAvatar(
                          radius: 30, backgroundColor: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: const Icon(Icons.photo_library, color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationUI() {
    return Container(
      color: const Color(0xFF1C1C1E), // Deep dark background matching your image
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Captured Image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0, left: 24.0, right: 24.0, bottom: 40.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(capturedImage!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          ),

          // 2. Action Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Retake (X)
                GestureDetector(
                  onTap: retakeImage,
                  child: Container(
                    height: 75, width: 75,
                    decoration: BoxDecoration(color: const Color(0xFF3A3A3C), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.close, color: Colors.white, size: 36),
                  ),
                ),
                // Confirm (✓)
                GestureDetector(
                  onTap: confirmAndDetect,
                  child: Container(
                    height: 75, width: 75,
                    decoration: BoxDecoration(color: const Color(0xFFFF2D55), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.check, color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay(AppColors theme) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.success),
            const SizedBox(height: 16),
            const Text("Analyzing Item...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationBreakdown(double points, Map<String, dynamic> stats, AppColors theme) {
    return Positioned(
      bottom: 50, left: 15, right: 15,
      child: Column(
        children: [
          _buildPointsAwardedCard(points, stats, theme),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  userWallet += points;
                  retakeImage(); // Collect points and reset
                });
              },
              icon: const Icon(Icons.stars, color: Colors.white),
              label: Text("COLLECT POINTS", style: TextDesign.buttonText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 60,
            child: OutlinedButton.icon(
              onPressed: retakeImage, // Discard and retake
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text("RETAKE PHOTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsAwardedCard(double points, Map<String, dynamic> stats, AppColors theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D16B), Color(0xFF00B15B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text("ITEMS DETECTED", style: TextDesign.badgeText(color: Colors.white.withOpacity(0.8)).copyWith(letterSpacing: 1.2, fontSize: 10)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Colors.white70, size: 30),
              const SizedBox(width: 16),
              Text("+${points.toStringAsFixed(2)}", style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          if (stats.isEmpty)
            const Text("No items detected in this image.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          else
            ...stats.entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${e.key.toUpperCase()} (x${e.value['count']})", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("${(e.value['points'] as double).toStringAsFixed(2)} pts", style: TextDesign.priceText(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}