import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ai/engine_selector.dart';
import 'core/providers/app_providers.dart';
import 'core/services/error_boundary.dart';
import 'features/desktop/desktop_home_screen.dart';
import 'shared/theme/app_theme.dart';

class AmbotDesktopApp extends ConsumerStatefulWidget {
  const AmbotDesktopApp({super.key});

  @override
  ConsumerState<AmbotDesktopApp> createState() => _AmbotDesktopAppState();
}

class _AmbotDesktopAppState extends ConsumerState<AmbotDesktopApp>
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

    return AmbotErrorBoundary(
      child: MaterialApp(
        title: 'Ambot AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const DesktopHomeScreen(),
      ),
    );
  }
}
