import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;
  static const int inputSize = 224;
  bool _isReady = false;

  bool get isReady => _isReady;

  /// Load model dan labels dari assets
  Future<void> loadModel() async {
    try {
      // fromAsset() memerlukan path SAMA PERSIS dengan yang di pubspec.yaml
      _interpreter = await Interpreter.fromAsset('assets/ml/model.tflite');
      final labelData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelData.split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.replaceAll(RegExp(r'^\d+\s*'), ''))
          .toList();
      _isReady = true;
      print('Model loaded successfully. Labels: $_labels');
    } catch (e) {
      print('Error loading model: $e');
      _isReady = false;
      rethrow;
    }
  }

  /// Konversi img.Image ke Uint8List RGB (0-255) untuk model quantized
  Uint8List _imageToInputBuffer(img.Image image) {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    var buf = Uint8List(1 * inputSize * inputSize * 3);
    int idx = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        buf[idx++] = p.r.toInt();
        buf[idx++] = p.g.toInt();
        buf[idx++] = p.b.toInt();
      }
    }
    return buf;
  }

  /// Jalankan inferensi dari buffer input
  Map<String, double> _runInference(Uint8List inputBuffer) {
    final input = inputBuffer.reshape([1, inputSize, inputSize, 3]);
    var output = Uint8List(_labels!.length).reshape([1, _labels!.length]);
    _interpreter!.run(input, output);

    // Konversi output uint8 ke probabilitas (0.0 - 1.0)
    final results = <String, double>{};
    for (int i = 0; i < _labels!.length; i++) {
      results[_labels![i]] = (output[0][i] as int) / 255.0;
    }

    return Map.fromEntries(results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
  }

  Future<Map<String, double>> classify(File imageFile) async {
    if (!_isReady || _interpreter == null || _labels == null) {
      throw Exception('Model belum dimuat. Panggil loadModel() terlebih dahulu.');
    }

    final buffer = await Future(() {
      final raw = img.decodeImage(imageFile.readAsBytesSync())!;
      return _imageToInputBuffer(raw);
    });

    return _runInference(buffer);
  }

 img.Image _convertCameraImage(CameraImage camImg) {
    final width = camImg.width;
    final height = camImg.height;
    final image = img.Image(width: width, height: height);

    final yPlane = camImg.planes[0];
    final uPlane = camImg.planes[1];
    final vPlane = camImg.planes[2];

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yVal = yPlane.bytes[yIndex];
        final uVal = uPlane.bytes[uvIndex];
        final vVal = vPlane.bytes[uvIndex];

        // YUV -> RGB conversion
        int r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
        int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
            .round().clamp(0, 255);
        int b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  Map<String, double> classifyFromCameraImage(CameraImage camImg) {
    if (!_isReady || _interpreter == null || _labels == null) {
      return {};
    }

    final image = _convertCameraImage(camImg);
    final buffer = _imageToInputBuffer(image);
    return _runInference(buffer);
  }

  void dispose() {
    _interpreter?.close();
  }
}