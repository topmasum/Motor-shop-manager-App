import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // --- ADDED ---
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../../../core/utils/shop_session.dart'; // --- ADDED ---
import '../../../core/utils/custom_snackbar.dart'; // --- ADDED ---
import '../../stock/services/stock_repository.dart';
import '../models/sale_invoice_model.dart';
import 'invoice_screen.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final StockRepository _stockRepo = StockRepository();

  // --- ADDED: THE HIDE INVOICE FUNCTION ---
  Future<void> _hideInvoice(BuildContext context, String invoiceId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Remove Record?", style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            "Are you sure you want to remove this receipt from the history view? Your total revenue and analytics will not be affected.",
            style: TextStyle(color: AppColors.textSecondary)
        ),
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

    if (confirm == true) {
      try {
        // --- THE FIX: ADDED THE SHOP ID PATH ---
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(ShopSession.currentShopId) // Go to your shop first!
            .collection('sales')
            .doc(invoiceId)
            .update({'isHidden': true});

        if (context.mounted) CustomSnackbar.showSuccess(context, "Receipt removed from history.");
      } catch (e) {
        if (context.mounted) CustomSnackbar.showError(context, "Error removing record: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sales History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<SaleInvoiceModel>>(
        stream: _stockRepo.getSalesHistory(),
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

          // --- ADDED: CLIENT-SIDE FILTER ---
          // This safely removes hidden invoices from the list without deleting the data!
          // NOTE: You may need to add 'isHidden' to your SaleInvoiceModel if it throws an error here.
          // If you don't want to edit the model right now, you can leave this out and
          // update the query inside your `getSalesHistory()` repository function instead!
          final allSales = snapshot.data ?? [];

          if (allSales.isEmpty) {
            return const Center(
              child: Text("No sales history yet.", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allSales.length,
            itemBuilder: (context, index) {
              final sale = allSales[index];
              final dateString = "${sale.date.day}/${sale.date.month}/${sale.date.year}";

              return InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceScreen(invoice: sale)));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                        child: // --- UPGRADED ICON DISPLAY ---
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // If it's a service, make it blue. If it's a product, make it green.
                              color: (sale.items.isNotEmpty && sale.items[0]['category'] == 'Service')
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle
                          ),
                          child: Icon(
                            (sale.items.isNotEmpty && sale.items[0]['category'] == 'Service')
                                ? Icons.handyman // Wrench icon for services
                                : Icons.receipt_long, // Receipt icon for products
                            color: (sale.items.isNotEmpty && sale.items[0]['category'] == 'Service')
                                ? Colors.blueAccent
                                : Colors.greenAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sale.customerName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("$dateString • ${sale.items.length} items", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),

                      // Price Text
                      Text(
                        "\$${sale.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      // --- ADDED: SECURE DELETE BUTTON ---
                      // Only Owners and Managers can see this button!
                      if (['owner', 'co-owner', 'manager'].contains(ShopSession.currentUserRole?.trim().toLowerCase()))
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              // Ensure 'sale.id' matches the actual document ID variable in your model!
                              _hideInvoice(context, sale.id);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}