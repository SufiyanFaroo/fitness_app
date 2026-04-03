import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/services/SleepService.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/view/sleep_tracker/sleep_schedule.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Chart ke liye zaroori hai
import 'package:shared_preferences/shared_preferences.dart';

class SleepTrackerView extends StatefulWidget {
  const SleepTrackerView({super.key});

  @override
  State<SleepTrackerView> createState() => _SleepTrackerViewState();
}

class _SleepTrackerViewState extends State<SleepTrackerView> {
  final SleepService _sleepService = SleepService();
  bool isBedtimeEnabled = true;
  bool isAlarmEnabled = true;
  String bedTimeText = "09:00pm"; // Initial value
  String alarmTimeText = "05:10am"; // Initial value
  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  // --- Task 9: Get Status from Local Storage ---
  // Future<bool> getLocalStatus(String key) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   // 'sleep_' prefix wahi hona chahiye jo aapne updateSleepSettings mein rakha hai
  //   return prefs.getBool('sleep_$key') ?? false;
  // }
  // --- Task 9: App khulte hi Local Storage se settings load karna ---
  Future<void> _loadLocalSettings() async {
    // Service se purana data mangwana
    bool bedtime = await _sleepService.getLocalStatus("bedtime");
    bool alarm = await _sleepService.getLocalStatus("alarm");

    // UI ko refresh karna naye data ke sath
    if (mounted) {
      setState(() {
        isBedtimeEnabled = bedtime;
        isAlarmEnabled = alarm;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      appBar: _buildAppBar(isDark),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _sleepService.getSleepData(),
        builder: (context, snapshot) {
          String sleepDuration = "8h 20m"; // Default
          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            sleepDuration = data['last_night_sleep'] ?? "8h 20m";
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildSleepChartSection(isDark),
                // Dynamic Sleep Duration pass karna
                _buildLastNightSleepBanner(isDark, sleepDuration),
                _buildDailySleepBanner(isDark),
                _buildAlarmSection(isDark),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Header Chart Section ---
  Widget _buildSleepChartSection(bool isDark) {
    return Container(
      height: 240, // Labels aur Tooltip ke liye thori aur space
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 15),
      padding: const EdgeInsets.only(right: 25, left: 5),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _sleepService.getSleepData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildChartLoadingPlaceholder(isDark);
          }

          List<FlSpot> spots = _getDynamicSpots(snapshot);
          int todayIndex = DateTime.now().weekday % 7;

          return LineChart(
            LineChartData(
              // --- 1. PREMIUM TOUCH INTERACTION ---
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                  // 🔥 Task 11: Jab user touch kare toh halki vibration (Haptic) ho
                  if (event is FlPanUpdateEvent || event is FlTapUpEvent) {
                    // HapticFeedback.selectionClick(); // Isay enable kar sakte hain
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (LineBarSpot touchedSpot) =>
                      isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  tooltipBorderRadius: BorderRadius.circular(12),
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  tooltipMargin: 15,
                  // Shadow effect for premium feel
                  showOnTopOfTheChartBoxArea: false,
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      bool isIncrease =
                          spot.y > 7; // Example logic: 7h se ooper 'Good'
                      return LineTooltipItem(
                        "${spot.y}h Sleep\n",
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: isIncrease
                                ? "⬆ 12% vs last week"
                                : "⬇ Below Goal",
                            style: TextStyle(
                              color: isIncrease
                                  ? const Color(0xFF42D3A5)
                                  : Colors.orangeAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
                // Custom Vertical Line Indicator
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: const Color(0xFF42D3A5).withValues(alpha: 0.2),
                        strokeWidth: 4, // Thicker indicator for modern look
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 6,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: const Color(0xFF42D3A5),
                            ),
                      ),
                    );
                  }).toList();
                },
              ),

              // --- 2. CLEAN GRID & AXIS ---
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (val, meta) =>
                        _buildBottomTitle(val, todayIndex),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (val, meta) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        "${val.toInt()}h",
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),

              // --- 3. THE GLOWING GRADIENT LINE ---
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.4, // Smoother curves
                  preventCurveOverShooting: true,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF42D3A5),
                      Color(0xFF92A3FD),
                    ], // Green to Blue fade
                  ),
                  barWidth: 5, // Slightly thicker line
                  isStrokeCapRound: true,
                  dotData: const FlDotData(
                    show: false,
                  ), // Hide dots until touched
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF42D3A5).withValues(alpha: 0.25),
                        const Color(0xFF42D3A5).withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Loading Shimmer Effect (Task 11) ---
  Widget _buildChartLoadingPlaceholder(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: const Color(0xFF92A3FD),
        strokeWidth: 2,
      ),
    );
  }

  // --- Firebase se Spots nikalne ka Logic (Task 12) ---
  List<FlSpot> _getDynamicSpots(AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (snapshot.hasData && snapshot.data!.exists) {
      var data = snapshot.data!.data() as Map<String, dynamic>;
      if (data['weekly_sleep'] != null) {
        List<dynamic> dbSpots = data['weekly_sleep'];
        return List.generate(
          dbSpots.length,
          (i) => FlSpot(i.toDouble(), dbSpots[i].toDouble()),
        );
      }
    }
    // Default Fallback Spots agar data na ho
    return const [
      FlSpot(0, 3),
      FlSpot(1, 5),
      FlSpot(2, 4),
      FlSpot(3, 6),
      FlSpot(4, 5.5),
      FlSpot(5, 8),
      FlSpot(6, 9),
    ];
  }

  // --- Dynamic Day Label Helper ---
  String _getDayLabel(int index) {
    return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][index % 7];
  }

  // --- Professional Bottom Title Design ---
  Widget _buildBottomTitle(double val, int todayIndex) {
    bool isToday = val.toInt() == todayIndex;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _getDayLabel(val.toInt()),
        style: TextStyle(
          color: isToday ? const Color(0xFF42D3A5) : Colors.grey,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
    );
  }

  // --- Last Night Sleep Card ---
  // --- Last Night Sleep Card (Updated to accept sleepDuration) ---
  Widget _buildLastNightSleepBanner(bool isDark, String sleepDuration) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 180,
      decoration: BoxDecoration(
        // 🔥 Premium Vibrant Gradient
        gradient: const LinearGradient(
          colors: [Color(0xFF00FAD9), Color(0xFF1AD2A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FAD9).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // --- Custom Painted Waves for Depth ---
          Positioned.fill(child: CustomPaint(painter: WavePainter())),

          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Last Night Sleep",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    // 🔥 Task 12: Sync Indicator
                    Icon(
                      Icons.cloud_done_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // --- Dynamic Data from Firebase ---
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Text(
                        sleepDuration, // 🔥 Firebase value
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32, // Thora bara font for impact
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins', // Fitness apps standard font
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // --- Task 4: Offline Status Message ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Check your deep sleep cycles",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Daily Sleep Schedule Banner ---
  Widget _buildDailySleepBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        // 🔥 Premium Glassmorphism Effect
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF2E8FF),
        borderRadius: BorderRadius.circular(22), // Thora aur rounded
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.white,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Sleep Schedule",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1D1617),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Check your bedtime goals",
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
            ],
          ),

          // --- Clickable Check Button with Animation ---
          SizedBox(
            height: 35,
            width: 90,
            child: ElevatedButton(
              onPressed: () => _handleCheckSchedule(),
              style: ElevatedButton.styleFrom(
                // 🔥 Professional Purple Gradient jaisa color
                backgroundColor: const Color(0xFF92A3FD),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                "Check",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🔥 Professional Navigation & Activity Tracking ---
  void _handleCheckSchedule() async {
    // 1. Task 4: Local storage mein track karna ke user ne schedule kab check kiya
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_schedule_access',
      DateTime.now().toIso8601String(),
    );

    // 2. Task 13: Smooth Page Transition
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SleepScheduleView()),
    );
  }

  Widget _buildAlarmSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today Schedule",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // 1. Bedtime Alarm
          _alarmTile(
            "Bedtime",
            bedTimeText,
            _calculateTimeLeft(
              bedTimeText,
            ), // 🔥 Static text ki jagah ye function call karein
            "assets/images/Bed.png",
            isBedtimeEnabled,
            (v) async {
              setState(() => isBedtimeEnabled = v);
              await _sleepService.updateSleepSettings("bedtime_enabled", v);
            },
            isDark,
          ),

          const SizedBox(height: 15),

          _alarmTile(
            "Alarm",
            alarmTimeText,
            _calculateTimeLeft(
              alarmTimeText,
            ), // 🔥 Yahan bhi function call karein
            "assets/images/Alaarm.png",
            isAlarmEnabled,
            (v) async {
              setState(() => isAlarmEnabled = v);
              await _sleepService.updateSleepSettings("alarm_enabled", v);
            },
            isDark,
          ),
        ],
      ),
    );
  }

  String _calculateTimeLeft(String timeStr) {
    try {
      // 1. Current Time lena
      DateTime now = DateTime.now();

      // 2. Alarm string (e.g., "09:00pm") ko parse karna
      // Note: TimeOfDay se DateTime banana parta hai farq nikalne ke liye
      int hour = int.parse(timeStr.split(':')[0]);
      int minute = int.parse(timeStr.split(':')[1].substring(0, 2));
      if (timeStr.contains('pm') && hour != 12) hour += 12;
      if (timeStr.contains('am') && hour == 12) hour = 0;

      DateTime alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

      // Agar alarm ka waqt guzar gaya hai toh kal ka din set karein
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      // 3. Farq (Duration) nikalna
      Duration diff = alarmTime.difference(now);

      return "in ${diff.inHours}hours ${diff.inMinutes % 60}minutes";
    } catch (e) {
      return "calculating...";
    }
  }

  Widget _alarmTile(
    String title,
    String time,
    String left,
    String imagePath,
    bool state,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              height: 48,
              width: 48,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 48,
                width: 48,
                color: const Color(0xFF92A3FD).withValues(alpha: 0.1),
                child: const Icon(Icons.alarm, color: Color(0xFF92A3FD)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$title, $time",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  left,
                  style: TextStyle(
                    color: state
                        ? Colors.grey
                        : Colors.redAccent.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: state ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMoreMenu(title, isDark),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: state,
                  onChanged: onChanged,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF00FAD9),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(String title, bool isDark) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) async {
        if (value == 'Edit') {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (pickedTime != null && mounted) {
            String formattedTime = pickedTime.format(context);

            // 🔥 Firebase Sync
            await _sleepService.updateAlarmTime(title, formattedTime);

            // 🔥 UI State Sync: Isse screen refresh hogi
            setState(() {
              if (title == "Bedtime") {
                bedTimeText = formattedTime;
              } else {
                alarmTimeText = formattedTime;
              }
            });

            _showSnackBar("$title updated to $formattedTime");
          }
        } else if (value == 'Delete') {
          _showDeleteConfirmation(title);
        }
      },
      itemBuilder: (context) => [
        _menuItem(
          "Edit",
          "Edit Schedule",
          Icons.edit_outlined,
          const Color(0xFF92A3FD),
        ),
        _menuItem(
          "Delete",
          "Delete Alarm",
          Icons.delete_outline,
          Colors.redAccent,
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete $title?",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("Kya aap waqai is $title ko khatam karna chahte hain?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await _sleepService.deleteAlarm(title);
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar("$title Deleted Successfully");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF92A3FD),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    String title,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 15,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Sleep Tracker",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      actions: [_buildTopRightMenu(isDark)],
    );
  }

  Widget _buildTopRightMenu(bool isDark) {
    return PopupMenuButton<String>(
      icon: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.more_horiz,
          color: isDark ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) {
        if (value == 'History') {
          _showSleepHistoryBottomSheet(isDark); // 🔥 Professional Bottom Sheet
        } else if (value == 'Goal') {
          _showSetGoalDialog(isDark); // 🔥 Professional Dialog
        }
      },
      itemBuilder: (context) => [
        _buildSleepMenuItem(
          "History",
          "Sleep History",
          Icons.history,
          const Color(0xFF92A3FD),
        ),
        _buildSleepMenuItem(
          "Goal",
          "Set Sleep Goal",
          Icons.track_changes,
          const Color(0xFFC58BF2),
        ),
      ],
    );
  }

  // --- 🔥 Professional History Bottom Sheet (Task 12) ---
  void _showSleepHistoryBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Taake full screen cover kar sakay
      backgroundColor: isDark ? const Color(0xFF1D1617) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Sleep History Log",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _sleepService.getSleepData(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    // Firebase se history ka array nikalna
                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    List<dynamic> history = data['sleep_history'] ?? [];

                    if (history.isEmpty) {
                      return const Center(
                        child: Text(
                          "No history found yet!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Colors.black12, // Isse line halki ho jayegi
                      ),
                      itemBuilder: (context, index) {
                        var item = history[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF92A3FD,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.nightlight_round,
                              color: Color(0xFF92A3FD),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            item['date'] ?? "N/A",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            "${item['duration']} Sleep Duration",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            item['status'] ?? "Good",
                            style: const TextStyle(
                              color: Color(0xFF42D3A5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 🔥 Professional Set Goal Dialog (Task 13) ---
  void _showSetGoalDialog(bool isDark) {
    TextEditingController goalController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Set Daily Sleep Goal"),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Enter hours (e.g. 8)",
            suffixText: "hours",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF92A3FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (goalController.text.isNotEmpty) {
                // Firebase Sync Logic
                await _sleepService.updateSleepSettings(
                  "daily_goal",
                  goalController.text,
                );
                Navigator.pop(context);
                _showSnackBar("Goal updated to ${goalController.text} hours!");
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 🔥 Professional Menu Item Helper ---
  PopupMenuItem<String> _buildSleepMenuItem(
    String value,
    String title,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    var path = Path();

    // Figma style ki 3 decorative waves
    for (int i = 0; i < 3; i++) {
      double yOffset = size.height * 0.7 + (i * 8);
      path.moveTo(0, yOffset);
      path.quadraticBezierTo(
        size.width * 0.35,
        yOffset - 20,
        size.width * 0.65,
        yOffset + 10,
      );
      path.quadraticBezierTo(
        size.width * 0.85,
        yOffset + 30,
        size.width,
        yOffset - 10,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
