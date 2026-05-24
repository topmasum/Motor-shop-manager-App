import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../stock/services/stock_repository.dart';

class WeeklyRevenueChart extends StatelessWidget {
  WeeklyRevenueChart({super.key});

  final StockRepository _stockRepo = StockRepository();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: StreamBuilder<List<double>>(
        stream: _stockRepo.getWeeklySales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final weeklyData = snapshot.data ?? List.filled(7, 0.0);

          // Find the highest sales day to scale the chart dynamically
          double maxSales = weeklyData.reduce((a, b) => a > b ? a : b);
          if (maxSales == 0) maxSales = 100; // Default height if no sales exist yet

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 10, bottom: 20),
                child: Text("Last 7 Days Revenue", style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false), // Hides messy background grid
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      // Y-Axis (Money)
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text('\$${value.toInt()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10));
                          },
                        ),
                      ),
                      // X-Axis (Days)
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['6d', '5d', '4d', '3d', '2d', '1d', 'Today'];
                            if (value.toInt() >= 0 && value.toInt() < 7) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(days[value.toInt()], style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: maxSales * 1.2, // Gives the chart a little breathing room at the top
                    lineBarsData: [
                      LineChartBarData(
                        spots: weeklyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true, // Smooth swooping line
                        color: Colors.greenAccent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false), // Hides the dots on the line
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.greenAccent.withOpacity(0.15), // Beautiful glowing gradient underneath
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}