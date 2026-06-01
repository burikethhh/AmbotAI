import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'downloadable_model.dart';
import 'model_downloader.dart';
import 'model_registry.dart';

// --- Image Model State ---

enum ImageModelStatus { notDownloaded, downloading, paused, verifying, ready, error }

class ImageModelState implements DownloadableState {
  final ImageModelStatus status;
  @override
  final double progress;
  @override
  final String? error;
  @override
  final String? modelId;
  final String? localPath;
  final String? taesdPath;

  const ImageModelState({
    this.status = ImageModelStatus.notDownloaded,
    this.progress = 0.0,
    this.error,
    this.modelId,
    this.localPath,
    this.taesdPath,
  });

  ImageModelState copyWith({
    ImageModelStatus? status,
    double? progress,
    String? error,
    String? modelId,
    String? localPath,
    String? taesdPath,
  }) {
    return ImageModelState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      modelId: modelId ?? this.modelId,
      localPath: localPath ?? this.localPath,
      taesdPath: taesdPath ?? this.taesdPath,
    );
  }

  @override
  bool get isReady => status == ImageModelStatus.ready && localPath != null;
  @override
  bool get isDownloading => status == ImageModelStatus.downloading;
  @override
  bool get isPaused => status == ImageModelStatus.paused;
  @override
  bool get hasError => status == ImageModelStatus.error;

  @override
  String get statusLabel {
    switch (status) {
      case ImageModelStatus.notDownloaded:
        return 'NOT DOWNLOADED';
      case ImageModelStatus.downloading:
        return 'DOWNLOADING ${(progress * 100).toStringAsFixed(0)}%';
      case ImageModelStatus.paused:
        return 'PAUSED ${(progress * 100).toStringAsFixed(0)}%';
      case ImageModelStatus.verifying:
        return 'VERIFYING';
      case ImageModelStatus.ready:
        return 'READY';
      case ImageModelStatus.error:
        return 'ERROR';
    }
  }

  /// Get recommended steps for the loaded model.
  int get recommendedSteps {
    if (modelId == null) return 20;
    return ModelRegistry.getRecommendedSteps(modelId!);
  }
}

// --- Image Model Manager ---

class ImageModelManager extends StateNotifier<ImageModelState> {
  ImageModelManager() : super(const ImageModelState());

  final ModelDownloader _downloader = ModelDownloader(throwOnCancel: false);

  static const _prefsKeyModelId = 'image_model_id';
  static const _prefsKeyModelPath = 'image_model_path';
  static const _prefsKeyTaesdPath = 'image_taesd_path';

  /// Load previously downloaded image model state.
  Future<void> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsKeyModelId);
    final savedPath = prefs.getString(_prefsKeyModelPath);
    final savedTaesdPath = prefs.getString(_prefsKeyTaesdPath);

    if (savedId != null && savedPath != null) {
      final file = File(savedPath);
      if (await file.exists()) {
        debugPrint('AMBOT_DL: loadSavedState found existing model at $savedPath');
        state = ImageModelState(
          status: ImageModelStatus.ready,
          progress: 1.0,
          modelId: savedId,
          localPath: savedPath,
          taesdPath: savedTaesdPath,
        );
        return;
      }
      debugPrint('AMBOT_DL: loadSavedState saved file gone, clearing prefs');
      await prefs.remove(_prefsKeyModelId);
      await prefs.remove(_prefsKeyModelPath);
    }

    // Scan for surviving image models
    await _scanForModels();
  }

  /// Download an image model from Hugging Face.
  Future<void> downloadModel(ModelInfo model, {String? hfToken}) async {
    if (kIsWeb) {
      state = state.copyWith(
        status: ImageModelStatus.error,
        error: 'Model download is not supported on web',
      );
      return;
    }

    try {
      await WakelockPlus.enable();
    } catch (_) {}

    state = ImageModelState(
      status: ImageModelStatus.downloading,
      progress: 0.0,
      modelId: model.id,
    );

    try {
      final dir = await _getModelsDirectory();
      debugPrint('AMBOT_DL: Starting download of ${model.id}');
      debugPrint('AMBOT_DL: URL=${model.downloadUrl}');
      debugPrint('AMBOT_DL: Path=${dir.path}/${model.fileName}');

      final result = await _downloader.downloadModel(
        url: model.downloadUrl,
        fileName: model.fileName,
        destinationDir: dir.path,
        sizeMB: model.sizeMB,
        hfToken: hfToken,
        onProgress: (p) {
          state = state.copyWith(progress: p.clamp(0.0, 1.0));
        },
        onVerifying: () {
          state = state.copyWith(status: ImageModelStatus.verifying);
        },
      );

      if (result == null) return;

      debugPrint('AMBOT_DL: HTTP response OK, file saved to $result');

      // Save to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyModelId, model.id);
      await prefs.setString(_prefsKeyModelPath, result);

      // Also download TAESD if not present
      String? taesdPath;
      final taesdModel = ModelRegistry.getTaesdModel();
      if (taesdModel != null) {
        final taesdFile = File('${dir.path}/${taesdModel.fileName}');
        if (!await taesdFile.exists()) {
          try {
            await _downloadTaesd(taesdFile, taesdModel);
            taesdPath = taesdFile.path;
            await prefs.setString(_prefsKeyTaesdPath, taesdPath);
          } catch (_) {
            // TAESD download failed, continue without it
          }
        } else {
          taesdPath = taesdFile.path;
        }
      }

      state = ImageModelState(
        status: ImageModelStatus.ready,
        progress: 1.0,
        modelId: model.id,
        localPath: result,
        taesdPath: taesdPath,
      );
      debugPrint('AMBOT_DL: Download complete, state=READY, path=$result');
    } catch (e, s) {
      debugPrint('AMBOT_DL: DOWNLOAD FAILED');
      debugPrint('AMBOT_DL: Error: $e');
      debugPrint('AMBOT_DL: Stack: $s');
      debugPrint('AMBOT_DL: State at failure: status=${state.status}, modelId=${state.modelId}, progress=${state.progress}');
      state = ImageModelState(
        status: ImageModelStatus.paused,
        progress: state.progress,
        modelId: model.id,
      );
    } finally {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }
  }

  Future<void> _downloadTaesd(File targetFile, ModelInfo model) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      final response = await client.getUrl(Uri.parse(model.downloadUrl));
      response.followRedirects = true;
      final httpResponse = await response.close();

      if (httpResponse.statusCode == 200) {
        final sink = targetFile.openWrite();
        await for (final chunk in httpResponse) {
          sink.add(chunk);
        }
        await sink.flush();
        await sink.close();
      }
    } finally {
      client.close();
    }
  }

  /// Cancel an in-progress download.
  void cancelDownload() {
    _downloader.cancelDownload();
  }

  /// Delete the downloaded image model.
  Future<void> deleteModel() async {
    if (state.localPath != null) {
      try {
        final file = File(state.localPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    if (state.taesdPath != null) {
      try {
        final file = File(state.taesdPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyModelId);
    await prefs.remove(_prefsKeyModelPath);
    await prefs.remove(_prefsKeyTaesdPath);

    state = const ImageModelState(status: ImageModelStatus.notDownloaded);
  }

  /// Scan for existing image models.
  Future<void> _scanForModels() async {
    try {
      final dir = await _getModelsDirectory();
      if (!await dir.exists()) return;

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.gguf')) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final model = ModelRegistry.findByFileName(fileName);
          if (model != null && model.modelType == ModelType.image) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefsKeyModelId, model.id);
            await prefs.setString(_prefsKeyModelPath, entity.path);

            // Check for TAESD
            String? taesdPath;
            final taesdFile = File('${dir.path}/taesd_encoder.pth');
            if (await taesdFile.exists()) {
              taesdPath = taesdFile.path;
              await prefs.setString(_prefsKeyTaesdPath, taesdPath);
            }

            state = ImageModelState(
              status: ImageModelStatus.ready,
              progress: 1.0,
              modelId: model.id,
              localPath: entity.path,
              taesdPath: taesdPath,
            );
            return;
          }
        }
      }
    } catch (_) {}
  }

  static Future<Directory> _getModelsDirectory() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final modelsDir = Directory('${extDir.path}/models');
          if (!await modelsDir.exists()) {
            await modelsDir.create(recursive: true);
          }
          return modelsDir;
        }
      } catch (_) {}
    }
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Get the path to a downloaded image model.
  static Future<String?> getModelPath(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsKeyModelId);
    final savedPath = prefs.getString(_prefsKeyModelPath);
    if (savedId == modelId && savedPath != null) {
      final file = File(savedPath);
      if (await file.exists()) return savedPath;
    }
    return null;
  }
}
