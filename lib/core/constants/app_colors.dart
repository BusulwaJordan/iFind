import 'package:flutter/material.dart';

/// App-wide color constants
/// Green & White palette - no gradients
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryGreen = Color(0xFF10B981); // Emerald Green
  static const Color darkGreen = Color(0xFF065F46); // Deep Forest Green
  static const Color secondaryGreen = Color(0xFF047857);
  static const Color deepGreen = Color(0xFF064E3B);
  static const Color lightGreen = Color(0xFFD1FAE5);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color darkText = Color(0xFF212121);
  static const Color lightText = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);
  
  // Semantic Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF0288D1);
  
  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  
  // Glassmorphism Colors
  static Color glassBackground = white.withValues(alpha: 0.2);
  static Color glassBorder = white.withValues(alpha: 0.3);
  static Color glassOverlay = white.withValues(alpha: 0.1);
}
