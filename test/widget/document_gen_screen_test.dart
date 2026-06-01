import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/features/document_gen/document_gen_screen.dart';

void main() {
  testWidgets('DocumentGenScreen renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DocumentGenScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DocumentGenScreen), findsOneWidget);
  });
}
