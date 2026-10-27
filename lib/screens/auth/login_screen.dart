import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/screens/auth/register_screen.dart';
import 'package:medguide/screens/patient/patient_access_gate.dart';
import 'package:medguide/screens/clinician/clinician_workspace.dart';
import 'package:medguide/screens/admin/admin_dashboard.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/screens/auth/forgot_password_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError, _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    setState(() {
      _emailError = email.isEmpty
          ? 'Enter your email address.'
          : !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
              ? 'Enter a valid email address.'
              : null;
      _passwordError =
          _passwordController.text.isEmpty ? 'Enter your password.' : null;
    });
    if (_emailError != null || _passwordError != null) return;
    setState(() => _isLoading = true);
    try {
      final user = await ApiClient.instance
          .login(_emailController.text, _passwordController.text);
      if (!mounted) return;
      final role = user['role']?.toString().toUpperCase();
      final Widget destination = switch (role) {
        'PATIENT' => const PatientAccessGate(),
        'CLINICIAN' => const ClinicianDashboard(),
        'ADMIN' => const AdminDashboard(),
        _ => throw ApiException('This account has an unsupported role.'),
      };
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destination), (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        setState(() => _passwordError = 'Email or password is incorrect.');
      } else {
        await showDialog<void>(
            context: context,
            builder: (dialog) => AlertDialog(
                    title: const Text('Sign-in Unavailable'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // Logo & Title
                Center(
                  child: Column(
                    children: [
                      Semantics(
                        label: 'RiskSense AI logo',
                        child: Image.asset(
                          AppColors.dark
                              ? 'assets/images/risksense_logo_dark.png'
                              : 'assets/images/risksense_logo.jpg',
                          width: 230,
                          height: 230,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Secure Access Required',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your RiskSense AI account',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                TextField(
                  controller: _emailController,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                    errorText: _emailError,
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Password
                TextField(
                  controller: _passwordController,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _passwordError,
                    hintText: '••••••••',
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
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => ForgotPasswordDialog(
                          initialEmail: _emailController.text.trim()),
                    ),
                    child: Text(
                      'Forgot Password?',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),

                // Sign In Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textLight)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Register as Patient'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.medical_services_outlined, size: 18),
                    label: const Text('Clinician Request Access'),
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: BorderSide(color: AppColors.teal, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
