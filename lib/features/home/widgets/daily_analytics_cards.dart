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
        int itemsSold = 0;

        if (snapshot.hasData) {
          revenue = snapshot.data!['revenue'] ?? 0.0;
          itemsSold = snapshot.data!['itemsSold'] ?? 0;
        }

        return Row(
          children: [
            // --- REVENUE CARD ---
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)], // Sleek Money Green
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
                    const Icon(Icons.attach_money, color: Colors.white70, size: 28),
                    const SizedBox(height: 12),
                    const Text("Today's Revenue", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("\$${revenue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // --- ITEMS SOLD CARD ---
            Expanded(
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