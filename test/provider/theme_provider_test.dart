import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambot_ai/core/providers/theme_provider.dart';

void main() {
  group('ThemeNotifier', () {
    test('default value is true (dark mode)', () {
      final notifier = ThemeNotifier();
      expect(notifier.state, isTrue);
    });

    test('toggle flips state', () {
      final notifier = ThemeNotifier();
      expect(notifier.state, isTrue);
      notifier.toggle();
      expect(notifier.state, isFalse);
      notifier.toggle();
      expect(notifier.state, isTrue);
    });

    test('ProviderContainer provides default dark mode', () {
      final container = ProviderContainer();
      expect(container.read(themeProvider), isTrue);
      container.dispose();
    });

    test('provider override works', () {
      final container = ProviderContainer(
        overrides: [
          themeProvider.overrideWith(
            (ref) => ThemeNotifier(),
          ),
        ],
      );
      expect(container.read(themeProvider), isTrue);
      container.dispose();
    });
  });
}
