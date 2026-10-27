import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog(
      {super.key,
      this.initialEmail = '',
      this.requestCode,
      this.completeRecovery,
      this.clock});
  final String initialEmail;
  final Future<Map<String, dynamic>> Function(String email)? requestCode;
  final Future<void> Function(String email, String code)? completeRecovery;
  final DateTime Function()? clock;

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  Timer? _timer;
  DateTime? _resendAt;
  bool _codeRequested = false;
  bool _complete = false;
  bool _busy = false;
  String? _error;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  int get _secondsRemaining {
    if (_resendAt == null) return 0;
    return (_resendAt!.difference(_now).inSeconds + 1).clamp(0, 60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_busy || (_codeRequested && _secondsRemaining > 0)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await (widget.requestCode ??
          ApiClient.instance.requestPasswordRecovery)(email);
      if (!mounted) return;
      _code.clear();
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      setState(() {
        _codeRequested = true;
        _resendAt = _now.add(
            Duration(seconds: response['resend_after_seconds'] as int? ?? 60));
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generatePassword() async {
    if (_code.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.completeRecovery ??
              ApiClient.instance.completePasswordRecovery)(
          _email.text.trim(), _code.text);
      if (mounted) setState(() => _complete = true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: AppColors.cardWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.heroStart, AppColors.heroEnd]),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.mark_email_read_outlined,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 14),
              Text(_complete ? 'Check Your Inbox' : 'Recover Your Password',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_complete) ...[
                    Text(
                        'A replacement password has been sent to your registered email address. Sign in with it, then open Settings → Change Password to choose your own.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, height: 1.5)),
                    const SizedBox(height: 18),
                    FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to Sign In')),
                  ] else ...[
                    Text(
                        'Enter your account email. We’ll send a six-digit code to confirm it is yours before replacing your password.',
                        style: TextStyle(
                            color: AppColors.textSecondary, height: 1.45)),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _email,
                      enabled: !_codeRequested && !_busy,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.mail_outline_rounded,
                              color: AppColors.primaryBlue)),
                    ),
                    if (_codeRequested) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6)
                        ],
                        onChanged: (_) => setState(() => _error = null),
                        decoration: InputDecoration(
                            labelText: 'Six-Digit Email Code',
                            prefixIcon: Icon(Icons.password_rounded,
                                color: AppColors.teal)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                          _secondsRemaining > 0
                              ? 'Send a new code in 0:${_secondsRemaining.toString().padLeft(2, '0')}'
                              : 'You can request a new code now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      TextButton(
                          onPressed: _secondsRemaining == 0 && !_busy
                              ? _requestCode
                              : null,
                          child: const Text('Send New Code')),
                    ],
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!,
                              style: TextStyle(color: AppColors.danger),
                              textAlign: TextAlign.center)),
                    const SizedBox(height: 14),
                    SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _busy
                              ? null
                              : _codeRequested
                                  ? (_code.text.length == 6
                                      ? _generatePassword
                                      : null)
                                  : _requestCode,
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Text(_codeRequested
                                  ? 'Generate Password'
                                  : 'Email Recovery Code'),
                        )),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.surfaceBlue,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.settings_outlined,
                            size: 20, color: AppColors.primaryBlue),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'After signing in, you can change the replacement password in Settings → Change Password.',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.4))),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        child: const Text('Cancel')),
                  ],
                ]),
          ),
        ])),
      ),
    );
  }
}
