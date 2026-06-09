import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; // --- ADDED FOR EMAILJS ---
import 'dart:convert'; // --- ADDED FOR EMAILJS ---
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/shop_session.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Staff';
  bool _isLoading = false;

  // --- THE EMAILJS ENGINE ---
  Future<void> _sendEmailJS(String email, String name, String password, String role) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'service_id': 'service_i01rvwf', // Double check these!
        'template_id': 'template_7fhj00b',
        'user_id': 'sMXCDjJ6zBrN4CyE8',
        'template_params': {
          'staff_name': name,
          'staff_email': email,
          'staff_password': password,
          'staff_role': role,
          'shop_name': 'Motor Shop',
        }
      }),
    );

    // --- ADDED THIS SAFETY SHIELD ---
    if (response.statusCode != 200) {
      // This will force the app to show the exact error in your red SnackBar!
      throw Exception("Email Delivery Failed: ${response.body}");
    }
  }

  Future<void> _inviteUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    FirebaseApp? tempApp; // Declare it up here so we can access it in the 'finally' block

    try {
      // 1. SAFELY INITIALIZE THE TEMP APP
      // First, check if a ghost session from a previous error still exists
      try {
        tempApp = Firebase.app('TemporaryRegisterApp');
      } catch (e) {
        // If it doesn't exist, create it cleanly
        tempApp = await Firebase.initializeApp(
          name: 'TemporaryRegisterApp',
          options: Firebase.app().options,
        );
      }

      // 2. Register the new user
      UserCredential newStaffCred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Save to database
      await FirebaseFirestore.instance.collection('users').doc(newStaffCred.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'shopId': ShopSession.currentShopId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        CustomSnackbar.showSuccess(context, "User created successfully! Sending invite...");

        // 4. Trigger EmailJS
        await _sendEmailJS(
          _emailController.text.trim(),
          _nameController.text.trim(),
          _passwordController.text.trim(),
          _selectedRole,
        );

        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase errors (like email-already-in-use)
      if (mounted) CustomSnackbar.showError(context, "Auth Error: ${e.message}");
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, "Error: ${e.toString()}");
    } finally {
      // --- BULLETPROOF CLEANUP ---
      // This runs NO MATTER WHAT. It guarantees the ghost session is destroyed.
      if (tempApp != null) {
        await tempApp.delete();
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Invite to Shop", style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Create an account for your staff. They will use this email and password to log in to your shop's inventory.", style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),

              CustomTextField(
                label: "Staff Name",
                hint: "John Doe",
                icon: Icons.person,
                controller: _nameController,
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              CustomTextField(
                label: "Email Address",
                hint: "john@motorshop.com",
                icon: Icons.email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty || !val.contains('@') ? "Valid email required" : null,
              ),
              CustomTextField(
                label: "Temporary Password",
                hint: "At least 6 characters",
                icon: Icons.lock,
                controller: _passwordController,
                validator: (val) => val!.length < 6 ? "Minimum 6 characters" : null,
              ),
              const SizedBox(height: 16),

              // Role Selector
              const Text("Access Level", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    dropdownColor: AppColors.surface,
                    isExpanded: true,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    items: ['Staff', 'Manager', 'Co-Owner'].map((String role) {
                      return DropdownMenuItem<String>(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: "Create Account & Send Invite",
                isLoading: _isLoading,
                onPressed: _inviteUser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}