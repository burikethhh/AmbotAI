import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:llamadart/llamadart.dart' as ld;
import '../ai_engine.dart';
import '../capability_detector.dart';
import '../model_registry.dart';

class LlamaEngine implements AIEngine {
  final String modelPath;
  final DeviceCapability? capability;
  final ModelInfo? modelInfo;
  bool _isReady = false;
  ld.LlamaEngine? _engine;
  ld.GenerationParams _generationParams = const ld.GenerationParams();
  ld.ModelParams? _lastModelParams;

  /// Tokens above which we consider context trimmed.
  static const int _maxContextTokens = 2048;

  /// Rough estimate: 1 token ≈ 4 characters for English text.
  static const int _charsPerToken = 4;

  LlamaEngine({
    required this.modelPath,
    this.capability,
    this.modelInfo,
  });

  @override
  Future<void> initialize() async {
    try {
      _generationParams = ld.GenerationParams(
        maxTokens: 2048,
        temp: 0.7,
        topK: 40,
        topP: 0.9,
        stopSequences: const [],
      );

      _engine = ld.LlamaEngine(ld.LlamaBackend());
      _lastModelParams = _computeModelParams();
      await _engine!.loadModel(
        modelPath,
        modelParams: _lastModelParams!,
      );

      // Warmup: pre-allocate KV cache before marking ready
      await _warmup();
      _isReady = true;
    } catch (e) {
      _isReady = false;
      rethrow;
    }
  }

  ld.ModelParams _computeModelParams() {
    final ramMB = capability?.ramMB ?? 6144;
    final contextSize = _computeContextSize(ramMB);
    final batchSize = _computeBatchSize(ramMB);
    final threads = _computeThreadCount();
    final threadsBatch = threads;

    return ld.ModelParams(
      contextSize: contextSize,
      batchSize: batchSize,
      numberOfThreads: threads,
      numberOfThreadsBatch: threadsBatch,
      gpuLayers: 0,
    );
  }

  /// Frees the KV cache under memory pressure by unloading and
  /// immediately reloading the model with a smaller context.
  @override
  void cancelStream() {}

  @override
  Future<void> handleMemoryPressure() async {
    if (!_isReady || _engine == null) return;
    try {
      _isReady = false;
      await _engine!.unloadModel();

      // Reload with a reduced context to free KV cache memory
      final ramMB = capability?.ramMB ?? 4096;
      final reducedContext = (_computeContextSize(ramMB) ~/ 2).clamp(512, 2048);
      _lastModelParams = ld.ModelParams(
        contextSize: reducedContext,
        batchSize: 128,
        numberOfThreads: _computeThreadCount(),
        numberOfThreadsBatch: _computeThreadCount(),
        gpuLayers: 0,
      );

      await _engine!.loadModel(
        modelPath,
        modelParams: _lastModelParams!,
      );
      _isReady = true;
    } catch (_) {
      _isReady = false;
    }
  }

  int _computeContextSize(int ramMB) {
    if (ramMB >= 8192) return 4096;
    if (ramMB >= 6144) return 3072;
    if (ramMB >= 4096) return 2048;
    return 1024;
  }

  int _computeBatchSize(int ramMB) {
    if (ramMB >= 8192) return 512;
    if (ramMB >= 6144) return 256;
    return 128;
  }

  int _computeThreadCount() {
    try {
      final cores = Platform.numberOfProcessors;
      if (cores >= 8) return cores - 1;
      if (cores >= 4) return cores;
      return cores;
    } catch (_) {
      return 4;
    }
  }

  /// Rough token count estimate for context window trimming.
  int estimateTokenCount(List<MessageEntry> history) {
    int chars = 0;
    for (final entry in history) {
      chars += entry.content.length;
    }
    return chars ~/ _charsPerToken;
  }

  /// Trim history to fit within context window (leaves room for response).
  List<MessageEntry> trimHistory(List<MessageEntry> history, {int responseTokens = 512}) {
    final budget = _maxContextTokens - responseTokens;
    if (budget <= 0) return [];

    // Start from newest, keep as many as fit
    final result = <MessageEntry>[];
    int tokenCount = 0;

    for (int i = history.length - 1; i >= 0; i--) {
      final estimated = history[i].content.length ~/ _charsPerToken;
      if (tokenCount + estimated > budget) break;
      result.insert(0, history[i]);
      tokenCount += estimated;
    }

    return result;
  }

  Future<void> _warmup() async {
    try {
      await for (final _ in _engine!.create(
        [
          ld.LlamaChatMessage.fromText(
            role: ld.LlamaChatRole.user,
            text: '.',
          ),
        ],
        params: const ld.GenerationParams(
          maxTokens: 1,
          temp: 0.1,
        ),
      )) {
        break;
      }
    } catch (e) {
      debugPrint('LLAMA: warmup failed: $e');
    }
  }

  @override
  Future<String> generate(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async {
    if (!_isReady || _engine == null) {
      throw StateError('LlamaEngine not initialized');
    }
    final trimmed = history != null ? trimHistory(history) : null;
    final messages = _buildMessageList(prompt, systemPrompt: systemPrompt, history: trimmed);
    final buffer = StringBuffer();
    await for (final chunk in _engine!.create(messages, params: _generationParams)) {
      final content = chunk.choices.firstOrNull?.delta.content;
      if (content != null) buffer.write(content);
    }
    return buffer.toString();
  }

  @override
  Stream<String> generateStream(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async* {
    if (!_isReady || _engine == null) {
      throw StateError('LlamaEngine not initialized');
    }
    final trimmed = history != null ? trimHistory(history) : null;
    final messages = _buildMessageList(prompt, systemPrompt: systemPrompt, history: trimmed);
    await for (final chunk in _engine!.create(messages, params: _generationParams)) {
      final content = chunk.choices.firstOrNull?.delta.content;
      if (content != null && content.isNotEmpty) {
        yield content;
      }
    }
  }

  List<ld.LlamaChatMessage> _buildMessageList(
    String prompt, {
    String? systemPrompt,
    List<MessageEntry>? history,
  }) {
    final messages = <ld.LlamaChatMessage>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add(ld.LlamaChatMessage.fromText(
        role: ld.LlamaChatRole.system,
        text: systemPrompt,
      ));
    }

    if (history != null) {
      for (final entry in history) {
        final role = entry.role == 'user'
            ? ld.LlamaChatRole.user
            : ld.LlamaChatRole.assistant;
        messages.add(ld.LlamaChatMessage.fromText(
          role: role,
          text: entry.content,
        ));
      }
    }

    messages.add(ld.LlamaChatMessage.fromText(
      role: ld.LlamaChatRole.user,
      text: prompt,
    ));

    return messages;
  }

  @override
  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _isReady = false;
  }

  @override
  String get engineName => 'llama.cpp (on-device)';

  @override
  DeviceTier get tier => DeviceTier.lowEnd;

  @override
  bool get isReady => _isReady;
}
