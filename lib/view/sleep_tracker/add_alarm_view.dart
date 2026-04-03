import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/services/SleepService.dart';

class AddAlarmView extends StatefulWidget {
  const AddAlarmView({super.key});

  @override
  State<AddAlarmView> createState() => _AddAlarmViewState();
}

class _AddAlarmViewState extends State<AddAlarmView> {
  final SleepService _sleepService = SleepService();

  // 🔥 State Variables
  bool isVibrate = true;
  DateTime selectedTime = DateTime.now();
  String selectedSleepHours = "08h 00m";
  String selectedRepeat = "Mon to Fri";
  bool isLoading = false;

  // --- 🔥 Logic: Reset All Selections ---
  void _handleClearSettings() {
    setState(() {
      // 1. Saare variables ko default par reset karna
      selectedTime = DateTime.now();
      selectedSleepHours = "08h 00m";
      selectedRepeat = "Mon to Fri";
      isVibrate = true;
    });

    // 2. User ko feedback dena (Snackbar)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Settings reset to default"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF92A3FD),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // --- 🔥 Logic: Show Professional Help Dialog ---
  void _handleHelpDialog(bool isDark) {
    print("hello;");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF92A3FD)),
            const SizedBox(width: 10),
            Text(
              "FitQuest Guide",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Tap on any tile to customize your alarm time, duration, and repeat mode. Press 'Add Alarm' to sync with your fitness cloud.",
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Got it",
              style: TextStyle(
                color: Color(0xFF92A3FD),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🛠️ Logic: Show Cupertino Time Picker ---
  void _showTimePicker(bool isDark) {
    showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (context) => Container(
        height: 250,
        color: isDark ? const Color(0xFF1D1B20) : Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: selectedTime,
                onDateTimeChanged: (DateTime newTime) {
                  setState(() => selectedTime = newTime);
                },
              ),
            ),
            CupertinoButton(
              child: const Text(
                "Done",
                style: TextStyle(color: Color(0xFF92A3FD)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // --- 🛠️ Logic: Show Sleep Hours Picker ---
  void _showSleepHoursPicker(bool isDark) {
    List<String> hoursOptions = [
      "06h 00m",
      "07h 00m",
      "08h 00m",
      "09h 00m",
      "10h 00m",
    ];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Select Sleep Duration"),
        actions: hoursOptions
            .map(
              (hour) => CupertinoActionSheetAction(
                child: Text(hour),
                onPressed: () {
                  setState(() => selectedSleepHours = hour);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // --- 🛠️ Logic: Show Repeat Picker ---
  void _showRepeatPicker(bool isDark) {
    List<String> options = ["Everyday", "Mon to Fri", "Weekends"];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Repeat Mode"),
        actions: options
            .map(
              (opt) => CupertinoActionSheetAction(
                child: Text(opt),
                onPressed: () {
                  setState(() => selectedRepeat = opt);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  // --- 🛠️ Logic: Save to Firebase ---
  void _onAddPressed() async {
    if (isLoading) return; // Baar baar click hone se bachane ke liye

    setState(() => isLoading = true);

    try {
      // Time ko 12-hour format (AM/PM) mein badalna
      String formattedTime =
          "${selectedTime.hour % 12 == 0 ? 12 : selectedTime.hour % 12}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.hour >= 12 ? 'PM' : 'AM'}";

      // Firebase aur Local Storage ko data bhejna
      await _sleepService.saveAlarm(
        bedtime: formattedTime,
        sleepHours: selectedSleepHours,
        repeat: selectedRepeat,
        isVibrate: isVibrate,
      );

      if (!mounted) return;

      // Screen band karne se pehle message dikhana
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Alarm Scheduled & Synced!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF92A3FD),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    Color bgColor = isDark ? const Color(0xFF1D1B20) : Colors.white;
    Color tileColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF7F8F8);
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, textColor),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSelectionTile(
              icon: Icons.bed_outlined,
              title: "Bedtime",
              value:
                  "${selectedTime.hour % 12 == 0 ? 12 : selectedTime.hour % 12}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.hour >= 12 ? 'PM' : 'AM'}",
              tileColor: tileColor,
              textColor: textColor,
              onTap: () => _showTimePicker(isDark),
            ),
            const SizedBox(height: 15),
            _buildSelectionTile(
              icon: Icons.access_time,
              title: "Hours of sleep",
              value: selectedSleepHours,
              tileColor: tileColor,
              textColor: textColor,
              onTap: () => _showSleepHoursPicker(isDark),
            ),
            const SizedBox(height: 15),
            _buildSelectionTile(
              icon: Icons.repeat,
              title: "Repeat",
              value: selectedRepeat,
              tileColor: tileColor,
              textColor: textColor,
              onTap: () => _showRepeatPicker(isDark),
            ),
            const SizedBox(height: 15),
            _buildSwitchTile(
              Icons.vibration,
              "Vibrate Alarm",
              isVibrate,
              tileColor,
              textColor,
              (v) => setState(() => isVibrate = v),
            ),
            const Spacer(),
            _buildAddButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- ✨ UI Helpers ---
  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String value,
    required Color tileColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF92A3FD), size: 22),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    bool value,
    Color tileColor,
    Color textColor,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? const Color(0xFF92A3FD) : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF92A3FD),
          ),
        ],
      ),
    );
  }

  // --- ✨ UI: The Popup Menu Button (...) ---
  Widget _buildAddAlarmMenu(bool isDark, Color textColor) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: textColor), // Teen dots wala icon
      offset: const Offset(0, 50), // Menu ko thora niche dikhane ke liye
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (value) {
        print("value $value");
        if (value == 'Clear') {
          _handleClearSettings(); // Settings reset karega
        } else if (value == 'Help') {
          _handleHelpDialog(isDark); // Help dialog khole ka
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          "Clear",
          Icons.delete_sweep_outlined,
          "Clear Settings",
          const Color(0xFF92A3FD),
          isDark,
        ),
        _buildPopupItem(
          "Help",
          Icons.help_outline,
          "Help & Guide",
          const Color(0xFFC58BF2),
          isDark,
        ),
      ],
    );
  }

  // --- ✨ UI Helper: Menu Items Styles ---
  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String title,
    Color iconColor,
    bool isDark,
  ) {
    return PopupMenuItem<String>(
      value: value,
      onTap: () => print("val: $value"),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF92A3FD).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _onAddPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Add Alarm",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Add Alarm",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      // 🔥 Yahan menu ko call karein, warning khatam ho jayegi
      actions: [_buildAddAlarmMenu(isDark, textColor)],
    );
  }
}
