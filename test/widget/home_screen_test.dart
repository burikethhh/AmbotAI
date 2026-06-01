import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambot_ai/core/ai/ai_engine.dart';
import 'package:ambot_ai/core/ai/engine_selector.dart';
import 'package:ambot_ai/core/providers/theme_provider.dart';
import 'package:ambot_ai/core/providers/roles_provider.dart';
import 'package:ambot_ai/core/roles/role.dart';
import 'package:ambot_ai/core/roles/role_domain.dart' hide DeviceTier;
import 'package:ambot_ai/shared/theme/theme_colors.dart';
import 'package:ambot_ai/core/providers/engine_providers.dart';
import 'package:ambot_ai/features/home/home_screen.dart';

class _TestThemeNotifier extends ThemeNotifier {
  _TestThemeNotifier() : super();
}

class _TestRolesNotifier extends RolesNotifier {
  _TestRolesNotifier(List<Role> roles) : super() {
    state = roles;
  }
}

class _MockAIEngine implements AIEngine {
  @override
  Future<void> initialize() async {}

  @override
  Future<String> generate(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async => '';

  @override
  Stream<String> generateStream(String prompt, {String? systemPrompt, List<MessageEntry>? history}) =>
      const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> handleMemoryPressure() async {}

  @override
  String get engineName => 'mock';

  @override
  DeviceTier get tier => DeviceTier.lowEnd;

  @override
  bool get isReady => true;
}

void main() {
  final installedRole = Role(
    id: 'tutor-1',
    name: 'Tutor',
    description: 'A helpful test tutor',
    systemPrompt: 'You are a helpful tutor.',
    category: RoleCategory.student,
    domain: RoleDomain.education,
    icon: Icons.school_outlined,
    createdAt: DateTime(2026, 1, 1),
    isInstalled: true,
  );

  testWidgets('HomeScreen renders quick action buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [
            themeProvider.overrideWith((ref) => _TestThemeNotifier()),
            themeColorsProvider.overrideWithValue(ThemeColors.dark()),
            rolesProvider.overrideWith(
              (ref) => _TestRolesNotifier([installedRole]),
            ),
            activeRoleProvider.overrideWith((ref) => null),
            engineSelectionProvider.overrideWith(
              (ref) => EngineSelection(
                engine: _MockAIEngine(),
                mode: EngineMode.local,
                reason: 'test',
              ),
            ),
          ],
          child: const HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('YOUR ROLES'), findsOneWidget);
    expect(find.text('BROWSE ALL'), findsOneWidget);
  });
}
