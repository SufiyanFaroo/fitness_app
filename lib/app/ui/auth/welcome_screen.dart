// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/services/auth_service.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/widgets/custom_button.dart';
import 'package:fitness_app/view/main_tab/main_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:fitness_app/commons/custom_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService(); // Instance call
  String userName = "";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // --- Service ke zariye Name fetch karne ka logic ---
  // --- Optimized Name Fetching ---
  Future<void> _fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Pehle Firebase Auth se direct name check karein (Fastest)
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          if (mounted) setState(() => userName = user.displayName!);
        }

        // 2. Phir Firestore se fetch karein (Final Confirmation)
        final userData = await _authService.getUserData(user.uid);
        if (userData != null && mounted) {
          setState(() {
            userName = userData['full_name'] ?? userData['name'] ?? "User";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching name: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  AppAssets.Welcome_Stefani,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              // Welcome Text Widget
              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: userName.isEmpty
                    ? 0.0
                    : 1.0, // Jab naam load ho jaye tab show karein
                child: Text(
                  'Welcome, $userName',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'You are all set now, let’s reach your goals together with us',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),

              CustomButton(
                text: 'Go To Home',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainTabView(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
