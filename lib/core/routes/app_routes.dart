import 'package:flutter/material.dart';
import 'package:fitness_app/app/splash/splash_screen.dart';
import 'package:fitness_app/app/ui/onboarding_screen/onboarding_screen.dart';
import 'package:fitness_app/app/ui/auth/login_screen.dart';
import 'package:fitness_app/app/ui/auth/profile_completion_screen.dart';
import 'package:fitness_app/view/main_tab/main_tab_view.dart';
// 🔥 Iska sahi path check kar lein (e.g. view/progress_photo/...)
import 'package:fitness_app/view/progress_photo/progress_photo_view.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String profileCompletion = '/profileCompletion';
  static const String mainTab = '/mainTab';
  // 🔥 Step A: Naya Constant Add Karein
  static const String progressPhoto = '/progressPhoto';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case profileCompletion:
        return MaterialPageRoute(
          builder: (_) => const ProfileCompletionScreen(),
          settings: settings,
        );

      case mainTab:
        return MaterialPageRoute(
          builder: (_) => const MainTabView(),
          settings: settings,
        );

      // 🔥 Step B: ProgressPhotoView ka Case Add Karein
      case progressPhoto:
        return MaterialPageRoute(
          builder: (_) => const ProgressPhotoView(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }

  /// Get initial route based on app state
  static String getInitialRoute({
    required bool isFirstTime,
    required bool isLoggedIn,
    required bool isProfileComplete,
  }) {
    if (isFirstTime) {
      return AppRoutes.onboarding;
    } else if (!isLoggedIn) {
      return AppRoutes.login;
    } else if (!isProfileComplete) {
      return AppRoutes.profileCompletion;
    } else {
      return AppRoutes.mainTab;
    }
  }
}
