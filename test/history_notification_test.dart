import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/shared/history_screen.dart';

void main() {
  testWidgets('opening a prediction reports the viewed result ID',
      (tester) async {
    final viewed = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: HistoryScreen(
        predictionsLoader: () async => [
          {
            'id': 'latest-risk',
            'prediction_target': 'diabetes_risk',
            'risk_score': 0.72,
            'risk_classification': 'elevated',
            'predicted_at': '2026-10-28T10:00:00Z',
          },
        ],
        onPredictionViewed: viewed.add,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diabetes Risk'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(viewed, ['latest-risk']);
    expect(find.textContaining('Diabetes'), findsWidgets);
  });
}
