import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/shop_session.dart';
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

        if (snapshot.hasData && snapshot.data != null) {
          // --- THE MULTI-USER UPGRADE ---
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnapshot) {

              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppColors.background,
                  body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                );
              }

              if (userSnapshot.hasError) {
                return Scaffold(body: Center(child: Text('Error: ${userSnapshot.error}')));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                // --- THE CRASH FIX: Safe Map Extraction ---
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;

                // 1. Restore the Shop ID safely
                ShopSession.currentShopId = userData['shopId'] ?? snapshot.data!.uid;

                // 2. --- THE DRAWER FIX: RESTORE USER ROLE ---
                // We uncommented this line so your role is loaded from the database on refresh!
                ShopSession.currentUserRole = userData['role'] ?? 'Owner';

              } else {
                // LEGACY FALLBACK: If the original owner logs in, use their UID
                ShopSession.currentShopId = snapshot.data!.uid;
                ShopSession.currentUserRole = 'Owner'; // Legacy accounts default to Owner
              }

              return const HomeScreen(); // Now we are 100% safe to load the dashboard!
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}