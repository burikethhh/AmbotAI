import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'model_download_manager.dart';

class HardwareInfo {
  final int ramMB;
  final int cpuCores;
  final String? gpuName;
  final int gpuVRAMMB;
  final bool hasCUDA;
  final bool hasMetal;
  final bool hasVulkan;

  const HardwareInfo({
    required this.ramMB,
    required this.cpuCores,
    this.gpuName,
    this.gpuVRAMMB = 0,
    this.hasCUDA = false,
    this.hasMetal = false,
    this.hasVulkan = false,
  });

  bool get hasDedicatedGPU => gpuVRAMMB > 0;
  bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  bool get isMobile => Platform.isAndroid || Platform.isIOS;

  String get gpuSummary {
    if (gpuName == null) return 'No GPU detected';
    return '$gpuName ($gpuVRAMMB MB VRAM)';
  }

  String get ramSummary {
    if (ramMB >= 1024) {
      return '${(ramMB / 1024).toStringAsFixed(1)} GB';
    }
    return '$ramMB MB';
  }
}

enum PerformanceTier {
  low,
  medium,
  high,
  ultra,
}

class ModelRecommendation {
  final LocalModelInfo model;
  final double score;
  final String reason;
  final PerformanceTier tier;
  final bool isRecommended;

  const ModelRecommendation({
    required this.model,
    required this.score,
    required this.reason,
    required this.tier,
    this.isRecommended = false,
  });
}

class ModelRecommendationEngine {
  final ModelDownloadManager _downloadManager;

  ModelRecommendationEngine(this._downloadManager);

  Future<HardwareInfo> detectHardware() async {
    int ramMB = 4096;
    int cpuCores = 4;
    String? gpuName;
    int gpuVRAMMB = 0;
    bool hasCUDA = false;
    bool hasMetal = false;
    bool hasVulkan = false;

    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'memorychip', 'get', 'capacity', '/format:value'
        ]);
        final output = result.stdout.toString();
        final match = RegExp(r'Capacity=(\d+)').firstMatch(output);
        if (match != null) {
          ramMB = (int.parse(match.group(1)!) / 1048576).round();
        }

        final cpuResult = await Process.run('wmic', [
          'cpu', 'get', 'NumberOfCores', '/format:value'
        ]);
        final cpuOutput = cpuResult.stdout.toString();
        final cpuMatch = RegExp(r'NumberOfCores=(\d+)').firstMatch(cpuOutput);
        if (cpuMatch != null) {
          cpuCores = int.parse(cpuMatch.group(1)!);
        }

        final gpuResult = await Process.run('wmic', [
          'path', 'win32_videocontroller', 'get', 'name,AdapterRAM', '/format:value'
        ]);
        final gpuOutput = gpuResult.stdout.toString();
        final gpuNameMatch = RegExp(r'Name=(.+)').firstMatch(gpuOutput);
        if (gpuNameMatch != null) {
          gpuName = gpuNameMatch.group(1)!.trim();
        }
        final vramMatch = RegExp(r'AdapterRAM=(\d+)').firstMatch(gpuOutput);
        if (vramMatch != null) {
          gpuVRAMMB = (int.parse(vramMatch.group(1)!) / 1048576).round();
        }

        hasCUDA = gpuName?.toLowerCase().contains('nvidia') ?? false;
        hasVulkan = true;
      } else if (Platform.isMacOS) {
        final result = await Process.run('sysctl', ['hw.memsize']);
        final output = result.stdout.toString();
        final match = RegExp(r'hw.memsize:\s+(\d+)').firstMatch(output);
        if (match != null) {
          ramMB = (int.parse(match.group(1)!) / 1048576).round();
        }

        final cpuResult = await Process.run('sysctl', ['hw.ncpu']);
        final cpuOutput = cpuResult.stdout.toString();
        final cpuMatch = RegExp(r'hw.ncpu:\s+(\d+)').firstMatch(cpuOutput);
        if (cpuMatch != null) {
          cpuCores = int.parse(cpuMatch.group(1)!);
        }

        gpuName = 'Apple GPU';
        hasMetal = true;
      } else if (Platform.isLinux) {
        final result = await Process.run('free', ['-m']);
        final output = result.stdout.toString();
        final match = RegExp(r'Mem:\s+(\d+)').firstMatch(output);
        if (match != null) {
          ramMB = int.parse(match.group(1)!);
        }

        final cpuResult = await Process.run('nproc', []);
        cpuCores = int.parse(cpuResult.stdout.toString().trim());
      } else if (Platform.isAndroid) {
        final result = await Process.run('cat', ['/proc/meminfo']);
        final output = result.stdout.toString();
        final match = RegExp(r'MemTotal:\s+(\d+) kB').firstMatch(output);
        if (match != null) {
          ramMB = (int.parse(match.group(1)!) / 1024).round();
        }
      }
    } catch (e) {
      debugPrint('Hardware detection error: $e');
    }

    return HardwareInfo(
      ramMB: ramMB,
      cpuCores: cpuCores,
      gpuName: gpuName,
      gpuVRAMMB: gpuVRAMMB,
      hasCUDA: hasCUDA,
      hasMetal: hasMetal,
      hasVulkan: hasVulkan,
    );
  }

  PerformanceTier _determineTier(HardwareInfo hw) {
    if (hw.ramMB >= 32768 && hw.gpuVRAMMB >= 8192) {
      return PerformanceTier.ultra;
    }
    if (hw.ramMB >= 16384 && hw.gpuVRAMMB >= 4096) {
      return PerformanceTier.high;
    }
    if (hw.ramMB >= 8192) {
      return PerformanceTier.medium;
    }
    return PerformanceTier.low;
  }

  Future<List<ModelRecommendation>> getRecommendations() async {
    final hw = await detectHardware();
    final tier = _determineTier(hw);
    final models = await _downloadManager.getAvailableModels();
    final recommendations = <ModelRecommendation>[];

    for (final model in models) {
      final score = _scoreModel(model, hw, tier);
      final reason = _explainScore(model, hw, tier);
      final modelTier = _modelTier(model);

      recommendations.add(ModelRecommendation(
        model: model,
        score: score,
        reason: reason,
        tier: modelTier,
      ));
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));

    if (recommendations.isNotEmpty) {
      recommendations[0] = ModelRecommendation(
        model: recommendations[0].model,
        score: recommendations[0].score,
        reason: recommendations[0].reason,
        tier: recommendations[0].tier,
        isRecommended: true,
      );
    }

    return recommendations;
  }

  double _scoreModel(LocalModelInfo model, HardwareInfo hw, PerformanceTier tier) {
    double score = 50;

    if (model.sizeBytes <= hw.ramMB * 1048576 * 0.5) {
      score += 20;
    } else if (model.sizeBytes <= hw.ramMB * 1048576 * 0.8) {
      score += 10;
    } else {
      score -= 20;
    }

    if (hw.hasDedicatedGPU) {
      if (model.sizeBytes <= hw.gpuVRAMMB * 1048576) {
        score += 15;
      }
    }

    switch (tier) {
      case PerformanceTier.ultra:
        if (model.sizeBytes >= 4000000000) score += 10;
        break;
      case PerformanceTier.high:
        if (model.sizeBytes >= 2000000000 && model.sizeBytes <= 5000000000) {
          score += 10;
        }
        break;
      case PerformanceTier.medium:
        if (model.sizeBytes >= 1000000000 && model.sizeBytes <= 3000000000) {
          score += 10;
        }
        break;
      case PerformanceTier.low:
        if (model.sizeBytes <= 1500000000) score += 10;
        break;
    }

    if (model.quantization.contains('Q4')) score += 5;
    if (model.contextSize >= 4096) score += 5;

    return score.clamp(0, 100);
  }

  String _explainScore(LocalModelInfo model, HardwareInfo hw, PerformanceTier tier) {
    final reasons = <String>[];

    if (model.sizeBytes <= hw.ramMB * 1048576 * 0.5) {
      reasons.add('Fits comfortably in RAM');
    } else if (model.sizeBytes <= hw.ramMB * 1048576 * 0.8) {
      reasons.add('May use most of available RAM');
    } else {
      reasons.add('Exceeds available RAM');
    }

    if (hw.hasDedicatedGPU && model.sizeBytes <= hw.gpuVRAMMB * 1048576) {
      reasons.add('Can run on GPU');
    }

    if (model.quantization.contains('Q4')) {
      reasons.add('Good quality/size balance');
    }

    return reasons.join('. ');
  }

  PerformanceTier _modelTier(LocalModelInfo model) {
    if (model.sizeBytes >= 4000000000) return PerformanceTier.ultra;
    if (model.sizeBytes >= 2000000000) return PerformanceTier.high;
    if (model.sizeBytes >= 1000000000) return PerformanceTier.medium;
    return PerformanceTier.low;
  }

  Future<LocalModelInfo?> getRecommendedModel() async {
    final recommendations = await getRecommendations();
    if (recommendations.isEmpty) return null;
    return recommendations.first.model;
  }
}
