import 'package:fitness_app/data/services/auth_service.dart';
import 'package:fitness_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'dart:async';

//import 'package:path/path.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService(); // Service instance

  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  // Auto-navigation logic via AuthService
  Future<void> _checkNavigation() async {
    // 3 seconds ka wait taake logo nazar aaye
    await Future.delayed(const Duration(seconds: 3));

    // Service se states fetch kiye
    final states = await _authService.getInitialState();

    bool isLoggedIn = states['isLoggedIn']!;
    bool isFirstTime = states['isFirstTime']!;
    bool isProfileComplete = states['isProfileComplete']!;

    if (mounted) {
      String nextRoute;

      // Priority Check Logic - Using AppRoutes
      if (isLoggedIn) {
        nextRoute = isProfileComplete
            ? AppRoutes.mainTab
            : AppRoutes.profileCompletion;
      } else if (isFirstTime) {
        nextRoute = AppRoutes.onboarding;
      } else {
        nextRoute = AppRoutes.login;
      }

      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFE26BFF), Color(0xFF9E58FF)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Colors.black, Colors.white],
                    stops: [0.6, 0.9],
                  ).createShader(bounds),
                  child: const Text(
                    "FITQUEST",
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Everybody Can Train",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
