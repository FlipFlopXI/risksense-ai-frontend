import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/patient/patient_access_gate.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/screen_help.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen(
      {super.key,
      required this.email,
      required this.password,
      required this.codeLength,
      required this.resendAfterSeconds,
      this.clock});

  final String email;
  final String password;
  final int codeLength;
  final int resendAfterSeconds;
  final DateTime Function()? clock;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;
  late DateTime _resendAt;
  bool _busy = false;
  String? _error;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _resendAt = _now.add(Duration(seconds: widget.resendAfterSeconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _controller.addListener(() {
      if (mounted) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _remaining {
    final seconds = _resendAt.difference(_now).inSeconds + 1;
    return seconds.clamp(0, widget.resendAfterSeconds);
  }

  Future<void> _resend() async {
    if (_remaining > 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response =
          await ApiClient.instance.resendRegistrationCode(widget.email);
      if (!mounted) return;
      _controller.clear();
      setState(() => _resendAt = _now.add(
          Duration(seconds: response['resend_after_seconds'] as int? ?? 60)));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || _controller.text.length != widget.codeLength) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiClient.instance
          .verifyRegistrationCode(widget.email, _controller.text);
      try {
        await ApiClient.instance.login(widget.email, widget.password);
      } on ApiException {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Email Verified'),
            content: const Text(
                'Your account was created. Please sign in to continue with access activation.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Continue'))
            ],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false);
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PatientAccessGate()),
          (_) => false);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final complete = _controller.text.length == widget.codeLength;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Verify Email'),
          backgroundColor: AppColors.cardWhite,
          actions: const [ScreenHelpButton(topic: 'Registration')]),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: AppColors.border)),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                                'assets/images/email_verification.png',
                                fit: BoxFit.contain)),
                      ),
                      const SizedBox(height: 26),
                      Text('Check your inbox',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 10),
                      Text(
                          'Enter the ${widget.codeLength}-digit code sent to ${widget.email}. The code expires after 10 minutes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, height: 1.5)),
                      const SizedBox(height: 28),
                      Semantics(
                          label: 'Verification code',
                          textField: true,
                          child: Stack(children: [
                            Opacity(
                                opacity: 0,
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                        widget.codeLength)
                                  ],
                                  onSubmitted: (_) => _verify(),
                                )),
                            IgnorePointer(
                                child: Row(
                                    children: List.generate(widget.codeLength,
                                        (index) {
                              final filled = index < _controller.text.length;
                              return Expanded(
                                  child: Container(
                                height: 58,
                                margin: EdgeInsets.only(
                                    right:
                                        index == widget.codeLength - 1 ? 0 : 7),
                                decoration: BoxDecoration(
                                    color: AppColors.cardWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: filled
                                            ? AppColors.primaryBlue
                                            : AppColors.border,
                                        width: 1.5)),
                                alignment: Alignment.center,
                                child: Text(
                                    filled ? _controller.text[index] : '',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                              ));
                            }))),
                          ])),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () => _focusNode.requestFocus(),
                          child: const Text('Tap to enter code')),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.danger))),
                      const SizedBox(height: 16),
                      SizedBox(
                          height: 52,
                          child: ElevatedButton(
                              onPressed: complete && !_busy ? _verify : null,
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Verify Email'))),
                      const SizedBox(height: 20),
                      Text(
                          _remaining > 0
                              ? 'Send a new code in 0:${_remaining.toString().padLeft(2, '0')}'
                              : 'Didn’t receive the code?',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                          onPressed: _remaining == 0 && !_busy ? _resend : null,
                          child: const Text('Send New Code')),
                    ]))),
      )),
    );
  }
}
