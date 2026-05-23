import 'package:flutter/material.dart';
import 'package:motorshop/features/auth/screens/login_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? result = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        shopName: _shopNameController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        // Show success or error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? 'An error occurred'),
            backgroundColor: result!.contains('Success') ? Colors.green : Colors.red,
          ),
        );

        // If successful, you would navigate to the Login screen here
        if (result.contains('Success')) {
          // Navigator.pop(context);
        }
      }
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Register your motor shop to start managing your business.",
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  CustomTextField(
                    label: "Shop Name",
                    hint: "Enter your shop's name",
                    icon: Icons.store,
                    controller: _shopNameController,
                    validator: (value) => value!.isEmpty ? "Shop name is required" : null,
                  ),
                  CustomTextField(
                    label: "Email Address",
                    hint: "shop@example.com",
                    icon: Icons.email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => !value!.contains('@') ? "Enter a valid email" : null,
                  ),
                  CustomTextField(
                    label: "Password",
                    hint: "Create a strong password",
                    icon: Icons.lock,
                    controller: _passwordController,
                    isPassword: true,
                    validator: (value) => value!.length < 6 ? "Password must be at least 6 characters" : null,
                  ),

                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: "Sign Up",
                    isLoading: _isLoading,
                    onPressed: _handleSignup,
                  ),
                  const SizedBox(height: 24),

                  // Navigation back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Log In",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}