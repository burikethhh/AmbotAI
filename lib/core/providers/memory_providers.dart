import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../memory/memory_extractor.dart';
import '../memory/memory_retriever.dart';
import '../memory/memory_service.dart';

final memoryServiceProvider = Provider<MemoryService>((ref) {
  return MemoryService.instance;
});

final memoryRetrieverProvider = Provider<MemoryRetriever>((ref) {
  return MemoryRetriever(ref.watch(memoryServiceProvider));
});

final memoryExtractorProvider = Provider<MemoryExtractor>((ref) {
  return MemoryExtractor(ref.watch(memoryServiceProvider));
});

final memoryEnabledProvider =
    StateNotifierProvider<MemoryEnabledNotifier, bool>((ref) {
  return MemoryEnabledNotifier(ref.watch(memoryServiceProvider));
});

class MemoryEnabledNotifier extends StateNotifier<bool> {
  MemoryEnabledNotifier(this._service) : super(_service.enabled);
  final MemoryService _service;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('memoryEnabled') ?? true;
    _service.enabled = enabled;
    state = enabled;
  }

  Future<void> setEnabled(bool v) async {
    _service.enabled = v;
    state = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('memoryEnabled', v);
  }
}
