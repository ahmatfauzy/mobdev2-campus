import 'dart:io';
import 'dart:typed_data';
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

  /// Preprocess gambar — model memerlukan input uint8 (0-255)
  Uint8List _preprocessImage(File imageFile) {
    final raw = img.decodeImage(imageFile.readAsBytesSync())!;
    final resized = img.copyResize(raw, width: inputSize, height: inputSize);
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

  /// Jalankan inferensi secara async (agar tidak memblokir UI thread)
  Future<Map<String, double>> classify(File imageFile) async {
    if (!_isReady || _interpreter == null || _labels == null) {
      throw Exception('Model belum dimuat. Panggil loadModel() terlebih dahulu.');
    }

    // Jalankan preprocessing di microtask terpisah agar UI tetap responsif
    final input = await Future(() {
      return _preprocessImage(imageFile).reshape([1, inputSize, inputSize, 3]);
    });

    // Output juga uint8 untuk model quantized
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

  void dispose() {
    _interpreter?.close();
  }
}