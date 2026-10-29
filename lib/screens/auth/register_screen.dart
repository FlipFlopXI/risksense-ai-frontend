import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/screens/auth/password_strength.dart';
import 'package:medguide/screens/auth/email_verification_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/widgets/app_form_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _consentGiven = false;
  String _selectedGender = '';
  DateTime? _selectedDOB;
  bool _isLoading = false;
  final Map<String, String> _errors = {};

  Future<void> _showPasswordStrengthHelp() => showDialog<void>(
        context: context,
        builder: (dialog) => AppFormDialog(
          icon: Icons.shield_outlined,
          title: const Text('Choosing a Strong Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Use a unique password that is hard for someone else to guess.',
                  style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              Text('Registration requirements',
                  style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  'Use 6 to 128 characters, with at least one capital letter, one number, and one special character.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              Text('How the meter works',
                  style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  'Very weak: the minimum requirements are not met.\n'
                  'Weak: the password contains your first name or surname.\n'
                  'Moderate: it meets the requirements but has only one letter.\n'
                  'Strong: it meets the requirements, avoids your name, and has more than one letter.',
                  style:
                      TextStyle(color: AppColors.textSecondary, height: 1.55)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                    'For better protection, use a longer, unique password and avoid reusing one from another account. The meter is a guide, not a security guarantee.',
                    style:
                        TextStyle(color: AppColors.textPrimary, fontSize: 12)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Got it'),
            )
          ],
        ),
      );

  Widget _passwordStrengthIndicator() {
    final strength = classifyRegistrationPassword(
        _passwordController.text, _fullNameController.text);
    final level = strength.index + 1;
    final label = switch (strength) {
      PasswordStrength.veryWeak => 'Very weak',
      PasswordStrength.weak => 'Weak',
      PasswordStrength.moderate => 'Moderate',
      PasswordStrength.strong => 'Strong',
    };
    final detail = switch (strength) {
      PasswordStrength.veryWeak => 'Meet the password requirements above.',
      PasswordStrength.weak => 'Avoid using your name or surname.',
      PasswordStrength.moderate => 'Add more letters for a stronger password.',
      PasswordStrength.strong => 'Password meets the strength criteria.',
    };
    final color = switch (strength) {
      PasswordStrength.veryWeak => AppColors.danger,
      PasswordStrength.weak => AppColors.amber,
      PasswordStrength.moderate => AppColors.primaryBlue,
      PasswordStrength.strong => AppColors.success,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Password strength: $label',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'About password strength',
            onPressed: _showPasswordStrengthHelp,
            icon: Icon(Icons.info_outline_rounded,
                color: AppColors.primaryBlue, size: 18),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ]),
        const SizedBox(height: 7),
        Row(
            children: List.generate(
                4,
                (index) => Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: index < level ? color : AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ))),
        const SizedBox(height: 6),
        Text(detail,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDOB = picked;
        _errors.remove('dob');
      });
    }
  }

  Future<void> _handleRegister() async {
    final names = _fullNameController.text.trim().split(RegExp(r'\s+'));
    setState(() {
      _errors.clear();
      if (names.length < 2 || names.any((name) => name.isEmpty)) {
        _errors['name'] = 'Enter your first and last name.';
      } else if (names.first.length > 100 ||
          names.skip(1).join(' ').length > 100) {
        _errors['name'] = 'Each name must be 100 characters or fewer.';
      }
      final email = _emailController.text.trim();
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        _errors['email'] = 'Enter a valid email address.';
      }
      final password = _passwordController.text;
      if (password.length < 6 || password.length > 128) {
        _errors['password'] = 'Use at least 6 characters (maximum 128).';
      } else if (!RegExp(r'[A-Z]').hasMatch(password) ||
          !RegExp(r'[0-9]').hasMatch(password) ||
          !RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) {
        _errors['password'] =
            'Include a capital letter, number, and special character.';
      }
      if (_confirmPasswordController.text != _passwordController.text) {
        _errors['confirm'] = 'Passwords do not match.';
      }
      if (_selectedDOB == null) _errors['dob'] = 'Select your date of birth.';
      if (_selectedGender.isEmpty) {
        _errors['gender'] = 'Select a gender option.';
      }
      if (!_consentGiven) {
        _errors['consent'] = 'Consent is required to create an account.';
      }
    });
    if (_errors.isNotEmpty) return;
    setState(() => _isLoading = true);
    try {
      final pending = await ApiClient.instance.register({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'first_name': names.first,
        'last_name': names.skip(1).join(' '),
        'date_of_birth': _selectedDOB!.toIso8601String().split('T').first,
        'gender': _selectedGender,
      });
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
                email: pending['email']?.toString() ??
                    _emailController.text.trim(),
                password: _passwordController.text,
                codeLength: pending['code_length'] as int? ?? 6,
                resendAfterSeconds:
                    pending['resend_after_seconds'] as int? ?? 60,
              )));
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        setState(() =>
            _errors['email'] = 'This email address is already registered.');
      } else {
        await showDialog<void>(
            context: context,
            builder: (dialog) => AlertDialog(
                    title: const Text('Registration Unavailable'),
                    content: Text(error.message),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialog),
                          child: const Text('Dismiss'))
                    ]));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
        actions: const [ScreenHelpButton(topic: 'Registration')],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Patient Registration',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text('Create your secure patient account',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),

              _label('Full Name'),
              TextField(
                controller: _fullNameController,
                onChanged: (_) => setState(() => _errors.remove('name')),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'John Smith',
                  errorText: _errors['name'],
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 14),

              _label('Email Address'),
              TextField(
                controller: _emailController,
                onChanged: (_) => setState(() => _errors.remove('email')),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'john@email.com',
                  errorText: _errors['email'],
                  prefixIcon: Icon(Icons.mail_outline_rounded,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 14),

              _label('Password'),
              Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                      'At least 6 characters, including a capital letter, number, and special character.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary))),
              TextField(
                controller: _passwordController,
                onChanged: (_) => setState(() => _errors.remove('password')),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  errorText: _errors['password'],
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              if (_passwordController.text.isNotEmpty)
                _passwordStrengthIndicator(),
              const SizedBox(height: 14),

              _label('Confirm Password'),
              TextField(
                controller: _confirmPasswordController,
                onChanged: (_) => setState(() => _errors.remove('confirm')),
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  errorText: _errors['confirm'],
                  prefixIcon: Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _label('Date of Birth'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDOB != null
                            ? '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}'
                            : 'Select date of birth',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDOB != null
                              ? AppColors.textPrimary
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errors['dob'] != null)
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_errors['dob']!,
                        style:
                            TextStyle(color: AppColors.danger, fontSize: 12))),
              const SizedBox(height: 14),

              _label('Gender'),
              Row(
                children: ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map(
                      (g) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedGender = g;
                              _errors.remove('gender');
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedGender == g
                                    ? AppColors.primaryBlue
                                    : AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedGender == g
                                      ? AppColors.primaryBlue
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                g,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedGender == g
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_errors['gender'] != null)
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_errors['gender']!,
                        style:
                            TextStyle(color: AppColors.danger, fontSize: 12))),
              const SizedBox(height: 24),

              // Consent
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _consentGiven
                      ? AppColors.success.withValues(alpha: 0.06)
                      : AppColors.amber.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _consentGiven
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _consentGiven,
                      onChanged: (v) => setState(() {
                        _consentGiven = v ?? false;
                        _errors.remove('consent');
                      }),
                      activeColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'I understand this is a decision-support system and not a diagnostic tool. I consent to my health data being processed for risk analysis purposes.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errors['consent'] != null)
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_errors['consent']!,
                        style:
                            TextStyle(color: AppColors.danger, fontSize: 12))),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Send Verification Code'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
