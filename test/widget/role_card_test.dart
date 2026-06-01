import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambot_ai/core/roles/role.dart';
import 'package:ambot_ai/core/roles/role_domain.dart';
import 'package:ambot_ai/shared/theme/theme_colors.dart';
import 'package:ambot_ai/core/providers/roles_provider.dart';
import 'package:ambot_ai/features/roles/widgets/role_card.dart';

void main() {
  final sampleRole = Role(
    id: 'test-tutor',
    name: 'Tutor',
    description: 'A helpful tutor for learning',
    systemPrompt: 'You are a tutor.',
    category: RoleCategory.student,
    domain: RoleDomain.education,
    icon: Icons.school_outlined,
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets('RoleCard renders with sample role data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              themeColorsProvider.overrideWithValue(ThemeColors.light()),
              rolesProvider.overrideWith((ref) => _TestRolesNotifier([])),
            ],
            child: RoleCard(role: sampleRole),
          ),
        ),
      ),
    );

    expect(find.text('TUTOR'), findsOneWidget);
    expect(find.text('A helpful tutor for learning'), findsOneWidget);
    expect(find.text('STUDENT'), findsOneWidget);
    expect(find.text('EDUCATION'), findsOneWidget);
  });

  testWidgets('RoleCard shows INSTALLED when role is installed',
      (tester) async {
    final installedRole = sampleRole.copyWith(isInstalled: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              themeColorsProvider.overrideWithValue(ThemeColors.dark()),
              rolesProvider.overrideWith(
                (ref) => _TestRolesNotifier([installedRole]),
              ),
            ],
            child: RoleCard(role: installedRole),
          ),
        ),
      ),
    );

    expect(find.text('INSTALLED'), findsOneWidget);
  });

  testWidgets('RoleCard shows INSTALL button when not installed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              themeColorsProvider.overrideWithValue(ThemeColors.light()),
              rolesProvider.overrideWith((ref) => _TestRolesNotifier([])),
            ],
            child: RoleCard(role: sampleRole),
          ),
        ),
      ),
    );

    expect(find.text('INSTALL'), findsOneWidget);
  });

  testWidgets('RoleCard shows image and doc badges when supported',
      (tester) async {
    final roleWithFeatures = sampleRole.copyWith(
      acceptsImage: true,
      acceptsDocument: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              themeColorsProvider.overrideWithValue(ThemeColors.light()),
              rolesProvider.overrideWith((ref) => _TestRolesNotifier([])),
            ],
            child: RoleCard(role: roleWithFeatures),
          ),
        ),
      ),
    );

    expect(find.text('IMAGE'), findsOneWidget);
    expect(find.text('DOC'), findsOneWidget);
  });
}

class _TestRolesNotifier extends RolesNotifier {
  _TestRolesNotifier(List<Role> roles) : super() {
    state = roles;
  }
}
