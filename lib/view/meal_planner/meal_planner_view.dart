import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/services/MealService.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/view/meal_planner/breakfast_view.dart';
import 'package:fitness_app/view/meal_planner/dinner_view.dart';
import 'package:fitness_app/view/meal_planner/lunch_view.dart';
import 'package:fitness_app/view/meal_planner/meal_schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

class MealPlannerView extends StatefulWidget {
  const MealPlannerView({super.key});

  @override
  State<MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends State<MealPlannerView> {
  // Function to fetch data based on Weekly/Monthly selection
  void _fetchNutritionData(String period) {
    debugPrint("Fetching $period data from Firebase...");

    // Yahan aap StreamBuilder ko update karenge ya
    // MealService se naya data fetch karenge
    if (period == "Weekly") {
      // Logic for weekly stats
    } else {
      // Logic for monthly stats
    }
  }

  // Service instance
  final MealService _mealService = MealService();

  String selectedMealType = "Breakfast";
  bool isSalmonNotify = true;
  bool isMilkNotify = false;
  String selectedPeriod = "Weekly";

  @override
  void initState() {
    super.initState();
    _loadLocalSettings(); // Screen khulne par local settings load karein
  }

  // 🔥 Local Storage se data nikalna
  Future<void> _loadLocalSettings() async {
    bool salmon = await _mealService.getNotifyStatus("salmon_nigiri");
    bool milk = await _mealService.getNotifyStatus("lowfat_milk");
    if (mounted) {
      setState(() {
        isSalmonNotify = salmon;
        isMilkNotify = milk;
      });
    }
  }

  // 🔥 Firebase aur Local Storage par save karna
  void _updateNotify(String id, bool currentVal) async {
    bool newVal = !currentVal;
    await _mealService.saveNotifyStatus(id, newVal);

    if (!mounted) return; // 👈 Ye lazmi rakhein

    setState(() {
      if (id == "salmon_nigiri") isSalmonNotify = newVal;
      if (id == "lowfat_milk") isMilkNotify = newVal;
    });
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNutritionHeader(isDark),
            const SizedBox(height: 10),
            // Dynamic Graph
            _buildNutritionGraph(isDark),
            const SizedBox(height: 25),
            _buildDailyMealBanner(isDark),
            const SizedBox(height: 25),
            _buildTodayMealsSection(isDark),
            const SizedBox(height: 25),
            _buildFindFoodSection(isDark),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 1. Main Graph Widget with Real-time Listener
  Widget _buildNutritionGraph(bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      // 🔥 MealService se connection
      stream: _mealService.getNutritionData(),
      builder: (context, snapshot) {
        // UI ko Stack mein rakha hai taake Tags upar float karein
        return Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, right: 10),
              // Graph data logic
              child: LineChart(_getChartData(isDark)),
            ),

            // --- UI Tags (Same as your design) ---
            Positioned(
              top: 0,
              left: 10,
              child: _nutritionTag(
                "Calories: 82% ↑",
                const Color(0xFF92A3FD),
                isDark,
              ),
            ),
            Positioned(
              top: 0,
              right: 10,
              child: _nutritionTag(
                "Fibre: 88% ↑",
                const Color(0xFFC58BF2),
                isDark,
              ),
            ),
            Positioned(
              bottom: 120,
              left: 20,
              child: _nutritionTag(
                "Sugar: 38% ↓",
                const Color(0xFFEEA4CE),
                isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  // 2. Chart Data Logic (Weekly vs Monthly)
  LineChartData _getChartData(bool isDark) {
    // Spots switching based on selectedPeriod
    List<FlSpot> spots = selectedPeriod == "Weekly"
        ? [
            const FlSpot(0, 30),
            const FlSpot(1, 40),
            const FlSpot(2, 35),
            const FlSpot(3, 50),
            const FlSpot(4, 40),
            const FlSpot(5, 60),
            const FlSpot(6, 50),
          ]
        : [
            const FlSpot(0, 20),
            const FlSpot(1, 50),
            const FlSpot(2, 40),
            const FlSpot(3, 70),
            const FlSpot(4, 30),
            const FlSpot(5, 45),
            const FlSpot(6, 80),
          ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (v, m) => Text(
              "${v.toInt()}%",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, m) {
              const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];

              // Prevent Index Error
              int index = v.toInt() % 7;
              String label = selectedPeriod == "Weekly"
                  ? days[index]
                  : months[index];

              bool isSelected = v.toInt() == 4;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? const Color(0xFFC58BF2) : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [Color(0xFF1AD2A4), Color(0xFF92A3FD)],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1AD2A4).withValues(alpha: 0.2),
                const Color(0xFF1AD2A4).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. UI Tag Component (Kept exactly same)
  Widget _nutritionTag(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --- Today Meals Section ---
  // 1. Today Meals Section (Main Layout)
  Widget _buildTodayMealsSection(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today Meals",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            // 🔥 Linked with your state and backend
            _customDropdown(selectedMealType, isDark),
          ],
        ),
        const SizedBox(height: 15),

        _mealCard(
          "Salmon Nigiri",
          "Today | 7am",
          "assets/images/food1.1.png",
          isSalmonNotify,
          isDark,
          () => _updateNotify("salmon_nigiri", isSalmonNotify),
        ),

        _mealCard(
          "Lowfat Milk",
          "Today | 8am",
          "assets/images/glassmilk.png",
          isMilkNotify,
          isDark,
          () => _updateNotify("lowfat_milk", isMilkNotify),
        ),
      ],
    );
  }

  // 2. Professional Meal Card (UI Intact)
  Widget _mealCard(
    String title,
    String time,
    String imagePath,
    bool notify,
    bool isDark,
    VoidCallback onNotifyTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
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
      ),
      child: Row(
        children: [
          Container(
            height: 55,
            width: 55,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF92A3FD).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.fastfood, color: Color(0xFF92A3FD)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            // 🔥 Professional handling for long text
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNotifyTap,
            splashRadius: 22,
            icon: Icon(
              notify
                  ? Icons.notifications_none
                  : Icons.notifications_off_outlined,
              color: notify ? const Color(0xFFC58BF2) : Colors.grey.shade300,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Smart Dropdown (Logic + UI)
  Widget _customDropdown(String title, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (String value) async {
        if (value == selectedMealType) return; // 🔥 Optimization

        setState(() {
          selectedMealType = value;
        });

        // 🔥 Backend sync
        try {
          await _mealService.updateNutritionGoals({
            "current_meal_category": value,
            "last_interaction": DateTime.now(),
          });
        } catch (e) {
          debugPrint("Dropdown Sync Error: $e");
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      itemBuilder: (context) => [
        _buildPopupItem(
          "Breakfast",
          Icons.wb_sunny_outlined,
          const Color(0xFF92A3FD),
        ), // 🔥 Color add kiya
        _buildPopupItem(
          "Lunch",
          Icons.light_mode_outlined,
          const Color(0xFFC58BF2),
        ), // 🔥 Color add kiya
        _buildPopupItem(
          "Dinner",
          Icons.nightlight_outlined,
          const Color(0xFFEEA4CE),
        ), // 🔥 Color add kiya
        _buildPopupItem(
          "Snack",
          Icons.fastfood_outlined,
          const Color(0xFF92A3FD),
        ), // 🔥 Color add kiya
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FACFE).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // --- Find Something to Eat Section ---
  // Pehle import karein (File ke bilkul upar)

  // Phir is function ko update karein
  Widget _buildFindFoodSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Find Something to Eat",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Breakfast
              _foodCategoryCard(
                "Breakfast",
                "120+ Foods",
                const Color(0xFFD1FFEA),
                "assets/images/dinner.png",
                isDark,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BreakfastView(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 15),

              // Lunch (Ab ye error nahi dega kyunki file mojud hai)
              _foodCategoryCard(
                "Lunch",
                "130+ Foods",
                const Color(0xFFF2E6FF),
                "assets/images/lunch.png",
                isDark,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LunchView()),
                  );
                },
              ),
              const SizedBox(width: 15),

              // Dinner
              _foodCategoryCard(
                "Dinner",
                "110+ Foods",
                const Color(0xFFE6EFFF),
                "assets/images/dinner.png",
                isDark,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DinnerView()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Clickable Food Category Card ---
  Widget _foodCategoryCard(
    String name,
    String count,
    Color bgColor,
    String imagePath,
    bool isDark,
    VoidCallback onSelect,
  ) {
    // 1. Card Background Gradient Logic
    List<Color> cardGradient;
    if (name == "Breakfast") {
      cardGradient = [const Color(0xFFD1FFEA), const Color(0xFFEFFFF7)];
    } else if (name == "Lunch") {
      cardGradient = [const Color(0xFFF2E6FF), const Color(0xFFF9F5FF)];
    } else if (name == "Dinner") {
      cardGradient = [const Color(0xFFD1FFEA), const Color(0xFFF9F5FF)];
    } else {
      cardGradient = [const Color(0xFFF2E6FF), const Color(0xFFD1FFEA)];
    }

    // 2. Button Gradient Logic
    List<Color> buttonGradient;
    if (name == "Breakfast") {
      buttonGradient = [const Color(0xFF00FAD9), const Color(0xFF00FAD9)];
    } else if (name == "Lunch") {
      buttonGradient = [const Color(0xFFC58BF2), const Color(0xFFEEA4CE)];
    } else {
      buttonGradient = [const Color(0xFF92A3FD), const Color(0xFF9DCEFF)];
    }

    return SizedBox(
      width: 200,
      height: 220,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 200,
              height: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: cardGradient,
                      ),
                color: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    count,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: buttonGradient),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      "Select",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 5,
              child: Image.asset(
                imagePath,
                height: 100,
                width: 100,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.fastfood, size: 50, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMealBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // 1. Banner background (No border here)
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF2E6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Daily Meal Schedule",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          // 2. Gradient "Check" Button
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealScheduleView(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                // 🔥 Yahan Check button ko gradient diya hai
                gradient: const LinearGradient(
                  colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF92A3FD).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Check",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- AppBar with Popup Menu (Three Dots) ---
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black,
              size: 15,
            ),
          ),
        ),
      ),
      title: Text(
        "Meal Planner",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                color: isDark ? Colors.white : Colors.black,
              ),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              onSelected: (value) async {
                try {
                  if (value == "Edit Nutrition Goals") {
                    await _mealService.updateNutritionGoals({
                      "target_kcal": 2000,
                      "updatedAt": DateTime.now(),
                    });
                    if (mounted) _showSnackBar("Goals Synced with Firebase!");
                  } else if (value == "Meal Reminders") {
                    await _mealService.toggleMealReminders(true);
                    if (mounted) _showSnackBar("Reminders Saved Locally!");
                  } else if (value == "Share Diet Plan") {
                    // 🔥 FIX: Yahan 'Meal Planner Plan' pass karein taake error khatam ho
                    await _mealService.shareDietPlan(
                      "FitQuest Meal Planner Plan",
                    );
                    if (mounted) _showSnackBar("Opening Share Menu...");
                  }
                } catch (e) {
                  if (mounted) _showSnackBar("Error: ${e.toString()}");
                }
              },
              itemBuilder: (context) => [
                _buildPopupItem(
                  "Edit Nutrition Goals",
                  Icons.edit,
                  const Color(0xFF92A3FD),
                ),
                _buildPopupItem(
                  "Meal Reminders",
                  Icons.notifications,
                  const Color(0xFFC58BF2),
                ),
                _buildPopupItem(
                  "Share Diet Plan",
                  Icons.share,
                  const Color(0xFF1AD2A4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // Helper to avoid code repetition
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // --- Popup Menu Item Helper ---
  PopupMenuItem<String> _buildPopupItem(
    String title,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // --- Nutrition Header with Switcher ---
  Widget _buildNutritionHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Meal Nutritions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        // Pass the current state to the button
        _dropdownBtn(selectedPeriod, isDark),
      ],
    );
  }

  Widget _dropdownBtn(String text, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          selectedPeriod = value;
        });
        // 🔥 Trigger Firebase Data Fetch based on selection
        _fetchNutritionData(value);
      },
      itemBuilder: (BuildContext context) => [
        _buildPopupItem(
          "Weekly",
          Icons.calendar_view_week,
          const Color(0xFFC58BF2),
        ),
        _buildPopupItem(
          "Monthly",
          Icons.calendar_month,
          const Color(0xFFEEA4CE),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC58BF2), Color(0xFFEEA4CE)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC58BF2).withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
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
}
