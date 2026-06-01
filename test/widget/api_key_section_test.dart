import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/config/api_keys.dart';
import 'package:ambot_ai/features/settings/widgets/api_key_section.dart';
import 'package:ambot_ai/shared/theme/app_colors.dart';

void main() {
  testWidgets('ApiKeySection renders with no user keys', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ApiKeySection(
            isDark: false,
            textPrimary: AppColors.textPrimaryLight,
            textSecondary: AppColors.textSecondaryLight,
            borderColor: AppColors.borderLight,
            cardColor: AppColors.cardLight,
            hasUserOpenRouter: false,
            hasUserGemini: false,
            hasUserQwen: false,
            hasUserHuggingFace: false,
            hasUserNvidia: false,
            hasUserNvidia2: false,
          ),
        ),
      ),
    );

    expect(find.text('OPENROUTER'), findsOneWidget);
    expect(find.text('GEMINI'), findsOneWidget);
    expect(find.text('QWEN'), findsOneWidget);
    expect(find.text('HUGGING FACE'), findsOneWidget);
    expect(find.text('NVIDIA BUILD (KEY 1)'), findsOneWidget);
    expect(find.text('NVIDIA BUILD (KEY 2)'), findsOneWidget);

    if (ApiKeys.hasAnyCloudKey) {
      expect(
        find.text(
            'Built-in keys active. Cloud AI is available as fallback.'),
        findsOneWidget,
      );
    } else {
      expect(
        find.text(
            'No API keys configured. Add keys in api_keys.dart or paste above.'),
        findsOneWidget,
      );
    }
  });

  testWidgets('ApiKeySection shows user keys as active', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ApiKeySection(
            isDark: true,
            textPrimary: AppColors.textPrimaryDark,
            textSecondary: AppColors.textSecondaryDark,
            borderColor: AppColors.borderDark,
            cardColor: AppColors.cardDark,
            hasUserOpenRouter: true,
            hasUserGemini: true,
            hasUserQwen: false,
            hasUserHuggingFace: false,
            hasUserNvidia: true,
            hasUserNvidia2: false,
          ),
        ),
      ),
    );

    expect(find.text('OPENROUTER'), findsOneWidget);
    expect(find.text('GEMINI'), findsOneWidget);
    expect(find.text('QWEN'), findsOneWidget);
    expect(find.text('HUGGING FACE'), findsOneWidget);
    expect(find.text('NVIDIA BUILD (KEY 1)'), findsOneWidget);
    expect(find.text('NVIDIA BUILD (KEY 2)'), findsOneWidget);
  });
}
