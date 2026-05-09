import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/classifier_with_delegate.dart';

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage>
    with SingleTickerProviderStateMixin {
  final _classifier = ClassifierWithDelegate();
  final _picker = ImagePicker();
  File? _selectedImage;
  List<BenchmarkSummary>? _results;
  bool _isRunning = false;
  String _progressText = '';
  int _iterations = 10;

  static const _delegateInfo = {
    DelegateType.cpu: {
      'label': 'CPU',
      'icon': Icons.memory_rounded,
      'color': Colors.blue,
      'desc': 'Default, kompatibel semua perangkat',
    },
    DelegateType.gpu: {
      'label': 'GPU',
      'icon': Icons.settings_input_component_rounded,
      'color': Colors.green,
      'desc': 'Akselerasi via OpenGL/OpenCL',
    },
    DelegateType.nnapi: {
      'label': 'NNAPI',
      'icon': Icons.hub_rounded,
      'color': Colors.orange,
      'desc': 'Android Neural Networks API',
    },
  };

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _results = null;
    });
  }

  Future<void> _runBenchmark() async {
    if (_selectedImage == null) return;

    setState(() {
      _isRunning = true;
      _results = null;
      _progressText = 'Memulai benchmark...';
    });

    try {
      final results = await _classifier.runBenchmark(
        _selectedImage!,
        iterations: _iterations,
        onProgress: (delegate, current, total) {
          if (mounted) {
            setState(() {
              final label = _delegateInfo[delegate]!['label'] as String;
              _progressText = '$label: $current / $total';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _results = results;
          _isRunning = false;
          _progressText = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _progressText = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Benchmark',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bandingkan kecepatan inferensi antar delegate hardware.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Configuration Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!,
                            height: 120, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isRunning ? null : _pickImage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(_selectedImage == null ? 'Pilih Gambar' : 'Ganti'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: (_isRunning || _selectedImage == null) ? null : _runBenchmark,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isRunning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.play_arrow_rounded),
                          label: Text(_isRunning ? 'Running' : 'Mulai'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Iterasi:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Expanded(
                        child: Slider(
                          value: _iterations.toDouble(),
                          min: 5,
                          max: 50,
                          divisions: 9,
                          label: '$_iterations',
                          onChanged: _isRunning ? null : (v) => setState(() => _iterations = v.toInt()),
                        ),
                      ),
                      Text('$_iterations', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isRunning && _progressText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(_progressText, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(borderRadius: BorderRadius.circular(10), minHeight: 8),
                ],
              ),
            ),
          ],

          if (_results != null) ...[
            const SizedBox(height: 32),
            Text(
              'Analisis Hasil',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChartSection(theme),
            const SizedBox(height: 16),
            ..._results!.map((r) => _buildDetailCard(r, theme)),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme) {
    final successResults = _results!.where((r) => r.successRuns > 0).toList();
    if (successResults.isEmpty) return const SizedBox.shrink();

    final maxTime = successResults.map((r) => r.maxTimeMs).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Waktu Rata-rata (ms)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...successResults.map((r) {
              final info = _delegateInfo[r.delegate]!;
              final color = info['color'] as Color;
              final label = info['label'] as String;
              final ratio = maxTime > 0 ? r.avgTimeMs / maxTime : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(info['icon'] as IconData, size: 20, color: color),
                        const SizedBox(width: 8),
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('${r.avgTimeMs.toStringAsFixed(2)} ms',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 12,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BenchmarkSummary r, ThemeData theme) {
    final info = _delegateInfo[r.delegate]!;
    final color = info['color'] as Color;
    final label = info['label'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(info['icon'] as IconData, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (r.error != null)
                Text('Error', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold))
              else
                Text('Success: ${r.successRuns}/${r.totalRuns}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          if (r.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(r.error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            )
          else ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Min', r.minTimeMs, Colors.green),
                _buildStatColumn('Avg', r.avgTimeMs, color),
                _buildStatColumn('Max', r.maxTimeMs, Colors.red),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('${value.toStringAsFixed(1)}ms',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }
}
