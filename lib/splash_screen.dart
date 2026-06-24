import 'package:flutter/material.dart';
import 'dart:async';
import 'features/auth/screens/auth_gate.dart'; // --- IMPORT YOUR AUTH GATE ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startLoadingHandoff();
  }

  void _startLoadingHandoff() async {
    // 1. Show the logo and spinner for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // 2. Hand off to the AuthGate to handle Login vs Dashboard!
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure this HEX code perfectly matches the 'color' in your pubspec.yaml
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your perfectly sized Flutter logo
            Image.asset(
              'assets/images/icon2.png',
              width: 150,
            ),

            const SizedBox(height: 40),

            // The loading spinner
            const CircularProgressIndicator(
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}