import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum DownloadState { idle, downloading, paused, completed, failed }

class LocalModelInfo {
  final String id;
  final String name;
  final String description;
  final String url;
  final int sizeBytes;
  final String quantization;
  final int contextSize;
  final String license;
  final List<String> tags;

  const LocalModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.sizeBytes,
    required this.quantization,
    required this.contextSize,
    this.license = 'Apache 2.0',
    this.tags = const [],
  });

  String get sizeLabel {
    if (sizeBytes >= 1073741824) {
      return '${(sizeBytes / 1073741824).toStringAsFixed(1)} GB';
    }
    return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'url': url,
    'sizeBytes': sizeBytes,
    'quantization': quantization,
    'contextSize': contextSize,
    'license': license,
    'tags': tags,
  };

  factory LocalModelInfo.fromJson(Map<String, dynamic> json) => LocalModelInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    url: json['url'] as String,
    sizeBytes: json['sizeBytes'] as int,
    quantization: json['quantization'] as String,
    contextSize: json['contextSize'] as int,
    license: json['license'] as String? ?? 'Apache 2.0',
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
  );
}

class DownloadProgress {
  final int received;
  final int total;
  final double speed;
  final Duration? remaining;

  const DownloadProgress({
    required this.received,
    required this.total,
    required this.speed,
    this.remaining,
  });

  double get percent => total > 0 ? received / total : 0;
  String get percentLabel => '${(percent * 100).toStringAsFixed(1)}%';
  String get speedLabel => '${(speed / 1024).toStringAsFixed(1)} KB/s';
}

class ModelDownloadManager {
  final Map<String, bool> _cancelledModels = {};
  final Map<String, DownloadProgress> _progress = {};
  final Map<String, DownloadState> _states = {};

  final _progressController = StreamController<DownloadProgress>.broadcast();
  final _stateController = StreamController<DownloadState>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;
  Stream<DownloadState> get stateStream => _stateController.stream;

  DownloadProgress? getProgress(String modelId) => _progress[modelId];
  DownloadState getState(String modelId) => _states[modelId] ?? DownloadState.idle;

  Future<Directory> get _modelsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/ambot_ai/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w\-]'), '_');
  }

  Future<File> getModelFile(String modelId) async {
    final dir = await _modelsDir;
    final files = await dir.list().toList();
    for (final file in files) {
      if (file.path.contains(modelId) && file.path.endsWith('.gguf')) {
        return File(file.path);
      }
    }
    throw FileSystemException('Model not found', modelId);
  }

  Future<bool> isModelDownloaded(String modelId) async {
    try {
      final file = await getModelFile(modelId);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> downloadModel(
    LocalModelInfo model, {
    Function(DownloadProgress)? onProgress,
    Function(String)? onComplete,
    Function(String)? onError,
  }) async {
    if (_states[model.id] == DownloadState.downloading) return;

    final dir = await _modelsDir;
    final filename = '${_sanitizeFilename(model.id)}.gguf';
    final filePath = '${dir.path}/$filename';

    _cancelledModels[model.id] = false;
    _states[model.id] = DownloadState.downloading;
    _stateController.add(DownloadState.downloading);

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(model.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException('Download failed: ${response.statusCode}');
      }

      final file = File(filePath);
      final sink = file.openWrite();

      int received = 0;
      final total = response.contentLength;
      final startTime = DateTime.now();

      await for (final chunk in response.asBroadcastStream()) {
        if (_cancelledModels[model.id] == true) {
          await sink.close();
          _states[model.id] = DownloadState.paused;
          _stateController.add(DownloadState.paused);
          client.close();
          return;
        }

        sink.add(chunk);
        received += chunk.length;

        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final speed = elapsed > 0 ? received / elapsed : 0.0;
        final remaining = speed > 0
            ? Duration(seconds: ((total - received) / speed).round())
            : null;

        final progress = DownloadProgress(
          received: received,
          total: total,
          speed: speed,
          remaining: remaining,
        );

        _progress[model.id] = progress;
        _progressController.add(progress);
        onProgress?.call(progress);
      }

      await sink.close();
      client.close();

      _states[model.id] = DownloadState.completed;
      _stateController.add(DownloadState.completed);
      onComplete?.call(filePath);
    } catch (e) {
      _states[model.id] = DownloadState.failed;
      _stateController.add(DownloadState.failed);
      onError?.call(e.toString());
    } finally {
      _cancelledModels.remove(model.id);
    }
  }

  void pauseDownload(String modelId) {
    _cancelledModels[modelId] = true;
  }

  void resumeDownload(LocalModelInfo model) {
    if (_states[model.id] == DownloadState.paused) {
      downloadModel(model);
    }
  }

  void cancelDownload(String modelId) {
    _cancelledModels[modelId] = true;
    _states.remove(modelId);
    _progress.remove(modelId);
  }

  Future<void> deleteModel(String modelId) async {
    try {
      final file = await getModelFile(modelId);
      await file.delete();
    } catch (_) {}
  }

  Future<List<LocalModelInfo>> getAvailableModels() async {
    return [
      const LocalModelInfo(
        id: 'tinyllama-1.1b',
        name: 'TinyLlama 1.1B',
        description: 'Fast, lightweight model for simple tasks',
        url: 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
        sizeBytes: 669000000,
        quantization: 'Q4_K_M',
        contextSize: 2048,
        tags: ['fast', 'lightweight', 'chat'],
      ),
      const LocalModelInfo(
        id: 'llama-3.2-3b',
        name: 'Llama 3.2 3B',
        description: 'Balanced performance and quality',
        url: 'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
        sizeBytes: 1800000000,
        quantization: 'Q4_K_M',
        contextSize: 4096,
        tags: ['balanced', 'instruction', 'chat'],
      ),
      const LocalModelInfo(
        id: 'llama-3-8b',
        name: 'Llama 3 8B',
        description: 'High quality for complex tasks',
        url: 'https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf',
        sizeBytes: 4920000000,
        quantization: 'Q4_K_M',
        contextSize: 8192,
        tags: ['high-quality', 'coding', 'reasoning'],
      ),
      const LocalModelInfo(
        id: 'codellama-7b',
        name: 'CodeLlama 7B',
        description: 'Specialized for code generation',
        url: 'https://huggingface.co/bartowski/codellama-7b-instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_M.gguf',
        sizeBytes: 3800000000,
        quantization: 'Q4_K_M',
        contextSize: 4096,
        tags: ['coding', 'programming', 'instruct'],
      ),
    ];
  }

  Future<List<LocalModelInfo>> getDownloadedModels() async {
    final available = await getAvailableModels();
    final downloaded = <LocalModelInfo>[];
    for (final model in available) {
      if (await isModelDownloaded(model.id)) {
        downloaded.add(model);
      }
    }
    return downloaded;
  }

  void dispose() {
    for (final modelId in _cancelledModels.keys) {
      _cancelledModels[modelId] = true;
    }
    _progressController.close();
    _stateController.close();
  }
}
