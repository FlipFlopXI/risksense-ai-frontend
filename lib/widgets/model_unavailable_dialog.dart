import 'package:flutter/material.dart';
import 'package:medguide/services/developer_contact.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/app_error_dialog.dart';
import 'package:medguide/widgets/app_form_dialog.dart';

bool isPausedModelError(int? statusCode, String message, {String? code}) {
  final description = message.toLowerCase();
  return statusCode == 503 &&
      (code == 'MODEL_INACTIVE' ||
          description.contains('model is inactive') ||
          description.contains('model is not active'));
}

Future<void> showModelUnavailableDialog(BuildContext context, String model) =>
    showDialog<void>(
      context: context,
      builder: (dialog) => AppFormDialog(
        icon: Icons.model_training_outlined,
        title: const Text('Model Currently Unavailable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The $model risk analysis model is currently unavailable. Please try again later.',
                style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text('If you need help, you can contact the developer from your email app.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () async {
              final opened = await launchDeveloperEmail();
              if (!dialog.mounted) return;
              Navigator.pop(dialog);
              if (!opened && context.mounted) {
                await showAppErrorDialog(context, 'No email app is available on this device.');
              }
            },
            icon: const Icon(Icons.email_outlined, size: 18),
            label: const Text('Contact Developer'),
          ),
        ],
      ),
    );
