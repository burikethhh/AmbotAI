import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/features/document_gen/widgets/editor_toolbar.dart';
import 'package:ambot_ai/shared/theme/theme_colors.dart';

void main() {
  testWidgets('EditorToolbar renders formatting buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: EditorToolbar(
              c: ThemeColors.light(),
              lineSpacing: 1.5,
              fontSize: 14.0,
              textAlign: TextAlign.left,
              onLineSpacingChanged: (_) {},
              onFontSizeChanged: (_) {},
              onTextAlignChanged: (_) {},
              onBold: () {},
              onItalic: () {},
              onUnderline: () {},
              onHeading1: () {},
              onHeading2: () {},
              onHeading3: () {},
              onBullet: () {},
              onNumbered: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip('Bold (**)'), findsOneWidget);
    expect(find.byTooltip('Italic (*)'), findsOneWidget);
    expect(find.byTooltip('Underline (<u>)'), findsOneWidget);
    expect(find.byTooltip('Heading 1 (#)'), findsOneWidget);
    expect(find.byTooltip('Heading 2 (##)'), findsOneWidget);
    expect(find.byTooltip('Heading 3 (###)'), findsOneWidget);
    expect(find.byTooltip('Bullet List (-)'), findsOneWidget);
    expect(find.byTooltip('Numbered List (1.)'), findsOneWidget);
  });

  testWidgets('EditorToolbar renders alignment buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: EditorToolbar(
              c: ThemeColors.dark(),
              lineSpacing: 1.5,
              fontSize: 14.0,
              textAlign: TextAlign.center,
              onLineSpacingChanged: (_) {},
              onFontSizeChanged: (_) {},
              onTextAlignChanged: (_) {},
              onBold: () {},
              onItalic: () {},
              onUnderline: () {},
              onHeading1: () {},
              onHeading2: () {},
              onHeading3: () {},
              onBullet: () {},
              onNumbered: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byIcon(Icons.format_align_left), findsOneWidget);
    expect(find.byIcon(Icons.format_align_center), findsOneWidget);
    expect(find.byIcon(Icons.format_align_right), findsOneWidget);
    expect(find.byIcon(Icons.format_align_justify), findsOneWidget);
  });

  testWidgets('EditorToolbar shows spacing and size dropdowns',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: EditorToolbar(
              c: ThemeColors.light(),
              lineSpacing: 1.5,
              fontSize: 14.0,
              textAlign: TextAlign.left,
              onLineSpacingChanged: (_) {},
              onFontSizeChanged: (_) {},
              onTextAlignChanged: (_) {},
              onBold: () {},
              onItalic: () {},
              onUnderline: () {},
              onHeading1: () {},
              onHeading2: () {},
              onHeading3: () {},
              onBullet: () {},
              onNumbered: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Spacing'), findsOneWidget);
    expect(find.text('Size'), findsOneWidget);
  });
}
