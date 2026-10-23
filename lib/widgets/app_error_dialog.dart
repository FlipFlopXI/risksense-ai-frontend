import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';

Future<void> showAppErrorDialog(BuildContext context, String message,
    {String title = 'Unable To Complete Action'}) => showDialog<void>(
  context: context,
  builder: (dialog) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    icon: const Icon(Icons.error_outline_rounded, color: AppColors.danger),
    title: Text(title),
    content: Text(message),
    actions: [TextButton(onPressed: () => Navigator.pop(dialog),
      child: const Text('Dismiss'))],
  ),
);
