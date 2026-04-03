import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:fitness_app/core/routes/app_routes.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/services/progress_service.dart';
//import 'dart:typed_data'; // ✅ Is ke baghair Uint8List error dega

class ResultView extends StatefulWidget {
  final String month1;
  final String month2;

  const ResultView({super.key, required this.month1, required this.month2});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  bool isPhotoSelected = true;
  final ProgressService _progressService = ProgressService();

  // 🔥 1. FULL SCREEN IMAGE VIEWER (Zoom & Move Fix)
  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: url, // Unique tag animation ke liye
                child: CachedNetworkImage(
                  imageUrl: url,
                  // Loading ke waqt indicator
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  // Agar internet na ho toh error icon
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 2. REAL DELETE LOGIC
  Future<void> _deleteResultRecords() async {
    try {
      // Month 1 aur Month 2 dono ke records delete karna
      await _progressService.deleteProgressByMonth(widget.month1);
      await _progressService.deleteProgressByMonth(widget.month2);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Comparison records deleted!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context); // Wapis Comparison screen par
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  // --- Updated Firebase Image Widget with Click Action ---
  Widget _buildFirebaseImage(String month, int poseIndex) {
    return FutureBuilder<QuerySnapshot>(
      future: _progressService.getPhotosByMonth(month),
      builder: (context, snapshot) {
        String? url;
        bool isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          try {
            var doc = snapshot.data!.docs.firstWhere(
              (d) =>
                  (d.data() as Map<String, dynamic>)['poseIndex'] == poseIndex,
            );
            url = (doc.data() as Map<String, dynamic>)['imageUrl'];
          } catch (e) {
            url = null;
          }
        }

        return Column(
          children: [
            Text(
              month,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              // 🔥 Click par image bari hogi
              onTap: url != null
                  ? () => _showFullScreenImage(context, url!)
                  : null,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  image: url != null
                      ? DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: url == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLoading
                                ? Icons.cloud_download_outlined
                                : Icons.add_a_photo_outlined,
                            color: Colors.grey.withValues(alpha: 0.5),
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLoading ? "Loading..." : "No Image",
                            style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  //🔥 Professional Delete Dialog
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Results?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure? This will remove these records from your history.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteResultRecords();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _trackActivity();
  }

  Future<void> _trackActivity() async {
    await _progressService.saveLastCheckDate();
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      appBar: _buildAppBar(context, isDark, textColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _buildToggleSwitch(isDark),
            const SizedBox(height: 25),
            if (isPhotoSelected) ...[
              _buildAverageProgress(
                isDark,
                textColor,
                0.62,
              ), // Teesri value (0.62) add kar di
              const SizedBox(height: 30),
              // 🔥 Dynamic Firebase Rows
              _buildDynamicRow("Front Facing", 0),
              const SizedBox(height: 20),
              _buildDynamicRow("Back Facing", 1),
              const SizedBox(height: 20),
              _buildDynamicRow("Left Facing", 2),
              const SizedBox(height: 20),
              _buildDynamicRow("Right Facing", 3),
            ] else ...[
              _buildStatisticSection(isDark, textColor),
            ],
            const SizedBox(height: 40),
            _buildHomeButton(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔥 Firebase Integrated Row
  Widget _buildDynamicRow(String title, int poseIndex) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFirebaseImage(widget.month1, poseIndex),
            _buildFirebaseImage(widget.month2, poseIndex),
          ],
        ),
      ],
    );
  }

  Widget _buildLeading(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 16, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      // 🔥 Leading button (Fix: Make sure _buildLeading exists)
      leading: _buildLeading(isDark, textColor),
      title: const Text(
        "Result",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        // --- 1. Share Action ---
        IconButton(
          tooltip: "Share Progress",
          icon: const Icon(Icons.share_outlined),
          onPressed: () {
            HapticFeedback.lightImpact();
            Share.share(
              "Check out my fitness progress: ${widget.month1} vs ${widget.month2} on FitQuest! 🔥",
            );
          },
        ),

        // --- 2. Professional Popup Menu ---
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          icon: const Icon(Icons.more_horiz),
          onSelected: (val) async {
            if (val == 'Delete') {
              _showDeleteDialog();
            } else if (val == 'Download') {
              HapticFeedback.mediumImpact();

              // 🔥 NOTE: Aapko yahan wo URLs pass karne hain jo aapne
              // Firestore se fetch kiye hain.
              // Agar aapne variables banaye hain toh wo use karein.

              await _handleDownload(
                widget.month1,
                "IMAGE_URL_FROM_FIRESTORE_1",
              );
              await _handleDownload(
                widget.month2,
                "IMAGE_URL_FROM_FIRESTORE_2",
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'Download',
              child: Row(
                children: [
                  Icon(Icons.download_rounded, size: 20, color: Colors.blue),
                  SizedBox(width: 12),
                  Text("Save to Gallery", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            const PopupMenuItem(
              value: 'Delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Delete Result",
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildToggleSwitch(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              "Photo",
              isPhotoSelected,
              () => setState(() => isPhotoSelected = true),
            ),
          ),
          Expanded(
            child: _buildTabItem(
              "Statistic",
              !isPhotoSelected,
              () => setState(() => isPhotoSelected = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFC58BF2), Color(0xFF92A3FD)],
                )
              : null,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 1. Pehle ye function update karein (Parameter 'progress' add kiya hai)
  Widget _buildAverageProgress(bool isDark, Color textColor, double progress) {
    // Progress ko percentage mein badalna
    int percentage = (progress * 100).toInt();
    String status = percentage > 50 ? "Good" : "Keep it up";
    Color statusColor = percentage > 50 ? Colors.green : Colors.orange;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Average Progress",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            // 🔥 Dynamic Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(
                value: progress, // 🔥 Real-time Value
                minHeight: 25,
                backgroundColor: isDark
                    ? Colors.white10
                    : const Color(0xFFF7F8F8),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFC58BF2),
                ),
              ),
              // 🔥 Dynamic Percentage Text
              Text(
                "$percentage%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF92A3FD), Color(0xFF9DCEFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF92A3FD).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // 1. Premium feel ke liye vibration
          HapticFeedback.mediumImpact();

          // 2. Navigation: Ye direct Progress Screen par le jayega
          // App "Restart" nahi hogi kyunki hum splash par nahi ja rahe
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.progressPhoto, // '/progressPhoto' call ho raha hai
            (route) =>
                false, // Purana sara stack clear (Camera, Result sab khatam)
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              "Back to Progress",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Updated Statistic Section with Real Chart ---
  Widget _buildStatisticSection(bool isDark, Color textColor) {
    return Column(
      children: [
        // --- 1. Premium Wavy Line Chart ---
        Container(
          height: 250,
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 25,
            right: 15,
            left: 5,
            bottom: 10,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF7F8F8),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.transparent,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: _buildComparisonChart(isDark),
        ),
        const SizedBox(height: 35),

        // --- 2. Month Labels with Icons ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMonthIndicator(widget.month1, const Color(0xFFC58BF2)),
            const Icon(
              Icons.compare_arrows_rounded,
              color: Colors.grey,
              size: 22,
            ),
            _buildMonthIndicator(widget.month2, const Color(0xFF00FAD9)),
          ],
        ),
        const SizedBox(height: 25),

        // --- 3. Professional Stat Progress Rows ---
        _buildStatProgressRow("Lose Weight", 0.33, 0.67, isDark),
        _buildStatProgressRow("Height Increase", 0.88, 0.12, isDark),
        _buildStatProgressRow("Muscle Mass Increase", 0.57, 0.43, isDark),
        _buildStatProgressRow("Abs Definition", 0.89, 0.11, isDark),
      ],
    );
  }

  // 🔥 Helper: Month Indicator
  Widget _buildMonthIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // 🔥 Helper: Statistical Progress Bars (Fix for isDark)
  Widget _buildStatProgressRow(
    String title,
    double valRed,
    double valGreen,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "${(valRed * 100).toInt()}%",
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: valGreen,
                    minHeight: 10,
                    backgroundColor: isDark
                        ? Colors.white10
                        : const Color(0xFFFFB2B2).withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00FAD9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${(valGreen * 100).toInt()}%",
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Chart Widget Logic (Added Area Shading)
  Widget _buildComparisonChart(bool isDark) {
    return Stack(
      children: [
        LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: _buildChartTitles(isDark),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              _buildLineBar(const Color(0xFF00FAD9), [
                20,
                45,
                80,
                25,
                60,
                95,
                75,
              ], true), // Main Line with Shade
              _buildLineBar(const Color(0xFFC58BF2).withValues(alpha: 0.2), [
                15,
                10,
                15,
                50,
                40,
                20,
                35,
              ], false), // Background Line
            ],
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLineBar(
    Color color,
    List<double> spots,
    bool showArea,
  ) {
    return LineChartBarData(
      spots: spots
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: showArea,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  FlTitlesData _buildChartTitles(bool isDark) {
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35,
          getTitlesWidget: (v, m) => Text(
            "${v.toInt()}%",
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, m) {
            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            if (v.toInt() >= days.length) return const Text("");
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                days[v.toInt()],
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            );
          },
        ),
      ),
    );
  }

  // 🔥 URL ko parameter mein mangwaein taake real photo download ho
  Future<void> _handleDownload(String month, String? imageUrl) async {
    // 1. Agar image URL khali ho toh foran exit karein
    if (imageUrl == null || imageUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ No image available to download")),
        );
      }
      return;
    }

    // 2. Messenger variable pehle hi save kar lein
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        SnackBar(content: Text("Downloading $month progress photo...")),
      );

      // 3. Dio ke zariye image download karein (Bytes format mein)
      var response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // 4. ImageGallerySaver use karke phone mein save karein
      // 🔥 Updated Save Logic for image_gallery_saver_plus
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.data),
        quality: 80,
        // Naye version mein 'name' parameter ki jagah filename directly support hota hai
        name: "FitQuest_${month}_${DateTime.now().millisecondsSinceEpoch}",
      );

      // 5. Success Check
      if (mounted && result['isSuccess']) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("✅ Image saved to Gallery!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Download error: $e");
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("❌ Download failed. Check your internet."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
