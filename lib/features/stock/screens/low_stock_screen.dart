import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/product_model.dart';
import '../services/stock_repository.dart';
import 'edit_product_screen.dart';

class LowStockScreen extends StatelessWidget {
  LowStockScreen({super.key});

  final StockRepository _stockRepo = StockRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Low Stock Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _stockRepo.getLowStockProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final lowStockItems = snapshot.data ?? [];

          if (lowStockItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
                  SizedBox(height: 16),
                  Text("Inventory is looking good!", style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                  Text("No low stock items right now.", style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lowStockItems.length,
            itemBuilder: (context, index) {
              final product = lowStockItems[index];
              final isCompletelyOut = product.quantity == 0;

              return InkWell(
                onTap: () {
                  // Let them tap it to quickly go to the edit screen and update the quantity when a shipment arrives
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProductScreen(product: product)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompletelyOut ? Colors.redAccent.withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCompletelyOut ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompletelyOut ? Icons.error_outline : Icons.warning_amber_rounded,
                          color: isCompletelyOut ? Colors.redAccent : Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("${product.categoryName} • ${product.productModel}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isCompletelyOut ? "SOLD OUT" : "Only ${product.quantity} left",
                            style: TextStyle(
                              color: isCompletelyOut ? Colors.redAccent : Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text("Tap to restock", style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        ],
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