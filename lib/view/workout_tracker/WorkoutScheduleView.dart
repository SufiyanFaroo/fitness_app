import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/view/workout_tracker/add_schedule_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/services/workout_service.dart'; // Path verify karlein

class WorkoutScheduleView extends StatefulWidget {
  const WorkoutScheduleView({super.key});

  @override
  State<WorkoutScheduleView> createState() => _WorkoutScheduleViewState();
}

class _WorkoutScheduleViewState extends State<WorkoutScheduleView> {
  final WorkoutService _service = WorkoutService();

  // ✅ DYNAMIC: Tracks active operational calendar focus pipelines natively
  DateTime _focusedCalendarMonth = DateTime.now();
  int selectedDateIndex = 0;

  double _calculateTopPosition(String timeString) {
    try {
      DateTime parsedTime = DateTime.parse(timeString);
      int hour = parsedTime.hour;
      int minute = parsedTime.minute;

      double startingHour = 6.0;
      double currentHourDecimal = hour + (minute / 60.0);
      double verticalDelta = currentHourDecimal - startingHour;

      if (verticalDelta < 0) return 10.0;
      return (verticalDelta * 60.0) + 20.0;
    } catch (e) {
      return 120.0;
    }
  }

  // Helper calculation loop determining total visible horizontal days dynamically
  DateTime _getCalculatedTargetDate(int index) {
    // Generates absolute chronological days baseline mapped relative to the currently scrolled focused month
    DateTime baselineDate = DateTime(
      _focusedCalendarMonth.year,
      _focusedCalendarMonth.month,
      1,
    );

    // If the focused calendar matches current live month parameters, align indices starting from today
    DateTime today = DateTime.now();
    if (_focusedCalendarMonth.month == today.month &&
        _focusedCalendarMonth.year == today.year) {
      return today.add(Duration(days: index));
    }
    return baselineDate.add(Duration(days: index));
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
          _buildMonthHeader(
            isDark,
          ), // ✅ Connected to Month Changer arrow controllers
          const SizedBox(height: 15),
          _buildDateSelector(
            isDark,
          ), // ✅ Automatically loops matching dynamic navigation shifts
          const SizedBox(height: 20),
          Expanded(child: _buildDynamicTimeline(isDark)),
        ],
      ),
      floatingActionButton: _buildFAB(context, isDark),
    );
  }

  Widget _buildDynamicTimeline(bool isDark) {
    DateTime selectedTargetDate = _getCalculatedTargetDate(selectedDateIndex);
    String dateQueryString = DateFormat(
      'yyyy-MM-dd',
    ).format(selectedTargetDate);

    List<String> timelineLabels = [
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

    if (_service.uid.isEmpty) {
      return const Center(
        child: Text("Please authenticate session to view parameters track."),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_service.uid)
          .collection('workout_schedules')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryActive),
          );
        }

        var todaysSchedules = [];
        if (snapshot.hasData) {
          todaysSchedules = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String scheduleTimeRaw = data['scheduleTime'] ?? data['time'] ?? "";
            return scheduleTimeRaw.startsWith(dateQueryString);
          }).toList();
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              Column(
                children: timelineLabels
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
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),

              ...todaysSchedules.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String docId = doc.id;
                String workoutName =
                    data['workoutName'] ?? data['workout'] ?? "Workout";
                String difficulty = data['difficulty'] ?? "Beginner";
                String reps = data['repetitions'] ?? data['reps'] ?? "";
                String weight = data['weight'] ?? "";
                String isoTime =
                    data['scheduleTime'] ??
                    data['time'] ??
                    DateTime.now().toIso8601String();
                bool isCompleted = data['isCompleted'] ?? false;

                DateTime parsedDateTime = DateTime.parse(isoTime);
                String formattedTimeLabel = DateFormat(
                  'hh:mm a',
                ).format(parsedDateTime);
                double computedTopPosition = _calculateTopPosition(isoTime);

                List<Color> cardGradients = [
                  const Color(0xFF92A3FD),
                  const Color(0xFF9DCEFF),
                ];
                if (workoutName.contains("Ab")) {
                  cardGradients = [
                    const Color(0xFFEEA4CE),
                    const Color(0xFFC58BF2),
                  ];
                } else if (isCompleted) {
                  cardGradients = [
                    const Color(0xFF42D3A5),
                    const Color(0xFF2AF598),
                  ];
                }

                return Positioned(
                  top: computedTopPosition,
                  left: 95,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      // ✅ PROFESSIONAL INTERACTION: Triggers dynamic bottom context options menu on tap operations
                      onTap: () => _showActionSheetMenu(docId, data, isDark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: cardGradients),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workoutName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$formattedTimeLabel | $difficulty | $reps | $weight",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ✅ ADVANCED CONTEXT ACTION SHEET: Hosts professional Edit and Delete triggers directly
  void _showActionSheetMenu(
    String docId,
    Map<String, dynamic> currentData,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.blueAccent,
                ),
                title: const Text(
                  "Modify Schedule Configurations",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Change workout categories, target date, times, or metrics reps load",
                ),
                onTap: () {
                  Navigator.pop(context); // Close actions modal sheet
                  // Routes over to creation interface passing existing dictionary maps parameters safely
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddScheduleView(
                        editDocId: docId,
                        existingData: currentData,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  "Purge Schedule Permanently",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Ejects this scheduling document entry completely out of the database",
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _service.deleteWorkoutSchedule(docId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Schedule removed successfully!"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ DYNAMIC MONTH CHANGERS LAYER: Navigates cleanly across year/month tracks smoothly without hardcoding values
  Widget _buildMonthHeader(bool isDark) {
    String monthLabelString = DateFormat(
      'MMMM yyyy',
    ).format(_focusedCalendarMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.grey.shade600),
          onPressed: () => setState(() {
            _focusedCalendarMonth = DateTime(
              _focusedCalendarMonth.year,
              _focusedCalendarMonth.month - 1,
              1,
            );
            selectedDateIndex =
                0; // Reset active tab reference to prevent canvas layout overflows
          }),
        ),
        const SizedBox(width: 15),
        Text(
          monthLabelString,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 15),
        IconButton(
          icon: Icon(Icons.chevron_right, color: Colors.grey.shade600),
          onPressed: () => setState(() {
            _focusedCalendarMonth = DateTime(
              _focusedCalendarMonth.year,
              _focusedCalendarMonth.month + 1,
              1,
            );
            selectedDateIndex = 0;
          }),
        ),
      ],
    );
  }

  Widget _buildDateSelector(bool isDark) {
    DateTime baseDate = DateTime(
      _focusedCalendarMonth.year,
      _focusedCalendarMonth.month,
      1,
    );
    DateTime today = DateTime.now();
    bool isCurrentMonth =
        _focusedCalendarMonth.month == today.month &&
        _focusedCalendarMonth.year == today.year;

    // Calculates total dynamic horizontal scrolling items based on the active month context constraints parameters
    int totalScrolledDaysRange = isCurrentMonth
        ? 14
        : DateTime(
            _focusedCalendarMonth.year,
            _focusedCalendarMonth.month + 1,
            0,
          ).day;

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: totalScrolledDaysRange,
        itemBuilder: (context, index) {
          DateTime displayDate = isCurrentMonth
              ? today.add(Duration(days: index))
              : baseDate.add(Duration(days: index));
          String dayName = DateFormat('E').format(displayDate);
          String dayNumber = displayDate.day.toString();
          bool isSelected = selectedDateIndex == index;

          return GestureDetector(
            onTap: () => setState(() => selectedDateIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
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
                    ? (isDark ? Colors.white10 : const Color(0xFFF7F8F8))
                    : null,
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
                  const SizedBox(height: 5),
                  Text(
                    dayNumber,
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

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _appBarIconButton(Icons.arrow_back_ios_new, isDark, () {
        if (Navigator.canPop(context)) Navigator.pop(context);
      }),
      title: Text(
        "Workout Schedule",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      // ✅ PROFESSIONAL UPGRADE: Added Right-Side Three-Dots Action Matrix
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
          offset: const Offset(0, 50),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          // Custom beautiful button matching your design system
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.more_horiz_rounded, // Premium looking horizontal dots
              color: isDark ? Colors.white : Colors.black,
              size: 18,
            ),
          ),
          itemBuilder: (context) => [
            _buildPopupItem(
              "Select Month & Year",
              Icons.calendar_month_rounded,
              isDark,
              "pick_date",
            ),
            _buildPopupItem(
              "Sync Repositories",
              Icons.refresh_rounded,
              isDark,
              "refresh",
            ),
            const PopupMenuDivider(height: 1),
            _buildPopupItem(
              "Purge All Schedules",
              Icons.delete_sweep_rounded,
              isDark,
              "clear_all",
            ),
          ],
        ),
        const SizedBox(width: 15), // Stable horizontal padding anchor
      ],
    );
  }

  // ✅ HELPER: Renders uniform premium lookup rows inside drop panels
  PopupMenuItem<String> _buildPopupItem(
    String title,
    IconData icon,
    bool isDark,
    String valueToken,
  ) {
    return PopupMenuItem<String>(
      value: valueToken,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: valueToken == "clear_all"
                ? Colors.redAccent
                : (isDark ? Colors.white70 : Colors.black54),
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: valueToken == "clear_all"
                  ? Colors.redAccent
                  : (isDark ? Colors.white : Colors.black),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ACTION ENGINE: Handles popup selections seamlessly including dynamic year wheel picker
  // ✅ FIXED: Standardized action pipeline mapping signatures cleanly
  void _handleMenuAction(String value) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (value == "pick_date") {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: 260,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Navigate Calendar Timeline",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.monthYear,
                    initialDateTime: _focusedCalendarMonth,
                    minimumYear: 2025,
                    maximumYear: 2030,
                    onDateTimeChanged: (DateTime newMonth) {
                      setState(() {
                        _focusedCalendarMonth = newMonth;
                        selectedDateIndex = 0;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } else if (value == "refresh") {
      _executeTimelineRefresh(); // ✅ FIXED: Redirected to a distinct non-conflicting explicit call trace
    } else if (value == "clear_all") {
      _service.clearAllSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All operational history collections wiped! 🗑️"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ FIXED: Renamed signature identifier safely to eliminate unresolved methods errors on build channels
  Future<void> _executeTimelineRefresh() async {
    if (mounted) {
      setState(() {
        // Triggers the timeline stream registry framework to pull updated snapshot maps straight from Firestore
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Schedule Engine Channels Sync Complete! 🔄"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryActive,
        ),
      );
    }
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
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black,
          size: 15,
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddScheduleView()),
      ),
      child: Container(
        height: 60,
        width: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
