import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../stock/screens/add_product_screen.dart';
import '../../stock/screens/stock_dashboard_screen.dart';
import '../widgets/sales_summary_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.background),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.two_wheeler, size: 48, color: AppColors.accent),
                  SizedBox(height: 12),
                  Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppColors.textPrimary),
              title: const Text('Dashboard', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: AppColors.textSecondary),
              title: const Text('Stock & Inventory', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {
                // Instantly pop the drawer and navigate to Stock Screen
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale, color: AppColors.textSecondary),
              title: const Text('Make a Sale', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {
                // TODO: Navigate to POS Screen
              },
            ),
            const Divider(color: AppColors.textSecondary, thickness: 0.2),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              const Text(
                "Welcome back,",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),

              // --- NEW DYNAMIC SHOP NAME CODE ---
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('shops')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .get(),
                builder: (context, snapshot) {
                  // While waiting for Firebase to respond
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      "Loading...",
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                    );
                  }

                  // If we successfully get the data
                  if (snapshot.hasData && snapshot.data!.exists) {
                    // Extract the shopName from the Firestore document
                    String shopName = snapshot.data!.get('shopName') ?? 'Shop Owner';
                    return Text(
                      shopName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                    );
                  }

                  // Fallback just in case something goes wrong
                  return const Text(
                    "Shop Owner",
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                  );
                },
              ),
              // -----------------------------------
              const SizedBox(height: 24),

              // Summary Cards Row
              const Row(
                children: [
                  SalesSummaryCard(
                    title: "Today's Sales",
                    value: "\$0.00",
                    icon: Icons.attach_money,
                    iconColor: Colors.greenAccent,
                  ),
                  SizedBox(width: 16),
                  SalesSummaryCard(
                    title: "Low Stock",
                    value: "0 Items",
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.orangeAccent,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions
              const Text(
                "Quick Actions",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: "New Sale",
                onPressed: () {
                  // TODO: Go to POS Screen
                },
              ),
              const SizedBox(height: 12),
              // A secondary outline button for adding stock
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
                  },
                  icon: const Icon(Icons.add_box, color: AppColors.textPrimary),
                  label: const Text("Add New Product", style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),

                ),
              ),
              const SizedBox(height: 32),

              // Placeholder for the 7-Day Chart
              const Text(
                "Last 7 Days",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    "Chart will be displayed here",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}