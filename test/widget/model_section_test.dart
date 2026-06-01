import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/ai/model_manager.dart';
import 'package:ambot_ai/core/ai/ai_engine.dart' show DeviceTier;
import 'package:ambot_ai/core/ai/model_registry.dart';
import 'package:ambot_ai/features/settings/widgets/model_section.dart';

void main() {
  testWidgets('ModelSection renders not downloaded state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSection(
            modelState: const ModelState(status: ModelStatus.notDownloaded),
            recommendedModel: null,
            detectingModel: false,
            isDark: false,
            onDownload: () {},
            onCancel: () {},
            onDelete: () {},
            onResume: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('NOT DOWNLOADED'), findsOneWidget);
    expect(find.text('No compatible model found for this device.'),
        findsOneWidget);
  });

  testWidgets('ModelSection renders detecting state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSection(
            modelState: const ModelState(status: ModelStatus.notDownloaded),
            recommendedModel: null,
            detectingModel: true,
            isDark: false,
            onDownload: () {},
            onCancel: () {},
            onDelete: () {},
            onResume: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('Detecting compatible model...'), findsOneWidget);
  });

  testWidgets('ModelSection renders with recommended model', (tester) async {
    final dummyModel = ModelInfo(
      id: 'test-model',
      name: 'Test Model',
      params: '3B',
      quantization: 'Q4_K_M',
      sizeMB: 2048,
      minRamMB: 4096,
      minStorageMB: 4096,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'test/test',
      fileName: 'test.gguf',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSection(
            modelState: const ModelState(status: ModelStatus.notDownloaded),
            recommendedModel: dummyModel,
            detectingModel: false,
            isDark: false,
            onDownload: () {},
            onCancel: () {},
            onDelete: () {},
            onResume: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('DOWNLOAD MODEL'), findsOneWidget);
    expect(find.text('TEST MODEL'), findsOneWidget);
    expect(find.text('2.0 GB'), findsOneWidget);
  });

  testWidgets('ModelSection renders ready state with model ID',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSection(
            modelState: const ModelState(
              status: ModelStatus.ready,
              modelId: 'qwen2.5-0.5b',
              progress: 1.0,
              localPath: '/test/model.gguf',
            ),
            recommendedModel: null,
            detectingModel: false,
            isDark: false,
            onDownload: () {},
            onCancel: () {},
            onDelete: () {},
            onResume: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('READY'), findsOneWidget);
    expect(find.text('DELETE MODEL'), findsOneWidget);
  });

  testWidgets('ModelSection renders downloading state with progress',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSection(
            modelState: const ModelState(
              status: ModelStatus.downloading,
              progress: 0.45,
            ),
            recommendedModel: null,
            detectingModel: false,
            isDark: false,
            onDownload: () {},
            onCancel: () {},
            onDelete: () {},
            onResume: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('45.0%'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);
  });

  testWidgets('ModelSection renders paused state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSection(
            modelState: const ModelState(
              status: ModelStatus.paused,
              progress: 0.6,
            ),
            recommendedModel: null,
            detectingModel: false,
            isDark: false,
            onDownload: () {},
            onCancel: () {},
            onDelete: () {},
            onResume: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('60.0%'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.text('DISMISS'), findsOneWidget);
  });

  testWidgets('ModelSection renders error state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSection(
            modelState: const ModelState(
              status: ModelStatus.error,
              error: 'Network timeout',
            ),
            recommendedModel: null,
            detectingModel: false,
            isDark: false,
            onDownload: () {},
            onCancel: () {},
            onDelete: () {},
            onResume: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('Network timeout'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('ModelSection renders verifying state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelSection(
            modelState: const ModelState(status: ModelStatus.verifying),
            recommendedModel: null,
            detectingModel: false,
            isDark: false,
            onDownload: () {},
            onCancel: () {},
            onDelete: () {},
            onResume: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('Verifying model integrity...'), findsOneWidget);
  });
}
