import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/auth/forgot_password_dialog.dart';

void main() {
  testWidgets('recovery requires an email code before generating a password',
      (tester) async {
    var clock = DateTime(2026, 1, 1);
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => ForgotPasswordDialog(
                  initialEmail: 'sample@example.com',
                  clock: () => clock,
                  requestCode: (email) async {
                    calls.add('request:$email');
                    return {'resend_after_seconds': 60};
                  },
                  completeRecovery: (email, code) async {
                    calls.add('complete:$email:$code');
                  },
                )),
        child: const Text('Open'),
      ),
    ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Email Recovery Code'), findsOneWidget);
    await tester.tap(find.text('Email Recovery Code'));
    await tester.pumpAndSettle();
    expect(calls, ['request:sample@example.com']);

    final generate = find.widgetWithText(FilledButton, 'Generate Password');
    expect(tester.widget<FilledButton>(generate).onPressed, isNull);
    await tester.enterText(
        find.widgetWithText(TextField, 'Six-Digit Email Code'), '123456');
    await tester.pump();
    expect(tester.widget<FilledButton>(generate).onPressed, isNotNull);
    expect(
        tester
            .widget<TextButton>(
                find.widgetWithText(TextButton, 'Send New Code'))
            .onPressed,
        isNull);
    clock = clock.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    expect(
        tester
            .widget<TextButton>(
                find.widgetWithText(TextButton, 'Send New Code'))
            .onPressed,
        isNotNull);

    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pumpAndSettle();
    expect(calls.last, 'complete:sample@example.com:123456');
    expect(find.text('Back to Sign In'), findsOneWidget);
  });
}
