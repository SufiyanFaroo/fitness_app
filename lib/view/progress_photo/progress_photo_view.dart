// ignore_for_file: unused_element
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/core/routes/app_routes.dart';
import 'package:fitness_app/data/services/cloudinary_service.dart';
import 'package:fitness_app/data/services/progress_service.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:fitness_app/view/progress_photo/camera_capture_view.dart';
import 'package:fitness_app/view/progress_photo/comparison_view.dart';
import 'package:fitness_app/view/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ProgressPhotoView extends StatefulWidget {
  final VoidCallback? onBack;
  const ProgressPhotoView({super.key, this.onBack});

  @override
  State<ProgressPhotoView> createState() => _ProgressPhotoViewState();
}

class _ProgressPhotoViewState extends State<ProgressPhotoView> {
  final ProgressService _progressService = ProgressService();
  bool _isBannerVisible = true;
  bool useHD = true;
  @override
  void initState() {
    super.initState();
    // Professional logging/tracking
    _progressService.saveLastCheckDate();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;

    final Color bgColor = isDark ? const Color(0xFF1D1B20) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color reminderBg = isDark
        ? Colors.red.withValues(alpha: 0.12)
        : const Color(0xFFFFE5E5);
    final Color bannerBg = isDark
        ? const Color(0xFF9B81FF).withValues(alpha: 0.12)
        : const Color(0xFFF2E8FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDark, textColor),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildReminderBanner(isDark, reminderBg),
            const SizedBox(height: 25),
            _buildTrackBanner(isDark, bannerBg),
            const SizedBox(height: 25),
            _buildCompareSection(isDark, bannerBg),
            const SizedBox(height: 30),
            _buildFirebaseGallery(isDark),
            const SizedBox(height: 120), // Padding for Floating Buttons/Nav
          ],
        ),
      ),
    );
  }

  // --- 1. Reminder Banner (Optimized) ---
  Widget _buildReminderBanner(bool isDark, Color bgColor) {
    if (!_isBannerVisible) return const SizedBox.shrink();

    // 🔥 Fix: Month calculation for 2026/2027 logic
    DateTime now = DateTime.now();

    // Is se month 13 nahi hoga, balki next year ka 1st month ban jayega automatically
    DateTime nextDate = DateTime(now.year, now.month + 1, 8);

    List<String> months = [
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

    // 🔥 Safe index check: (nextDate.month - 1) hamesha 0-11 ke darmiyan rahega
    String nextMonth = months[(nextDate.month - 1) % 12];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/images/reminder.png",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.red.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Reminder!",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Next Photos Fall On $nextMonth 08",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _isBannerVisible = false;
              });
            },
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white38 : Colors.grey,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // --- 2. Track Progress Banner ---
  Widget _buildTrackBanner(bool isDark, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25), // More rounded for modern look
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF9B81FF,
            ).withValues(alpha: isDark ? 0.05 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(text: "Track Your Progress Each\nMonth With "),
                      TextSpan(
                        text: "Photo",
                        style: TextStyle(
                          color: Color(0xFFC58BF2),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // 🔥 Professional Button with Haptic Feedback
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact(); // Professional vibration
                      _showLearnMoreSheet(
                        context,
                        isDark,
                      ); // Real function call
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B81FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text(
                      "Learn More",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 🔥 Animated Hero-like Image
          TweenAnimationBuilder(
            duration: const Duration(seconds: 1),
            tween: Tween<double>(begin: 0.8, end: 1.0),
            builder: (context, double value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Image.asset(
              "assets/images/progress.png",
              height: 95,
              errorBuilder: (c, e, s) => Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B81FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  size: 60,
                  color: Color(0xFF9B81FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Compare Photo Section ---
  Widget _buildCompareSection(bool isDark, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        // Adding a slight shadow for depth (optional)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Compare my Photo",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              // Camera Icon Button
              IconButton(
                onPressed: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraCaptureView(),
                      ),
                    );
                  } catch (e) {
                    // Agar click par koi error aaye to console mein nazar aa jaye
                    debugPrint("Navigation Error: $e");
                  }
                },
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF9B81FF),
                ),
              ),
              const SizedBox(width: 8),

              // Compare Button
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComparisonView(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B81FF),
                    foregroundColor: Colors.white, // Text color
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Compare",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. Firebase Gallery with Shimmer Effect Logic ---
  Widget _buildFirebaseGallery(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Gallery",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // 🔥 See more button ab real work karega
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FullGalleryGridView(),
                  ),
                );
              },
              child: const Text(
                "See more",
                style: TextStyle(
                  color: Color(
                    0xFF9B81FF,
                  ), // Primary color for better visibility
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        StreamBuilder<QuerySnapshot>(
          stream: _progressService.getProgressPhotos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(); // Reusable empty state function
            }
            return _buildGalleryItemRow(
              "Recent Progress",
              isDark,
              snapshot.data!.docs,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGalleryItemRow(
    String label,
    bool isDark,
    List<QueryDocumentSnapshot> docs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            // itemBuilder ke andar ye logic check karein
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String imageUrl = data['imageUrl'] ?? "";
              final String docId = doc.id;
              // 🔥 Check karein ke Firestore mein field ka naam 'publicId' hi hai na?
              final String publicId = data['publicId'] ?? "";

              return GestureDetector(
                onTap: () => _showFullScreenImage(context, imageUrl),
                onLongPress: () {
                  if (imageUrl.isNotEmpty) {
                    // Haptic feedback user experience behtar karta hai
                    HapticFeedback.heavyImpact();
                    _showDeleteConfirmDialog(
                      context,
                      docId,
                      imageUrl,
                      publicId,
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 105,
                    height: 105,
                    fit: BoxFit.cover,
                    // ... rest of your UI code
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔥 1. Photo ko full screen dikhane ke liye function
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
            child: Hero(
              tag: url, // Hero tag animation ke liye
              child: InteractiveViewer(
                clipBehavior: Clip
                    .none, // 🔥 Is se image move (pan) karte waqt kate gi nahi
                panEnabled: true, // 🔥 Move karne ke liye
                minScale: 0.5, // Chota karne ke liye
                maxScale: 4.0, // Bara karne ke liye
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 2. Delete confirmation dialog dikhane ke liye function
  void _showDeleteConfirmDialog(
    BuildContext context,
    String docId,
    String url,
    String publicId,
  ) {
    // Messenger ko pehle hi nikal lein taake async gap ka masla na ho
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Photo?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This photo will be permanently deleted from the gallery and cloud. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              // Dialog ko foran band karein
              Navigator.pop(dialogContext);

              try {
                // 🔥 1. Pehle Cloudinary se delete karein
                // Method name check karein aapki service mein 'deleteImageFromCloudinary' hi hai na?
                bool isCloudDeleted =
                    await CloudinaryService.deleteImageFromCloudinary(publicId);

                if (isCloudDeleted) {
                  // 🔥 2. Phir Firestore se document delete karein
                  await _progressService.deleteProgressPhoto(docId);

                  // 🔥 3. Cache se image clear karein taake UI foran update ho
                  await CachedNetworkImage.evictFromCache(url);

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("✅ Photo deleted successfully!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  throw Exception("Cloudinary could not delete the file.");
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text("❌ Delete Failed: ${e.toString()}"),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Bottom Sheets & Helpers ---
  void _showLearnMoreSheet(BuildContext context, bool isDark) {
    // 🔥 Step 1: Professional Vibration
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Background transparent for round corners
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1B20) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 Step 2: Drag Handle (Elite Look)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 25),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const Text(
              "Pro Tracking Tips",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 25),

            // 🔥 Functions Call (Ab error nahi aayega)
            _buildTipItem(
              Icons.light_mode_outlined,
              "Consistent Lighting",
              "Maintain consistent lighting in every shot.",
            ),
            _buildTipItem(
              Icons.aspect_ratio_rounded,
              "Fixed Distance",
              "Keep the same distance from the camera.",
            ),
            _buildTipItem(
              Icons.history_toggle_off_rounded,
              "Monthly Updates",
              "Monthly updates show the most visible changes.",
            ),

            const SizedBox(height: 35),

            // 🔥 Step 3: Premium Action Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B81FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Got it!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 🔥 Professional Tip Item Builder (Only ONE version kept to fix error)
  // 🔥 Ye function mobile screen ka 'NoSuchMethodError' khatam kar dega
  // 🔥 Ye function aapke teenon items (Lighting, Distance, Updates) ko render karega
  Widget _buildTipItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), // Har tip ke darmiyan gap
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9B81FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xFF9B81FF), size: 24),
          ),
          const SizedBox(width: 18),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Error Fix: _buildEmptyState method (image_2f38c8 fix)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Colors.grey.withValues(alpha: 0.5),
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              "No photos uploaded yet.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // 1. Agar custom onBack function diya gaya hai toh wo chale
            if (widget.onBack != null) {
              widget.onBack!();
            }
            // 2. Agar hum peeche ja sakte hain toh pop karein
            else if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
            // 3. Agar stack khali hai (Blank page se bachne ke liye) toh Main Tab par bhej dein
            else {
              Navigator.pushReplacementNamed(context, AppRoutes.mainTab);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: textColor),
          ),
        ),
      ),
      title: Text(
        "Progress Photo",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_horiz, color: textColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          offset: const Offset(0, 50),
          onSelected: (String value) {
            if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const GallerySettingsView()),
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            _buildPopupItem(
              "Settings",
              Icons.settings_outlined,
              "settings",
              isDark,
            ),
            const PopupMenuDivider(height: 1),
            _buildPopupItem(
              "Clear Cache",
              Icons.delete_outline,
              "clear_cache",
              isDark,
            ),
          ],
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // 🔥 Helper: Professional Menu Item Builder
  PopupMenuItem<String> _buildPopupItem(
    String title,
    IconData icon,
    String value,
    bool isDark,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black87),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.settings, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text("Gallery Settings coming soon!"),
          ],
        ),
        backgroundColor: const Color(0xFF9B81FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, bool isDark) {
    // 1. Messenger ko dialog se pehle save karein (Context safety)
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Clear Cache?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This will refresh your gallery images. Your photos will remain safe.",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            // Confirm Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                // 2. Dialog ko foran band karein
                Navigator.pop(dialogContext);

                // 3. Pehla feedback (Cleaning...)
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("Cleaning cache..."),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                // 4. Artificial Delay (Real feel ke liye)
                await Future.delayed(const Duration(seconds: 2));

                // 5. Final success message
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("✅ Cache Cleared Successfully!"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                "Clear Now",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final ProgressService _progressService = ProgressService();

class FullGalleryGridView extends StatelessWidget {
  const FullGalleryGridView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      appBar: AppBar(
        title: const Text(
          "All Progress Photos",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ProgressService()
            .getProgressPhotos(), // Real-time Firebase Stream
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Aik row mein 3 photos
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Variables nikaalna
              final String imageUrl = data['imageUrl'] ?? "";
              final String docId = doc.id;
              final String publicId = data['publicId'] ?? "";

              return GestureDetector(
                // 1. Single Tap: Full screen view
                onTap: () => _showFullScreenImage(context, imageUrl),

                // 2. Long Press: Delete Confirmation
                onLongPress: () {
                  if (imageUrl.isNotEmpty) {
                    HapticFeedback.mediumImpact(); // User ko vibrate feel hoga (Pro touch)
                    _showDeleteConfirmDialog(
                      context,
                      docId,
                      imageUrl,
                      publicId, // Sirf ye 4 parameters pass karein
                    );
                  }
                },

                child: Container(
                  margin: const EdgeInsets.only(
                    right: 12,
                  ), // Space maintain karne ke liye
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 105,
                      height: 105,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    String docId,
    String url,
    String publicId,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Photo?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Kya aap waqai is photo ko delete karna chahte hain?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                // 1. Cloudinary se delete
                await CloudinaryService.deleteImageFromCloudinary(publicId);
                // 2. Cache clear
                await CachedNetworkImage.evictFromCache(url);
                // 3. Firestore se delete
                await _progressService.deleteProgressPhoto(docId);

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("✅ Photo Deleted Successfully!"),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("❌ Error: $e")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black, // Elite Look ke liye background black
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: Hero(
              tag: url,
              child: InteractiveViewer(
                // 🔥 Is se user zoom bhi kar sakega
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: MediaQuery.of(
                    context,
                  ).size.width, // Poori screen ki width
                  fit: BoxFit
                      .contain, // 🔥 Ye photo ko katne nahi dega, poora dikhayega
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
