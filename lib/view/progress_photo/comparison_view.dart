import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptic feedback ke liye
import 'package:provider/provider.dart';
import 'package:fitness_app/data/services/progress_service.dart';
import 'package:share_plus/share_plus.dart';
import 'result_view.dart';

class ComparisonView extends StatefulWidget {
  const ComparisonView({super.key});

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  final ProgressService _progressService = ProgressService();

  // 🔥 Default Values ko professional rakha hai
  String selectedMonth1 = "Select Month";
  String selectedMonth2 = "Select Month";

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    // Tracking current visit
    await _progressService.saveLastCheckDate();
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    Color bgColor = isDark ? const Color(0xFF1D1B20) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color tileColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF7F8F8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, textColor),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Month 1 Tile
            _buildSelectionTile(
              icon: Icons.calendar_today_outlined,
              title: "Select Month 1",
              value: selectedMonth1,
              tileColor: tileColor,
              onTap: () => _showMonthPicker((val) {
                setState(() => selectedMonth1 = val);
              }),
            ),
            const SizedBox(height: 15),
            // Month 2 Tile
            _buildSelectionTile(
              icon: Icons.calendar_today_outlined,
              title: "Select Month 2",
              value: selectedMonth2,
              tileColor: tileColor,
              onTap: () => _showMonthPicker((val) {
                setState(() => selectedMonth2 = val);
              }),
            ),
            const Spacer(),
            _buildCompareButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String value,
    required Color tileColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(
          18,
        ), // Thora space barhaya hai balance ke liye
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value == "Select Month"
                ? Colors.transparent
                : const Color(0xFFC58BF2).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC58BF2), size: 20),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF92A3FD),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(Function(String) onSelect) {
    final List<String> months = [
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: months.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(
              months[index],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              onSelect(months[index]);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompareButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B50F6), Color(0xFFCC8FED)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B50F6).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (selectedMonth1 != "Select Month" &&
              selectedMonth2 != "Select Month") {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ResultView(month1: selectedMonth1, month2: selectedMonth2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please select both months to compare!"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Compare",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
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
        icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Comparison",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          icon: Icon(Icons.more_horiz, color: textColor),
          onSelected: (val) async {
            if (val == 'Reset') {
              setState(() {
                selectedMonth1 = "Select Month";
                selectedMonth2 = "Select Month";
              });
            } else if (val == 'Share') {
              final String shareMessage =
                  "🔥 *FitQuest Progress Update* 🔥\n"
                  "Check out my transformation from $selectedMonth1 to $selectedMonth2!\n"
                  "Download FitQuest: https://fitquest.app";
              await Share.share(shareMessage);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Share', child: Text("Share Progress")),
            const PopupMenuItem(
              value: 'Reset',
              child: Text("Reset Selections"),
            ),
          ],
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
