//import 'package:fitness_app/view/workout_tracker/detail.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../../data/services/workout_service.dart';
import 'package:fitness_app/view/workout_tracker/WorkoutScheduleView.dart';
import 'package:fitness_app/view/workout_tracker/exercise_detail_view.dart';
import 'package:provider/provider.dart';

class WorkoutDetailView extends StatefulWidget {
  const WorkoutDetailView({super.key});
  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {
  // 🔥 FIX 1: Service instance ko class ke andar define karein
  final WorkoutService _service = WorkoutService();
  final List<Exercise> workoutExercises = [
    // SET 1
    Exercise(
      title: "Warm Up",
      calories: "30 Calories Burn",
      level: "Easy",
      videoPath: "assets/images/warm.mp4",
      description:
          "Warm-up prepare your muscles for activity and increase blood flow.",
      steps: [
        {"title": "Gentle Jogging", "desc": "Light jog in place for 2 mins."},
      ],
    ),
    Exercise(
      title: "Jumping Jack",
      calories: "390 Calories Burn",
      level: "Easy",
      videoPath: "assets/images/jumping.mp4",
      description:
          "A jumping jack, also known as a star jump and called a side-straddle hop in the US military, is a physical jumping exercise performed by jumping to a position with the legs spread wide ....",
      steps: [
        {
          "title": "Spread Your Arms",
          "desc":
              "To make the gestures feel more relaxed, stretch your arms as you start this movement. No bending of hands.",
        },
        {
          "title": "Rest at The Toe",
          "desc":
              "The basis of this movement is jumping. Now, what needs to be considered is that you have to use the tips of your feet",
        },
        {
          "title": "RAdjust Foot Movement",
          "desc":
              "Jumping Jack is not just an ordinary jump. But, you also have to pay close attention to leg movements.",
        },
        {
          "title": "Clapping Both Hands",
          "desc":
              "This cannot be taken lightly. You see, without realizing it, the clapping of your hands helps you to keep your rhythm while doing the Jumping Jack",
        },
      ],
    ),
    Exercise(
      title: "Skipping",
      calories: "450 Calories Burn",
      level: "Medium",
      videoPath: "assets/images/skipping.mp4",
      description:
          "Skipping is a great cardio exercise that improves coordination.",
      steps: [
        {"title": "Rhythm", "desc": "Maintain a steady jump rope rhythm."},
      ],
    ),
    // SET 2
    Exercise(
      title: "Squats",
      calories: "320 Calories Burn",
      level: "Medium",
      videoPath: "assets/images/squats.mp4",
      description:
          "Squats strengthen your lower body, focusing on thighs and hips.",
      steps: [
        {
          "title": "Sitting Posture",
          "desc": "Sit back as if on an invisible chair.",
        },
      ],
    ),
    Exercise(
      title: "Arm Raises",
      calories: "150 Calories Burn",
      level: "Easy",
      videoPath: "assets/images/arm.mp4",
      description: "Focus on shoulder muscles by raising arms slowly.",
      steps: [
        {
          "title": "Stretching",
          "desc": "Raise arms horizontally to the sides.",
        },
      ],
    ),
    Exercise(
      title: "Rest and Drink",
      calories: "0 Calories Burn",
      level: "Easy",
      videoPath: "assets/images/rest.mp4",
      description: "Hydrate and let your heart rate settle down.",
      steps: [
        {"title": "Drink Water", "desc": "Take small sips of water."},
      ],
    ),
    // SET 3
    Exercise(
      title: "Incline Push-Ups",
      calories: "200 Calories Burn",
      level: "Medium",
      videoPath: "assets/images/inclint_pushup.mp4",
      description: "Push-ups with hands on an elevated surface.",
      steps: [
        {"title": "Chest Focus", "desc": "Push down and keep your core tight."},
      ],
    ),
    Exercise(
      title: "Push-Ups",
      calories: "250 Calories Burn",
      level: "Hard",
      videoPath: "assets/images/pushup.mp4",
      description: "Standard push-ups for chest and tricep strength.",
      steps: [
        {
          "title": "Plank Position",
          "desc": "Keep your body in a straight line.",
        },
      ],
    ),
  ];
  // --- 🔥 NEW: Firebase & Local Sync Logic ---
  Future<void> _handleStartWorkout() async {
    try {
      // Backend Sync call
      await _service.startWorkoutSession(
        "Fullbody Workout",
        workoutExercises.length,
      );

      if (mounted) {
        // Navigation to first exercise
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ExerciseDetailView(exercise: workoutExercises[0]),
          ),
        );
      }
    } catch (e) {
      debugPrint("Workout Sync Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : AppColors.white,
      body: Stack(
        children: [
          _buildHeaderBackground(media),
          _buildMainContent(media, isDark),
          _buildAppBarButtons(isDark),

          // 🔥 Bottom Button Call (Properly passing the function)
          _buildBottomButton(
            media,
            context,
            workoutExercises,
            _handleStartWorkout, // Callback logic
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(Size media) {
    return Container(
      height: media.height * 0.50,
      width: media.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor2, AppColors.primaryColor1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: media.height * 0.75,
            width: media.width * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Image.asset(
            'assets/images/Man.png',
            height: media.height * 0.38,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarButtons(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _actionButton(
              Icons.arrow_back_ios_new,
              () => Navigator.pop(context),
              isDark,
            ),

            // 🔥 Popup Menu with REAL WORK
            Theme(
              data: Theme.of(context).copyWith(
                cardColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'favorite') {
                    // Logic: Pure workout ko favorite mark karna
                    await _service.updateScheduleStatus(
                      "Fullbody_Workout_Fav",
                      true,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Added to your Favorites! ❤️"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else if (value == 'share') {
                    // 🔥 Logic: App Link ke sath Share karna
                    const String appLink =
                        "https://play.google.com/store/apps/details?id=com.fitquest.app";
                    final String shareMessage =
                        "Check out this 'Fullbody Workout' on FitQuest App! 💪\n"
                        "Includes ${workoutExercises.length} exercises to keep you fit.\n\n"
                        "Download now: $appLink";

                    await Share.share(
                      shareMessage,
                      subject: 'FitQuest Workout',
                    );
                  }
                },
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                itemBuilder: (context) => [
                  _buildPopupItem(
                    "Share Workout",
                    Icons.share_rounded,
                    isDark,
                    'share',
                  ),
                  _buildPopupItem(
                    "Add to Favorite",
                    Icons.favorite_rounded,
                    isDark,
                    'favorite',
                  ),
                ],
                child: _customMoreButton(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customMoreButton(bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.more_horiz,
        color: isDark ? Colors.white : Colors.black,
        size: 16,
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String title,
    IconData icon,
    bool isDark,
    String value,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icons, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          // Dark mode mein button ka background halka transparent white
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icons,
          color: isDark ? Colors.white : AppColors.black,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildMainContent(Size media, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: media.height * 0.4),
          Container(
            width: media.width,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              // Card background color logic
              color: isDark ? const Color(0xFF1D1B20) : AppColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : AppColors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildTitleSection(isDark),
                const SizedBox(height: 25),
                _buildInfoBars(isDark),
                const SizedBox(height: 25),
                _buildEquipments(isDark),
                const SizedBox(height: 25),
                _buildExerciseList(isDark),
                const SizedBox(height: 80), // Space for start button
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fullbody Workout',
              style: TextStyle(
                // Text color logic
                color: isDark ? Colors.white : AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '11 Exercises | 32mins | 320 Calories Burn',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
        ),
        const Icon(Icons.favorite, color: Colors.red),
      ],
    );
  }

  Widget _buildInfoBars(bool isDark) {
    return Column(
      children: [
        _infoTile(
          Icons.calendar_month_outlined,
          "Schedule Workout",
          "5/27, 09:00 AM",
          isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xffD1FFEA),
          isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutScheduleView(),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        _infoTile(
          Icons.swap_vert_rounded,
          "Difficulty",
          "Beginner",
          isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xffF2E8FF),
          isDark,
          onTap: () {
            // Difficulty ke liye agar koi screen hai to yahan add karein
          },
        ),
      ],
    );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
    Color bgColor,
    bool isDark, {
    VoidCallback? onTap, // Optional onTap function add kiya
  }) {
    return InkWell(
      onTap: onTap, // Click event yahan attach kiya
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipments(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You’ll Need',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '5 Items',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _equipmentCard('Barbell', 'assets/images/equipment1.png', isDark),
              _equipmentCard(
                'Skipping Rope',
                'assets/images/skipping1.png',
                isDark,
              ),
              _equipmentCard(
                'Bottle 1 Liters',
                'assets/images/bottle.png',
                isDark,
              ),
              _equipmentCard(
                'Pushups Stand',
                'assets/images/equipments1.1.png',
                isDark,
              ),
              _equipmentCard(
                'Kettle Bell',
                'assets/images/equipments0.png',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _equipmentCard(String name, String imgPath, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 130,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              // Dark mode mein background halka dark
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(imgPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exercises',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              '3 Sets',
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _sectionTitle("Set-1", isDark),
        _exerciseRow(
          workoutExercises[0],
          "05:00",
          "assets/images/ex1.png",
          isDark,
        ),
        _exerciseRow(
          workoutExercises[1],
          "12x",
          "assets/images/ex2.png",
          isDark,
        ),
        _exerciseRow(
          workoutExercises[2],
          "15x",
          "assets/images/ex3.png",
          isDark,
        ),

        const SizedBox(height: 10),
        _sectionTitle("Set-2", isDark),
        _exerciseRow(
          workoutExercises[3],
          "20x",
          "assets/images/ex4.png",
          isDark,
        ),
        _exerciseRow(
          workoutExercises[4],
          "00:53",
          "assets/images/ex5.png",
          isDark,
        ),
        _exerciseRow(
          workoutExercises[5],
          "02:00",
          "assets/images/ex6.png",
          isDark,
        ),
        const SizedBox(height: 10),
        _sectionTitle("Set-3", isDark),
        _exerciseRow(
          workoutExercises[6],
          "12x",
          "assets/images/ex7.png",
          isDark,
        ),
        _exerciseRow(
          workoutExercises[7],
          "15x",
          "assets/images/ex8.png",
          isDark,
        ),

        // ... Baqi rows bhi isi tarah set karein
      ],
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : AppColors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 3. Updated Exercise Row (Dynamic Navigation)
  Widget _exerciseRow(
    Exercise ex,
    String subtitle,
    String imgPath,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          // --- ERROR FIXED HERE ---
          // 'const' hata diya aur dynamic 'exercise' bhej diya
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseDetailView(exercise: ex),
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imgPath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

Widget _buildBottomButton(
  Size media,
  BuildContext context,
  List<Exercise> workoutExercises,
  VoidCallback onStart, // 🔥 Callback add kiya
) {
  return Positioned(
    bottom: 20,
    left: 30,
    right: 30,
    child: InkWell(
      onTap: onStart, // 🔥 Ab ye Firebase logic trigger karega
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff6B50F6), Color(0xffCC8FED)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            "Start Workout",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
