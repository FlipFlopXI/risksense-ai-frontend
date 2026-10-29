import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/shared/ai_assistant_screen.dart';

void main() {
  testWidgets(
      'assistant explains medication commands and add chip only drafts text',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AiAssistantScreen()));
    expect(find.textContaining('add medication name + routine + dosage'),
        findsOneWidget);
    expect(find.text('Add medication…'), findsNothing);
    await tester.tap(find.text('Suggested Questions'));
    await tester.pumpAndSettle();
    expect(find.text('Add medication…'), findsOneWidget);
    expect(find.text('View medication'), findsOneWidget);
    expect(find.text('Remove medication…'), findsOneWidget);
    await tester.tap(find.text('Add medication…'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'add medication ');
    expect(find.textContaining('was added'), findsNothing);
  });
}
