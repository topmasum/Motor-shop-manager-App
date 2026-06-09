import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream (to check if someone is logged in)
  Stream<User?> get userStream => _auth.authStateChanges();

  // Sign Up (This remains the same for the original Shop Owner)
  Future<String?> signUp({
    required String email,
    required String password,
    required String shopName
  }) async {
    try {
      // 1. Create the user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        // 2. Send Email Verification (Only applies to the Owner now)
        await user.sendEmailVerification();

        // 3. Save the extra details (like shop name) to Firestore
        ShopUserModel newShop = ShopUserModel(
          uid: user.uid,
          email: email,
          shopName: shopName,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('shops').doc(user.uid).set(newShop.toMap());

        return "Success! Please check your email to verify your account.";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
    return null;
  }

  // Login
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword( // Removed 'UserCredential credential =' since we don't need it below anymore
        email: email,
        password: password,
      );

      // --- THE FIX: REMOVED EMAIL VERIFICATION BLOCKER ---
      // Since staff are manually invited by the Owner via EmailJS,
      // their emails are already trusted. We bypass this check!

      // if (!credential.user!.emailVerified) {
      //   return "Please verify your email address before logging in.";
      // }

      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // Reset Password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}