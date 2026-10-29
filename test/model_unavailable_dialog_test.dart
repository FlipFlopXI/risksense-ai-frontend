import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/widgets/model_unavailable_dialog.dart';

void main() {
  test('paused model is distinguished from other service failures', () {
    expect(isPausedModelError(503, 'The selected model is not active.'), isTrue);
    expect(isPausedModelError(503, 'Model unavailable', code: 'MODEL_INACTIVE'), isTrue);
    expect(isPausedModelError(503, 'Service unavailable', code: 'MODEL_UNAVAILABLE'), isFalse);
    expect(isPausedModelError(422, 'Model is inactive'), isFalse);
  });

  testWidgets('paused model dialog explains and offers developer contact', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(onPressed: () =>
        showModelUnavailableDialog(context, 'Diabetes'), child: const Text('Open')),
    ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Model Currently Unavailable'), findsOneWidget);
    expect(find.textContaining('Please try again later'), findsOneWidget);
    expect(find.text('Contact Developer'), findsOneWidget);
  });
}
