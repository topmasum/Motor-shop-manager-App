import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../stock/services/stock_repository.dart';

class DailyAnalyticsCards extends StatelessWidget {
  DailyAnalyticsCards({super.key});

  final StockRepository _stockRepo = StockRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      // This listens to the live stream we built in the repository!
      stream: _stockRepo.getTodayMetrics(),
      builder: (context, snapshot) {

        // Default to zero if loading or no sales yet
        double revenue = 0.0;
        double profit = 0.0; // --- ADDED PROFIT ---
        int itemsSold = 0;

        if (snapshot.hasData) {
          revenue = snapshot.data!['revenue'] ?? 0.0;
          profit = snapshot.data!['profit'] ?? 0.0; // --- EXTRACTED PROFIT ---
          itemsSold = snapshot.data!['itemsSold'] ?? 0;
        }

        // We wrap everything in a Column so we can stack the rows perfectly
        return Column(
          children: [
            Row(
              children: [
                // --- REVENUE CARD (Sleek Blue) ---
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF0D47A1)], // Deep Blue
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.point_of_sale, color: Colors.white70, size: 28),
                        const SizedBox(height: 12),
                        const Text("Today's Revenue", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("\$${revenue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // --- NET PROFIT CARD (Your Money Green!) ---
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white70, size: 28),
                        const SizedBox(height: 12),
                        const Text("Net Profit", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text("\$${profit.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- ITEMS SOLD CARD (Full Width Bottom) ---
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.build_circle, color: AppColors.accent, size: 28),
                    const SizedBox(height: 12),
                    const Text("Parts Sold Today", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("$itemsSold", style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}