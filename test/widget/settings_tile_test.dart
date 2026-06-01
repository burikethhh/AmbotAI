import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/features/settings/widgets/settings_tile.dart';

void main() {
  testWidgets('SettingsTile renders with title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsTile(
            title: Text('Test Title'),
          ),
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('SettingsTile renders with leading, subtitle, trailing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsTile(
            leading: Icon(Icons.settings),
            title: Text('Title'),
            subtitle: Text('Subtitle text'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subtitle text'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('SettingsTile can be tapped', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsTile(
            title: Text('Tap Me'),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap Me'));
    expect(tapped, isTrue);
  });
}
