import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/screens/shared/data_input_screen.dart';

void main() {
  testWidgets('clinical rows fit a narrow phone without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
      padding: EdgeInsets.all(18),
      child: Column(children: [
        InfoRow(label: 'Waist circumference', value: 'Not recorded'),
        FeatureImpactBar(
            feature: 'Systolic blood pressure',
            impact: 'Raises score',
            percent: .5,
            color: AppColors.amber),
      ]),
    ))));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: SizedBox(
          width: 134,
          height: 138,
          child: StatCard(
              title: 'Drug Enquiries',
              value: '123',
              subtitle: 'Linked patients',
              icon: Icons.medication_liquid_outlined,
              color: AppColors.amber)),
    ))));
    expect(tester.takeException(), isNull);
  });

  testWidgets('clinician demonstration demographics fit a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        const MaterialApp(home: DataInputScreen(clinicianMode: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demographics'));
    await tester.pumpAndSettle();
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('years'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'patient quick stat shows its value and context on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: SizedBox(
          width: 138,
          height: 174,
          child: StatCard(
              compact: true,
              title: 'Blood Pressure',
              value: '120/80',
              subtitle: 'Latest recorded BP',
              icon: Icons.favorite_border_rounded,
              color: AppColors.danger)),
    ))));
    expect(find.text('120/80'), findsOneWidget);
    expect(find.text('Latest recorded BP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
