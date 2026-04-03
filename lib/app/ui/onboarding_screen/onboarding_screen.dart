import 'package:fitness_app/app/ui/auth/app_strings.dart';
import 'package:fitness_app/app/ui/auth/login_screen.dart';
import 'package:fitness_app/data/services/auth_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/widgets/circular_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Service instance initialize kiya
  final AuthService _authService = AuthService();

  final List<Map<String, String>> onboardingData = [
    {
      "title": AppStrings.onboardTitle1,
      "desc": AppStrings.onboardDesc1,
      "image": AppAssets.Onboarding_track,
    },
    {
      "title": AppStrings.onboardTitle2,
      "desc": AppStrings.onboardDesc2,
      "image": AppAssets.Onboarding_Get,
    },
    {
      "title": AppStrings.onboardTitle3,
      "desc": AppStrings.onboardDesc3,
      "image": AppAssets.Onboarding_Eat,
    },
    {
      "title": AppStrings.onboardTitle4,
      "desc": AppStrings.onboardDesc4,
      "image": AppAssets.Onboarding_Sleep,
    },
  ];

  // --- 1. LOCAL STORAGE & FIREBASE LOGIC (Updated) ---
  Future<void> _completeOnboarding() async {
    try {
      // Service call ho rahi hai, logic ab centralized hai
      await _authService.completeOnboarding();
      await _authService.logOnboardingEvent();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error saving onboarding status: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : AppColors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    onboardingData[index]["image"]!,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.55,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          onboardingData[index]["title"]!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          onboardingData[index]["desc"]!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            right: 30,
            bottom: 50,
            child: CircularNextButton(
              percentage: (_currentPage + 1) / onboardingData.length,
              onPressed: () {
                if (_currentPage < onboardingData.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                } else {
                  _completeOnboarding();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
