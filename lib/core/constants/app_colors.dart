import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryActive = Color(0xFF1AD2A4);
  // --- Brand Primary Colors & Gradients ---
  static const Color primaryColor1 = Color(0xFF92A3FD); // Blue Light
  static const Color primaryColor2 = Color(0xFF9DCEFF); // Blue Dark

  static const Color secondaryColor1 = Color(0xFFC58BF2); // Purple Light
  static const Color secondaryColor2 = Color(0xFFEEA4CE); // Pink/Purple Dark

  static const List<Color> primaryG = [primaryColor1, primaryColor2];
  static const List<Color> secondaryG = [secondaryColor1, secondaryColor2];

  // --- UI Specific Colors ---
  static const Color primaryNeon = Color(0xFFD0FD3E);
  static const Color progressPurple = Color(0xFF6B50F6);
  static const Color cyan = Color(0xFF00FAD9);

  // --- Backgrounds & Surface ---
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color lightBackground = Colors.white;
  static const Color cardGrey = Color(0xFF2C2C2E);
  static const Color borderColor = Color(0xFFF7F8F8);

  // --- Neutral Colors ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1D1617);
  static const Color grey = Color(0xFF7B6F72);
  static const Color lightGrey = Color(0xFFF7F8F8);
  static const Color greyText = Color(0xFFADA4A5);

  // --- Helper Gradients ---
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: primaryG,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get secondaryGradient => const LinearGradient(
    colors: secondaryG,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  //static Color get secondaryPurple => null;
}

class AppStyles {
  // Title Style: Dynamic for Light/Dark Mode
  static TextStyle getTitleStyle(bool isDark) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.white : AppColors.black,
    );
  }

  // Description Style: Dynamic for Light/Dark Mode
  static TextStyle getDescStyle(bool isDark) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: isDark ? Colors.white70 : AppColors.grey,
    );
  }

  // Standard Styles (For static contexts)
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle descStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
  );
}
