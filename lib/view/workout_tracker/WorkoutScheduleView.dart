import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/workout_service.dart'; // Apna service path sahi rakhein

class WorkoutTask {
  final String title;
  final String time;
  final List<Color> colors;
  final double topPosition;
  bool isDone; // Tracking status locally

  WorkoutTask({
    required this.title,
    required this.time,
    required this.colors,
    required this.topPosition,
    this.isDone = false,
  });
}

class WorkoutScheduleView extends StatefulWidget {
  const WorkoutScheduleView({super.key});

  @override
  State<WorkoutScheduleView> createState() => _WorkoutScheduleViewState();
}

class _WorkoutScheduleViewState extends State<WorkoutScheduleView> {
  int selectedDateIndex = 3;
  final WorkoutService _service = WorkoutService(); // Service Instance

  final List<WorkoutTask> tasks = [
    WorkoutTask(
      title: "Ab Workout, 7:30am",
      time: "07:30 AM",
      colors: [const Color(0xFFEEA4CE), const Color(0xFFC150F6)],
      topPosition: 90,
    ),
    WorkoutTask(
      title: "Upperbody Workout, 9am",
      time: "09:00 AM",
      colors: [
        const Color(0xFF92A3FD).withValues(alpha: 0.6),
        const Color(0xFF9DCEFF),
      ],
      topPosition: 180,
    ),
    WorkoutTask(
      title: "Lowerbody Workout, 3pm",
      time: "03:00 PM",
      colors: [const Color(0xFFF7F8F8), const Color(0xFFF7F8F8)],
      topPosition: 540,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // App khulte hi status load karein
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    // Aaj ki select ki hui date nikalna
    DateTime selectedDate = DateTime.now().add(
      Duration(days: selectedDateIndex),
    );
    String dateKey =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    for (var task in tasks) {
      // 🔥 FIXED: Humne ID ke saath dateKey bhi bheji hai
      bool status = await _service.getLocalScheduleStatus(
        "${task.title}_$dateKey",
      );
      if (mounted) {
        setState(() {
          task.isDone = status;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildMonthHeader(isDark),
          const SizedBox(height: 15),
          _buildDateSelector(isDark),
          const SizedBox(height: 20),
          Expanded(child: _buildTimeline(isDark)),
        ],
      ),
      floatingActionButton: _buildFAB(context, isDark),
    );
  }

  // --- POPUP: Backend Sync Connected ---
  void _showWorkoutStatusDialog(WorkoutTask task, bool isDark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1D1B20) : Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const Text(
                        "Workout Schedule",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.more_vert),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title.split(',')[0],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Today | ${task.time}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () async {
                      // 🔥 SERVICE CALL: Sync to Local and Firebase
                      await _service.updateScheduleStatus(task.title, true);
                      setState(() => task.isDone = true);
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(
                        child: Text(
                          "Mark as Done",
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
          ),
        );
      },
    );
  }

  // --- SAVE Button: Test Sync ---
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GestureDetector(
        onTap: () async {
          // Firebase test save
          await _service.updateScheduleStatus(
            "Schedule_Saved_${DateTime.now().second}",
            false,
          );
          if (mounted) Navigator.pop(context);
        },
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(
            child: Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- BOTTOM SHEET: Add Schedule (image_f34beb.png) ---
  void _showAddScheduleSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1B20) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            _buildSheetHeader(isDark),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: Colors.grey),
                  SizedBox(width: 10),
                  Text(
                    "Thu, 27 May 2022",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Time",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Scrolling Time Picker logic
            SizedBox(
              height: 120,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                onDateTimeChanged: (val) {},
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Details Workout",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _buildDetailTile(
              Icons.fitness_center,
              "Choose Workout",
              "Upperbody Workout",
              isDark,
            ),
            _buildDetailTile(Icons.swap_vert, "Difficulty", "Beginner", isDark),
            _buildDetailTile(Icons.repeat, "Custom Repetitions", "", isDark),
            _buildDetailTile(
              Icons.monitor_weight_outlined,
              "Custom Weights",
              "",
              isDark,
            ),
            const Spacer(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // Helper logic for Timeline
  Widget _buildTimeline(bool isDark) {
    List<String> times = [
      "06:00 AM",
      "07:00 AM",
      "08:00 AM",
      "09:00 AM",
      "10:00 AM",
      "11:00 AM",
      "12:00 PM",
      "01:00 PM",
      "02:00 PM",
      "03:00 PM",
      "04:00 PM",
      "05:00 PM",
      "06:00 PM",
      "07:00 PM",
    ];
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Stack(
        children: [
          Column(
            children: times
                .map(
                  (time) => Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 65,
                          child: Text(
                            time,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          ...tasks.map(
            (task) => Positioned(
              top: task.topPosition,
              left: task.title.contains("Lowerbody")
                  ? MediaQuery.of(context).size.width * 0.28
                  : (task.title.contains("Upperbody") ? 95 : null),
              right: task.title.contains("Ab Workout") ? 20 : null,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showWorkoutStatusDialog(task, isDark),
                  borderRadius: BorderRadius.circular(25),
                  child: _workoutCard(task, isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for UI consistency
  Widget _buildSheetHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Add Schedule",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.more_horiz),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String title,
    String val,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(val, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  // Existing UI Widgets (AppBar, FAB, etc.)
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _appBarIconButton(
        Icons.arrow_back_ios_new,
        isDark,
        () => Navigator.pop(context),
      ),
      title: Text(
        "Workout Schedule",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          // 🔥 FIXED: Custom widget ki jagah simple Container dein taake conflict na ho
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.more_horiz,
              color: isDark ? Colors.white : Colors.black,
              size: 16,
            ),
          ),
          itemBuilder: (context) => [
            _buildPopupItem("Refresh", Icons.refresh, isDark),
            _buildPopupItem("Clear All", Icons.delete_outline, isDark),
            _buildPopupItem("Settings", Icons.settings, isDark),
          ],
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // 1. Menu Items Design Helper
  // 1. Popup UI (Same as yours, no UI change)
  PopupMenuItem<String> _buildPopupItem(
    String title,
    IconData icon,
    bool isDark,
  ) {
    return PopupMenuItem(
      value: title.toLowerCase().replaceAll(' ', '_'),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }

  // 2. Action Logic (Firebase & Local Sync)
  // 1. Action Handling Logic
  void _handleMenuAction(String value) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (value == "refresh") {
      _loadStatuses(); // Firebase se data reload hoga
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Schedule Synced! 🔥")));
    } else if (value == "clear_all") {
      _service.clearAllSchedules(); // Service call
      setState(() {
        for (var task in tasks) {
          task.isDone = false;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All tasks cleared! 🗑️")));
    } else if (value == "settings") {
      // 🔥 Settings click fix
      _showSettingsSheet(context, isDark);
    }
  }

  // 2. Settings BottomSheet Function
  void _showSettingsSheet(BuildContext context, bool isDark) {
    var themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        // FutureBuilder use karenge taake local storage se value load ho sake
        return FutureBuilder<bool>(
          future: _service.getSettingLocally(
            'reminders',
          ), // Service se value mangwao
          builder: (context, snapshot) {
            bool reminderValue =
                snapshot.data ?? true; // Default true agar data na mile

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 25,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Workout Settings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 1. Working Reminder Switch
                      SwitchListTile(
                        secondary: Icon(
                          Icons.notifications_active_outlined,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        title: const Text("Workout Reminders"),
                        subtitle: const Text(
                          "Notify me before workout",
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: const Color(0xFF92A3FD),
                        value: reminderValue, // 🔥 FIXED: Variable connected
                        onChanged: (bool newValue) async {
                          // A. Local storage aur Firebase mein sync karein
                          await _service.saveSetting('reminders', newValue);

                          // B. Modal ki UI refresh karein
                          setModalState(() {
                            reminderValue = newValue;
                          });
                        },
                      ),

                      // 2. Theme Switch (Already Fixed)
                      SwitchListTile(
                        secondary: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        title: const Text("Dark Mode"),
                        subtitle: Text(
                          isDark ? "Dark theme ON" : "Light theme ON",
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: const Color(0xFFC150F6),
                        value: isDark,
                        onChanged: (bool value) {
                          themeProvider.toggleTheme(
                            value,
                          ); // Fixed positional argument
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 1. Month Header (Real-Time)
  Widget _buildMonthHeader(bool isDark) {
    // Aaj ki date se month aur year nikalna
    DateTime now = DateTime.now();
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
    String currentMonthYear = "${months[now.month - 1]} ${now.year}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chevron_left, color: Colors.grey.shade400, size: 20),
        const SizedBox(width: 15),
        Text(
          currentMonthYear, // 🔥 Ab ye real month dikhayega
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 15),
        Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
      ],
    );
  }

  // 2. Date Selector (Real-Time 7 Days)
  Widget _buildDateSelector(bool isDark) {
    DateTime today = DateTime.now();

    // Dino ke naam nikalne ke liye list
    List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 7, // Agle 7 din
        itemBuilder: (context, index) {
          // Aaj ki date mein index plus karke agla din nikalna
          DateTime displayDate = today.add(Duration(days: index));
          String dayName = weekDays[displayDate.weekday - 1];
          String dayNumber = displayDate.day.toString();

          bool isSelected = selectedDateIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDateIndex = index;
              });
              // 🔥 Date change hote hi statuses load karein
              _loadStatuses();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 70,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFEEA4CE), Color(0xFFC150F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected
                    ? (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF7F8F8))
                    : null,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName, // Real Day Name
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dayNumber, // Real Day Number
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  Widget _workoutCard(WorkoutTask task, bool isDark) {
    bool isLight = task.title.contains("Lowerbody");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: isLight ? null : LinearGradient(colors: task.colors),
        color: isLight
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFF7F8F8))
            : null,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        task.title,
        style: TextStyle(
          color: isLight ? Colors.grey : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _appBarIconButton(IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => _showAddScheduleSheet(isDark), // FAB connection to Add Page
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
