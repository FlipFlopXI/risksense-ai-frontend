import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/widgets/shared_widgets.dart';

void main() {
  testWidgets('risk overview uses the analysis result precision',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: RiskMeterWidget(label: 'Diabetes', percent: 0.726)),
    ));
    expect(find.text('72.6%'), findsOneWidget);
    expect(find.text('72%'), findsNothing);
  });
}
