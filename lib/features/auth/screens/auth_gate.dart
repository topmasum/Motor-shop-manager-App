import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // --- ADDED ---
import '../../../core/utils/shop_session.dart'; // --- ADDED ---
import 'login_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../../core/constants/app_colors.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        if (snapshot.hasData) {
          // --- THE MULTI-USER UPGRADE ---
          // Before going to the Dashboard, we MUST load the Master Shop ID!
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppColors.background,
                  body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                // Lock the session for the new multi-user staff!
                ShopSession.currentShopId = userSnapshot.data!.get('shopId');
              } else {
                // LEGACY FALLBACK: If the original owner logs in, use their UID
                ShopSession.currentShopId = snapshot.data!.uid;
              }

              return const HomeScreen(); // Now we are safe to load the dashboard!
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}