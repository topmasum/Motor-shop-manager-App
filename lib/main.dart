import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// --- ADDED FOR OFFLINE PERSISTENCE ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motorshop/features/auth/screens/login_screen.dart';
import 'features/auth/screens/auth_gate.dart';
import 'firebase_options.dart';
import 'features/auth/screens/signup_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';

void main() async {
  // 1. This must be called first so Flutter can talk to native code (like Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Wait for Firebase to fully start before running the app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- 3. ENABLE FIREBASE OFFLINE PERSISTENCE ---
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Turns on the offline cache and queue
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Store unlimited offline data
  );

  // 4. Now it is safe to run the app
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

        // Instantly applies the 'Poppins' font to every text widget in your app
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),
      // The AuthGate intelligently routes the user based on login state
      home: const AuthGate(),
    );
  }
}