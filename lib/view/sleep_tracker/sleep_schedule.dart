import 'package:fitness_app/data/services/SleepService.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/view/sleep_tracker/add_alarm_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this
import 'package:share_plus/share_plus.dart';

class SleepScheduleView extends StatefulWidget {
  const SleepScheduleView({super.key});

  @override
  State<SleepScheduleView> createState() => _SleepScheduleViewState();
}

class _SleepScheduleViewState extends State<SleepScheduleView> {
  final SleepService _sleepService = SleepService(); // 🔥 Service Initialize
  int selectedCalendarIndex = 4;

  // Local state for UI responsiveness
  bool isBedtimeEnabled = true;
  bool isAlarmEnabled = true;
  String bedTimeText = "09:00pm";
  String alarmTimeText = "05:10am";

  @override
  void initState() {
    super.initState();
    _loadLocalSettings(); // 🔥 Task 9: Load from Cache
  }

  Future<void> _loadLocalSettings() async {
    bool bedtime = await _sleepService.getLocalStatus("bedtime_enabled");
    bool alarm = await _sleepService.getLocalStatus("alarm_enabled");
    setState(() {
      isBedtimeEnabled = bedtime;
      isAlarmEnabled = alarm;
    });
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      appBar: _buildAppBar(isDark),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _sleepService.getSleepData(), // 🔥 Task 12: Real-time Stream
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;

            // Sync Firebase data to UI
            var settings = data['sleep_settings'] ?? {};
            var alarms = data['alarms'] ?? {};

            isBedtimeEnabled = settings['bedtime_enabled'] ?? isBedtimeEnabled;
            isAlarmEnabled = settings['alarm_enabled'] ?? isAlarmEnabled;

            bedTimeText = alarms['Bedtime']?['time'] ?? bedTimeText;
            alarmTimeText = alarms['Alarm']?['time'] ?? alarmTimeText;

            // 🔥 Task 4: Cache this fresh data
            _sleepService.cacheSleepData(data);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdealSleepBanner(isDark),
                const SizedBox(height: 30),
                const Text(
                  "Your Schedule",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildCalendarRow(isDark),
                const SizedBox(height: 30),

                // --- Bedtime Tile ---
                _buildScheduleTile(
                  "Bedtime, $bedTimeText",
                  _calculateTimeLeft(bedTimeText),
                  "assets/images/Bed.png",
                  isBedtimeEnabled,
                  (v) async {
                    setState(() => isBedtimeEnabled = v);
                    await _sleepService.updateSleepSettings(
                      "bedtime_enabled",
                      v,
                    );
                  },
                  isDark,
                ),
                const SizedBox(height: 15),

                // --- Alarm Tile ---
                _buildScheduleTile(
                  "Alarm, $alarmTimeText",
                  _calculateTimeLeft(alarmTimeText),
                  "assets/images/Alarrm.png",
                  isAlarmEnabled,
                  (v) async {
                    setState(() => isAlarmEnabled = v);
                    await _sleepService.updateSleepSettings("alarm_enabled", v);
                  },
                  isDark,
                ),
                const SizedBox(height: 25),
                _buildProgressCard(isDark),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAlarmView()),
          );
        },
        backgroundColor: const Color(0xFF00FAD9),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // Helper: Time Left Calculation
  String _calculateTimeLeft(String timeStr) {
    try {
      DateTime now = DateTime.now();
      int hour = int.parse(timeStr.split(':')[0]);
      int minute = int.parse(timeStr.split(':')[1].substring(0, 2));
      if (timeStr.toLowerCase().contains('pm') && hour != 12) hour += 12;
      if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;
      DateTime alarmTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (alarmTime.isBefore(now))
        alarmTime = alarmTime.add(const Duration(days: 1));
      Duration diff = alarmTime.difference(now);
      return "in ${diff.inHours}hours ${diff.inMinutes % 60}minutes";
    } catch (e) {
      return "calculating...";
    }
  }

  // --- UI Widgets remain same but linked with Service ---
  Widget _buildScheduleTile(
    String title,
    String time,
    String img,
    bool state,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    String cleanTitle = title.split(',')[0].trim(); // Get "Bedtime" or "Alarm"
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        children: [
          Image.asset(
            img,
            height: 45,
            width: 45,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.alarm, color: Color(0xFF92A3FD)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPopupMenu(cleanTitle), // 🔥 Logic for Edit/Delete
              const SizedBox(height: 2),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: state,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF00FAD9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(String title) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      onSelected: (value) async {
        if (value == "Edit") {
          TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (picked != null) {
            await _sleepService.updateAlarmTime(title, picked.format(context));
          }
        } else if (value == "Delete") {
          await _sleepService.deleteAlarm(title);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: "Edit", child: Text("Edit")),
        const PopupMenuItem(value: "Delete", child: Text("Delete")),
      ],
    );
  }

  void _onLearnMorePressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // Background transparent rakhein taake rounded corners nazar aayen
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.75, // 75% screen cover karega
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // --- Handle Bar ---
              const SizedBox(height: 12),
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 25),
              const Text(
                "Sleep Science 101",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Why your body needs 8 hours",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 25),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // --- Custom Illustration Card ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 40,
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "Deep sleep helps your brain flush out toxins and solidify memories.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Real App Style Benefit Tiles ---
                    _buildEliteBenefitTile(
                      icon: Icons.psychology_outlined,
                      title: "Mental Performance",
                      desc:
                          "Improves reaction time and cognitive function by 30%.",
                      color: const Color(0xFFC58BF2),
                    ),
                    _buildEliteBenefitTile(
                      icon: Icons.bolt_rounded,
                      title: "Metabolism Boost",
                      desc:
                          "Helps regulate hunger hormones (Ghrelin & Leptin).",
                      color: const Color(0xFF92A3FD),
                    ),
                    _buildEliteBenefitTile(
                      icon: Icons.shield_moon_outlined,
                      title: "Immune Support",
                      desc:
                          "Strengthens your immune system to fight off viruses.",
                      color: const Color(0xFF42D3A5),
                    ),

                    const SizedBox(height: 20),
                    // --- Action Button to Close ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF92A3FD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Got it, Thanks!",
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
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper Widget for Elite Tiles
  Widget _buildEliteBenefitTile({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _sleepService.getSleepData(), // 🔥 Real-time Firebase data
      builder: (context, snapshot) {
        // Default values agar data load na ho
        int h = 8;
        int m = 0;
        double p = 1.0;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          var alarms = data['alarms'] ?? {};

          // Firebase se real-time timings uthana
          String bed = alarms['Bedtime']?['time'] ?? "09:00pm";
          String alarm = alarms['Alarm']?['time'] ?? "05:10am";

          // 🔥 Calculation Logic call karna
          var stats = _calculateSleepProgress(bed, alarm);
          h = stats['h'];
          m = stats['m'];
          p = stats['p'];
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF92A3FD).withValues(alpha: 0.1)
                : const Color(0xFFF2E8FF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC150F6).withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "You will get "),
                    TextSpan(
                      text: "$h",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFC150F6),
                      ),
                    ),
                    const TextSpan(text: " hours "),
                    TextSpan(
                      text: "$m",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFC150F6),
                      ),
                    ),
                    const TextSpan(text: " minutes\n"),
                    TextSpan(
                      text: "for tonight based on your schedule",
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- Animated Progress Bar ---
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 18,
                  width: double.infinity,
                  color: isDark ? Colors.white10 : Colors.white,
                  child: Stack(
                    children: [
                      // 🔥 p ki value ke mutabiq width khud barhay gi
                      AnimatedFractionallySizedBox(
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        widthFactor: p.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFC150F6), Color(0xFFEEA4CE)],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "${(p * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Baqi Helper Functions ---
  Widget _buildIdealSleepBanner(bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _sleepService.getSleepData(),
      builder: (context, snapshot) {
        // --- 1. Loading State Handling ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerPlaceholder(
            isDark,
          ); // Niche placeholder function hai
        }

        // --- 2. Data Extraction ---
        String idealHours = "08hours 00minutes"; // Default
        if (snapshot.hasData && snapshot.data!.exists) {
          try {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            var goal = data['sleep_settings']?['daily_goal'] ?? "8";
            // Formatting: Agar 1 digit ho toh 08 ban jaye
            String formattedGoal = goal.toString().padLeft(2, '0');
            idealHours = "${formattedGoal}hours 00minutes";
          } catch (e) {
            debugPrint("Banner Data Error: $e");
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF92A3FD).withValues(alpha: 0.15),
                      const Color(0xFF9DCEFF).withValues(alpha: 0.15),
                    ]
                  : [const Color(0xFFF2E8FF), const Color(0xFFE8F1FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ideal Hours for Sleep",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 🔥 AnimatedSwitcher: Jab time badlay toh smooth transition ho
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        idealHours,
                        key: ValueKey(idealHours),
                        style: const TextStyle(
                          color: Color(0xFF9B81FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () => _onLearnMorePressed(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B81FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Learn More",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Decorative Section ---
              _buildDecorativeMoon(),
            ],
          ),
        );
      },
    );
  }

  // --- 🔥 Loading Placeholder (Task 11: UX Improvement) ---
  Widget _buildBannerPlaceholder(bool isDark) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  // --- 🔥 Reusable Moon Widget ---
  Widget _buildDecorativeMoon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF9B81FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
        ),
        Image.asset(
          "assets/images/moon.png",
          height: 85,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const Icon(
            Icons.nightlight_round,
            size: 55,
            color: Color(0xFF9B81FF),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarRow(bool isDark) {
    // 🔥 Task 11: Generate dynamic dates for the current week
    DateTime now = DateTime.now();

    // Aaj se pichle 2 din aur agle 4 din dikhane ka logic (Total 7 days)
    List<DateTime> weekDates = List.generate(7, (index) {
      return now.add(Duration(days: index - 2));
    });

    List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(weekDates.length, (index) {
          DateTime dateObj = weekDates[index];
          bool isToday =
              dateObj.day == now.day &&
              dateObj.month == now.month &&
              dateObj.year == now.year;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedCalendarIndex = index);
                // Yahan aap specific date ka data Firebase se fetch kar sakte hain
              },
              child: _CalendarItem(
                weekDays[dateObj.weekday - 1], // Day Name (Mon, Tue...)
                dateObj.day.toString().padLeft(2, '0'), // Date (01, 15...)
                selectedCalendarIndex == index,
                isToday, // Naya parameter "Aaj ki date" highlight karne ke liye
              ),
            ),
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Text(
        "Sleep Schedule",
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
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.more_horiz,
          color: isDark ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
      offset: const Offset(0, 55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) async {
        if (value == "Reset") {
          _showResetConfirmation(); // 🔥 Reset Logic
        } else if (value == "Export") {
          _handleExportData(); // 🔥 Export Logic
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          "Reset",
          "Reset Schedule",
          Icons.refresh,
          const Color(0xFF92A3FD),
        ),
        _buildPopupItem(
          "Export",
          "Export Report",
          Icons.ios_share,
          const Color(0xFFC58BF2),
        ),
      ],
    );
  }

  // --- 🔥 Reset Functionality (Task 10 & 13) ---
  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Schedule?"),
        content: const Text(
          "Kya aap waqai apni saari sleep settings default par set karna chahte hain?",
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
              // 1. Firebase Reset
              await _sleepService.updateSleepSettings("bedtime_enabled", true);
              await _sleepService.updateSleepSettings("alarm_enabled", true);
              await _sleepService.updateAlarmTime("Bedtime", "09:00pm");
              await _sleepService.updateAlarmTime("Alarm", "05:10am");

              if (mounted) {
                Navigator.pop(context);
                _showSnackBar("Schedule Reset to Default Successfully!");
              }
            },
            child: const Text(
              "Reset Now",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🔥 Professional SnackBar for User Feedback (Task 13) ---
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars(); // Purani hatane ke liye
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF92A3FD), // App theme color
        behavior: SnackBarBehavior.floating, // Premium floating look
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- 🔥 Export Functionality (Task 13) ---
  void _handleExportData() {
    // 1. Report ka data tayyar karein
    String report =
        """
📊 FitQuest Sleep Report
------------------------
🗓️ Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
🌙 Bedtime: $bedTimeText
⏰ Wake up: $alarmTimeText
🎯 Target: 8 Hours
✅ Status: ${_calculateSleepProgress(bedTimeText, alarmTimeText)['p'] >= 1.0 ? "Goal Achieved!" : "Keep it up!"}
------------------------
Generated by FitQuest App
""";

    // 2. 🔥 Real App Logic: Share Sheet khulwayein
    // Isse WhatsApp, Gmail, aur Save to Files ke options mil jayenge
    Share.share(report, subject: 'My Sleep Report');

    // Optional: User ko batane ke liye
    _showSnackBar("Opening Share Options...");
  }

  // Helper for Menu Items
  PopupMenuItem<String> _buildPopupItem(
    String value,
    String title,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateSleepProgress(String bed, String alarm) {
    try {
      DateTime now = DateTime.now();

      // Helper function to parse "09:00pm"
      DateTime parseTime(String t) {
        int hr = int.parse(t.split(':')[0]);
        int min = int.parse(t.split(':')[1].substring(0, 2));
        if (t.toLowerCase().contains('pm') && hr != 12) hr += 12;
        if (t.toLowerCase().contains('am') && hr == 12) hr = 0;
        return DateTime(now.year, now.month, now.day, hr, min);
      }

      DateTime bedTime = parseTime(bed);
      DateTime alarmTime = parseTime(alarm);

      if (alarmTime.isBefore(bedTime))
        alarmTime = alarmTime.add(const Duration(days: 1));

      Duration duration = alarmTime.difference(bedTime);
      double hours = duration.inMinutes / 60.0;

      // Percentage based on 8 hours ideal goal
      double percent = (hours / 8.0).clamp(0.0, 1.0);

      return {
        "h": duration.inHours,
        "m": duration.inMinutes % 60,
        "p": percent,
      };
    } catch (e) {
      return {"h": 8, "m": 0, "p": 1.0};
    }
  }
}

class _CalendarItem extends StatelessWidget {
  final String day, date;
  final bool active;
  final bool isToday; // Extra detail for professional look

  const _CalendarItem(this.day, this.date, this.active, this.isToday);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
              )
            : null,
        color: active
            ? null
            : (isToday
                  ? const Color(0xFF92A3FD).withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(15),
        border: isToday && !active
            ? Border.all(color: const Color(0xFF92A3FD), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            date,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          // Chota dot agar aaj ki date hai
          if (isToday && !active)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF92A3FD),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
