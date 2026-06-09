import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart'; // Make sure this path matches your project!

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    // The Shimmer widget creates the sweeping light effect over whatever is inside it
    return Shimmer.fromColors(
      baseColor: AppColors.surface, // The dark background of the card
      highlightColor: Colors.grey[700]!, // The lighter sweeping "shine"
      child: Card(
        color: AppColors.surface,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // Dummy Avatar
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
          ),
          // Dummy Title (Name)
          title: Container(
            height: 16,
            width: double.infinity,
            color: Colors.white,
          ),
          // Dummy Subtitle (Email & Badge)
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(height: 12, width: 150, color: Colors.white),
              const SizedBox(height: 8),
              Container(
                height: 20,
                width: 60,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}