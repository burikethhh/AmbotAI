import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/api_keys.dart';
import 'core/device_control/action_log.dart';
import 'core/memory/conversation_summary_store.dart';
import 'core/memory/memory_service.dart';
import 'core/providers/app_providers.dart';
import 'core/services/conversation_store.dart';
import 'features/programmer/programmer_store.dart';
import 'app.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('AMBOT_ERROR: ${details.exception}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('AMBOT_ERROR: $error\n$stack');
      return true;
    };

    await Hive.initFlutter();
  await MemoryService.instance.init();
  await ConversationSummaryStore.instance.init();
  await ActionLog.instance.init();
  await ConversationStore.instance.init();
  await ProgrammerStore.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final container = ProviderContainer();
  await container.read(themeProvider.notifier).load();
  await container.read(onboardingCompleteProvider.notifier).load();
  await container.read(aiSetupCompleteProvider.notifier).load();
  await container.read(memoryEnabledProvider.notifier).load();

  // If user has cloud API keys defined at build time, skip AI setup
  if (!container.read(aiSetupCompleteProvider) && ApiKeys.hasAnyCloudKey) {
    container.read(aiSetupCompleteProvider.notifier).completeSilent();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AmbotApp(),
    ),
  );
  }, (error, stack) {
    debugPrint('AMBOT_FATAL: $error\n$stack');
  });
}
