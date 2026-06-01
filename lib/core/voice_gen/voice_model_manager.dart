import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../ai/downloadable_model.dart';
import '../ai/model_downloader.dart';
import '../ai/model_registry.dart';

enum VoiceModelStatus { notDownloaded, downloading, paused, ready, error }

class VoiceModelState implements DownloadableState {
  final VoiceModelStatus status;
  @override
  final double progress;
  @override
  final String? error;
  @override
  final String? modelId;
  final String? onnxPath;
  final String? configPath;

  const VoiceModelState({
    this.status = VoiceModelStatus.notDownloaded,
    this.progress = 0.0,
    this.error,
    this.modelId,
    this.onnxPath,
    this.configPath,
  });

  VoiceModelState copyWith({
    VoiceModelStatus? status,
    double? progress,
    String? error,
    String? modelId,
    String? onnxPath,
    String? configPath,
  }) {
    return VoiceModelState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      modelId: modelId ?? this.modelId,
      onnxPath: onnxPath ?? this.onnxPath,
      configPath: configPath ?? this.configPath,
    );
  }

  @override
  bool get isReady => status == VoiceModelStatus.ready && onnxPath != null;
  @override
  bool get isDownloading => status == VoiceModelStatus.downloading;
  @override
  bool get isPaused => status == VoiceModelStatus.paused;
  @override
  bool get hasError => status == VoiceModelStatus.error;

  @override
  String get statusLabel {
    switch (status) {
      case VoiceModelStatus.notDownloaded:
        return 'NOT DOWNLOADED';
      case VoiceModelStatus.downloading:
        return 'DOWNLOADING ${(progress * 100).toStringAsFixed(0)}%';
      case VoiceModelStatus.paused:
        return 'PAUSED ${(progress * 100).toStringAsFixed(0)}%';
      case VoiceModelStatus.ready:
        return 'READY';
      case VoiceModelStatus.error:
        return 'ERROR';
    }
  }
}

class VoiceModelManager extends StateNotifier<VoiceModelState> {
  VoiceModelManager() : super(const VoiceModelState());

  final ModelDownloader _downloader = ModelDownloader(throwOnCancel: true);

  static const _prefsKeyModelId = 'voice_model_id';
  static const _prefsKeyOnnxPath = 'voice_onnx_path';
  static const _prefsKeyConfigPath = 'voice_config_path';

  Future<void> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsKeyModelId);
    final savedOnnx = prefs.getString(_prefsKeyOnnxPath);
    final savedConfig = prefs.getString(_prefsKeyConfigPath);

    if (savedId != null && savedOnnx != null) {
      final file = File(savedOnnx);
      if (await file.exists()) {
        state = VoiceModelState(
          status: VoiceModelStatus.ready,
          progress: 1.0,
          modelId: savedId,
          onnxPath: savedOnnx,
          configPath: savedConfig,
        );
        return;
      }
      await prefs.remove(_prefsKeyModelId);
      await prefs.remove(_prefsKeyOnnxPath);
      await prefs.remove(_prefsKeyConfigPath);
    }
    await _scanForModels();
  }

  Future<void> _scanForModels() async {
    try {
      final dir = await _getVoiceDirectory();
      if (!await dir.exists()) return;
      final files = await dir.list().toList();
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.onnx')) {
          final configFile = File('${entity.path}.json');
          state = VoiceModelState(
            status: VoiceModelStatus.ready,
            progress: 1.0,
            modelId: 'detected',
            onnxPath: entity.path,
            configPath: await configFile.exists() ? configFile.path : null,
          );
          break;
        }
      }
    } catch (_) {}
  }

  Future<void> downloadModel(ModelInfo model, {String? hfToken}) async {
    if (kIsWeb) {
      state = state.copyWith(
        status: VoiceModelStatus.error,
        error: 'Voice model download is not supported on web',
      );
      return;
    }

    try {
      await WakelockPlus.enable();
    } catch (_) {}

    state = VoiceModelState(
      status: VoiceModelStatus.downloading,
      progress: 0.0,
      modelId: model.id,
    );

    try {
      final dir = await _getVoiceDirectory();
      final onnxFileName = model.fileName.split('/').last;
      final onnxPath = '${dir.path}/$onnxFileName';
      final configPath = '${dir.path}/$onnxFileName.json';
      debugPrint('VOICE_DL: Starting download of ${model.id}');
      debugPrint('VOICE_DL: onnx URL=https://huggingface.co/${model.huggingFaceRepo}/resolve/main/${model.fileName}');
      debugPrint('VOICE_DL: onnx path=$onnxPath');

      // Download .onnx file
      final onnxResult = await _downloader.downloadModel(
        url: model.downloadUrl,
        fileName: onnxFileName,
        destinationDir: dir.path,
        sizeMB: model.sizeMB,
        hfToken: hfToken,
        userAgent: 'ambot-ai/1.0',
        onProgress: (p) {
          state = VoiceModelState(
            status: VoiceModelStatus.downloading,
            progress: p,
            modelId: model.id,
          );
        },
        onVerifying: () {
          state = VoiceModelState(
            status: VoiceModelStatus.downloading,
            progress: 1.0,
            modelId: model.id,
          );
        },
      );

      if (onnxResult == null) return;

      // Download .json config from same HF path as model (non-fatal)
      final configModel = ModelInfo(
        id: '${model.id}-config',
        name: '${model.name} Config',
        params: 'N/A',
        quantization: 'N/A',
        sizeMB: 1,
        minRamMB: 0,
        minStorageMB: 10,
        targetTier: model.targetTier,
        huggingFaceRepo: model.huggingFaceRepo,
        fileName: '${model.fileName}.json',
        modelType: ModelType.voice,
      );
      debugPrint('VOICE_DL: configModel fileName=${configModel.fileName}');
      debugPrint('VOICE_DL: config path=$configPath');

      try {
        await _downloader.downloadModel(
          url: configModel.downloadUrl,
          fileName: '$onnxFileName.json',
          destinationDir: dir.path,
          sizeMB: 1,
          hfToken: hfToken,
          userAgent: 'ambot-ai/1.0',
          onProgress: (p) {
            state = VoiceModelState(
              status: VoiceModelStatus.downloading,
              progress: p,
              modelId: model.id,
            );
          },
        );
      } catch (e) {
        if (_downloader.isCancelRequested) return;
        debugPrint('VOICE_DL: Config download failed (non-fatal): $e');
      }

      // Save state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyModelId, model.id);
      await prefs.setString(_prefsKeyOnnxPath, onnxPath);
      await prefs.setString(_prefsKeyConfigPath, configPath);

      state = VoiceModelState(
        status: VoiceModelStatus.ready,
        progress: 1.0,
        modelId: model.id,
        onnxPath: onnxPath,
        configPath: configPath,
      );
      debugPrint('VOICE_DL: READY state set for ${model.id}');
    } catch (e, s) {
      debugPrint('VOICE_DL: DOWNLOAD FAILED for ${model.id}: $e');
      debugPrint('VOICE_DL: Stack: $s');
      state = VoiceModelState(
        status: VoiceModelStatus.paused,
        progress: state.progress,
        modelId: model.id,
      );
    } finally {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }
  }

  void cancelDownload() {
    _downloader.cancelDownload();
  }

  Future<void> deleteModel() async {
    final prefs = await SharedPreferences.getInstance();
    final onnxPath = prefs.getString(_prefsKeyOnnxPath);
    final configPath = prefs.getString(_prefsKeyConfigPath);

    if (onnxPath != null) {
      try { await File(onnxPath).delete(); } catch (_) {}
    }
    if (configPath != null) {
      try { await File(configPath).delete(); } catch (_) {}
    }

    await prefs.remove(_prefsKeyModelId);
    await prefs.remove(_prefsKeyOnnxPath);
    await prefs.remove(_prefsKeyConfigPath);

    state = const VoiceModelState();
  }

  Future<Directory> _getVoiceDirectory() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final dir = Directory('${extDir.path}/models/voices');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          return dir;
        }
      } catch (_) {}
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/models/voices');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
