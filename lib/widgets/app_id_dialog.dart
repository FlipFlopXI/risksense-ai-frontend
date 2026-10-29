import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/app_form_dialog.dart';

Future<void> showAppIdDialog(BuildContext context,
        {required String title, required String id}) =>
    showDialog<void>(
        context: context,
        builder: (dialog) => AppFormDialog(
              icon: Icons.badge_outlined,
              title: Text(title),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your RiskSense reference',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 14),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border)),
                        child: SelectableText(id,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700))),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: const Text('Back')),
                FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: id));
                      if (dialog.mounted) Navigator.pop(dialog);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy ID')),
              ],
            ));
