import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        'service_id': dotenv.env['EMAILJS_SERVICE_ID'],
        'template_id': dotenv.env['EMAILJS_TEMPLATE_ID'],
        'user_id': dotenv.env['EMAILJS_PUBLIC_KEY'],
        'template_params': {
          'staff_name': name,
          'staff_email': email,
          'staff_password': password,
          'staff_role': role,
          'shop_name': 'Motor Shop',
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Email Delivery Failed: ${response.body}");
    }
  }

  Future<void> _inviteUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Get your project's Web API Key automatically from your existing setup
      final apiKey = Firebase.app().options.apiKey;

      // 2. THE BYPASS: Make a direct HTTP request to Google's Auth Servers
      final authUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');

      final response = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'returnSecureToken': false, // Ensures it doesn't log the new user in on your device!
        }),
      );

      final responseData = json.decode(response.body);

      // 3. Handle Firebase Auth Errors directly from the HTTP response
      if (response.statusCode != 200) {
        final errorMessage = responseData['error']['message'] ?? 'Unknown Error';

        if (errorMessage == 'EMAIL_EXISTS') {
          // --- THE SOFT DELETE REACTIVATION FIX ---
          var existingUsers = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: _emailController.text.trim())
              .get();

          if (existingUsers.docs.isNotEmpty) {
            var userId = existingUsers.docs.first.id;
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'name': _nameController.text.trim(),
              'role': _selectedRole,
              'status': 'active', // Bring them back to life
            });

            if (mounted) {
              CustomSnackbar.showSuccess(context, "User reactivated! Sending email invite...");
              await _sendEmailJS(
                _emailController.text.trim(),
                _nameController.text.trim(),
                _passwordController.text.trim(),
                _selectedRole,
              );
              Navigator.pop(context);
            }
          } else {
            if (mounted) CustomSnackbar.showError(context, "Email registered but not in your database.");
          }
          return; // Stop execution here since we successfully reactivated them
        } else {
          // If it's a different error (like WEAK_PASSWORD or INVALID_EMAIL)
          throw Exception("Auth Error: $errorMessage");
        }
      }

      // 4. If successful, grab the new user's unique ID from the payload
      final newUid = responseData['localId'];

      // 5. Save their profile to your Firestore database using that new UID
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'shopId': ShopSession.currentShopId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        CustomSnackbar.showSuccess(context, "User created successfully! Sending invite...");

        // 6. Trigger EmailJS
        await _sendEmailJS(
          _emailController.text.trim(),
          _nameController.text.trim(),
          _passwordController.text.trim(),
          _selectedRole,
        );

        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, "Error: ${e.toString()}");
    } finally {
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