import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/data/services/fitness_repository.dart';
import 'package:fitness_app/data/services/search_delegate.dart';
import 'package:fitness_app/view/activity_tracker/activity_tracker_view.dart';
import 'package:fitness_app/view/notification/notification_screen.dart';
import 'package:fitness_app/view/profile/profile_view.dart';
import 'package:fitness_app/view/progress_photo/progress_photo_view.dart';
import 'package:fitness_app/view/sleep_tracker/sleep_tracker_view.dart';
import 'package:fitness_app/view/workout_tracker/workout_tracker_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  // Har workout ki live progress track karne ke liye
  Map<String, double> _liveWorkoutProgress = {};
  final FitnessRepository _repo = FitnessRepository();
  // Repository Instance
  int selectedIndex = 0;
  String selectedPeriod = "Weekly";
  // 1. Class level par variable (build method se bahar)
  //int _searchClickCount = 0;

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    // 🔥 PopScope ko sabse upar rakha hai taake back button control ho sake
    return PopScope(
      canPop: false, // Default exit ko rok diya
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Agar user pehle se dashboard (index 0) par nahi hai, toh pehle dashboard par le jayen
        if (selectedIndex != 0) {
          setState(() => selectedIndex = 0);
        } else {
          // 🔥 Agar dashboard par hi hai, toh professional dialog dikhayen
          _showExitDialog(context, isDark);
        }
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: _repo.getUserStream(),
        builder: (context, snapshot) {
          String fullName = "User", weight = "0 KG", height = "0 CM";

          if (snapshot.hasData && snapshot.data!.exists) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            fullName = userData['full_name'] ?? userData['name'] ?? "User";
            weight = userData['weight'] ?? "0 KG";
            height = userData['height'] ?? "0 CM";
            _repo.cacheDashboardData(fullName, weight, height);
          }

          final List<Widget> pages = [
            _buildDashboardUI(isDark, fullName, weight, height),
            ActivityTrackerView(
              onBack: () => setState(() => selectedIndex = 0),
            ),
            ProgressPhotoView(onBack: () => setState(() => selectedIndex = 0)),
            ProfileView(onBack: () => setState(() => selectedIndex = 0)),
          ];

          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF1D1B20) : AppColors.white,
            body: IndexedStack(index: selectedIndex, children: pages),
            bottomNavigationBar: _buildBottomNav(isDark),
            floatingActionButton: _buildFAB(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
        },
      ),
    );
  }

  void _showExitDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            // 🛑 Professional Alert Icon
            const Icon(
              Icons.exit_to_app_rounded,
              color: Color(0xFF92A3FD),
              size: 45,
            ),
            const SizedBox(height: 15),
            Text(
              "Exit FitQuest?",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "Do you really want to leave? We'll miss your workout progress!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
        actions: [
          Row(
            children: [
              // Stay Button
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Stay",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Exit Button (Gradient Look)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => SystemNavigator.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Exit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardUI(
    bool isDark,
    String name,
    String weight,
    String height,
  ) {
    String getGreeting() {
      var hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning,';
      if (hour < 17) return 'Good Afternoon,';
      return 'Good Evening,';
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getGreeting(),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // _buildDashboardUI ke andar header wala IconButton:
                  IconButton(
                    onPressed: () async {
                      // 1. Red dot ko clear karne ke liye repository call karein
                      await _repo.clearNotificationDot();

                      // 2. Notification screen par navigate karein
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      }
                    },
                    icon: StreamBuilder<DocumentSnapshot>(
                      stream: _repo.getUserStream(),
                      builder: (context, snapshot) {
                        bool hasNotification = false;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          var userData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          // Firestore mein 'has_notification' field true honi chahiye jab naya notification aaye
                          hasNotification =
                              userData['has_notification'] ?? false;
                        }

                        return Badge(
                          isLabelVisible: hasNotification,
                          backgroundColor: Colors.red,
                          smallSize: 10,
                          child: Icon(
                            Icons.notifications_none_outlined,
                            color: isDark ? Colors.white : Colors.black,
                            size: 25,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildBMICard(isDark, weight, height),
            _buildTodayTarget(isDark),
            _buildHeartRateCard(isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWaterCard(isDark),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSleepCard(isDark),
                        const SizedBox(height: 15),
                        _buildCaloriesCard(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildWorkoutProgressChart(isDark),
            const SizedBox(height: 20),
            _buildSectionHeader(isDark, "Latest Workout", "See more"),
            const SizedBox(height: 15),
            _buildLatestWorkoutList(isDark),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Updated FAB with Repo call
  Widget _buildFAB() {
    return Container(
      width: 65,
      height: 65,
      decoration: _fabDecoration(),
      child: FloatingActionButton(
        onPressed: () =>
            _showQuickActions(context), // Saare features yahan se khulenge
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(
          Icons.search_rounded,
          color: Colors.white,
          size: 35,
        ), // Plus icon zyada professional hai
      ),
    );
  }

  // --- Professional Quick Actions Menu ---
  void _showQuickActions(BuildContext context) {
    // Haptic feedback for premium feel
    HapticFeedback.mediumImpact();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Quick Track",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            // 🔥 Grid of your real features
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              // GridView ke andar aise update karein:
              children: [
                _actionItem(Icons.search, "Search", () {
                  Navigator.pop(context);
                  _handleSearchClick();
                }, isDark), // 🔥 Yahan isDark pass karein

                _actionItem(
                  Icons.fitness_center,
                  "Workout",
                  () => _jumpToTab(0),
                  isDark,
                ),
                _actionItem(
                  Icons.restaurant,
                  "Meal",
                  () => _jumpToTab(1),
                  isDark,
                ),
                _actionItem(
                  Icons.bedtime,
                  "Sleep",
                  () => _jumpToTab(0),
                  isDark,
                ),
                _actionItem(
                  Icons.camera_alt,
                  "Progress",
                  () => _jumpToTab(2),
                  isDark,
                ),
                _actionItem(
                  Icons.person,
                  "Profile",
                  () => _jumpToTab(3),
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 Icon Container with Premium Styling
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF92A3FD).withValues(alpha: isDark ? 0.2 : 0.1),
                  const Color(
                    0xFF9DCEFF,
                  ).withValues(alpha: isDark ? 0.1 : 0.05),
                ],
              ),
              // Soft Border for Glassmorphism
              border: Border.all(
                color: const Color(0xFF92A3FD).withValues(alpha: 0.2),
                width: 1.5,
              ),
              // Premium Elevated Shadow
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF92A3FD).withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ShaderMask(
              // 🔥 Icon ko Gradient look dene ke liye
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Icon(
                icon,
                color: Colors.white, // ShaderMask ki wajah se gradient dikhega
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 🔥 Label with Professional Typography
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToTab(int index) {
    Navigator.pop(context);
    setState(() => selectedIndex = index);
  }

  // UI Decoration logic separate karein
  BoxDecoration _fabDecoration() {
    return const BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Color(0x446B50F6),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      gradient: LinearGradient(
        colors: [Color(0xff6B50F6), Color(0xffCC8FED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  // Event handling logic separate karein
  Future<void> _handleSearchClick() async {
    try {
      await _repo.logInteraction('search_fab_click', 'User clicked search');
      _onSearchAction();
    } catch (e) {
      debugPrint('Error logging interaction: $e');
    }
  }

  Widget _buildBMICard(bool isDark, String weight, String height) {
    double weightVal = double.tryParse(weight.split(' ')[0]) ?? 0.0;
    double heightVal = double.tryParse(height.split(' ')[0]) ?? 0.0;

    String bmiScore = "0.0";
    String bmiStatus = "Calculating...";
    Color statusColor = Colors.white;
    String bmiAdvice = "";

    if (weightVal > 0 && heightVal > 0) {
      double heightInMeters = heightVal / 100;
      double bmi = weightVal / (heightInMeters * heightInMeters);
      bmiScore = bmi.toStringAsFixed(1);

      if (bmi < 18.5) {
        bmiStatus = "Underweight";
        statusColor = const Color(0xFFFDBB12); // Amber
        bmiAdvice =
            "You are in the underweight range. Consider consulting a nutritionist for a balanced diet plan.";
      } else if (bmi < 25) {
        bmiStatus = "Normal weight";
        statusColor = const Color(0xFF42D3A5); // Greenish Teal
        bmiAdvice =
            "A BMI of 18.5-24.9 indicates that you are at a healthy weight for your height. Great job!";
      } else if (bmi < 30) {
        bmiStatus = "Overweight";
        statusColor = const Color(0xFFFF8064); // Orange/Coral
        bmiAdvice =
            "You are in the overweight range. Maintaining a healthy weight lowers your risk of serious health problems.";
      } else {
        bmiStatus = "Obese";
        statusColor = const Color(0xFFFF5252); // Red
        bmiAdvice =
            "You are in the obese range. Focus on consistent exercise and a calorie-controlled diet.";
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.secondaryG,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                AppAssets.Main_Tab_view_dots,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "BMI (Body Mass Index)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        bmiStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      MaterialButton(
                        onPressed: () => _showBMIDetails(
                          bmiScore,
                          bmiStatus,
                          bmiAdvice,
                          isDark,
                        ),
                        color: const Color(0xFF92A3FD),
                        elevation: 0,
                        shape: const StadiumBorder(),
                        child: const Text(
                          "View More",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(AppAssets.Main_Tab_view_Banner),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 22,
                        right: 18,
                        child: Text(
                          bmiScore,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                blurRadius: 6.0,
                                color: Colors.black45,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dynamic BottomSheet Function ---
  void _showBMIDetails(
    String score,
    String status,
    String advice,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "BMI Result",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                score,
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92A3FD),
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC58BF2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                advice,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // --- Latest Workout List (Connected with Firestore & Local Storage) ---
  Widget _buildLatestWorkoutList(bool isDark) {
    // Professional Static Data for Fallback
    final List<Map<String, dynamic>> defaultWorkouts = [
      {
        'title': "Fullbody Workout",
        'kcal': 180,
        'mins': 20,
        'asset': AppAssets.Fullbody_Workout,
      },
      {
        'title': "Lowerbody Workout",
        'kcal': 200,
        'mins': 30,
        'asset': AppAssets.Lowerbody_Workout,
      },
      {
        'title': "Ab Workout",
        'kcal': 150,
        'mins': 15,
        'asset': AppAssets.Ab_Workout,
      },
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: _repo.getLatestWorkoutsStream(),
      builder: (context, snapshot) {
        // 1. Agar data aa gaya hai aur khali nahi hai
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var workoutDocs = snapshot.data!.docs;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: workoutDocs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String title = data['title'] ?? "Workout";
                double progress = (data['progress'] ?? 0.0).toDouble();

                // Find static info for image and calories
                var staticInfo = defaultWorkouts.firstWhere(
                  (w) => w['title'] == title,
                  orElse: () => defaultWorkouts[0],
                );

                return _workoutItemTile(
                  isDark,
                  title,
                  "${staticInfo['kcal']} Calories Burn | ${staticInfo['mins']}mins",
                  _liveWorkoutProgress[title] ?? progress,
                  staticInfo['asset'],
                  staticInfo['kcal'],
                  staticInfo['mins'],
                );
              }).toList(),
            ),
          );
        }

        // 2. Agar Loading ho rahi hai ya data nahi mila (Circle ki bajaye static list dikhayen)
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: defaultWorkouts.map((w) {
              return _workoutItemTile(
                isDark,
                w['title'],
                "${w['kcal']} Calories Burn | ${w['mins']}mins",
                _liveWorkoutProgress[w['title']] ?? 0.0,
                w['asset'],
                w['kcal'],
                w['mins'],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> cacheWorkoutsLocally(List<QueryDocumentSnapshot> docs) async {
    final prefs = await SharedPreferences.getInstance();

    // ERROR FIX: uid ko yahan define karein taake compiler isay pehchane
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "guest_user";

    List<String> workoutList = docs.map((doc) {
      // safely casting for jsonEncode
      return jsonEncode(doc.data() as Map<String, dynamic>);
    }).toList();

    // Ab ${uid} red nahi hoga
    await prefs.setStringList('local_workouts_${uid}', workoutList);
  }
  // --- 3. REUSABLE COMPONENTS (Kept from your original UI) ---

  // --- Professional Bottom Navigation ---
  Widget _buildBottomNav(bool isDark) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: isDark ? const Color(0xFF1D1B20) : Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, isDark),
            _buildNavItem(1, Icons.analytics_outlined, isDark),
            const SizedBox(width: 40),
            _buildNavItem(2, Icons.camera_alt_outlined, isDark),
            _buildNavItem(3, Icons.person_outline, isDark),
          ],
        ),
      ),
    );
  }

  // --- Nav Item with Local Storage Logic ---
  Widget _buildNavItem(int index, IconData icon, bool isDark) {
    bool isSelected =
        selectedIndex == index; // Ensure selectedIndex is defined in State

    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });

        // --- LOCAL STORAGE ---
        // Save current tab so the app remembers where the user left off
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_tab_index', index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSelected
              ? ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (Rect bounds) => const LinearGradient(
                    colors: [Color(0xff92A3FD), Color(0xff9DCEFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Icon(icon, size: 28, color: Colors.white),
                )
              : Icon(
                  icon,
                  size: 28,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            width: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xff92A3FD) : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  // Example Function to apply on FAB click
  // 2. Main Search Action Logic
  void _onSearchAction() {
    // 1. Professional tactile feel (Premium vibe ke liye)
    HapticFeedback.mediumImpact();

    // 2. Agar koi purana SnackBar khula hai toh foran khatam karein
    ScaffoldMessenger.of(context).clearSnackBars();

    // 3. One Click Action: Direct Search Open karein
    _openRealSearch();
  }

  // 🔥 Professional Search Opener
  void _openRealSearch() {
    showSearch(context: context, delegate: FitQuestSearchDelegate());
  }

  // --- Today Target (Functional with Firestore & Local Storage) ---
  Widget _buildTodayTarget(bool isDark) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      // Firestore se user ka specific daily goal ya target msg lena
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        String displayTarget = "Today Target";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          // Agar database mein naya target message hai toh wo dikhayen
          displayTarget = data['daily_goal_title'] ?? "Today Target";

          // Data ko offline support ke liye local save karna
          _saveTargetLocally(displayTarget);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            // Theme specific colors with modern opacity
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFEEA4CE).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          height: 60,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayTarget, // Dynamic target text
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 75,
                height: 35,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff6B50F6), Color(0xffCC8FED)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: MaterialButton(
                  onPressed: () {
                    // Navigate to Workout Tracker
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutTrackerView(),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Check',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Local Storage Helper ---
  Future<void> _saveTargetLocally(String target) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_today_target', target);
  }

  // --- Dynamic Heart Rate Card ---
  Widget _buildHeartRateCard(bool isDark) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        int bpmValue = 78; // Default value
        String lastSeen = "Just now";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          bpmValue = int.tryParse(data['heart_rate']?.toString() ?? "78") ?? 78;
          lastSeen = data['heart_rate_time'] ?? "3 mins ago";

          _saveHeartRateLocally(bpmValue.toString(), lastSeen);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.secondaryColor2.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            // 🔥 Added soft glow for premium look
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: const Color(0xffC58BF2).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Heart Rate',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$bpmValue', // Dynamic BPM
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'BPM',
                    style: TextStyle(
                      color: Color(0xffC58BF2),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: Image.asset(
                      AppAssets.Main_Tab_view_HeartRate,
                      fit: BoxFit.cover,
                      // 🔥 Wave animation effect colors
                      color: const Color(0xFF92A3FD).withOpacity(0.8),
                    ),
                  ),
                  Positioned(
                    top: -35,
                    right: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff92A3FD), Color(0xff9DCEFF)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff92A3FD).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            lastSeen,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xff92A3FD),
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper for Local Storage
  Future<void> _saveHeartRateLocally(String bpm, String time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_bpm', bpm);
    await prefs.setString('local_bpm_time', time);
  }

  // --- 1. Water Intake Card (Connected with Firestore) ---
  Widget _buildWaterCard(bool isDark) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        String totalWater = "0.0 Liters";
        double progressLevel = 0.0;
        const double dailyGoal =
            4.0; // Isay aap user profile se bhi le sakte hain

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;

          // 🔥 Safe Parsing: Regex use kiya taake sirf number nikle
          String rawWater = data['water_intake']?.toString() ?? "0";
          double consumed =
              double.tryParse(rawWater.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;

          totalWater = "${consumed.toStringAsFixed(1)} Liters";

          // 🔥 Calculation: Total height 270 hai
          // Formula: (Consumed / Goal) * MaxHeight
          progressLevel = (consumed / dailyGoal) * 270.0;

          // Bar ko 270 se upar nahi jane dena
          if (progressLevel > 270) progressLevel = 270;

          _saveWaterLocally(totalWater);
        }

        return Container(
          width: 150,
          constraints: const BoxConstraints(minHeight: 315),
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(isDark),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 Vertical Bar with Animation
              _verticalProgressUI(isDark, progressLevel),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Water Intake",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      totalWater,
                      style: const TextStyle(
                        color: Color(0xffC58BF2),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Real time updates",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),

                    // 🔥 Professional Logs (Timeline)
                    _buildSmallLog("6am - 8am", "600ml", isLast: false),
                    _buildSmallLog("9am - 11am", "500ml", isLast: false),
                    _buildSmallLog("11am - 2pm", "1000ml", isLast: false),
                    _buildSmallLog("2pm - 4pm", "700ml", isLast: false),
                    _buildSmallLog("4pm - now", "900ml", isLast: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 2. Vertical Progress UI (With Animation) ---
  Widget _verticalProgressUI(bool isDark, double levelHeight) {
    return Container(
      width: 20,
      height: 270,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xffF7F8F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // AnimatedContainer use kiya taake bar smooth move kare
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 20,
            height: levelHeight, // Ab ye height data par depend karti hai
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff92A3FD), Color(0xff9DCEFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to save locally
  Future<void> _saveWaterLocally(String val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_water_intake', val);
  }
  // --- 2. Sleep Card (With Wave Graph) ---

  // --- Sleep Card (Connected with Firestore & Local Storage) ---
  Widget _buildSleepCard(bool isDark) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Default static data
        String sleepDuration = "8h 20m";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          // Firebase se sleep data uthana
          sleepDuration = data['sleep_duration'] ?? "8h 20m";

          // Data ko local storage mein cache karna
          _saveSleepLocally(sleepDuration);
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SleepTrackerView()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: _cardDecoration(isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sleep",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  sleepDuration, // Dynamic sleep duration
                  style: const TextStyle(
                    color: Color(0xffC58BF2),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // Wave Image from AppAssets
                Image.asset(
                  AppAssets.Main_Tab_view_Sleep,
                  // Hardcoded path ki jagah AppAssets use karein
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper to save sleep data in SharedPreferences ---
  Future<void> _saveSleepLocally(String duration) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_sleep_duration', duration);
  }

  // --- Calories Card (Connected with Firestore & Local Storage) ---
  Widget _buildCaloriesCard(bool isDark) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Default values agar data na mile
        double consumedCalories = 760.0;
        double targetCalories = 2000.0; // Daily Goal
        double progressValue = 0.38; // Percentage (760/2000)

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;

          // Firebase se calories nikalna
          String calString = data['calories_burned'] ?? "760 kCal";
          consumedCalories = double.tryParse(calString.split(' ')[0]) ?? 760.0;

          // User profile se target calories nikalna (agar save hain)
          targetCalories = (data['daily_goal_calories'] ?? 2000).toDouble();

          // Progress calculate karna (Circular indicator ke liye 0.0 se 1.0 ke darmiyan)
          progressValue = consumedCalories / targetCalories;
          if (progressValue > 1.0) progressValue = 1.0;

          // Local storage sync
          _saveCaloriesLocally(calString);
        }

        double caloriesLeft = targetCalories - consumedCalories;
        if (caloriesLeft < 0) caloriesLeft = 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Calories",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                "${consumedCalories.toInt()} kCal", // Dynamic Consumed
                style: const TextStyle(
                  color: Color(0xffC58BF2),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Progress Ring
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: progressValue, // Dynamic Progress
                        strokeWidth: 8,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.grey.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xff92A3FD),
                        ),
                      ),
                    ),
                    // Inner Gradient Circle with "Left" Text
                    Container(
                      width: 55,
                      height: 55,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xffC58BF2), Color(0xffEEA4CE)],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${caloriesLeft.toInt()}kCal", // Dynamic Remaining
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "left",
                            style: TextStyle(color: Colors.white, fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helper to save calories locally ---
  Future<void> _saveCaloriesLocally(String calories) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_calories_burned', calories);
  }
  // --- Helper: Dotted Timeline Log ---

  Widget _buildSmallLog(String time, String amount, {required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Column(
          children: [
            Container(
              height: 8,

              width: 8,

              decoration: const BoxDecoration(
                color: Color(0xffC58BF2),

                shape: BoxShape.circle,
              ),
            ),

            if (!isLast)
              Container(
                width: 1,

                height: 25,

                color: const Color(
                  0xffC58BF2,
                ).withValues(alpha: 0.3), // Dotted line effect
              ),
          ],
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(time, style: const TextStyle(fontSize: 9, color: Colors.grey)),

            Text(
              amount,

              style: const TextStyle(
                fontSize: 9,

                color: Color(0xffC58BF2),

                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Reusable Card Decoration ---

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,

      borderRadius: BorderRadius.circular(20),

      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),

                blurRadius: 10,

                offset: const Offset(0, 5),
              ),
            ],
    );
  }

  // --- Workout Progress Graph Widget ---

  // --- Workout Progress Graph Widget ---
  Widget _buildWorkoutProgressChart(bool isDark) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Workout Progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              _buildWeeklyDropdown(),
            ],
          ),
          const SizedBox(height: 10),
          // StreamBuilder for Real-time Graph Data
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('graph_data')
                  .snapshots(),
              builder: (context, snapshot) {
                // Default spots aapke original logic se
                List<FlSpot> currentSpots = _lineBarData().spots;

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  // Firebase se data aane par local storage update karein
                  _saveGraphLocally(snapshot.data!.docs);
                }

                // Error fixed: Ab spots pass ho rahe hain
                return LineChart(_workoutChartData(isDark, currentSpots));
              },
            ),
          ),
        ],
      ),
    );
  }

  // Weekly/Monthly Dropdown Button
  Widget _buildWeeklyDropdown() {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          selectedPeriod = value;
        });
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(value: "Weekly", child: Text("Weekly")),
        const PopupMenuItem(value: "Monthly", child: Text("Monthly")),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffC58BF2), Color(0xffEEA4CE)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              selectedPeriod,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // --- Image ke mutabiq Graph Logic ---
  // Parameter 'spots' add kiya gaya hai taake dynamic data handle ho sake
  LineChartData _workoutChartData(bool isDark, List<FlSpot> spots) {
    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) =>
              isDark ? const Color(0xFF3A3A3C) : Colors.white,
          tooltipBorderRadius: BorderRadius.circular(12),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          tooltipMargin: 15,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                'Fri, 28 May',
                TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                  fontFamily: 'Poppins',
                ),
                children: [
                  const TextSpan(
                    text: '     90% ↑\n',
                    style: TextStyle(
                      color: Color(0xff42D3A5),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  TextSpan(
                    text: 'Upperbody Workout',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (val) => FlLine(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (val, meta) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '${(val * 20).toInt()}%',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
            reservedSize: 40,
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              if (selectedPeriod == "Weekly") {
                const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                bool isSelected = val.toInt() == 5;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    days[val.toInt() % 7],
                    style: TextStyle(
                      color: isSelected ? const Color(0xffC58BF2) : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                );
              } else {
                const weeks = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'];
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    weeks[val.toInt() % 7],
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              }
            },
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 5,
      showingTooltipIndicators: [
        ShowingTooltipIndicators([
          LineBarSpot(_lineBarData(), 0, _lineBarData().spots[5]),
        ]),
      ],
      lineBarsData: [
        LineChartBarData(
          spots: spots, // Using dynamic spots
          isCurved: true,
          curveSmoothness: 0.4,
          gradient: const LinearGradient(
            colors: [Color(0xffC58BF2), Color(0xff92A3FD)],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, p, b, i) {
              if (spot.x == 5) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: const Color(0xffC58BF2),
                );
              }
              return FlDotCirclePainter(radius: 0);
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xffC58BF2).withValues(alpha: 0.15),
                const Color(0xff92A3FD).withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  // Original spots logic kept as it is
  LineChartBarData _lineBarData() {
    List<FlSpot> spots = selectedPeriod == "Weekly"
        ? const [
            FlSpot(0, 2),
            FlSpot(1, 1.5),
            FlSpot(2, 3.5),
            FlSpot(3, 2.2),
            FlSpot(4, 2.8),
            FlSpot(5, 4.2),
            FlSpot(6, 3.2),
          ]
        : const [
            FlSpot(0, 1),
            FlSpot(1, 3),
            FlSpot(2, 2.5),
            FlSpot(3, 4.5),
            FlSpot(4, 3.2),
            FlSpot(5, 4.8),
            FlSpot(6, 4),
          ];

    return LineChartBarData(spots: spots);
  }

  // Local Storage Helper
  Future<void> _saveGraphLocally(List<QueryDocumentSnapshot> docs) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = docs.map((d) => d.data().toString()).toList();
    await prefs.setStringList('local_workout_graph', data);
  }
  // Individual Workout Card

  // 1. Updated Tile Widget (Added kcal and mins)
  Widget _workoutItemTile(
    bool isDark,
    String title,
    String subtitle,
    double progress,
    String image,
    int totalKcal, // 🔥 Naya Parameter
    int totalMins, // 🔥 Naya Parameter
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: _cardDecoration(isDark), // Design safe hai
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // 🔥 Error fixed: Ab 4 arguments pass ho rahe hain
        onTap: () => _startWorkoutLogic(title, progress, totalKcal, totalMins),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildWorkoutImage(image),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 📊 Bar ab yahan real-time update hogi
                    _buildProgressBar(progress, isDark),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildTrailingAction(),
            ],
          ),
        ),
      ),
    );
  }

  // 2. 🔥 Professional Timer Logic (English Messages + Real-time Fill)
  void _startWorkoutLogic(
    String title,
    double currentProgress,
    int kcal,
    int mins,
  ) {
    HapticFeedback.mediumImpact();

    if (currentProgress >= 1.0) {
      _showRestartDialog(title, kcal, mins);
      return;
    }

    // English Status Message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("⚡ $title started. Duration: $mins mins"),
        backgroundColor: const Color(0xFF92A3FD),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Initial value set karein
    _liveWorkoutProgress[title] = currentProgress;

    // 🔥 Logic: Har 1 second baad kitni progress barhni chahiye?
    // Formula: 1.0 (full bar) / (minutes * 60 seconds)
    double step = 1.0 / (mins * 60);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Progress ko har second barhayen
        _liveWorkoutProgress[title] =
            (_liveWorkoutProgress[title] ?? 0.0) + step;
      });

      // Jab bar full ho jaye
      if (_liveWorkoutProgress[title]! >= 1.0) {
        _liveWorkoutProgress[title] = 1.0;
        timer.cancel();

        // Database update
        _repo.updateWorkoutProgress(title, 1.0, kcal, mins);
        _showCompletionMessage(title);
      } else {
        // Background Sync: Har 1 minute baad database update karein
        if ((timer.tick % 60) == 0) {
          _repo.updateWorkoutProgress(
            title,
            _liveWorkoutProgress[title]!,
            kcal,
            mins,
          );
        }
      }
    });
  }

  void _showCompletionMessage(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎉 Outstanding! You've completed your $title."),
        backgroundColor: const Color(0xFF42D3A5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  // 🔥 Professional Start Logic (Safe from duplicate timers)
  // void _startWorkoutLogic(String title, double currentProgress) {
  //   HapticFeedback.mediumImpact(); // Premium tactile feel

  //   if (currentProgress >= 1.0) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("$title Great job! You’ve already finished this. 🌟"),
  //       ),
  //     );
  //     return;
  //   }

  //   // Yahan aap apna Timer logic ya Navigation logic dal sakte hain
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       behavior: SnackBarBehavior.floating,
  //       backgroundColor: const Color(0xFF92A3FD),
  //       content: Text("$title shuru ho gaya! ⚡"),
  //     ),
  //   );

  //   // Tip: Real app mein Timer hamesha detail page par hota hai, list par nahi.
  // }

  // 🔥 Ye function add karein taake error khatam ho jaye
  void _showRestartDialog(String title, int kcal, int mins) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Workout Completed",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "You've already finished the $title. Do you want to challenge yourself again?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("NOT NOW", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF92A3FD),
              shape: StadiumBorder(),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startWorkoutLogic(title, 0.0, kcal, mins);
            },
            child: Text("RESTART", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: isDark ? Colors.white10 : const Color(0xFFF7F8F8),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF92A3FD)),
      ),
    );
  }

  Widget _buildWorkoutImage(String image) {
    return Container(
      height: 55,
      width: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF92A3FD).withValues(alpha: 0.15),
            const Color(0xFF9DCEFF).withValues(alpha: 0.15),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          image,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.fitness_center, color: Color(0xFF92A3FD)),
        ),
      ),
    );
  }

  Widget _buildTrailingAction() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF92A3FD).withValues(alpha: 0.2),
        ),
      ),
      child: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF92A3FD),
        size: 18,
      ),
    );
  }

  // Section Header for "See more"

  Widget _buildSectionHeader(bool isDark, String title, String actionText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // Dart Theme Logic: Dark mode mein white aur Light mein black
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          TextButton(
            onPressed: () async {
              // --- 1. LOCAL STORAGE LOGIC ---
              // User ka last clicked section save karna taake app ko pata ho user ne kya dekha
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_visited_section', title);

              // --- 2. FIREBASE LOGIC (Optional Analytics) ---
              // Aap track kar sakte hain ke user "See More" kitni baar click kar raha hai
              String uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";
              FirebaseFirestore.instance.collection('user_interactions').add({
                'uid': uid,
                'section': title,
                'timestamp': FieldValue.serverTimestamp(),
              });

              // --- 3. NAVIGATION ---
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutTrackerView(),
                  ),
                );
              }
            },
            child: Text(
              actionText,
              style: const TextStyle(
                color: Colors.grey, // Figma style grey color
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
