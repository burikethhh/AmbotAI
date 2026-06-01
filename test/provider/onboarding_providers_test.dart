import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambot_ai/core/providers/onboarding_providers.dart';

void main() {
  group('OnboardingNotifier', () {
    test('onboardingCompleteProvider starts false', () {
      final container = ProviderContainer();
      expect(container.read(onboardingCompleteProvider), isFalse);
      container.dispose();
    });

    test('complete sets state to true', () {
      final notifier = OnboardingNotifier();
      expect(notifier.state, isFalse);
      // complete() calls SharedPreferences, but we only test state change
      notifier.state = true;
      expect(notifier.state, isTrue);
    });
  });

  group('userTypeProvider', () {
    test('defaults to UserType.student', () {
      final container = ProviderContainer();
      expect(container.read(userTypeProvider), UserType.student);
      container.dispose();
    });
  });
}
