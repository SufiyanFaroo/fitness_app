import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; //
import '../../data/services/workout_service.dart';

class WorkoutFinishedView extends StatefulWidget {
  const WorkoutFinishedView({super.key});

  @override
  State<WorkoutFinishedView> createState() => _WorkoutFinishedViewState();
}

class _WorkoutFinishedViewState extends State<WorkoutFinishedView> {
  // 🔥 1. Service Instance
  final WorkoutService _service = WorkoutService();

  @override
  void initState() {
    super.initState();
    // 🔥 2. Screen load hote hi data sync karein
    _markWorkoutAsFinished();
  }

  Future<void> _markWorkoutAsFinished() async {
    try {
      // Firebase aur Local Storage mein data update karega
      await _service.updateScheduleStatus("Fullbody_Workout_Finished", true);

      // Aap yahan activity log bhi sync kar sakte hain
      debugPrint("Workout marked as finished in Firebase & Local.");
    } catch (e) {
      debugPrint("Error syncing finished workout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme logic
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    Color bgColor = isDark ? const Color(0xFF1D1B20) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // 1. Illustration Image (UI same)
              Image.asset(
                "assets/images/workout.png",
                height: 300,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.emoji_events,
                  size: 150,
                  color: Color(0xFF92A3FD),
                ),
              ),

              const SizedBox(height: 40),

              // 2. Congratulations Text
              Text(
                "Congratulations, You Have\nFinished Your Workout",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // 3. Quote Text
              Text(
                "Exercises is king and nutrition is queen. Combine the two and you will have a kingdom",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 10),

              const Text(
                "-Jack Lalanne",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const Spacer(),

              // 4. Back To Home Button
              _buildHomeButton(context),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF92A3FD), Color(0xFFC58BF2)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF92A3FD).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Home page par wapis jane ke liye
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          "Back To Home",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
