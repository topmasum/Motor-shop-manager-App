import 'package:flutter/material.dart';
import 'package:motorshop/features/sales_history/screens/history_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/shop_session.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../pos/screens/point_of_sale_screen.dart';
import '../../staff/screens/add_staff_screen.dart';
import '../../staff/screens/staff_list_screen.dart';
import '../../stock/screens/add_product_screen.dart';
import '../../stock/screens/low_stock_screen.dart';
import '../../stock/screens/stock_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/weekly_revenue_chart.dart';
// --- ADDED YOUR NEW ANALYTICS WIDGET IMPORT ---
import '../widgets/daily_analytics_cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
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
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              title: const Text('Low Stock Alerts', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => LowStockScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_toggle_off_outlined, color: AppColors.textSecondary),
              title: const Text('Sales History', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
              },
            ),

            ListTile(
              leading: const Icon(Icons.point_of_sale, color: AppColors.textSecondary),
              title: const Text('Make a Sale', style: TextStyle(color: AppColors.textSecondary)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
              },
            ),
            if (['owner', 'co-owner', 'manager'].contains(ShopSession.currentUserRole?.trim().toLowerCase()))
              ListTile(
                leading: const Icon(Icons.people_alt, color: Colors.blueAccent),
                title: const Text('Manage Team', style: TextStyle(color: Colors.blueAccent)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StaffListScreen()));
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

              // Dynamic Shop Name
              // Dynamic Shop Name
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('shops')
                    .doc(ShopSession.currentShopId) // --- CHANGED THIS LINE ---
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      "Loading...",
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                    );
                  }

                  if (snapshot.hasData && snapshot.data!.exists) {
                    String shopName = snapshot.data!.get('shopName') ?? 'Shop Owner';
                    return Text(
                      shopName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                    );
                  }

                  return const Text(
                    "Motor Shop", // Better fallback name!
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(height: 24),

              // --- REPLACED THE OLD CARDS WITH YOUR LIVE ANALYTICS ---
              DailyAnalyticsCards(),
              // -------------------------------------------------------

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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                },
              ),
              const SizedBox(height: 12),
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

              // 7-Day Chart
              const Text(
                "Last 7 Days",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              WeeklyRevenueChart(),
            ],
          ),
        ),
      ),
    );
  }
}