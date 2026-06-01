import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ambot_ai/core/providers/api_key_providers.dart';

Future<dynamic> _mockSecureStorage(MethodCall call) async {
  switch (call.method) {
    case 'read':
    case 'write':
    case 'delete':
    case 'containsKey':
    case 'readAll':
      return null;
    default:
      return null;
  }
}

void main() {
  group('UserGeminiKeyNotifier', () {
    testWidgets('starts as null', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        _mockSecureStorage,
      );
      final notifier = UserGeminiKeyNotifier();
      await tester.pump();
      expect(notifier.state, isNull);
    });

    testWidgets('set updates state', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        _mockSecureStorage,
      );
      final notifier = UserGeminiKeyNotifier();
      await tester.pump();
      await notifier.set('test-key');
      expect(notifier.state, 'test-key');
    });
  });

  group('UserOpenRouterKeyNotifier', () {
    testWidgets('starts as null', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        _mockSecureStorage,
      );
      final notifier = UserOpenRouterKeyNotifier();
      await tester.pump();
      expect(notifier.state, isNull);
    });

    testWidgets('set updates state', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        _mockSecureStorage,
      );
      final notifier = UserOpenRouterKeyNotifier();
      await tester.pump();
      await notifier.set('or-key');
      expect(notifier.state, 'or-key');
    });
  });

  group('UserQwenKeyNotifier', () {
    testWidgets('starts as null', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        _mockSecureStorage,
      );
      final notifier = UserQwenKeyNotifier();
      await tester.pump();
      expect(notifier.state, isNull);
    });

    testWidgets('set updates state', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        _mockSecureStorage,
      );
      final notifier = UserQwenKeyNotifier();
      await tester.pump();
      await notifier.set('qwen-key');
      expect(notifier.state, 'qwen-key');
    });
  });

  group('UserHfTokenNotifier', () {
    testWidgets('starts as null', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        _mockSecureStorage,
      );
      final notifier = UserHfTokenNotifier();
      await tester.pump();
      expect(notifier.state, isNull);
    });

    testWidgets('set updates state', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        _mockSecureStorage,
      );
      final notifier = UserHfTokenNotifier();
      await tester.pump();
      await notifier.set('hf-token');
      expect(notifier.state, 'hf-token');
    });
  });
}
