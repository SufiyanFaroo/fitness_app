import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/data/services/MealService.dart';

class MealScheduleView extends StatefulWidget {
  const MealScheduleView({super.key});

  @override
  State<MealScheduleView> createState() => _MealScheduleViewState();
}

class _MealScheduleViewState extends State<MealScheduleView> {
  int _selectedDayIndex = 3;
  final MealService _mealService = MealService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _syncOfflineData();
  }

  Future<void> _syncOfflineData() async {
    debugPrint("Checking for offline meal logs to sync...");
  }

  Future<void> _handleClearAllMeals() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'today_meals': FieldValue.delete(),
        });
        if (mounted) _showSnackBar("Today's schedule cleared from Cloud.");
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    }
  }

  void _addNewMealAction(String category) async {
    Navigator.pop(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_added_meal_category', category);

    await _mealService.updateNutritionGoals({
      "last_meal_category": category,
      "sync_time": FieldValue.serverTimestamp(),
    });

    if (mounted) {
      _showSnackBar("New $category Meal synced to your profile!");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF92A3FD),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      appBar: _buildAppBar(isDark),
      body: StreamBuilder<DocumentSnapshot>(
        // 🔥 Task 12: Listening to Cloud Data
        stream: _mealService.getNutritionData(),
        builder: (context, snapshot) {
          // Data check and Error handling
          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(isDark),
                _buildDateSelector(isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // --- Breakfast ---
                      _buildMealHeader(
                        "Breakfast",
                        "2 meals | 230 calories",
                        isDark,
                      ),
                      _mealTile(
                        "Honey Pancake",
                        "07:00am",
                        "assets/images/honeycake.png",
                        const Color(0xFFD1FFEA),
                        isDark,
                      ),
                      _mealTile(
                        "Coffee",
                        "07:30am",
                        "assets/images/coffee.png",
                        const Color(0xFFF2E8FF),
                        isDark,
                      ),

                      const SizedBox(height: 25),

                      // --- Lunch ---
                      _buildMealHeader(
                        "Lunch",
                        "2 meals | 500 calories",
                        isDark,
                      ),
                      _mealTile(
                        "Chicken Steak",
                        "01:00pm",
                        "assets/images/chickensteak.png",
                        const Color(0xFFD1FFEA),
                        isDark,
                      ),
                      _mealTile(
                        "Milk",
                        "01:20pm",
                        "assets/images/glassmilk.png",
                        const Color(0xFFF2E8FF),
                        isDark,
                      ),

                      const SizedBox(height: 25),
                      _buildMealHeader(
                        "Snacks",
                        "2 meals | 140 calories",
                        isDark,
                      ),
                      _mealTile(
                        "Orange",
                        "04:30pm",
                        "assets/images/orange1.png",
                        const Color(0xFFD1FFEA),
                        isDark,
                      ),
                      _mealTile(
                        "Apple Pie",
                        "04:40pm",
                        "assets/images/applepie.png",
                        const Color(0xFFF2E8FF),
                        isDark,
                      ),

                      const SizedBox(height: 25),
                      _buildMealHeader(
                        "Dinner",
                        "2 meals | 120 calories",
                        isDark,
                      ),
                      _mealTile(
                        "Salad",
                        "07:10pm",
                        "assets/images/salad1.png",
                        const Color(0xFFD1FFEA),
                        isDark,
                      ),
                      _mealTile(
                        "Oatmeal",
                        "08:10pm",
                        "assets/images/oatmeal.png",
                        const Color(0xFFF2E8FF),
                        isDark,
                      ),

                      const SizedBox(height: 30),

                      // --- Nutrition Section ---
                      _buildTodayNutrition(isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildAddButton(),
    );
  }

  // --- Helper Widgets ---

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: _appBarButton(
        Icons.arrow_back_ios_new,
        isDark,
        () => Navigator.pop(context),
      ),
      title: Text(
        "Meal Schedule",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [_buildPopupMenu(isDark)],
    );
  }

  Widget _buildPopupMenu(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Icon(
          Icons.more_horiz,
          size: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
        onSelected: (value) async {
          if (value == 'Share Schedule') {
            // 🔥 Task 3: Professional Sharing with tracking
            await _mealService.shareDietPlan("My FitQuest Weekly Schedule");
            _showSnackBar("Schedule shared successfully!");
          } else if (value == 'Clear All Meals') {
            // 🔥 Task 6: Secure Activity Deletion from Firebase
            _showDeleteConfirmationDialog();
          } else if (value == 'Meal Reminders') {
            // 🔥 Task 9: Local Storage Toggle
            bool currentStatus = await _mealService.getNotifyStatus(
              "global_reminders",
            );
            await _mealService.toggleMealReminders(!currentStatus);
            _showSnackBar(
              currentStatus ? "Reminders Disabled" : "Reminders Enabled",
            );
          }
        },
        itemBuilder: (context) => [
          _menuItem(
            "Share Schedule",
            Icons.share_outlined,
            const Color(0xFF92A3FD),
          ),
          _menuItem(
            "Meal Reminders",
            Icons.notifications_none_outlined,
            const Color(0xFFC58BF2),
          ),
          const PopupMenuDivider(), // Professional separation
          _menuItem("Clear All Meals", Icons.delete_outline, Colors.redAccent),
        ],
      ),
    );
  }

  // --- Back Button Helper Widget ---
  Widget _appBarButton(IconData icon, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  // --- 🔥 Professional Delete Confirmation Dialog ---
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear Schedule?"),
        content: const Text(
          "This will permanently delete today's meal logs from the cloud.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _handleClearAllMeals(); // Purana Firebase deletion function
            },
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String title, IconData icon, Color color) {
    return PopupMenuItem(
      value: title,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(bool isDark) {
    // 🔥 Task 8: Aaj ki real date aur month nikalna
    DateTime now = DateTime.now();
    String currentMonthYear = "${_getMonthName(now.month)} ${now.year}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => _changeMonth(false), // Piche wala mahina
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
          ),
          GestureDetector(
            onTap: () => _saveCurrentViewToLocal(currentMonthYear),
            child: Text(
              currentMonthYear,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(true), // Agla mahina
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- Helper: Mahine ka naam nikalne ke liye ---
  String _getMonthName(int month) {
    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  // --- Task 4: View status local storage mein save karna ---
  void _saveCurrentViewToLocal(String monthYear) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_viewed_month', monthYear);
    _showSnackBar("Viewing schedule for $monthYear");
  }

  void _changeMonth(bool isNext) {
    // Yahan aap mahina change karne ka logic add kar sakte hain
    _showSnackBar("Month switching coming soon!");
  }

  Widget _buildDateSelector(bool isDark) {
    // 🔥 Task 8: Aaj ki date se hafte ke din nikalna
    DateTime now = DateTime.now();

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          // Aaj se agle 7 din calculate karein
          DateTime date = now.add(Duration(days: index));
          bool isSelected = index == _selectedDayIndex;

          // Din aur Date format nikalna
          String dayName = _getDayName(date.weekday);
          String dayNumber = date.day.toString();

          return GestureDetector(
            onTap: () async {
              setState(() => _selectedDayIndex = index);

              // 🔥 Task 4: Selected date ko local storage mein yaad rakhna
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                'selected_schedule_date',
                date.toIso8601String(),
              );

              _showSnackBar("Loading data for $dayName, $dayNumber...");
            },
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFC58BF2), Color(0xFFEEA4CE)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? Colors.white10 : const Color(0xFFF7F8F8)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper: Weekday number ko Naam mein badalne ke liye
  String _getDayName(int weekday) {
    List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[weekday - 1];
  }

  Widget _mealTile(
    String name,
    String time,
    String img,
    Color bg,
    bool isDark,
  ) {
    return GestureDetector(
      // 🔥 Task 6: Deletion on Long Press
      onLongPress: () {
        _showDeleteConfirmation(name);
      },
      // 🔥 Task 12: Navigation to details on Tap
      onTap: () {
        _showSnackBar("Opening details for $name...");
      },
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.all(10), // Thori padding for better touch
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : bg.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                img,
                errorBuilder: (c, e, s) => const Icon(Icons.fastfood),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    time,
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

  // --- 🔥 Task 6: Delete Confirmation Dialog ---
  void _showDeleteConfirmation(String mealName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Activity?"),
        content: Text(
          "Are you sure you want to remove '$mealName' from your schedule?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context); // Dialog band karein

              // 🔥 Yahan aapka Firebase deletion logic ayega
              _showSnackBar("$mealName deleted successfully!");

              // Example deletion call (Agar aapke paas Doc ID ho):
              // await _mealService.deleteMealFromFirebase(mealName);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMealHeader(String title, String subtitle, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTodayNutrition(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today Meal Nutritions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // 🔥 Task 12: Real-time Data Binding with StreamBuilder
        StreamBuilder<DocumentSnapshot>(
          stream: _mealService.getNutritionData(),
          builder: (context, snapshot) {
            // Default static data agar Firebase load na ho
            double calVal = 0.7;
            double proVal = 0.45;
            double fatVal = 0.35;
            double carVal = 0.55;

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              // Firebase se real values uthana (e.g., 0.0 se 1.0 ke darmiyan)
              calVal = data['calories_ratio'] ?? 0.7;
              proVal = data['protein_ratio'] ?? 0.45;
              fatVal = data['fat_ratio'] ?? 0.35;
              carVal = data['carbo_ratio'] ?? 0.55;
            }

            return Column(
              children: [
                _nutritionProgress(
                  "Calories",
                  "🔥",
                  calVal,
                  "${(calVal * 500).toInt()} kCal",
                  const Color(0xFFC58BF2),
                  isDark,
                ),
                const SizedBox(height: 20),
                _nutritionProgress(
                  "Proteins",
                  "🥩",
                  proVal,
                  "${(proVal * 100).toInt()}g",
                  const Color(0xFFC58BF2),
                  isDark,
                ),
                const SizedBox(height: 20),
                _nutritionProgress(
                  "Fats",
                  "🥑",
                  fatVal,
                  "${(fatVal * 50).toInt()}g",
                  const Color(0xFFC58BF2),
                  isDark,
                ),
                const SizedBox(height: 20),
                _nutritionProgress(
                  "Carbo",
                  "🌾",
                  carVal,
                  "${(carVal * 150).toInt()}g",
                  const Color(0xFFC58BF2),
                  isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _nutritionProgress(
    String label,
    String icon,
    double val,
    String amount,
    Color col,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 5),
                Text(icon),
              ],
            ),
            Text(
              amount,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 🔥 Task 4: Local Storage se interaction track karna
        InkWell(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_checked_nutrition', label);
            _showSnackBar("Detail view for $label coming soon!");
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: val, // Ye value ab Firebase se dynamic hogi
              minHeight: 12,
              backgroundColor: isDark
                  ? Colors.white10
                  : const Color(0xFFF7F8F8),
              valueColor: AlwaysStoppedAnimation<Color>(col),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddMealSheet(BuildContext context) {
    // 🔥 Haptic feedback for professional feel
    // HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Round corners ke liye
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D1B20) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Content ke mutabiq height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Grab Handle ---
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              Text(
                "Choose Category",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select a meal time to log your nutrition data",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // --- Options List ---
              _sheetOption(
                "Breakfast",
                Icons.wb_sunny_rounded,
                const Color(0xFF92A3FD),
                isDark,
                () => _addNewMealAction("Breakfast"),
              ),
              _sheetOption(
                "Lunch",
                Icons.fastfood_rounded,
                const Color(0xFFC58BF2),
                isDark,
                () => _addNewMealAction("Lunch"),
              ),
              _sheetOption(
                "Snacks",
                Icons.cookie_rounded,
                const Color(0xFF1AD2A4),
                isDark,
                () => _addNewMealAction("Snacks"),
              ),
              _sheetOption(
                "Dinner",
                Icons.nightlight_round_rounded,
                Colors.orangeAccent,
                isDark,
                () => _addNewMealAction("Dinner"),
              ),
              const SizedBox(height: 15), // Bottom spacing
            ],
          ),
        );
      },
    );
  }

  Widget _sheetOption(
    String title,
    IconData icon,
    Color col,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: col, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isDark ? Colors.white38 : Colors.black26,
        ),
        onTap: onTap,
      ),
    );
  }

  // --- 🔥 Task 11: Floating Add Button Widget ---
  Widget _buildAddButton() {
    return FloatingActionButton(
      onPressed: () {
        // Yeh function bottom sheet kholne ke liye call hota hai
        _showAddMealSheet(context);
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B50F6), Color(0xFFCC8FED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF92A3FD).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
