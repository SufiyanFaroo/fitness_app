import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/services/workout_service.dart'; // Path verify karlein

class AddScheduleView extends StatefulWidget {
  final String? editDocId;
  final Map<String, dynamic>? existingData;

  const AddScheduleView({super.key, this.editDocId, this.existingData});

  @override
  State<AddScheduleView> createState() => _AddScheduleViewState();
}

class _AddScheduleViewState extends State<AddScheduleView> {
  final WorkoutService _service = WorkoutService();

  late String selectedWorkout;
  late String selectedDifficulty;
  late String selectedReps;
  late String selectedWeight;
  late DateTime selectedDateTime;
  bool isSaving = false;

  bool get isEditMode => widget.editDocId != null;

  @override
  void initState() {
    super.initState();
    // ✅ DYNAMIC FORM ROUTINE: Auto-fills standard pickers tracking maps if parameters exists
    if (isEditMode && widget.existingData != null) {
      var d = widget.existingData!;
      selectedWorkout = d['workoutName'] ?? d['workout'] ?? "Upperbody Workout";
      selectedDifficulty = d['difficulty'] ?? "Beginner";
      selectedReps = d['repetitions'] ?? d['reps'] ?? "12 Times";
      selectedWeight = d['weight'] ?? "10 kg";
      selectedDateTime = DateTime.parse(
        d['scheduleTime'] ?? d['time'] ?? DateTime.now().toIso8601String(),
      );
    } else {
      selectedWorkout = "Upperbody Workout";
      selectedDifficulty = "Beginner";
      selectedReps = "12 Times";
      selectedWeight = "10 kg";
      selectedDateTime = DateTime.now();
    }
  }

  Future<void> _handleSave() async {
    setState(() => isSaving = true);

    if (isEditMode) {
      // ✅ INTERCEPT TRIGGER: Fires explicit custom updating function when key pointers exist
      await _service.updateWorkoutSchedule(
        docId: widget.editDocId!,
        workout: selectedWorkout,
        difficulty: selectedDifficulty,
        reps: selectedReps,
        weight: selectedWeight,
        time: selectedDateTime,
      );
    } else {
      await _service.saveWorkoutSchedule(
        workout: selectedWorkout,
        difficulty: selectedDifficulty,
        reps: selectedReps,
        weight: selectedWeight,
        time: selectedDateTime,
      );
    }

    if (mounted) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? "Schedule variables modified successfully!"
                : "Schedule synchronized successfully! 🔥",
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryActive,
        ),
      );
      Navigator.pop(context);
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
              "Dynamic Date & Time Configuration wheel",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          _buildDateTimePicker(isDark),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Details Workout Optimization",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),

          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildDetailTile(
                  Icons.fitness_center_outlined,
                  "Choose Workout",
                  selectedWorkout,
                  isDark,
                  onTap: () async {
                    List<String> categories = await _service
                        .getWorkoutCategories();
                    if (mounted) {
                      _showSelectionPicker(
                        context,
                        categories,
                        (v) => setState(() => selectedWorkout = v),
                        isDark,
                      );
                    }
                  },
                ),
                _buildDetailTile(
                  Icons.swap_vert_rounded,
                  "Difficulty Level",
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
                  "Custom Load Weights",
                  selectedWeight,
                  isDark,
                  onTap: () => _showNumberPicker(
                    context,
                    "Weights",
                    "kg",
                    0,
                    150,
                    (v) => setState(() => selectedWeight = "$v kg"),
                    isDark,
                  ),
                ),
              ],
            ),
          ),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
      child: InkWell(
        onTap: isSaving ? null : _handleSave,
        borderRadius: BorderRadius.circular(30),
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
                ? const CupertinoActivityIndicator(color: Colors.white)
                : Text(
                    isEditMode
                        ? "Apply Parameter Changes"
                        : "Commit Schedule Parameters",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(bool isDark) {
    return SizedBox(
      height: 140,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 15,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.dateAndTime,
          initialDateTime: selectedDateTime,
          minimumYear: 2025,
          maximumYear: 2030,
          use24hFormat: false,
          onDateTimeChanged: (val) => setState(() => selectedDateTime = val),
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
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(
                options[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              onTap: () {
                onSelect(options[index]);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

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
        height: 280,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                "Select $title",
                style: const TextStyle(
                  fontSize: 16,
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
                        fontSize: 16,
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
                "Confirm Selection",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF92A3FD),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(14),
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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              val,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        isEditMode ? "Modify Target parameters" : "Create Custom Schedule",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
    );
  }

  Widget _buildDateHeader() {
    String formattedDate = DateFormat(
      'EEEE, dd MMMM yyyy - hh:mm a',
    ).format(selectedDateTime);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Target Date Target: $formattedDate",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
