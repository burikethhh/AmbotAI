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

// --- Model State ---

enum ModelStatus { notDownloaded, downloading, paused, verifying, ready, error }

class ModelState implements DownloadableState {
  final ModelStatus status;
  @override
  final double progress;
  @override
  final String? error;
  @override
  final String? modelId;
  final String? localPath;

  const ModelState({
    this.status = ModelStatus.notDownloaded,
    this.progress = 0.0,
    this.error,
    this.modelId,
    this.localPath,
  });

  ModelState copyWith({
    ModelStatus? status,
    double? progress,
    String? error,
    String? modelId,
    String? localPath,
  }) {
    return ModelState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      modelId: modelId ?? this.modelId,
      localPath: localPath ?? this.localPath,
    );
  }

  @override
  bool get isReady => status == ModelStatus.ready && localPath != null;
  @override
  bool get isDownloading => status == ModelStatus.downloading;
  @override
  bool get isPaused => status == ModelStatus.paused;
  @override
  bool get hasError => status == ModelStatus.error;

  @override
  String get statusLabel {
    switch (status) {
      case ModelStatus.notDownloaded:
        return 'NOT DOWNLOADED';
      case ModelStatus.downloading:
        return 'DOWNLOADING ${(progress * 100).toStringAsFixed(0)}%';
      case ModelStatus.paused:
        return 'PAUSED ${(progress * 100).toStringAsFixed(0)}%';
      case ModelStatus.verifying:
        return 'VERIFYING';
      case ModelStatus.ready:
        return 'READY';
      case ModelStatus.error:
        return 'ERROR';
    }
  }
}

// --- Model Manager ---

class ModelManager extends StateNotifier<ModelState> {
  ModelManager() : super(const ModelState());

  final ModelDownloader _downloader = ModelDownloader(throwOnCancel: false);

  static const _prefsKeyModelId = 'downloaded_model_id';
  static const _prefsKeyModelPath = 'downloaded_model_path';
  static const _prefsKeyDownloadingId = 'downloading_model_id';

  /// Load previously downloaded model state from prefs.
  /// Detects partial .tmp downloads and sets paused state for resume.
  Future<void> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsKeyModelId);
    final savedPath = prefs.getString(_prefsKeyModelPath);

    if (savedId != null && savedPath != null) {
      final file = File(savedPath);
      if (await file.exists()) {
        state = ModelState(
          status: ModelStatus.ready,
          progress: 1.0,
          modelId: savedId,
          localPath: savedPath,
        );
        return;
      }
      // File path changed (e.g., reinstall) — try to find it
      await prefs.remove(_prefsKeyModelId);
      await prefs.remove(_prefsKeyModelPath);
    }

    // Migrate from old internal storage & scan for surviving models
    await _migrateAndScanModels();
    if (state.isReady) return;

    // Check for interrupted download (.tmp file)
    final downloadingId = prefs.getString(_prefsKeyDownloadingId);
    if (downloadingId != null) {
      final model = ModelRegistry.getById(downloadingId);
      if (model != null) {
        try {
          final dir = await _getModelsDirectory();
          final tempFile = File('${dir.path}/${model.fileName}.tmp');
          if (await tempFile.exists()) {
            final bytes = await tempFile.length();
            final totalEstimate = model.sizeMB * 1024 * 1024;
            final progress = totalEstimate > 0 ? bytes / totalEstimate : 0.0;
            state = ModelState(
              status: ModelStatus.paused,
              progress: progress.clamp(0.0, 0.99),
              modelId: downloadingId,
            );
            return;
          }
        } catch (_) {
          // Best effort
        }
      }
      // No valid .tmp found, clean up
      await prefs.remove(_prefsKeyDownloadingId);
    }
  }

  /// Resume a paused/interrupted download.
  Future<void> resumeDownload({String? hfToken}) async {
    if (state.modelId == null) return;
    final model = ModelRegistry.getById(state.modelId!);
    if (model == null) return;
    await downloadModel(model, hfToken: hfToken);
  }

  /// Dismiss a paused download and delete the .tmp file.
  Future<void> dismissPausedDownload() async {
    if (state.modelId == null) return;
    final model = ModelRegistry.getById(state.modelId!);
    if (model != null) {
      try {
        final dir = await _getModelsDirectory();
        final tempFile = File('${dir.path}/${model.fileName}.tmp');
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyDownloadingId);
    state = const ModelState(status: ModelStatus.notDownloaded);
  }

  /// Download a model from Hugging Face.
  /// Pass [hfToken] for authenticated access to gated models.
  Future<void> downloadModel(ModelInfo model, {String? hfToken}) async {
    if (kIsWeb) {
      state = state.copyWith(
        status: ModelStatus.error,
        error: 'Model download is not supported on web',
      );
      return;
    }

    try {
      await WakelockPlus.enable();
    } catch (_) {}

    state = ModelState(
      status: ModelStatus.downloading,
      progress: 0.0,
      modelId: model.id,
    );

    // Persist which model is being downloaded for resume on restart
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyDownloadingId, model.id);
    } catch (_) {}

    try {
      final dir = await _getModelsDirectory();

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
          state = state.copyWith(status: ModelStatus.verifying);
        },
      );

      if (result == null) return;

      // Save to prefs and clear downloading state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyModelId, model.id);
      await prefs.setString(_prefsKeyModelPath, result);
      await prefs.remove(_prefsKeyDownloadingId);

      state = ModelState(
        status: ModelStatus.ready,
        progress: 1.0,
        modelId: model.id,
        localPath: result,
      );
    } catch (e) {
      // Any interruption (user cancel, network drop, app backgrounded)
      // → paused state so the user can resume without re-downloading
      state = ModelState(
        status: ModelStatus.paused,
        progress: state.progress,
        modelId: model.id,
      );
    } finally {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }
  }

  /// Cancel an in-progress download. Sets state to paused (resumable).
  void cancelDownload() {
    _downloader.cancelDownload();
  }

  /// Delete the downloaded model and free storage.
  Future<void> deleteModel() async {
    if (state.localPath != null) {
      try {
        final file = File(state.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best effort
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyModelId);
    await prefs.remove(_prefsKeyModelPath);

    state = const ModelState(status: ModelStatus.notDownloaded);
  }

  /// Get the models directory, preferring external storage for persistence
  /// across app updates and reinstalls.
  static Future<Directory> _getModelsDirectory() async {
    // Prefer external storage (survives updates; with hasFragileUserData
    // the user is prompted to keep data on uninstall)
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
      } catch (_) {
        // Fall through to internal storage
      }
    }
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Migrate models from old internal storage to external storage.
  /// Also scans external storage for models that survived a reinstall.
  Future<void> _migrateAndScanModels() async {
    try {
      final extDir = await _getModelsDirectory();
      final appDir = await getApplicationDocumentsDirectory();
      final oldModelsDir = Directory('${appDir.path}/models');

      // Migrate: if model exists in old internal dir but not in new external dir
      if (await oldModelsDir.exists() && extDir.path != oldModelsDir.path) {
        await for (final entity in oldModelsDir.list()) {
          if (entity is File && entity.path.endsWith('.gguf')) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            final newFile = File('${extDir.path}/$fileName');
            if (!await newFile.exists()) {
              await entity.copy(newFile.path);
            }
            // Clean up old copy
            await entity.delete();
          }
        }
      }

      // Scan: find any .gguf model files that exist (e.g., survived reinstall)
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefsKeyModelId);
      final savedPath = prefs.getString(_prefsKeyModelPath);

      // If prefs say we have a model but file is gone, scan for it
      if (savedId != null && savedPath != null && !await File(savedPath).exists()) {
        // Check if model file exists in external dir under a different path
        final model = ModelRegistry.getById(savedId);
        if (model != null) {
          final expectedFile = File('${extDir.path}/${model.fileName}');
          if (await expectedFile.exists()) {
            await prefs.setString(_prefsKeyModelPath, expectedFile.path);
            state = ModelState(
              status: ModelStatus.ready,
              progress: 1.0,
              modelId: savedId,
              localPath: expectedFile.path,
            );
            return;
          }
        }
      }

      // No prefs but model file exists? Re-register it
      if (savedId == null) {
        await for (final entity in extDir.list()) {
          if (entity is File && entity.path.endsWith('.gguf')) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            // Try to match to a known model
            final model = ModelRegistry.findByFileName(fileName);
            if (model != null) {
              await prefs.setString(_prefsKeyModelId, model.id);
              await prefs.setString(_prefsKeyModelPath, entity.path);
              state = ModelState(
                status: ModelStatus.ready,
                progress: 1.0,
                modelId: model.id,
                localPath: entity.path,
              );
              return;
            }
          }
        }
      }
    } catch (_) {
      // Best effort — don't break startup
    }
  }

  /// Get the path to a downloaded model file, if it exists.
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
