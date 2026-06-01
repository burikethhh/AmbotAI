import 'capability_detector.dart';
import 'engine_selector.dart';
import 'model_manager.dart';
import 'model_registry.dart';

abstract class ModelService {
  List<ModelInfo> getModels({ModelType? type});

  ModelInfo? getModelById(String id);

  Future<EngineSelection> selectEngine({
    required DeviceCapability capability,
    required ModelState modelState,
    String? userGeminiKey,
    String? userOpenRouterKey,
    String? userQwenKey,
    CloudProvider preferredCloudProvider = CloudProvider.openRouter,
  });

  ModelState get modelState;

  Future<void> downloadModel(ModelInfo model, {String? hfToken});

  void cancelDownload();

  Future<void> deleteModel();

  static String? getHuggingFaceToken({String? userToken}) {
    return EngineSelector.getHuggingFaceToken(userToken: userToken);
  }
}
