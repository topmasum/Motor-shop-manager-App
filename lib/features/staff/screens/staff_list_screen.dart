import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/custom_snackbar.dart';
import '../../../core/utils/shop_session.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_card.dart';
import 'add_staff_screen.dart';

class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key});

  Future<void> _removeStaff(BuildContext context, String userId, String staffName) async {
    // 1. Show Confirmation Dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Remove Staff?", style: TextStyle(color: AppColors.textPrimary)),
        content: Text("Are you sure you want to remove $staffName? They will immediately lose access to the shop.", style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // 2. Hide in Database if confirmed
    if (confirm == true) {
      try {
        // --- ADDED: THE SOFT DELETE FIX ---
        // Instead of permanently deleting, we just flag them as inactive
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'status': 'inactive'
        });

        if (context.mounted) CustomSnackbar.showSuccess(context, "$staffName removed successfully.");
      } catch (e) {
        if (context.mounted) CustomSnackbar.showError(context, "Error removing staff: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check
    if (ShopSession.currentShopId == null) {
      return const Scaffold(body: Center(child: Text("Error: No Shop ID found")));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Team', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add, color: AppColors.textPrimary),
        label: const Text("Add Staff", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStaffScreen()));
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to all users who share this specific shop ID
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('shopId', isEqualTo: ShopSession.currentShopId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) {
                return const SkeletonCard();
              },
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final allDocs = snapshot.data?.docs ?? [];

          // --- ADDED: THE CLIENT-SIDE ACTIVE FILTER ---
          // This avoids the need for a new Firebase index and prevents older
          // test accounts from disappearing because they lack the 'status' field.
          final staffDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'active'; // Default older accounts to active
            return status == 'active';
          }).toList();

          if (staffDocs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.group_add_outlined,
              title: "No Team Members Yet",
              message: "It looks a little quiet here. Add your staff so they can start managing the inventory and making sales!",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffDocs.length,
            itemBuilder: (context, index) {
              final staff = staffDocs[index].data() as Map<String, dynamic>;
              final docId = staffDocs[index].id;

              final name = staff['name'] ?? 'Unknown';
              final email = staff['email'] ?? 'No email';
              final role = staff['role'] ?? 'Staff';

              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: role == 'Manager' ? Colors.purple.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                            role,
                            style: TextStyle(
                                color: role == 'Manager' ? Colors.purpleAccent : Colors.blueAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ),
                    ],
                  ),
                  trailing: role != 'Owner'
                      ? IconButton(
                    icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                    onPressed: () => _removeStaff(context, docId, name),
                  )
                      : const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}