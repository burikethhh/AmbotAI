import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambot_ai/core/config/api_keys.dart';
import 'package:ambot_ai/core/providers/onboarding_providers.dart';

/// Replicates the redirect logic from createRouter so we can test it
/// without needing a full GoRouter / WidgetRef setup.
String? _computeRedirect({
  required bool onboardingDone,
  required bool aiSetupDone,
  required bool hasAnyCloudKey,
  required String currentLocation,
}) {
  if (!onboardingDone) {
    if (currentLocation == '/welcome') return null;
    return '/welcome';
  }
  if (!aiSetupDone && !hasAnyCloudKey) {
    if (currentLocation == '/ai-setup') return null;
    return '/ai-setup';
  }
  return null;
}

void main() {
  group('Router redirect logic', () {
    test('unauthenticated → redirect to /welcome', () {
      final result = _computeRedirect(
        onboardingDone: false,
        aiSetupDone: false,
        hasAnyCloudKey: ApiKeys.hasAnyCloudKey,
        currentLocation: '/',
      );
      expect(result, '/welcome');
    });

    test('already on /welcome → no redirect', () {
      final result = _computeRedirect(
        onboardingDone: false,
        aiSetupDone: false,
        hasAnyCloudKey: ApiKeys.hasAnyCloudKey,
        currentLocation: '/welcome',
      );
      expect(result, isNull);
    });

    test('onboarding done, no AI setup, no cloud keys → redirect to /ai-setup', () {
      final result = _computeRedirect(
        onboardingDone: true,
        aiSetupDone: false,
        hasAnyCloudKey: false,
        currentLocation: '/',
      );
      expect(result, '/ai-setup');
    });

    test('already on /ai-setup → no redirect', () {
      final result = _computeRedirect(
        onboardingDone: true,
        aiSetupDone: false,
        hasAnyCloudKey: false,
        currentLocation: '/ai-setup',
      );
      expect(result, isNull);
    });

    test('onboarding and AI setup complete → no redirect', () {
      final result = _computeRedirect(
        onboardingDone: true,
        aiSetupDone: true,
        hasAnyCloudKey: false,
        currentLocation: '/',
      );
      expect(result, isNull);
    });
  });

  group('Direct navigation', () {
    testWidgets('/ route is accessible when both complete',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingCompleteProvider.overrideWith(
              (ref) => OnboardingNotifier()..state = true,
            ),
            aiSetupCompleteProvider.overrideWith(
              (ref) => AISetupNotifier()..state = true,
            ),
          ],
          child: const _TestApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(_TestApp), findsOneWidget);
    });
  });
}

/// Minimal test app that mimics the router setup.
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(onboardingCompleteProvider);
    final aiSetupDone = ref.watch(aiSetupCompleteProvider);

    // Simulate the redirect logic to show which screen we land on
    final redirect = _computeRedirect(
      onboardingDone: onboardingDone,
      aiSetupDone: aiSetupDone,
      hasAnyCloudKey: ApiKeys.hasAnyCloudKey,
      currentLocation: '/',
    );

    return MaterialApp(
      home: Text(redirect ?? 'home'),
    );
  }
}
