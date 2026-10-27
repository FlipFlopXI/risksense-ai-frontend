import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/auth/email_verification_screen.dart';

void main() {
  testWidgets(
      'code completion enables verification and resend waits one minute',
      (tester) async {
    var currentTime = DateTime(2026, 1, 1);
    await tester.pumpWidget(MaterialApp(
      home: EmailVerificationScreen(
        email: 'example@example.test',
        password: 'TestPassword123!',
        codeLength: 6,
        resendAfterSeconds: 60,
        clock: () => currentTime,
      ),
    ));

    final verify = find.widgetWithText(ElevatedButton, 'Verify Email');
    final resend = find.widgetWithText(TextButton, 'Send New Code');
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNull);
    expect(tester.widget<TextButton>(resend).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(verify).onPressed, isNotNull);

    currentTime = currentTime.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<TextButton>(resend).onPressed, isNotNull);
  });
}
