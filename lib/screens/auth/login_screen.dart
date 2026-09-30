import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/screens/auth/register_screen.dart';
import 'package:medguide/screens/patient/patient_access_gate.dart';
import 'package:medguide/screens/clinician/clinician_dashboard.dart';
import 'package:medguide/screens/admin/admin_dashboard.dart';
import 'package:medguide/services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _failedAttempts = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter your email and password.'),
          backgroundColor: AppColors.danger));
      return;
    }
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
      setState(() => _failedAttempts++);
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
                          'assets/images/risksense_logo.jpg',
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

                // Failed attempts warning
                if (_failedAttempts >= 3)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded,
                            color: AppColors.danger, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Multiple failed attempts detected. Account may be temporarily locked.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
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

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textLight)),
                    ),
                    Expanded(child: Divider()),
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
                      side: const BorderSide(color: AppColors.teal, width: 1.5),
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
