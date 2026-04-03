import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Firebase Imports ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const FitnessApp(),
    ),
  );
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Fitness App",
      themeMode: themeProvider.themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryColor1,
          secondary: AppColors.secondaryColor1,
          surface: AppColors.borderColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBackground,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryColor1,
          secondary: AppColors.secondaryColor1,
          surface: AppColors.cardGrey,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // --- Routes Configuration (Remove home, use initialRoute only) ---
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
