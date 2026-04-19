import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../../../app/TextDesign.dart';
import '../../../app/app_theme.dart';
import '../../../app/assets.dart';
import '../../../models/Recycle_category.dart';
import '../../../models/RecyclingSubmission.dart';
import '../../../provider/UserProvider.dart';
import '../../../utils/async_task_runner.dart';
import 'package:recycle_go/services/LocalStorageService.dart';
import 'package:geolocator/geolocator.dart';
import 'package:recycle_go/services/LocalStorageService.dart';

class VerifyRecycleItem extends StatefulWidget {
  const VerifyRecycleItem({super.key});

  @override
  State<VerifyRecycleItem> createState() => _VerifyRecycleItemState();
}

class _VerifyRecycleItemState extends State<VerifyRecycleItem> {
  CameraController? controller;
  List<CameraDescription> cameras = [];
  Interpreter? interpreter;
  List<String> labels = [];
  List<Map<String, dynamic>> pendingItems = [];

  File? capturedImage;
  List<Map<String, dynamic>> detections = [];

  bool isProcessing = false;
  bool isLoaded = false;
  bool isCameraInitialized = false;
  bool hasAnalyzed = false;
  double userWallet = 0.0;

  List<RecycleCategory> _categories = [];
  Map<String, RecycleCategory> _categoryByLabel = {};
  String? _stationId;

  double getDensity(String label) => _categoryByLabel[label]?.density ?? 1.0;
  double getBaseWeight(String label) =>
      _categoryByLabel[label]?.baseWeight ?? 5.0;
  num getPointsPerKg(String label) => _categoryByLabel[label]?.point ?? 1;

  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _checkQRValidity();
    _loadDynamicData();
    _loadModel();
    initCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    interpreter?.close();
    super.dispose();
  }

  Future<void> _checkQRValidity() async {
    final station = await LocalStorageService.getStation();

    if (station == null) {
      _kickOut("Please scan QR first ❌");
      return;
    }

    try {
      final verifiedTime = DateTime.parse(station['verified_at']);

      if (DateTime.now().difference(verifiedTime).inMinutes > 10) {
        await LocalStorageService.clearStation();
        _kickOut("QR expired. Please scan again ⏱️");
        return;
      }

      final isNear = await _isStillNearStation(
        station['latitude'],
        station['longitude'],
      );

      if (!isNear) {
        await LocalStorageService.clearStation();
        _kickOut("You left the station area 📍");
        return;
      }

      _stationId = station['station_id'];

    } catch (e) {
      await LocalStorageService.clearStation();
      _kickOut("Invalid QR data ❌");
    }
  }

  void _kickOut(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      Navigator.pop(context);
    });
  }

  Future<bool> _isStillNearStation(
      double lat,
      double lng,
      ) async {
    final pos = await Geolocator.getCurrentPosition();

    double distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      lat,
      lng,
    );

    return distance <= 50;
  }

  Future<void> _loadDynamicData() async {
    try {
      final supabase = Supabase.instance.client;
      final List<dynamic> catData = await supabase
          .from('recycle_category')
          .select('category_id, category_name, label, density, base_weight_grams, points_per_kg')
          .not('label', 'is', null);

      _categories = catData.map((j) => RecycleCategory.fromJson(j)).toList();
      for (var cat in _categories) {
        if (cat.label != null) {
          _categoryByLabel[cat.label!] = cat;
        }
      }

      final userId = supabase.auth.currentUser!.id;
      final userRes = await supabase
          .from('users')
          .select('station_id')
          .eq('user_id', userId)
          .single();
      _stationId = userRes['station_id'] as String?;

      setState(() => _isLoadingData = false);
    } catch (e) {
      debugPrint("Error loading dynamic data: $e");
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadModel() async {
    try {
      final labelsData = await rootBundle.loadString(AppAssets.label);

      labels = labelsData
          .split('\n')
          .map((e) => e.trim().toLowerCase())
          .toList();
      interpreter = await Interpreter.fromAsset(AppAssets.model);

      setState(() => isLoaded = true);
    } catch (e) {
      debugPrint("Model Load Error: $e");
    }
  }

  Map<String, Map<String, dynamic>> _calculateStats() {
    Map<String, Map<String, dynamic>> results = {};

    for (var det in detections) {
      String label = det["tag"];
      double w = det["w"];
      double h = det["h"];

      double estimatedDepth = w * 0.6;
      double volumePixels = w * h * estimatedDepth;
      double density = getDensity(label);
      double individualWeight = volumePixels * 0.0008 * density;
      double finalWeight = individualWeight > 2.0
          ? individualWeight
          : getBaseWeight(label);

      if (!results.containsKey(label)) {
        results[label] = {
          'count': 0,
          'weight': 0.0,
          'weightKg': 0.0,
          'points': 0.0,
        };
      }

      results[label]!['count'] = (results[label]!['count'] as int) + 1;
      results[label]!['weight'] =
          (results[label]!['weight'] as double) + finalWeight;
    }

    results.forEach((label, data) {
      double totalWeightGrams = data['weight'] as double;
      double totalWeightKg = totalWeightGrams / 1000.0;
      data['weightKg'] = totalWeightKg;
      num multiplier = getPointsPerKg(label);
      data['points'] = totalWeightKg * multiplier;
    });

    return results;
  }

  // --- CAMERA SETUP ---
  Future<void> initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No cameras found.");
        return;
      }
      controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller!.initialize();
      if (mounted) setState(() => isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> captureImage() async {
    if (controller == null || !isLoaded) return;
    try {
      XFile file = await controller!.takePicture();
      setState(() {
        capturedImage = File(file.path);
        hasAnalyzed = false;
        detections = [];
      });
    } catch (e) {
      debugPrint("Capture error: $e");
    }
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          capturedImage = File(pickedFile.path);
          hasAnalyzed = false;
          detections = [];
        });
      }
    } catch (e) {
      debugPrint("Gallery error: $e");
    }
  }

  void retakeImage() {
    setState(() {
      capturedImage = null;
      hasAnalyzed = false;
      detections = [];
    });
  }

  Future<void> confirmAndDetect() async {
    if (capturedImage == null) return;
    setState(() => isProcessing = true);
    await _runDetection(capturedImage!);
  }

  Future<void> _runDetection(File imageFile) async {
    if (interpreter == null) {
      setState(() => isProcessing = false);
      return;
    }
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? imgData = img.decodeImage(bytes);
      if (imgData != null) {
        img.Image resized = img.copyResize(imgData, width: 300, height: 300);
        var input = _processImage(resized);
        var output = List<double>.filled(1 * 6, 0.0).reshape([1, 6]);
        interpreter!.run(input, output);
        _parseResults(output[0]);
      }
    } catch (e) {
      debugPrint("Detection crash: $e");
    } finally {
      if (mounted)
        setState(() {
          isProcessing = false;
          hasAnalyzed = true;
        });
    }
  }

  void _parseResults(List<double> scores) {
    List<Map<String, dynamic>> temp = [];
    double highestScore = 0.0;
    int highestIndex = -1;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > highestScore) {
        highestScore = scores[i];
        highestIndex = i;
      }
    }
    if (highestScore > 0.60 && highestIndex < labels.length) {
      temp.add({
        "tag": labels[highestIndex],
        "w": 200.0,
        "h": 200.0,
        "box": [0.0, 0.0, 300.0, 300.0],
      });
    }
    detections = temp;
  }

  dynamic _processImage(img.Image imgData) {
    var buffer = Float32List(1 * 300 * 300 * 3);
    int idx = 0;
    for (var y = 0; y < 300; y++) {
      for (var x = 0; x < 300; x++) {
        var p = imgData.getPixel(x, y);
        buffer[idx++] = (p.r - 127.5) / 127.5;
        buffer[idx++] = (p.g - 127.5) / 127.5;
        buffer[idx++] = (p.b - 127.5) / 127.5;
      }
    }
    return buffer.reshape([1, 300, 300, 3]);
  }

  // --- SUBMISSION ---
  Future<void> _submitAndCollectPoints(
    double totalPoints,
    Map<String, dynamic> stats,
  ) async {
    final File? imageFile = capturedImage;
    if (imageFile == null) return;
    // if (_stationId == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station ID not found')));
    //   return;
    // }

    await TaskRunner.run(
      context: context,
      loadingMessage: "Saving your submission...",
      successMessage:
          "Awesome! You earned ${totalPoints.toStringAsFixed(2)} points.",
      task: () async {
        final supabase = Supabase.instance.client;

        final String fileExtension = imageFile.path.split('.').last;
        final String fileName =
            'submission_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final String bucketName = 'recycleImage';
        final Uint8List fileBytes = await imageFile.readAsBytes();
        await supabase.storage
            .from(bucketName)
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: FileOptions(
                contentType: 'image/$fileExtension',
                upsert: true,
              ),
            );
        final String uploadedPhotoUrl = supabase.storage
            .from(bucketName)
            .getPublicUrl(fileName);

        double totalWeightKg = 0.0;
        double totalPointsEarned = 0.0;
        String? primaryCategoryLabel;
        int maxCount = 0;

        stats.forEach((label, data) {
          double weightKg = data['weightKg'] as double;
          double points = data['points'] as double;
          totalWeightKg += weightKg;
          totalPointsEarned += points;
          int count = data['count'] as int;
          if (count > maxCount) {
            maxCount = count;
            primaryCategoryLabel = label;
          }
        });

        stats.forEach((label, data) {
          if (data['count'] > maxCount) {
            maxCount = data['count'];
            primaryCategoryLabel = label;
          }
        });

        // Now normalise and get ID
        int? categoryId;
        for (var cat in _categories) {
          if (cat.label != null) {
            final normalizedKey = cat.label!.toLowerCase().trim();
            _categoryByLabel[normalizedKey] = cat;
          }
        }

        final user = context.read<UserProvider>().user;
        final userId = user?.userId;

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found or not logged in')),
          );
          return;
        }

        final newSubmission = RecycleSubmission(
          userId: userId,
          stationId: '33333333-3333-3333-3333-000000000001',
          weight: totalWeightKg,
          pointAward: totalPointsEarned.toDouble(),
          categoryId: categoryId,
          status:
              SubmissionStatus.pending.name,
          photoUrl: uploadedPhotoUrl,
        );

        await supabase
            .from('recyclingsubmission')
            .insert(newSubmission.toJsonForInsert());

        setState(() {
          userWallet += totalPointsEarned;
          retakeImage();
        });
      },
    );
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    if (!isCameraInitialized || !isLoaded || _isLoadingData) {
      return Scaffold(
        backgroundColor: theme.background,
        body: Center(child: CircularProgressIndicator(color: theme.primary)),
      );
    }

    final stats = _calculateStats();
    double currentPoints = stats.values.fold(
      0.0,
      (sum, item) =>
          sum + (double.tryParse(item['points']?.toString() ?? '0') ?? 0.0),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (capturedImage == null) ...[
            CameraPreview(controller!),
            _buildCameraGrid(),
            _buildTranslucentHeader(context, theme),
            _buildCameraControls(context, theme),
          ],
          if (capturedImage != null && !hasAnalyzed && !isProcessing)
            _buildConfirmationUI(theme),
          if (isProcessing) _buildProcessingOverlay(theme),
          if (capturedImage != null && hasAnalyzed && !isProcessing) ...[
            Positioned.fill(
              child: Image.file(capturedImage!, fit: BoxFit.cover),
            ),
            _buildCalculationBreakdown(currentPoints, stats, theme),
          ],
        ],
      ),
    );
  }

  // --- UI Helpers (unchanged) ---
  Widget _buildTranslucentHeader(BuildContext context, AppColors theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          top: 50,
          left: 20,
          right: 20,
          bottom: 20,
        ),
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
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _gridBox()),
                  Expanded(child: _gridBox()),
                  Expanded(child: _gridBox()),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _gridBox()),
                  Expanded(child: _gridBox()),
                  Expanded(child: _gridBox()),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _gridBox()),
                  Expanded(child: _gridBox()),
                  Expanded(child: _gridBox()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridBox() => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white30, width: 0.5),
    ),
  );

  Widget _buildCameraControls(BuildContext context, AppColors theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.only(
          bottom: 50,
          left: 24,
          right: 24,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                GestureDetector(
                  onTap: captureImage,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 6),
                    ),
                    child: Center(
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 50.0),
                      child: GestureDetector(
                        onTap: pickImageFromGallery,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: const Icon(
                              Icons.photo_library,
                              color: Colors.black54,
                            ),
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

  Widget _buildConfirmationUI(AppColors theme) {
    return Container(
      color: theme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 80.0,
                left: 24.0,
                right: 24.0,
                bottom: 30.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  capturedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: retakeImage,
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          color: theme.onSurface,
                          size: 36,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => confirmAndDetect(),
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.check,
                          color: theme.onPrimary,
                          size: 36,
                        ),
                      ),
                    ),
                  ],
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
            const Text(
              "Analyzing Item...",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationBreakdown(
    double points,
    Map<String, dynamic> stats,
    AppColors theme,
  ) {
    return Positioned(
      bottom: 50,
      left: 15,
      right: 15,
      child: Column(
        children: [
          _buildPointsAwardedCard(points, stats, theme),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: points > 0 ? () => _submitAndCollectPoints(points, stats) : null,
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
            width: double.infinity,
            height: 60,
            child: OutlinedButton.icon(
              onPressed: retakeImage,
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text(
                "RETAKE PHOTO",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "CLOSE",
                style: TextStyle(
                  color: theme.hint,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsAwardedCard(
    double points,
    Map<String, dynamic> stats,
    AppColors theme,
  ) {
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
          Text(
            "ITEMS DETECTED",
            style: TextDesign.badgeText(
              color: Colors.white.withOpacity(0.8),
            ).copyWith(letterSpacing: 1.2, fontSize: 10),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Colors.white70, size: 30),
              const SizedBox(width: 16),
              Text(
                "+${points.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          if (stats.isEmpty)
            const Text(
              "No items detected in this image.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            ...stats.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${e.key.toUpperCase()} (x${e.value['count']})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${(e.value['points'] as double).toStringAsFixed(2)} pts",
                      style: TextDesign.priceText(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
