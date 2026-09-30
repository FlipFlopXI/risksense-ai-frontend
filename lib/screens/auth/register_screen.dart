import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/screens/patient/patient_access_gate.dart';
import 'package:medguide/services/api_client.dart';

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
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDOB = picked);
    }
  }

  Future<void> _handleRegister() async {
    final names = _fullNameController.text.trim().split(RegExp(r'\s+'));
    if (!_consentGiven ||
        names.length < 2 ||
        _selectedDOB == null ||
        _selectedGender.isEmpty ||
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Complete all required fields and ensure passwords match.'),
          backgroundColor: AppColors.danger));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.register({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'first_name': names.first,
        'last_name': names.skip(1).join(' '),
        'date_of_birth': _selectedDOB!.toIso8601String().split('T').first,
        'gender': _selectedGender,
      });
      await ApiClient.instance
          .login(_emailController.text, _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PatientAccessGate()),
          (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.message), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
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
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'John Smith',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 14),

              _label('Email Address'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'john@email.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 14),

              _label('Password'),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
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
              const SizedBox(height: 14),

              _label('Confirm Password'),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
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
                      const Icon(Icons.calendar_today_outlined,
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
              const SizedBox(height: 14),

              _label('Gender'),
              Row(
                children: ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map(
                      (g) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedGender = g),
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
              const SizedBox(height: 24),

              // Consent
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _consentGiven
                      ? AppColors.success.withOpacity(0.06)
                      : AppColors.amber.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _consentGiven
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.amber.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _consentGiven,
                      onChanged: (v) =>
                          setState(() => _consentGiven = v ?? false),
                      activeColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
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
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_consentGiven && !_isLoading) ? _handleRegister : null,
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
                      : const Text('Create Account'),
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
