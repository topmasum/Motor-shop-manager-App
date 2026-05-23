import 'package:flutter/material.dart';
import 'app_colors.dart';

class TextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, // Will use white
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary, // Will use light grey
  );
}