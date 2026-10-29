import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/admin/admin_dashboard.dart';
import 'package:medguide/screens/patient/patient_dashboard.dart';

void main() {
  testWidgets('patient navigation keeps profile available', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PatientDashboard()));
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });

  testWidgets('admin navigation keeps profile available', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminDashboard()));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
  });
}
