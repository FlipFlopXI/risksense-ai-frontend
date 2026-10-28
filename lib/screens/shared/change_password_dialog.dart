import 'package:medguide/widgets/app_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, this.savePassword});

  final Future<void> Function(String current, String replacement)? savePassword;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _replacement = TextEditingController();
  final _confirm = TextEditingController();
  String? _message;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _replacement.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final current = _current.text;
    final replacement = _replacement.text;
    if (current.isEmpty ||
        replacement.length < 6 ||
        !RegExp(r'[A-Z]').hasMatch(replacement) ||
        !RegExp(r'[0-9]').hasMatch(replacement) ||
        !RegExp(r'[^A-Za-z0-9\s]').hasMatch(replacement)) {
      setState(() =>
          _message = 'Enter a current password and a valid new password.');
      return;
    }
    if (replacement != _confirm.text) {
      setState(() => _message = 'New passwords do not match.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      if (widget.savePassword != null) {
        await widget.savePassword!(current, replacement);
      } else {
        await ApiClient.instance.patch('/auth/password', data: {
          'current_password': current,
          'new_password': replacement,
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = error is ApiException
              ? error.message
              : 'Could not change password.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppFormDialog(
        icon: Icons.lock_reset_rounded,
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                'Use at least 6 characters, including a capital letter, number and special character.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            TextField(
                controller: _current,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 10),
            TextField(
                controller: _replacement,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 10),
            TextField(
                controller: _confirm,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm New Password')),
            if (_message != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_message!,
                      style: TextStyle(color: AppColors.danger))),
          ]),
        ),
        actions: [
          TextButton(
              onPressed:
                  _saving ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save Password')),
        ],
      );
}
