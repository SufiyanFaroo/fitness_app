// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/app/ui/auth/app_strings.dart';
import 'package:fitness_app/data/services/auth_service.dart';
import 'package:fitness_app/app/ui/auth/welcome_screen.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/widgets/custom_button.dart';
//import 'package:fitness_app/utils/app_assets.dart';
//import 'package:fitness_app/utils/theme_provider.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/widgets.dart' hide State;
//import 'package:fitness_app/commons/custom_button.dart';
import 'package:provider/provider.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  final AuthService _authService = AuthService(); // Instance call
  int _currentPage = 0;
  bool _isLoading = false;

  final List<Map<String, String>> goalData = [
    {
      "image": AppAssets.Goal_Improve_Shape,
      "title": AppStrings.improveShape,
      "desc":
          "I have a low amount of body fat and need / want to build more muscle",
    },
    {
      "image": AppAssets.Goal_Lean_Tone,
      "title": AppStrings.leanTone,
      "desc":
          "I’m “skinny fat”. look thin but have no shape. I want to add lean muscle in the right way",
    },
    {
      "image": AppAssets.Goal_Lose_Fat,
      "title": AppStrings.loseFat,
      "desc":
          "I have over 20 lbs to lose. I want to drop all this fat and gain muscle mass",
    },
  ];

  // --- Logic via AuthService (UI mehfooz hai) ---
  Future<void> _saveGoal() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in";

      // Service se data save karwa rahe hain
      await _authService.saveUserGoal(
        uid: user.uid,
        goalTitle: goalData[_currentPage]["title"]!,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              AppStrings.goalTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                AppStrings.goalSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: goalData.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildGoalCard(index),
              ),
            ),

            _buildDotsIndicator(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: CustomButton(
                text: "Confirm",
                onPressed: _saveGoal,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(int index) {
    // --- 🔥 3D Scaling Logic ---
    // Isse active card bada dikhega aur side wale chhote
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
        } else {
          // Initial state (Jab page load ho raha ho)
          value = index == 0 ? 1.0 : 0.8;
        }

        return Center(
          child: SizedBox(
            height: Curves.easeOut.transform(value) * 500, // Dynamic Height
            width: Curves.easeOut.transform(value) * 350, // Dynamic Width
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF92A3FD),
              Color(0xFFD49AFA),
            ], // Reverted for better look
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF92A3FD).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Image.asset(
                goalData[index]["image"]!,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              goalData[index]["title"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            // Divider Line
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 1.5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Description
            Expanded(
              flex: 1,
              child: Text(
                goalData[index]["desc"]!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(goalData.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 20 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF92A3FD)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
