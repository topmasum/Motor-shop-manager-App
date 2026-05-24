import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../../core/constants/app_colors.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // This stream instantly checks if Firebase has a saved login token on the device
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // While it's checking, show a quick loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        // If it found a valid logged-in user, send them straight to the Dashboard!
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Otherwise, send them to the Login Screen
        return const LoginScreen();
      },
    );
  }
}