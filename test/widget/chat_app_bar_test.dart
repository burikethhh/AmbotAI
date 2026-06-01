import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambot_ai/core/roles/role.dart';
import 'package:ambot_ai/core/roles/role_domain.dart';
import 'package:ambot_ai/shared/theme/theme_colors.dart';
import 'package:ambot_ai/features/chat/widgets/chat_app_bar.dart';

void main() {
  final role = Role(
    id: 'test-tutor',
    name: 'Tutor',
    description: 'A helpful tutor role for testing',
    systemPrompt: 'You are a helpful tutor.',
    category: RoleCategory.student,
    domain: RoleDomain.education,
    icon: Icons.school_outlined,
    createdAt: DateTime(2026, 1, 1),
    isInstalled: true,
  );

  testWidgets('ChatAppBar renders without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeColorsProvider.overrideWithValue(ThemeColors.dark()),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: ChatAppBar(
              role: role,
              isStreaming: false,
              responseMode: ResponseMode.chat,
              qaMode: false,
              onCycleResponseMode: () {},
              onToggleQaMode: () {},
              onHistory: () {},
              onMoreOptions: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ChatAppBar), findsOneWidget);
    expect(find.text('TUTOR'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
  });
}
