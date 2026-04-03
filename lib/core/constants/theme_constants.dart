import 'package:flutter/material.dart';

class AppColors {
  // --- Core Colors (Figma Design) ---
  static const Color primaryNeon = Color(0xFFD0FD3E); // Your Neon Green
  static const Color primaryBlue = Color(0xFF92A3FD); // Standard Fitness Blue
  static const Color secondaryPurple = Color(0xFFC58BF2); // Figma Purple

  // --- Backgrounds ---
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color lightBackground = Colors.white;
  static const Color white = Colors.white;

  // --- Cards & Components ---
  static const Color cardGrey = Color(0xFF2C2C2E);
  static const Color borderColor = Color(0xFFF7F8F8);
  static const Color gray = Colors.grey;

  // --- Progress & Gradients ---
  static const Color progressPurple = Color(0xFFEEA4CE);
  static Color bgPurpleLight = const Color(0xFF92A3FD).withValues(alpha: 0.1);
}

class AppStyles {
  // Title Style: Dark mode mein color change karne ke liye hum isse static method banayenge
  static TextStyle getTitleStyle(bool isDark) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
    );
  }

  // Description Style
  static TextStyle getDescStyle(bool isDark) {
    return TextStyle(
      fontSize: 14,
      color: isDark ? Colors.white70 : Colors.grey,
      fontWeight: FontWeight.normal,
    );
  }

  // Purane constants (compatibility ke liye)
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle descStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
    fontWeight: FontWeight.normal,
  );
}
