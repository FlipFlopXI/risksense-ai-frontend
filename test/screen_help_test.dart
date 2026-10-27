import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/widgets/screen_help.dart';

void main() {
  testWidgets('every main-screen help topic opens with context and disclaimer',
      (tester) async {
    const topics = [
      'Settings', 'Registration', 'Onboarding Health Profile', 'Health Data Input', 'Prediction Result',
      'Nutrition', 'Mindfulness', 'Meal Plan', 'Fitness', 'Fitness Routine',
      'Dashboard', 'Health Trends', 'Prediction History', 'Assistant',
      'My Profile', 'Admin Console', 'User Management', 'Audit Logs',
      'Model Management', 'Admin Profile', 'Clinician Dashboard', 'Patients',
      'Clinician Profile', 'Patient Detail', 'Demonstration Analysis',
    ];
    for (final topic in topics) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
          body: Center(child: ScreenHelpButton(key: ValueKey(topic), topic: topic)))));
      await tester.tap(find.byTooltip('About this screen'));
      await tester.pumpAndSettle();
      expect(find.text('ABOUT THIS SCREEN'), findsOneWidget, reason: topic);
      expect(find.byType(Dialog), findsOneWidget, reason: topic);
      expect(tester.takeException(), isNull, reason: topic);
      await tester.tap(find.byTooltip('Close help'));
      await tester.pumpAndSettle();
    }
  });
}
