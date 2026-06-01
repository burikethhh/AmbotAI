import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambot_ai/core/ai/model_manager.dart';
import 'package:ambot_ai/core/providers/theme_provider.dart';
import 'package:ambot_ai/core/providers/model_manager_providers.dart';
import 'package:ambot_ai/shared/widgets/download_banner.dart';

void main() {
  testWidgets('DownloadBanner is hidden when not downloading',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              themeProvider.overrideWith((ref) => _TestThemeNotifier()),
              modelManagerProvider.overrideWith(
                (ref) => _TestModelManager(
                  const ModelState(status: ModelStatus.notDownloaded),
                ),
              ),
            ],
            child: const DownloadBanner(),
          ),
        ),
      ),
    );

    expect(find.byType(DownloadBanner), findsOneWidget);
    expect(find.text('DOWNLOADING MODEL'), findsNothing);
    expect(find.text('DOWNLOAD PAUSED'), findsNothing);
  });

  testWidgets('DownloadBanner shows downloading state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              themeProvider.overrideWith((ref) => _TestThemeNotifier()),
              modelManagerProvider.overrideWith(
                (ref) => _TestModelManager(
                  const ModelState(
                    status: ModelStatus.downloading,
                    progress: 0.3,
                  ),
                ),
              ),
            ],
            child: const DownloadBanner(),
          ),
        ),
      ),
    );

    expect(find.text('DOWNLOADING MODEL'), findsOneWidget);
    expect(find.text('30.0%'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);
  });

  testWidgets('DownloadBanner shows paused state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              themeProvider.overrideWith((ref) => _TestThemeNotifier()),
              modelManagerProvider.overrideWith(
                (ref) => _TestModelManager(
                  const ModelState(
                    status: ModelStatus.paused,
                    progress: 0.7,
                  ),
                ),
              ),
            ],
            child: const DownloadBanner(),
          ),
        ),
      ),
    );

    expect(find.text('DOWNLOAD PAUSED'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.text('DISMISS'), findsOneWidget);
  });

  testWidgets('DownloadBanner shows ready state as hidden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              themeProvider.overrideWith((ref) => _TestThemeNotifier()),
              modelManagerProvider.overrideWith(
                (ref) => _TestModelManager(
                  const ModelState(
                    status: ModelStatus.ready,
                    progress: 1.0,
                    modelId: 'test',
                    localPath: '/test',
                  ),
                ),
              ),
            ],
            child: const DownloadBanner(),
          ),
        ),
      ),
    );

    expect(find.byType(DownloadBanner), findsOneWidget);
    expect(find.text('DOWNLOADING MODEL'), findsNothing);
    expect(find.text('DOWNLOAD PAUSED'), findsNothing);
  });
}

class _TestThemeNotifier extends ThemeNotifier {
  _TestThemeNotifier() : super();
}

class _TestModelManager extends ModelManager {
  _TestModelManager(ModelState state) : super() {
    this.state = state;
  }
}
