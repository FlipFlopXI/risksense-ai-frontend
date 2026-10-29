import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/auth/password_strength.dart';
import 'package:medguide/screens/auth/register_screen.dart';

void main() {
  test('registration strength follows requirement, name, and letter priorities',
      () {
    expect(classifyRegistrationPassword('abc', 'Alex Smith'),
        PasswordStrength.veryWeak);
    expect(classifyRegistrationPassword('Abcdef1', 'Alex Smith'),
        PasswordStrength.veryWeak);
    expect(classifyRegistrationPassword('Smith123!', 'Alex Smith'),
        PasswordStrength.weak);
    expect(classifyRegistrationPassword('aLEX123!', 'Alex Smith'),
        PasswordStrength.weak);
    expect(classifyRegistrationPassword('A12345!', 'Alex Smith'),
        PasswordStrength.moderate);
    expect(classifyRegistrationPassword('Ax1234!', 'Alex Smith'),
        PasswordStrength.strong);
  });

  testWidgets('strength label responds to password and name edits',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), 'A12345!');
    await tester.pump();
    expect(find.text('Password strength: Moderate'), findsOneWidget);
    await tester.tap(find.byTooltip('About password strength'));
    await tester.pumpAndSettle();
    expect(find.text('Choosing a Strong Password'), findsOneWidget);
    expect(find.textContaining('avoid reusing one from another account'),
        findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    await tester.enterText(fields.at(2), 'Alex123!');
    await tester.pump();
    expect(find.text('Password strength: Strong'), findsOneWidget);
    await tester.enterText(fields.at(0), 'Alex Smith');
    await tester.pump();
    expect(find.text('Password strength: Weak'), findsOneWidget);
    await tester.enterText(fields.at(2), 'alex');
    await tester.pump();
    expect(find.text('Password strength: Very weak'), findsOneWidget);
  });
}
