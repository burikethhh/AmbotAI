import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/features/document_gen/widgets/document_stats_bar.dart';
import 'package:ambot_ai/shared/theme/theme_colors.dart';

void main() {
  testWidgets('DocumentStatsBar displays word, char, line, paragraph counts',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentStatsBar(
            c: ThemeColors.light(),
            wordCount: 42,
            charCount: 210,
            lineCount: 5,
            paraCount: 3,
          ),
        ),
      ),
    );

    expect(find.text('42 words'), findsOneWidget);
    expect(find.text('210 chars'), findsOneWidget);
    expect(find.text('5 lines'), findsOneWidget);
    expect(find.text('3 paragraphs'), findsOneWidget);
  });

  testWidgets('DocumentStatsBar renders with zeros', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentStatsBar(
            c: ThemeColors.dark(),
            wordCount: 0,
            charCount: 0,
            lineCount: 0,
            paraCount: 0,
          ),
        ),
      ),
    );

    expect(find.text('0 words'), findsOneWidget);
    expect(find.text('0 chars'), findsOneWidget);
    expect(find.text('0 lines'), findsOneWidget);
    expect(find.text('0 paragraphs'), findsOneWidget);
  });
}
