import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/classifier_service.dart';

class RealtimePage extends StatefulWidget {
  @override
  State<RealtimePage> createState() => _RealtimeState();
}

class _RealtimeState extends State<RealtimePage> {
  CameraController? _camCtrl;
  final _classifier = ClassifierService();
  bool _isProcessing = false;
  bool _modelLoading = true;
  bool _cameraReady = false;
  String? _errorMessage;
  Map<String, double>? _results;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Muat model terlebih dahulu
    try {
      await _classifier.loadModel();
      setState(() => _modelLoading = false);
    } catch (e) {
      setState(() {
        _modelLoading = false;
        _errorMessage = 'Gagal memuat model: $e';
      });
      return;
    }

    // 2. Inisialisasi kamera
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'Tidak ada kamera yang tersedia.');
        return;
      }

      _camCtrl = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _camCtrl!.initialize();

      // 3. Mulai stream frame untuk klasifikasi realtime
      _camCtrl!.startImageStream((CameraImage image) {
        if (!_isProcessing && _classifier.isReady) {
          _isProcessing = true;
          _classifyFrame(image);
        }
      });

      setState(() => _cameraReady = true);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal menginisialisasi kamera: $e');
    }
  }

  void _classifyFrame(CameraImage camImg) {
    try {
      final results = _classifier.classifyFromCameraImage(camImg);
      if (mounted) {
        setState(() {
          _results = results;
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('Error classifying frame: $e');
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Realtime Classifier',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Muhammad Iqbal Saputra', style: TextStyle(fontSize: 12)),
            Text('NIM: 23090001', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Tampilkan error jika ada
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red.shade800),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilkan loading saat model/kamera belum siap
    if (_modelLoading || !_cameraReady) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              _modelLoading ? 'Memuat model...' : 'Menginisialisasi kamera...',
            ),
          ],
        ),
      );
    }

    // Tampilkan kamera + hasil klasifikasi
    return Column(
      children: [
        // Preview kamera
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            child: CameraPreview(_camCtrl!),
          ),
        ),

        // Hasil klasifikasi
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: _results != null && _results!.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label utama
                    Center(
                      child: Text(
                        _results!.entries.first.key,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Center(
                      child: Text(
                        '${(_results!.entries.first.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Semua label
                    ..._results!.entries.map(
                      (e) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: LinearProgressIndicator(
                                value: e.value,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${(e.value * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'Arahkan kamera ke objek...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _camCtrl?.stopImageStream();
    _camCtrl?.dispose();
    _classifier.dispose();
    super.dispose();
  }
}