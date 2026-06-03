import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/services/workout_service.dart'; // Path verify karlein
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/view/workout_tracker/WorkoutScheduleView.dart';
import 'package:fitness_app/view/workout_tracker/workout_detail_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class WorkoutTrackerView extends StatefulWidget {
  const WorkoutTrackerView({super.key});

  @override
  State<WorkoutTrackerView> createState() => _WorkoutTrackerViewState();
}

class _WorkoutTrackerViewState extends State<WorkoutTrackerView> {
  List<bool> switchStates = [false, false];
  final WorkoutService _service = WorkoutService();
  StreamSubscription? _workoutSubscription;

  String _currentTime = "";
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    _initPersistentData();
    _startClock();
  }

  @override
  void dispose() {
    _workoutSubscription?.cancel();
    _timeTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
        });
      }
    });
  }

  Future<void> _initPersistentData() async {
    final localStates = await _service.getLocalSwitchStates(2);
    if (mounted && localStates.isNotEmpty) {
      setState(() {
        switchStates = localStates;
      });
    }

    _workoutSubscription = _service.getWorkoutStream()?.listen((snapshot) {
      if (snapshot.exists && mounted) {
        var data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          if (switchStates.length >= 2) {
            switchStates[0] = data['workout_0'] ?? switchStates[0];
            switchStates[1] = data['workout_1'] ?? switchStates[1];
          }
        });
      }
    }, onError: (error) => debugPrint("Firestore Sync Crash: $error"));
  }

  Future<void> _handleRefresh() async {
    await _initPersistentData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cloud Sync Complete!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSwitchToggle(int index, bool value) {
    if (index < switchStates.length) {
      setState(() {
        switchStates[index] = value;
      });
      _service.saveSwitchState(index, value);
      _service.updateWorkoutOnFirebase(index, value);

      if (_service.uid.isNotEmpty) {
        int currentDayIndex = DateTime.now().weekday % 7;
        FirebaseFirestore.instance
            .collection('users')
            .doc(_service.uid)
            .collection('workout_analytics')
            .doc("day_$currentDayIndex")
            .set({
              'day_index': currentDayIndex,
              'fullbody_percentage': switchStates[0] == true ? 85.0 : 15.0,
              'upperbody_percentage': switchStates[1] == true ? 75.0 : 25.0,
              'last_sync': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dynamicBg = isDark ? const Color(0xff1D1617) : AppColors.white;
    final Color dynamicCard = isDark
        ? const Color(0xff2C2C2C)
        : AppColors.white;
    final Color dynamicText = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: dynamicBg,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primaryColor1,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildGraphHeader(),
              const SizedBox(height: 30),
              _buildDailyScheduleBanner(isDark),
              const SizedBox(height: 30),
              _buildSectionHeader(
                "Upcoming Workout",
                "See more",
                dynamicText,
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutScheduleView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildUpcomingWorkoutList(dynamicCard, dynamicText),
              const SizedBox(height: 30),
              _buildSectionHeader("What Do You Want to Train", "", dynamicText),
              const SizedBox(height: 15),
              _buildTrainingList(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color popupBgColor = isDark ? const Color(0xff2C2C2C) : Colors.white;
    final Color popupIconColor = isDark ? Colors.white : Colors.black;
    final Color popupTextColor = isDark ? Colors.white : Colors.black;

    String activeWorkout = "No Active Workout";
    if (switchStates.length >= 2) {
      if (switchStates[0] && switchStates[1]) {
        activeWorkout = "Multiple Workouts Active";
      } else if (switchStates[0]) {
        activeWorkout = "Fullbody Workout Active";
      } else if (switchStates[1]) {
        activeWorkout = "Upperbody Workout Active";
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _actionBtn(
              icon: Icons.arrow_back_ios_new,
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Workout Tracker",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$_currentTime | $activeWorkout",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: popupBgColor,
              onSelected: (value) async {
                if (value == 'refresh') await _handleRefresh();
                if (value == 'share') {
                  await Share.share(
                    'FitQuest Activity Update: $activeWorkout at $_currentTime\nTrack your progress now!',
                  );
                }
              },
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: _actionBtn(icon: Icons.more_horiz, onTap: null),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: popupIconColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Refresh Framework Data",
                        style: TextStyle(color: popupTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: popupIconColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Share Analytics Vector",
                        style: TextStyle(color: popupTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryColor1, AppColors.secondaryColor2],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          _buildAppBar(),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: _service.getWeeklyAnalyticsStream(),
                builder: (context, snapshot) {
                  List<FlSpot> fullBodySpots = const [
                    FlSpot(0, 20),
                    FlSpot(1, 40),
                    FlSpot(2, 30),
                    FlSpot(3, 70),
                    FlSpot(4, 50),
                    FlSpot(5, 80),
                    FlSpot(6, 40),
                  ];
                  List<FlSpot> upperBodySpots = const [
                    FlSpot(0, 30),
                    FlSpot(1, 20),
                    FlSpot(2, 50),
                    FlSpot(3, 40),
                    FlSpot(4, 70),
                    FlSpot(5, 30),
                    FlSpot(6, 60),
                  ];

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    List<FlSpot> cleanFull = [];
                    List<FlSpot> cleanUpper = [];

                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      int x = (data['day_index'] ?? 0).toInt();
                      double yFull = (data['fullbody_percentage'] ?? 0.0)
                          .toDouble();
                      double yUpper = (data['upperbody_percentage'] ?? 0.0)
                          .toDouble();

                      // Safety range limit constraints parameters check
                      if (x >= 0 && x <= 6) {
                        cleanFull.add(FlSpot(x.toDouble(), yFull));
                        cleanUpper.add(FlSpot(x.toDouble(), yUpper));
                      }
                    }
                    if (cleanFull.length == 7) fullBodySpots = cleanFull;
                    if (cleanUpper.length == 7) upperBodySpots = cleanUpper;
                  }

                  return LineChart(
                    _mainChartData(fullBodySpots, upperBodySpots),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _mainChartData(
    List<FlSpot> fullBodySpots,
    List<FlSpot> upperBodySpots,
  ) {
    String formattedDate = DateFormat('EEE, dd MMM').format(DateTime.now());
    int today = DateTime.now().weekday % 7;
    int yesterday = today > 0 ? today - 1 : 6;

    bool fullBodyOn = switchStates.isNotEmpty && switchStates[0];
    bool upperBodyOn = switchStates.length > 1 && switchStates[1];

    List<ShowingTooltipIndicators> tooltips = [];

    // ✅ FIXED: Checked bounds explicitly to ensure index length matches structural sizes safely before triggering tooltips
    if ((fullBodyOn && fullBodySpots.length > today) ||
        (upperBodyOn && upperBodySpots.length > today)) {
      bool targetUpper = upperBodyOn;
      tooltips = [
        ShowingTooltipIndicators([
          LineBarSpot(
            _getLineBarData(
              targetUpper ? upperBodySpots : fullBodySpots,
              targetUpper ? const Color(0xffC58BF2) : const Color(0xff00FAD9),
            ),
            targetUpper ? 1 : 0,
            targetUpper ? upperBodySpots[today] : fullBodySpots[today],
          ),
        ]),
      ];
    }

    return LineChartData(
      showingTooltipIndicators: tooltips,
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => Colors.white,
          tooltipBorderRadius: BorderRadius.circular(12),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isFullBody = spot.barIndex == 0;
              final accurateSpots = isFullBody ? fullBodySpots : upperBodySpots;

              // ✅ FIXED: Multi-layered boundary range safety check to avoid structural layout mismatch exceptions
              if (accurateSpots.length <= today ||
                  accurateSpots.length <= yesterday ||
                  today < 0 ||
                  yesterday < 0) {
                return const LineTooltipItem("", TextStyle());
              }

              double todayVal = accurateSpots[today].y;
              double yesterdayVal = accurateSpots[yesterday].y;
              String arrow = todayVal >= yesterdayVal ? " ↑" : " ↓";

              return LineTooltipItem(
                "${isFullBody ? 'Fullbody' : 'Upperbody'}\n",
                TextStyle(
                  color: isFullBody
                      ? const Color(0xff00FAD9)
                      : const Color(0xffC58BF2),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: "${spot.y.toInt()}% $arrow",
                    style: TextStyle(
                      color: todayVal >= yesterdayVal
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: "\n$formattedDate",
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, m) {
              const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
              int index = v.toInt();
              if (index < 0 || index >= days.length) return const SizedBox();
              bool isToday = index == today;
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  days[index],
                  style: TextStyle(
                    color: isToday
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (v, m) => Text(
              "${v.toInt()}%",
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        if (fullBodyOn) _getLineBarData(fullBodySpots, const Color(0xff00FAD9)),
        if (upperBodyOn)
          _getLineBarData(upperBodySpots, const Color(0xffC58BF2)),
      ],
    );
  }

  LineChartBarData _getLineBarData(List<FlSpot> spots, Color lineColor) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: lineColor,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: lineColor.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _buildUpcomingWorkoutList(Color cardBg, Color txtColor) {
    String todayDate = DateFormat('MMMM dd').format(DateTime.now());
    return Column(
      children: [
        _upcomingTile(
          "Fullbody Workout",
          "Today, $todayDate",
          0,
          AppAssets.Fullbody_Workout,
          cardBg,
          txtColor,
        ),
        _upcomingTile(
          "Upperbody Workout",
          "June 05, 02:00pm",
          1,
          AppAssets.Lowerbody_Workout,
          cardBg,
          txtColor,
        ),
      ],
    );
  }

  Widget _upcomingTile(
    String title,
    String time,
    int index,
    String imgPath,
    Color cardBg,
    Color txtColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15, left: 25, right: 25),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xff92FE9D).withValues(alpha: 0.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(imgPath, fit: BoxFit.contain),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: txtColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (index < switchStates.length)
            _buildGradientSwitch(
              value: switchStates[index],
              onChanged: (val) => _handleSwitchToggle(index, val),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xff00FAD9), Color(0xff2AF598)],
                )
              : null,
          color: value ? null : const Color(0xffDDDADA),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 18),
      ),
    );
  }

  Widget _buildTrainingList(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          _trainingCard(
            "Fullbody Workout",
            "11 Exercises | 32mins",
            isDark ? const Color(0xff3B3B3B) : const Color(0xffF7F0FF),
            AppAssets.Fullbody_Workout,
          ),
          _trainingCard(
            "Lowerbody Workout",
            "12 Exercises | 40mins",
            isDark ? const Color(0xff3B3B3B) : const Color(0xffF0F4FF),
            AppAssets.Lowerbody_Workout,
          ),
          _trainingCard(
            "AB Workout",
            "14 Exercises | 40mins",
            isDark ? const Color(0xff3B3B3B) : const Color(0xffF0F4FF),
            AppAssets.Ab_Workout,
          ),
        ],
      ),
    );
  }

  Widget _trainingCard(
    String title,
    String subtitle,
    Color bg,
    String imgPath,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutDetailView(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      "View more",
                      style: TextStyle(
                        color: Color(0xffC58BF2),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Image.asset(imgPath, height: 100, width: 100, fit: BoxFit.contain),
        ],
      ),
    );
  }

  Widget _buildDailyScheduleBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff2C2C2C) : const Color(0xffF7F8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Daily Workout Schedule",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutScheduleView(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryColor2, AppColors.primaryColor1],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Check",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action,
    Color txtColor, {
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: txtColor,
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
