import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/patient/onboarding_data_source.dart';
import 'package:medguide/screens/patient/patient_onboarding_screen.dart';

class _FakeOnboarding implements PatientOnboardingDataSource {
  int writes = 0;

  @override
  Future<Map<String, dynamic>> load() async => {'completed': false, 'existing': <String, dynamic>{}};

  @override
  Future<void> save(Map<String, dynamic> details) async { writes++; }

  @override
  Future<void> finishSession() async {}
}

void main() {
  testWidgets('six mobile onboarding steps fit a narrow screen and reject missing measurements', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dataSource = _FakeOnboarding();
    await tester.pumpWidget(MaterialApp(home: PatientOnboardingScreen(dataSource: dataSource)));
    await tester.pumpAndSettle();

    expect(find.text('1 of 6'), findsOneWidget);
    expect(find.bySemanticsLabel('Onboarding step 6 of 6'), findsOneWidget);
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 6'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 6'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Onboarding step 6 of 6'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 6 of 6'), findsOneWidget);
    expect(find.text('Complete Your Health Profile'), findsOneWidget);
    expect(find.byType(AspectRatio), findsNothing);
    await tester.scrollUntilVisible(find.text('Save and Continue to Login'), 250,
        scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    await tester.tap(find.text('Save and Continue to Login'));
    await tester.pumpAndSettle();
    expect(dataSource.writes, 0);
    expect(tester.takeException(), isNull);
  });
}
