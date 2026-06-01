import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/model_manager.dart';
import '../ai/image_model_manager.dart';
import '../voice_gen/voice_model_manager.dart';

final modelManagerProvider =
    StateNotifierProvider<ModelManager, ModelState>((ref) {
  final manager = ModelManager();
  manager.loadSavedState();
  return manager;
});

final imageModelManagerProvider =
    StateNotifierProvider<ImageModelManager, ImageModelState>((ref) {
  final manager = ImageModelManager();
  manager.loadSavedState();
  return manager;
});

final voiceModelManagerProvider =
    StateNotifierProvider<VoiceModelManager, VoiceModelState>((ref) {
  final manager = VoiceModelManager();
  manager.loadSavedState();
  return manager;
});
