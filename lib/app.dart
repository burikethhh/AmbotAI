import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ai/engine_selector.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/download_banner.dart';

class AmbotApp extends ConsumerStatefulWidget {
  const AmbotApp({super.key});

  @override
  ConsumerState<AmbotApp> createState() => _AmbotAppState();
}

class _AmbotAppState extends ConsumerState<AmbotApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final modelState = ref.read(modelManagerProvider);
      if (modelState.isPaused && modelState.modelId != null) {
        final hfToken = EngineSelector.getHuggingFaceToken(
          userToken: ref.read(userHfTokenProvider),
        );
        ref.read(modelManagerProvider.notifier).resumeDownload(hfToken: hfToken);
      }
    }
  }

  @override
  void didHaveMemoryPressure() {
    final engine = ref.read(aiEngineProvider);
    unawaited(engine.handleMemoryPressure());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Ambot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Column(
          children: [
            const DownloadBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
      routerConfig: createRouter(ref),
    );
  }
}
