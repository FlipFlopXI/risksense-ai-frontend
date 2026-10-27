import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medguide/screens/shared/change_password_dialog.dart';

void main() {
  testWidgets('successful password change closes without using disposed controllers', (tester) async {
    String? savedCurrent;
    String? savedReplacement;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => ChangePasswordDialog(savePassword: (current, replacement) async {
            savedCurrent = current;
            savedReplacement = replacement;
          }),
        ),
        child: const Text('Change password'),
      ),
    ))));
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'OldPassword123!');
    await tester.enterText(find.byType(TextField).at(1), 'NewPassword123!');
    await tester.enterText(find.byType(TextField).at(2), 'NewPassword123!');
    await tester.tap(find.text('Save Password'));
    await tester.pumpAndSettle();
    expect(savedCurrent, 'OldPassword123!');
    expect(savedReplacement, 'NewPassword123!');
    expect(find.byType(ChangePasswordDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
