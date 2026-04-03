import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/workout_service.dart'; // 🔥 Service import check karein

class AddScheduleView extends StatefulWidget {
  const AddScheduleView({super.key});

  @override
  State<AddScheduleView> createState() => _AddScheduleViewState();
}

class _AddScheduleViewState extends State<AddScheduleView> {
  final WorkoutService _service = WorkoutService(); // 🔥 Service Instance

  String selectedWorkout = "Upperbody Workout";
  String selectedDifficulty = "Beginner";
  String selectedReps = "12 Times";
  String selectedWeight = "10 kg";
  DateTime selectedTime = DateTime.now();
  bool isSaving = false; // 🔥 Save button loading indicator
  // --- Date Helpers to fix the errors ---

  String _getWeekday(int day) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[day - 1];
  }

  String _getMonth(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  // --- 🔥 NEW: Save Functionality ---
  Future<void> _handleSave() async {
    setState(() => isSaving = true);

    await _service.saveWorkoutSchedule(
      workout: selectedWorkout,
      difficulty: selectedDifficulty,
      reps: selectedReps,
      weight: selectedWeight,
      time: selectedTime,
    );

    if (mounted) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Workout Schedule Saved to Cloud! 🔥")),
      );
      Navigator.pop(context); // Save ke baad pichle page par jayein
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Time",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          _buildTimePicker(isDark),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Details Workout",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // _buildDetailTile ke onTap ko update karein:
          _buildDetailTile(
            Icons.fitness_center_outlined,
            "Choose Workout",
            selectedWorkout,
            isDark,
            onTap: () async {
              // 🔥 Firebase se categories mangwao
              List<String> categories = await _service.getWorkoutCategories();

              if (mounted) {
                _showSelectionPicker(
                  context,
                  categories, // 🔥 Ab ye dynamic list use karega
                  (v) => setState(() => selectedWorkout = v),
                  isDark,
                );
              }
            },
          ),
          _buildDetailTile(
            Icons.swap_vert_rounded,
            "Difficulty",
            selectedDifficulty,
            isDark,
            onTap: () => _showSelectionPicker(
              context,
              ["Beginner", "Intermediate", "Advanced"],
              (v) => setState(() => selectedDifficulty = v),
              isDark,
            ),
          ),
          _buildDetailTile(
            Icons.repeat_rounded,
            "Custom Repetitions",
            selectedReps,
            isDark,
            onTap: () => _showNumberPicker(
              context,
              "Repetitions",
              "Times",
              1,
              50,
              (v) => setState(() => selectedReps = "$v Times"),
              isDark,
            ),
          ),
          _buildDetailTile(
            Icons.monitor_weight_outlined,
            "Custom Weights",
            selectedWeight,
            isDark,
            onTap: () => _showNumberPicker(
              context,
              "Weights",
              "kg",
              1,
              150,
              (v) => setState(() => selectedWeight = "$v kg"),
              isDark,
            ),
          ),
          const Spacer(),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  // --- 🔥 Updated Save Button with Loading ---
  // --- 🔥 Corrected Save Button ---
  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: InkWell(
        // Navigator.pop ki jagah _handleSave call karein
        onTap: isSaving ? null : _handleSave,
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
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

  void _showSelectionPicker(
    BuildContext context,
    List<String> options,
    Function(String) onSelect,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: options.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(
              options[index],
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            onTap: () {
              onSelect(options[index]);
              Navigator.pop(context); // Selection ke baad band ho jaye
            },
          ),
        ),
      ),
    );
  }

  // --- Scrolling Number Picker (Reps & Weights ke liye) ---
  void _showNumberPicker(
    BuildContext context,
    String title,
    String unit,
    int min,
    int max,
    Function(int) onSelect,
    bool isDark,
  ) {
    int tempVal = min;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                "Select $title",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) => tempVal = min + index,
                children: List.generate(
                  max - min + 1,
                  (index) => Center(
                    child: Text(
                      "${min + index} $unit",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                onSelect(tempVal);
                Navigator.pop(context);
              },
              child: const Text(
                "Confirm",
                style: TextStyle(fontSize: 18, color: Color(0xFF92A3FD)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---
  Widget _buildTimePicker(bool isDark) {
    return SizedBox(
      height: 120,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          onDateTimeChanged: (val) {
            setState(() {
              selectedTime = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String title,
    String val,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
            Icon(icon, color: Colors.grey.shade500, size: 18),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const Spacer(),
            Text(val, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(width: 5),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Add Schedule",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        // Three dots menu logic
        PopupMenuButton(
          icon: Icon(
            Icons.more_horiz,
            color: isDark ? Colors.white : Colors.black,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 1, child: Text("Clear Fields")),
          ],
          onSelected: (val) {
            if (val == 1) {
              setState(() {
                selectedWorkout =
                    "Upperbody Workout"; // Initial value ke sath match karein
                selectedDifficulty = "Beginner";
                selectedReps = "12 Times";
                selectedWeight = "10 kg";
              });
            }
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // _buildDateHeader ko dynamic banayein
  Widget _buildDateHeader() {
    DateTime now = DateTime.now(); // 🔥 Current Date

    // Dynamic String: e.g., "Wed, 11 Mar 2026"
    String formattedDate =
        "${_getWeekday(now.weekday)}, ${now.day} ${_getMonth(now.month)} ${now.year}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            formattedDate,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
