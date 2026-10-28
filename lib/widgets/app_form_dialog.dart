import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';

/// A themed shell for compact data-entry and settings dialogs.
class AppFormDialog extends StatelessWidget {
  const AppFormDialog(
      {super.key,
      required this.title,
      required this.content,
      required this.actions,
      this.icon = Icons.edit_note_rounded});

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      backgroundColor: AppColors.cardWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 460, maxHeight: MediaQuery.sizeOf(context).height * .86),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.heroStart, AppColors.heroEnd]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(children: [
              Icon(icon, color: Colors.white, size: 25),
              const SizedBox(width: 12),
              Expanded(
                  child: DefaultTextStyle.merge(
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                      child: title)),
            ]),
          ),
          Flexible(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: content,
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions),
          ),
        ]),
      ),
    );
  }
}
