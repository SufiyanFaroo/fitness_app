import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view/meal_planner/meal_planner_view.dart';
import '../../data/services/workout_service.dart';

class ActivityTrackerView extends StatefulWidget {
  final VoidCallback onBack;
  const ActivityTrackerView({super.key, required this.onBack});

  @override
  State<ActivityTrackerView> createState() => _ActivityTrackerViewState();
}

class _ActivityTrackerViewState extends State<ActivityTrackerView> {
  List<double> weeklyData = [0.2, 0.5, 0.3, 0.7, 0.4, 0.8, 0.5];
  final WorkoutService _service = WorkoutService();
  String waterIntake = "0L";
  String stepsCount = "0";
  String selectedTime = "Weekly";

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  // 🔄 Fixed Refresh Logic
  Future<void> _loadActivityData() async {
    try {
      // Dono data parallel mein fetch honge taake speed fast ho
      final results = await Future.wait([
        _service.getLocalActivityData("water"),
        _service.getLocalActivityData("steps"),
      ]);

      if (mounted) {
        setState(() {
          waterIntake = results[0];
          stepsCount = results[1];
        });
        debugPrint("✅ Data Synced Successfully");
      }
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
    }
  }

  // 🗑️ Delete Logic linked to onLongPress
  Future<void> _deleteActivity(String docId) async {
    try {
      await _service.deleteActivityLog(docId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Activity removed"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      debugPrint("❌ UI Delete Error: $e");
    }
  }

  void _showGoalInputDialog(String type) {
    TextEditingController controller = TextEditingController();
    String title = type == "water"
        ? "Water Goal (e.g. 5L)"
        : "Steps Goal (e.g. 5000)";

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Set $title",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            hintText: "Enter value",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff92A3FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _service.saveGoal(type, controller.text);
                await _service.logActivity(
                  type == "water"
                      ? "Set Water Goal to ${controller.text}"
                      : "Set Steps Goal to ${controller.text}",
                  type,
                );

                if (mounted) {
                  Navigator.pop(dialogContext);
                  _loadActivityData(); // 🔥 Trigger auto-refresh
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildTodayTargetCard(isDark),
              _buildActivityProgressSection(isDark),
              _buildLatestActivitySection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => widget.onBack(),
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            "Activity Tracker",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          _buildTopMenu(isDark),
        ],
      ),
    );
  }

  Widget _buildTopMenu(bool isDark) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(cardColor: isDark ? const Color(0xFF1D1B20) : Colors.white),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Icon(
          Icons.more_horiz,
          color: isDark ? Colors.white : Colors.black,
        ),
        onSelected: (value) async {
          if (value == 'refresh') {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("🔄 Syncing..."),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
            await _loadActivityData(); // 🔥 Refresh button fixed
          } else if (value == 'settings') {
            _showSettingsSheet(context, isDark);
          }
        },
        itemBuilder: (context) => [
          _popupItem('Refresh', Icons.refresh, isDark, 'refresh'),
          _popupItem('Settings', Icons.settings, isDark, 'settings'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
    String title,
    IconData icon,
    bool isDark,
    String val,
  ) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTargetCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD696D6).withValues(alpha: isDark ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today Target",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              _buildAddButton(isDark),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildSmallTargetItem(
                  waterIntake,
                  "Water Intake",
                  "assets/images/glass 1.png",
                  isDark,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSmallTargetItem(
                  stepsCount,
                  "Foot Steps",
                  "assets/images/shoes1.png",
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return InkWell(
      onTap: () => _showSettingsSheet(context, isDark),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xff92A3FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildLatestActivitySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Latest Activity",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealPlannerView(),
                  ),
                ),
                child: const Text(
                  "See more",
                  style: TextStyle(color: Color(0xff92A3FD), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _service.getLatestActivitiesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xff92A3FD),
                  ),
                ),
              );
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return _buildEmptyState(isDark);

            final activities = snapshot.data!.docs;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = activities[index].data() as Map<String, dynamic>;
                String docId = activities[index].id;
                Timestamp? ts = data['timestamp'] as Timestamp?;
                String timeDisplay = ts != null
                    ? _formatTimestamp(ts)
                    : "Just now";

                return _buildActivityItem(
                  docId,
                  data['title'] ?? 'Activity Update',
                  timeDisplay,
                  data['type'] == 'water'
                      ? "assets/images/Activity-drink.png"
                      : "assets/images/set-steps.png",
                  isDark,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String docId,
    String title,
    String time,
    String imagePath,
    bool isDark,
  ) {
    return InkWell(
      onLongPress: () =>
          _deleteActivity(docId), // 🔥 Delete linked to Long Press
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xff92A3FD).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, color: Colors.grey, size: 40),
          SizedBox(height: 12),
          Text(
            "No Recent Activity Found",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTargetItem(
    String value,
    String title,
    String imagePath,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Image.asset(imagePath, width: 35, height: 35),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xff92A3FD),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityProgressSection(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Activity Progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              _buildTimeFilter(),
            ],
          ),
        ),
        _buildCustomBarChart(isDark),
      ],
    );
  }

  Widget _buildTimeFilter() {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => selectedTime = val),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: "Weekly", child: Text("Weekly")),
        const PopupMenuItem(value: "Monthly", child: Text("Monthly")),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff00FF66), Color(0xff00F0FF)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              selectedTime,
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

  Widget _buildCustomBarChart(bool isDark) {
    List<String> days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          days.length,
          (index) => _bar(days[index], weeklyData[index], index % 2 == 0),
        ),
      ),
    );
  }

  Widget _bar(String day, double factor, bool isCyan) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 140,
              width: 22,
              decoration: BoxDecoration(
                color: const Color(0xffF7F8F8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            Container(
              height: 140 * factor,
              width: 22,
              decoration: BoxDecoration(
                gradient: isCyan
                    ? const LinearGradient(
                        colors: [Color(0xff00FAD9), Color(0xff00FAD9)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xffC58BF2), Color(0xffEEA4CE)],
                      ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: const TextStyle(fontSize: 12, color: Color(0xffB6B6B6)),
        ),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Tracker Settings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.water_drop, color: Color(0xff92A3FD)),
              title: Text(
                "Set Water Goal",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                _showGoalInputDialog("water");
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.directions_walk,
                color: Color(0xffC58BF2),
              ),
              title: Text(
                "Set Steps Goal",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                _showGoalInputDialog("steps");
              },
            ),
          ],
        ),
      ),
    );
  }
}
