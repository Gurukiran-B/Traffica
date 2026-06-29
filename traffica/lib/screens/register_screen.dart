import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  // final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  final AuthService _authService = AuthService();

  bool _isPasswordStrong(String password) {
    // A basic password strength check: min length 6, has digit and letter
    final hasMinLength = password.length >= 6;
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasLetter = password.contains(RegExp(r'[A-Za-z]'));
    return hasMinLength && hasDigit && hasLetter;
  }

  Future<void> _createAccount() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    // final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (username.isEmpty) {
      setState(() {
        errorMessage = 'Username is required';
      });
      return;
    }
    if (email.isEmpty) {
      setState(() {
        errorMessage = 'Please enter email address';
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      return;
    }
    if (!_isPasswordStrong(password)) {
      setState(() {
        errorMessage = 'Password is too weak. Min 6 chars with letters and digits';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Assuming signUp method accepts username, email, and password only.
      final success = await _authService.signUp(username, email, password);

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (mounted) {
        setState(() {
          errorMessage = 'Sign up failed. Email may already exist.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Sign up failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create Your Account',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter your username',
                      ),
                    ),
  const SizedBox(height: 12),
  TextField(
    controller: emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: const InputDecoration(
      labelText: 'Email',
      prefixIcon: Icon(Icons.email_outlined),
      hintText: 'Enter your email',
    ),
  ),
  /*
  const SizedBox(height: 12),
  TextField(
    controller: phoneController,
    keyboardType: TextInputType.phone,
    decoration: const InputDecoration(
      labelText: 'Mobile Phone',
      prefixIcon: Icon(Icons.phone_outlined),
      hintText: 'Enter your phone (optional if email)',
    ),
  ),
  */
  const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: 'Create a strong password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: 'Re-enter your password',
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: isLoading ? 'Creating Account...' : 'Create Account',
                      onPressed: isLoading ? null : _createAccount,
                      icon: Icons.person_add_alt_1_rounded,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
