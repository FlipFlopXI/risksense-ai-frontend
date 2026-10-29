import 'package:medguide/widgets/app_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';

Future<void> showAppErrorDialog(BuildContext context, String message,
    {String title = 'Unable To Complete Action'}) => showDialog<void>(
  context: context,
  builder: (dialog) => AppFormDialog(
    icon: Icons.error_outline_rounded,
    title: Text(title),
    content: Text(message),
    actions: [TextButton(onPressed: () => Navigator.pop(dialog),
      child: const Text('Dismiss'))],
  ),
);
