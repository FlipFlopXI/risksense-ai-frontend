import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/shared/health_conditions_dialog.dart';
import 'package:medguide/services/recorded_conditions.dart';

void main() {
  testWidgets('patient can record diagnoses without a narrow-screen overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    RecordedConditions? result;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showDialog<RecordedConditions>(
            context: context,
            builder: (_) => const HealthConditionsDialog(
              initial: RecordedConditions(other: 'Asthma'),
            ),
          );
        },
        child: const Text('Open'),
      ),
    ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diagnosed with diabetes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(result?.diabetes, isTrue);
    expect(result?.other, 'Asthma');
  });
}
