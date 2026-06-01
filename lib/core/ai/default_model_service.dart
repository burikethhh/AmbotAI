import 'capability_detector.dart';
import 'engine_selector.dart';
import 'image_model_manager.dart';
import 'model_manager.dart';
import 'model_registry.dart';
import 'model_service.dart';

class DefaultModelService implements ModelService {
  final ModelManager modelManager;
  final ImageModelManager imageModelManager;

  DefaultModelService({
    required this.modelManager,
    required this.imageModelManager,
  });

  @override
  List<ModelInfo> getModels({ModelType? type}) {
    if (type == null) return List.unmodifiable(ModelRegistry.all);
    return ModelRegistry.all.where((m) => m.modelType == type).toList();
  }

  @override
  ModelInfo? getModelById(String id) => ModelRegistry.getById(id);

  @override
  Future<EngineSelection> selectEngine({
    required DeviceCapability capability,
    required ModelState modelState,
    String? userGeminiKey,
    String? userOpenRouterKey,
    String? userQwenKey,
    CloudProvider preferredCloudProvider = CloudProvider.openRouter,
  }) {
    return EngineSelector.select(
      capability: capability,
      modelState: modelState,
      userGeminiKey: userGeminiKey,
      userOpenRouterKey: userOpenRouterKey,
      userQwenKey: userQwenKey,
      preferredCloudProvider: preferredCloudProvider,
    );
  }

  @override
  ModelState get modelState => ModelState(
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        status: modelManager.state.status,
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        progress: modelManager.state.progress,
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        modelId: modelManager.state.modelId,
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        localPath: modelManager.state.localPath,
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        error: modelManager.state.error,
      );

  @override
  Future<void> downloadModel(ModelInfo model, {String? hfToken}) async {
    if (model.modelType == ModelType.image) {
      await imageModelManager.downloadModel(model, hfToken: hfToken);
    } else {
      await modelManager.downloadModel(model, hfToken: hfToken);
    }
  }

  @override
  void cancelDownload() {
    modelManager.cancelDownload();
    imageModelManager.cancelDownload();
  }

  @override
  Future<void> deleteModel() async {
    await modelManager.deleteModel();
    await imageModelManager.deleteModel();
  }

  static String? getHuggingFaceToken({String? userToken}) {
    return EngineSelector.getHuggingFaceToken(userToken: userToken);
  }
}
