import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/auth/register_screen.dart';

void main() {
  testWidgets('login shows missing credentials beside their fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('registration shows distinct required-field errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.enterText(find.byType(TextField).at(2), 'ExamplePass123');
    tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!();
    await tester.pump();
    expect(find.text('Enter your first and last name.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('registration explains password rules and screen purpose', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.enterText(find.byType(TextField).at(2), 'abcdef');
    tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!();
    await tester.pump();
    expect(find.text('Include a capital letter, number, and special character.'), findsOneWidget);
    await tester.tap(find.byTooltip('About this screen'));
    await tester.pumpAndSettle();
    expect(find.text('Create your patient account'), findsOneWidget);
  });
}
