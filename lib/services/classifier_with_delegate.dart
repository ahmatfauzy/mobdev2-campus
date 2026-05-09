import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Jenis delegate yang didukung
enum DelegateType { cpu, gpu, nnapi }

/// Hasil benchmark per satu kali inferensi
class BenchmarkResult {
  final DelegateType delegate;
  final Map<String, double> predictions;
  final double inferenceTimeMs;
  final bool success;
  final String? error;

  BenchmarkResult({
    required this.delegate,
    required this.predictions,
    required this.inferenceTimeMs,
    this.success = true,
    this.error,
  });
}

/// Hasil benchmark lengkap (rata-rata dari N iterasi)
class BenchmarkSummary {
  final DelegateType delegate;
  final double avgTimeMs;
  final double minTimeMs;
  final double maxTimeMs;
  final int totalRuns;
  final int successRuns;
  final String? error;

  BenchmarkSummary({
    required this.delegate,
    required this.avgTimeMs,
    required this.minTimeMs,
    required this.maxTimeMs,
    required this.totalRuns,
    required this.successRuns,
    this.error,
  });
}

class ClassifierWithDelegate {
  List<String>? _labels;
  static const int inputSize = 224;

  /// Load labels dari assets
  Future<void> loadLabels() async {
    final labelData = await rootBundle.loadString('assets/ml/labels.txt');
    _labels = labelData
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.replaceAll(RegExp(r'^\d+\s*'), ''))
        .toList();
  }

  /// Buat Interpreter dengan delegate tertentu
  Future<Interpreter> _createInterpreter(DelegateType delegate) async {
    final options = InterpreterOptions();

    switch (delegate) {
      case DelegateType.gpu:
        options.addDelegate(GpuDelegateV2());
        break;
      case DelegateType.nnapi:
        // NNAPI diaktifkan via flag, bukan class delegate terpisah
        options.useNnApiForAndroid = true;
        break;
      case DelegateType.cpu:
        // Default — tanpa delegate tambahan, gunakan CPU
        // Bisa set jumlah thread untuk optimasi CPU
        options.threads = 4;
        break;
    }

    return await Interpreter.fromAsset(
      'assets/ml/model.tflite',
      options: options,
    );
  }

  /// Konversi img.Image ke Uint8List RGB (0-255)
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

  /// Jalankan inferensi satu kali dengan delegate tertentu
  Future<BenchmarkResult> classifyWithDelegate(
    File imageFile,
    DelegateType delegate,
  ) async {
    if (_labels == null) await loadLabels();

    Interpreter? interpreter;
    try {
      interpreter = await _createInterpreter(delegate);

      // Preprocessing
      final raw = img.decodeImage(imageFile.readAsBytesSync())!;
      final inputBuffer = _imageToInputBuffer(raw);
      final input = inputBuffer.reshape([1, inputSize, inputSize, 3]);
      var output = Uint8List(_labels!.length).reshape([1, _labels!.length]);

      // Ukur waktu inferensi saja (tanpa preprocessing)
      final stopwatch = Stopwatch()..start();
      interpreter.run(input, output);
      stopwatch.stop();

      // Parse hasil
      final results = <String, double>{};
      for (int i = 0; i < _labels!.length; i++) {
        results[_labels![i]] = (output[0][i] as int) / 255.0;
      }

      final sorted = Map.fromEntries(
        results.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );

      return BenchmarkResult(
        delegate: delegate,
        predictions: sorted,
        inferenceTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
      );
    } catch (e) {
      return BenchmarkResult(
        delegate: delegate,
        predictions: {},
        inferenceTimeMs: 0,
        success: false,
        error: e.toString(),
      );
    } finally {
      interpreter?.close();
    }
  }

  /// Jalankan benchmark lengkap: N iterasi untuk setiap delegate
  Future<List<BenchmarkSummary>> runBenchmark(
    File imageFile, {
    int iterations = 10,
    void Function(DelegateType delegate, int current, int total)? onProgress,
  }) async {
    if (_labels == null) await loadLabels();

    final summaries = <BenchmarkSummary>[];

    for (final delegate in DelegateType.values) {
      Interpreter? interpreter;
      final times = <double>[];
      String? error;

      try {
        interpreter = await _createInterpreter(delegate);

        // Preprocessing sekali saja
        final raw = img.decodeImage(imageFile.readAsBytesSync())!;
        final inputBuffer = _imageToInputBuffer(raw);

        // Warmup 1 kali
        final warmupInput = inputBuffer.reshape([1, inputSize, inputSize, 3]);
        var warmupOutput =
            Uint8List(_labels!.length).reshape([1, _labels!.length]);
        interpreter.run(warmupInput, warmupOutput);

        // Jalankan N iterasi
        for (int i = 0; i < iterations; i++) {
          onProgress?.call(delegate, i + 1, iterations);

          final input = inputBuffer.reshape([1, inputSize, inputSize, 3]);
          var output =
              Uint8List(_labels!.length).reshape([1, _labels!.length]);

          final stopwatch = Stopwatch()..start();
          interpreter.run(input, output);
          stopwatch.stop();

          times.add(stopwatch.elapsedMicroseconds / 1000.0);

          // Sedikit jeda agar UI tetap responsif
          await Future.delayed(Duration(milliseconds: 10));
        }
      } catch (e) {
        error = e.toString();
      } finally {
        interpreter?.close();
      }

      if (times.isNotEmpty) {
        times.sort();
        final avg = times.reduce((a, b) => a + b) / times.length;
        summaries.add(BenchmarkSummary(
          delegate: delegate,
          avgTimeMs: avg,
          minTimeMs: times.first,
          maxTimeMs: times.last,
          totalRuns: iterations,
          successRuns: times.length,
        ));
      } else {
        summaries.add(BenchmarkSummary(
          delegate: delegate,
          avgTimeMs: 0,
          minTimeMs: 0,
          maxTimeMs: 0,
          totalRuns: iterations,
          successRuns: 0,
          error: error ?? 'Delegate tidak didukung pada perangkat ini',
        ));
      }
    }

    return summaries;
  }
}
