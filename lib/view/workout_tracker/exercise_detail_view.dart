import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/view/workout_tracker/workout_finished_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

// 🔥 SERVICE IMPORTS
import '../../data/services/workout_service.dart';

class ExerciseDetailView extends StatefulWidget {
  final Exercise exercise; // 'where flutter' hata diya gaya hai

  const ExerciseDetailView({super.key, required this.exercise});

  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

// Exercise model class (Must match your app's structure)
class Exercise {
  final String title;
  final String calories;
  final String level;
  final String description;
  final String videoPath;
  final List<Map<String, String>> steps;

  Exercise({
    required this.title,
    required this.calories,
    required this.level,
    required this.description,
    required this.videoPath,
    required this.steps,
  });
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  late VideoPlayerController _controller;
  bool isExpanded = false;

  // 🔥 1. Service Instance initialize karein
  final WorkoutService _service = WorkoutService();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.exercise.videoPath)
      ..initialize()
          .then((_) {
            setState(() {});
            _controller.play();
          })
          .catchError((error) {
            debugPrint("Video Error: $error");
          });
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔥 2. REAL WORK Logic: Firebase aur Local Sync
  Future<void> _handleSaveProgress() async {
    try {
      // Background mein sync karein (Title, calories aur level bhej rahe hain)
      await _service.updateScheduleStatus(
        "${widget.exercise.title}_Completed",
        true,
      );

      if (mounted) {
        // Navigation: Congratulations screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WorkoutFinishedView()),
        );
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: 10),
            _buildTitleSection(isDark),
            const SizedBox(height: 20),
            _buildHowToDoSection(isDark),
            const SizedBox(height: 30),
            _buildRepetitionsSection(isDark),
            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // 🔥 3. Save function connect kiya
      floatingActionButton: _buildSaveButton(context),
    );
  }

  // ... (Header aur Title sections bilkul same hain)
  Widget _buildHeader(BuildContext context, bool isDark) {
    return SizedBox(
      height: 380,
      child: Stack(
        children: [
          Container(
            height: 350,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xffEEA4CE), Color(0xffC150F6)],
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(25),
              ),
              clipBehavior: Clip.antiAlias,
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerIcon(Icons.close, () => Navigator.pop(context)),
                  _headerIcon(Icons.more_horiz, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    String desc = widget.exercise.description;
    String shortDesc = desc.length > 120
        ? "${desc.substring(0, 120)}... "
        : desc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exercise.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "${widget.exercise.level} | ${widget.exercise.calories}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 25),
          const Text(
            "Descriptions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.6,
              ),
              children: [
                TextSpan(text: isExpanded ? desc : shortDesc),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => setState(() => isExpanded = !isExpanded),
                    child: Text(
                      isExpanded ? " Show Less" : " Read More..",
                      style: TextStyle(
                        color: Colors.tealAccent[700],
                        fontWeight: FontWeight.bold,
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
  }

  // --- 4. Updated Save Button (Connected to _handleSaveProgress) ---
  Widget _buildSaveButton(BuildContext context) {
    return Material(
      color: Colors
          .transparent, // Gradient nazar aane ke liye transparent rakha hai
      child: InkWell(
        onTap: () {
          debugPrint(
            "Save Button Clicked!",
          ); // Console mein check karne ke liye
          _handleSaveProgress(); // Aapka sync function call ho raha hai
        },
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff92A3FD), Color(0xffC58BF2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffC58BF2).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            width: 320,
            height: 55,
            alignment: Alignment.center,
            child: const Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (Repetitions aur steps sections same rahenge)
  Widget _buildHowToDoSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "How To Do It",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "${widget.exercise.steps.length} Steps",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 25),
          ...widget.exercise.steps.asMap().entries.map((entry) {
            int idx = entry.key;
            var step = entry.value;
            return _stepItem(
              "0${idx + 1}",
              step['title']!,
              step['desc']!,
              isLast: idx == widget.exercise.steps.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _stepItem(
    String number,
    String title,
    String sub, {
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                number,
                style: const TextStyle(color: Color(0xffC58BF2), fontSize: 12),
              ),
              const SizedBox(height: 5),
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xffC58BF2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xffC58BF2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: const Color(0xffC58BF2).withValues(alpha: 0.3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sub,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepetitionsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Custom Repetitions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _repsRow("29", isSelected: false),
          const Divider(),
          _repsRow("30", isSelected: true, suffix: "times"),
          const Divider(),
          _repsRow("31", isSelected: false),
        ],
      ),
    );
  }

  Widget _repsRow(String val, {required bool isSelected, String suffix = ""}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: isSelected ? Colors.orange : Colors.grey[300],
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            "450 Calories Burn",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(width: 20),
          Text(
            val,
            style: TextStyle(
              fontSize: isSelected ? 22 : 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black87 : Colors.grey[400],
            ),
          ),
          if (suffix.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              suffix,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}

// Painter class same rahegi
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
