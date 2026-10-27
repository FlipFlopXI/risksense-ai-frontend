import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/shared/history_screen.dart';
import 'package:medguide/screens/shared/prediction_result_screen.dart';

void main() {
  testWidgets('New risk result opens its own PDF instead of showing a toast',
      (tester) async {
    String? openedId;
    await tester.pumpWidget(MaterialApp(
        home: PredictionResultScreen(
      condition: 'Diabetes',
      riskScore: .42,
      predictionId: 'new-prediction',
      reportOpener: (_, id) async => openedId = id,
    )));
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump();
    await tester.ensureVisible(find.text('Generate PDF Report'));
    await tester.tap(find.text('Generate PDF Report'));
    await tester.pump();
    expect(openedId, 'new-prediction');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('An older saved prediction keeps its own report ID',
      (tester) async {
    final opened = <String>[];
    final predictions = [
      {
        'id': 'newer',
        'prediction_target': 'diabetes_risk',
        'risk_score': .24,
        'risk_classification': 'standard',
        'predicted_at': '2026-10-25T10:00:00Z',
      },
      {
        'id': 'older',
        'prediction_target': 'heart_disease',
        'risk_score': .76,
        'risk_classification': 'elevated',
        'predicted_at': '2026-09-20T10:00:00Z',
      },
    ];
    await tester.pumpWidget(MaterialApp(
        home: HistoryScreen(
      predictionsLoader: () async => predictions,
      reportOpener: (_, id) async => opened.add(id),
    )));
    await tester.pump();
    await tester.pump();
    final buttons = find.byTooltip('Open PDF report');
    expect(buttons, findsNWidgets(2));
    await tester.ensureVisible(buttons.last);
    await tester.tap(buttons.last);
    await tester.pump();
    expect(opened, ['older']);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Heart Disease Risk').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump();
    await tester.ensureVisible(find.text('Generate PDF Report'));
    await tester.tap(find.text('Generate PDF Report'));
    await tester.pump();
    expect(opened, ['older', 'older']);
  });
}
