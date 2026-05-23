import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:motorshop/features/auth/screens/login_screen.dart';
import 'firebase_options.dart';
import 'features/auth/screens/signup_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart'; // Make sure you have this to use your colors

void main() async {
  // 1. This must be called first so Flutter can talk to native code (like Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Wait for Firebase to fully start before running the app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Now it is safe to run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      title: 'Motor Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark, // Tells Flutter this is a dark theme
      ),
      useMaterial3: true,

      // This instantly applies the 'Inter' font to every text widget in your app
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme, // Base it on the dark theme defaults
      ).apply(
        bodyColor: AppColors.textPrimary,      // Default text color
        displayColor: AppColors.textPrimary,   // Default header color
      ),
    ),
      // Set the initial screen to your new Signup Screen
      home: const LoginScreen(),
    );
  }
}