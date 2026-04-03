import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart'; // ThemeProvider import karein

class CircularNextButton extends StatelessWidget {
  final double percentage;
  final VoidCallback onPressed;

  const CircularNextButton({
    super.key,
    required this.percentage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // --- Dark Mode Logic ---
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Outer Progress Circle
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 2,
              // Dark mode mein background color white12 rakha hai taake dark par visible rahe
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFCC8FED),
              ),
            ),
          ),
          // 2. Inner Solid Button (Gradient remains same for both modes)
          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6B50F6), Color(0xFFCC8FED)],
              ),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
