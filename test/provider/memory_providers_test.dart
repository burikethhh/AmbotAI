import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ambot_ai/core/providers/memory_providers.dart';
import 'package:ambot_ai/core/memory/memory_service.dart';

void main() {
  late MemoryEnabledNotifier notifier;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    notifier = MemoryEnabledNotifier(MemoryService.instance);
  });

  group('MemoryEnabledNotifier', () {
    test('default value is true (memory enabled)', () {
      expect(notifier.state, isTrue);
    });

    test('setEnabled flips state to false', () async {
      await notifier.setEnabled(false);
      expect(notifier.state, isFalse);
    });

    test('setEnabled flips state back to true', () async {
      await notifier.setEnabled(false);
      expect(notifier.state, isFalse);
      await notifier.setEnabled(true);
      expect(notifier.state, isTrue);
    });
  });
}
