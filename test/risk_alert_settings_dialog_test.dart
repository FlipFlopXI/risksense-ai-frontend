import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/shared/risk_alert_settings_dialog.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('risk alert options live inside the dialog and email starts off',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.setRiskAlerts(true);
    bool? savedEmail;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => RiskAlertSettingsDialog(
                      loadEmailPreference: () async => false,
                      saveEmailPreference: (value) async {
                        savedEmail = value;
                        return value;
                      },
                    ),
                  ),
                  child: const Text('Open Alerts'),
                )),
      ),
    ));

    expect(find.text('Email Elevated Results'), findsNothing);
    await tester.tap(find.text('Open Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Alert Badges'), findsOneWidget);
    expect(find.text('Email Elevated Results'), findsOneWidget);
    final switches = find.byType(SwitchListTile);
    expect(switches, findsNWidgets(2));
    expect(tester.widget<SwitchListTile>(switches.at(0)).value, isTrue);
    expect(tester.widget<SwitchListTile>(switches.at(1)).value, isFalse);

    await tester.tap(find.text('Email Elevated Results'));
    await tester.pumpAndSettle();
    expect(savedEmail, isTrue);
    expect(tester.widget<SwitchListTile>(switches.at(1)).value, isTrue);

    await tester.tap(find.text('Dashboard Alert Badges'));
    await tester.pumpAndSettle();
    expect(AppPreferences.instance.riskAlerts, isFalse);
    await AppPreferences.instance.setRiskAlerts(true);
  });
}
