import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

class VerifyRecycleItem extends StatefulWidget {
  const VerifyRecycleItem({super.key});

  @override
  State<VerifyRecycleItem> createState() => _VerifyRecycleItemState();
}

class _VerifyRecycleItemState extends State<VerifyRecycleItem> {
  CameraController? controller;
  Interpreter? interpreter;
  List<String> labels = [];
  File? capturedImage;
  List<Map<String, dynamic>> detections = [];
  bool isProcessing = false;
  bool isLoaded = false;
  bool isCameraInitialized = false;
  double userWallet = 0.0;

  final Map<String, double> materialDensity = {
    'plastic': 1.38,
    'glass': 2.50,
    'paper': 0.80,
    'metal': 2.70,
    'cardboard': 0.60,
  };

  final Map<String, double> baseWeights = {
    'plastic': 18.0,
    'glass': 200.0,
    'paper': 5.0,
    'metal': 15.0,
    'cardboard': 50.0,
  };

  final Map<String, int> pointValues = {
    'plastic': 10,
    'glass': 15,
    'paper': 5,
    'metal': 20,
    'cardboard': 8,
  };

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
  }

  Future<void> loadModel() async {
    try {
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      labels = labelsData.split('\n').map((e) => e.trim().toLowerCase()).toList();
      interpreter = await Interpreter.fromAsset('assets/best_model.tflite');
      setState(() => isLoaded = true);
    } catch (e) {
      debugPrint("Model Load Error: $e");
    }
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      controller = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
      await controller!.initialize();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
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
      double individualWeight = volumePixels * 0.0008 * (materialDensity[label] ?? 1.0);
      double finalWeight = individualWeight > 2.0 ? individualWeight : (baseWeights[label] ?? 5.0);

      if (!results.containsKey(label)) {
        results[label] = {
          'count': 0,
          'weight': 0.0,
          'weightKg': 0.0,
          'points': 0.0
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
      data['points'] = totalWeightKg * multiplier;
    });

    return results;
  }

  Future<void> captureAndDetect() async {
    if (controller == null || !isLoaded || !isCameraInitialized) return;
    setState(() {
      isProcessing = true;
      detections = [];
    });

    try {
      XFile file = await controller!.takePicture();
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return;

      img.Image resized = img.copyResize(image, width: 640, height: 640);
      var input = _processImage(resized);
      var output = List<double>.filled(1 * 9 * 8400, 0.0).reshape([1, 9, 8400]);

      interpreter!.run(input, output);
      _parseResults(output[0]);

      setState(() {
        capturedImage = File(file.path);
        isProcessing = false;
      });
    } catch (e) {
      setState(() => isProcessing = false);
    }
  }

  void _parseResults(List<List<double>> raw) {
    List<Map<String, dynamic>> temp = [];
    for (var i = 0; i < 8400; i++) {
      List<double> scores = [raw[4][i], raw[5][i], raw[6][i], raw[7][i], raw[8][i]];
      double score = scores.reduce((a, b) => a > b ? a : b);
      if (score > 0.45) {
        temp.add({
          "tag": labels[scores.indexOf(score)],
          "w": raw[2][i],
          "h": raw[3][i],
          "box": [raw[0][i], raw[1][i], raw[2][i], raw[3][i]]
        });
      }
    }
    detections = temp;
  }

  dynamic _processImage(img.Image imgData) {
    var buffer = Float32List(1 * 640 * 640 * 3);
    int idx = 0;
    for (var y = 0; y < 640; y++) {
      for (var x = 0; x < 640; x++) {
        var p = imgData.getPixel(x, y);
        buffer[idx++] = p.r / 255.0;
        buffer[idx++] = p.g / 255.0;
        buffer[idx++] = p.b / 255.0;
      }
    }
    return buffer.reshape([1, 640, 640, 3]);
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized || !isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _calculateStats();
    double currentPoints = stats.values.fold(0.0, (sum, item) => sum + (item['points'] as double));

    return Scaffold(
      appBar: AppBar(
        title: Text("Wallet: ${userWallet.toStringAsFixed(1)} pts"),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: capturedImage != null
                ? Image.file(capturedImage!, fit: BoxFit.cover)
                : CameraPreview(controller!),
          ),
          if (capturedImage != null && !isProcessing)
            Positioned(
              bottom: 110,
              left: 15,
              right: 15,
              child: Card(
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Calculation Breakdown",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Divider(),
                      ...stats.entries.map((e) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${e.key.toUpperCase()} (x${e.value['count']})"),
                          Text(
                            "${(e.value['weightKg'] as double).toStringAsFixed(3)}kg × ${pointValues[e.key]} = ${(e.value['points'] as double).toStringAsFixed(2)} pts",
                          ),
                        ],
                      )),
                      const Divider(),
                      Text(
                        "SESSION TOTAL: ${currentPoints.toStringAsFixed(2)} PTS",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isProcessing
          ? const CircularProgressIndicator()
          : (capturedImage == null
          ? FloatingActionButton.extended(
        onPressed: captureAndDetect,
        label: const Text("Scan Items"),
        icon: const Icon(Icons.scale),
      )
          : FloatingActionButton.extended(
        onPressed: () => setState(() {
          userWallet += currentPoints;
          capturedImage = null;
        }),
        label: const Text("Collect Points"),
        icon: const Icon(Icons.stars),
      )),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    interpreter?.close();
    super.dispose();
  }
}