import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Modern blue palette
  static const primary = Color(0xFF1976D2);        // Primary blue
  static const primaryLight = Color(0xFF42A5F5);   // Light blue
  static const primaryDark = Color(0xFF1565C0);    // Dark blue
  
  // Secondary colors
  static const secondary = Color(0xFF00ACC1);      // Cyan
  static const success = Color(0xFF4CAF50);        // Green
  static const warning = Color(0xFFFF9800);        // Orange
  static const danger = Color(0xFFE53935);         // Red
  
  // Light theme colors
  static const background = Color(0xFFF5F7FA);     // Light grey background
  static const cardBg = Color(0xFFFFFFFF);         // White card background
  static const surface = Color(0xFFF8F9FA);        // Light surface color
  static const divider = Color(0xFFE0E0E0);        // Divider color
  
  // Text colors for light theme
  static const textPrimary = Color(0xFF212121);    // Dark text
  static const textSecondary = Color(0xFF757575);  // Medium grey text
  static const textHint = Color(0xFF9E9E9E);       // Hint text
  
  // Legacy support (mapped to light theme)
  static const dark = textPrimary;
  static const light = textPrimary;
}
  
