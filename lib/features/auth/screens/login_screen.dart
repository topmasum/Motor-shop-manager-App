import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/shop_session.dart';
import '../../home/screens/home_screen.dart';
import '../services/auth_service.dart';
import 'forget_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- THE SESSION & ROLE LOCK ---
      if (result == "Success") {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            ShopSession.currentShopId = userDoc.get('shopId');

            // --- NEW: GRAB THEIR ROLE ---
            ShopSession.currentUserRole = userDoc.get('role');
          } else {
            ShopSession.currentShopId = user.uid;

            // --- NEW: ORIGINAL USERS ARE OWNERS ---
            ShopSession.currentUserRole = 'Owner';
          }
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        if (result == "Success") {
          CustomSnackbar.showSuccess(context, "Login successful!");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
          );
        } else {
          CustomSnackbar.showError(context, result ?? 'An error occurred');
        }
      }
    }
  }

  @override
  void dispose() {
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
                  Center(
                    child: Icon(Icons.two_wheeler, size: 80, color: AppColors.primary),
                  ),
                  const SizedBox(height: 32),

                  const Text("Welcome Back", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  const Text("Log in to manage your motor shop.", style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 32),

                  CustomTextField(
                    label: "Email Address", hint: "shop@example.com", icon: Icons.email,
                    controller: _emailController, keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? "Please enter your email" : null,
                  ),
                  CustomTextField(
                    label: "Password", hint: "Enter your password", icon: Icons.lock,
                    controller: _passwordController, isPassword: true,
                    validator: (value) => value!.isEmpty ? "Please enter your password" : null,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                      },
                      child: const Text("Forgot Password?", style: TextStyle(color: AppColors.accent)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  PrimaryButton(text: "Log In", isLoading: _isLoading, onPressed: _handleLogin),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                        },
                        child: const Text("Sign Up", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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