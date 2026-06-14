import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PerformanceMetrics {
  final double tokensPerSecond;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final Duration loadTime;
  final Duration generationTime;
  final int vramUsageMB;
  final int ramUsageMB;
  final double cpuUsagePercent;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.tokensPerSecond,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.loadTime,
    required this.generationTime,
    this.vramUsageMB = 0,
    this.ramUsageMB = 0,
    this.cpuUsagePercent = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get tokensPerSecondLabel => tokensPerSecond.toStringAsFixed(1);
  String get loadTimeLabel => '${loadTime.inMilliseconds}ms';
  String get generationTimeLabel => '${(generationTime.inMilliseconds / 1000).toStringAsFixed(1)}s';
}

class PerformanceMonitor {
  final List<PerformanceMetrics> _history = [];
  final _metricsController = StreamController<PerformanceMetrics>.broadcast();
  Timer? _monitorTimer;

  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;
  List<PerformanceMetrics> get history => List.unmodifiable(_history);
  PerformanceMetrics? get latest => _history.isNotEmpty ? _history.last : null;

  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(interval, (_) => _collectMetrics());
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  Future<void> _collectMetrics() async {
    try {
      int ramUsage = 0;
      double cpuUsage = 0;

      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'OS', 'get', 'TotalVisibleMemorySize,FreePhysicalMemory', '/format:value'
        ]);
        final output = result.stdout.toString();
        final totalMatch = RegExp(r'TotalVisibleMemorySize=(\d+)').firstMatch(output);
        final freeMatch = RegExp(r'FreePhysicalMemory=(\d+)').firstMatch(output);
        if (totalMatch != null && freeMatch != null) {
          final total = int.parse(totalMatch.group(1)!);
          final free = int.parse(freeMatch.group(1)!);
          ramUsage = ((total - free) / 1024).round();
        }

        final cpuResult = await Process.run('wmic', [
          'cpu', 'get', 'LoadPercentage', '/format:value'
        ]);
        final cpuOutput = cpuResult.stdout.toString();
        final cpuMatch = RegExp(r'LoadPercentage=(\d+)').firstMatch(cpuOutput);
        if (cpuMatch != null) {
          cpuUsage = double.parse(cpuMatch.group(1)!);
        }
      } else if (Platform.isLinux) {
        final result = await Process.run('free', ['-m']);
        final output = result.stdout.toString();
        final match = RegExp(r'buffers/cache:\s+(\d+)').firstMatch(output);
        if (match != null) {
          ramUsage = int.parse(match.group(1)!);
        }
      }

      final metrics = PerformanceMetrics(
        tokensPerSecond: 0,
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: 0,
        loadTime: Duration.zero,
        generationTime: Duration.zero,
        ramUsageMB: ramUsage,
        cpuUsagePercent: cpuUsage,
      );

      _history.add(metrics);
      if (_history.length > 100) {
        _history.removeAt(0);
      }

      _metricsController.add(metrics);
    } catch (e) {
      debugPrint('Performance monitoring error: $e');
    }
  }

  void recordGeneration({
    required int promptTokens,
    required int completionTokens,
    required Duration loadTime,
    required Duration generationTime,
  }) {
    final tokensPerSecond = completionTokens > 0 && generationTime.inMilliseconds > 0
        ? completionTokens / (generationTime.inMilliseconds / 1000)
        : 0.0;

    final metrics = PerformanceMetrics(
      tokensPerSecond: tokensPerSecond,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: promptTokens + completionTokens,
      loadTime: loadTime,
      generationTime: generationTime,
    );

    _history.add(metrics);
    _metricsController.add(metrics);
  }

  double get averageTokensPerSecond {
    if (_history.isEmpty) return 0;
    final sum = _history.fold(0.0, (sum, m) => sum + m.tokensPerSecond);
    return sum / _history.length;
  }

  Duration get averageLoadTime {
    if (_history.isEmpty) return Duration.zero;
    final sum = _history.fold(0, (sum, m) => sum + m.loadTime.inMilliseconds);
    return Duration(milliseconds: sum ~/ _history.length);
  }

  Duration get averageGenerationTime {
    if (_history.isEmpty) return Duration.zero;
    final sum = _history.fold(0, (sum, m) => sum + m.generationTime.inMilliseconds);
    return Duration(milliseconds: sum ~/ _history.length);
  }

  void clear() {
    _history.clear();
  }

  void dispose() {
    stopMonitoring();
    _metricsController.close();
  }
}
