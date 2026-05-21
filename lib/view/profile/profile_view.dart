// ignore_for_file: avoid_print
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/app/ui/chat/presentation/screen/chat_dashboard_screen.dart';
import 'package:fitness_app/data/services/fitness_repository.dart';
import 'package:fitness_app/data/services/profile_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitness_app/app/ui/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; // Naya import share ke liye

class ProfileView extends StatefulWidget {
  final VoidCallback onBack;
  const ProfileView({super.key, required this.onBack});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileService _service = ProfileService();
  bool _isUploading = false;
  String? _localImagePath;
  final FitnessRepository _repo = FitnessRepository();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _localImagePath = prefs.getString('user_profile_local_${_service.uid}');
      });
    }
  }

  Future<void> _handleImagePicker() async {
    final ImagePicker picker = ImagePicker();
    final prefs = await SharedPreferences.getInstance();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (image != null) {
      setState(() {
        _isUploading = true;
        _localImagePath = image.path;
      });

      await prefs.setString('user_profile_local_${_service.uid}', image.path);

      try {
        String? downloadUrl = await _repo.uploadProfileImage(File(image.path));

        if (downloadUrl != null) {
          await _repo.updateUserProfile({"profile_image": downloadUrl});
          _showSnackBar("Profile Updated Successfully! ✅");
        }
      } catch (e) {
        _showSnackBar("Upload Failed: $e", isError: true);
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty || dob == "---") return "---";
    try {
      List<String> parts = dob.split('-');
      int birthYear = int.parse(parts[parts.length - 1]);
      return "${DateTime.now().year - birthYear}yo";
    } catch (e) {
      return "---";
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _service.logoutUser();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_service.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "User Name",
            program = "Lose a Fat Program",
            height = "---",
            weight = "---",
            age = "---";
        String? firestoreImageUrl;
        bool notificationsEnabled = true;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['full_name'] ?? data['name'] ?? "User";
          program = data['program'] ?? "Lose a Fat Program";
          height = data['height'] ?? "---";
          weight = data['weight'] ?? "---";
          firestoreImageUrl = data['profile_image'];
          notificationsEnabled = data['notifications_enabled'] ?? true;
          age = data['age'] ?? _calculateAge(data['dob']);
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF1D1B20) : AppColors.white,
          appBar: _buildAppBar(isDark, name, program),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildProfileHeader(
                  isDark,
                  name,
                  program,
                  firestoreImageUrl,
                  _localImagePath,
                ),
                const SizedBox(height: 25),
                _buildPhysicalStats(isDark, height, weight, age),
                const SizedBox(height: 25),

                // 🔥 Professional Chat Entry Action Button Card
                _buildCommunityChatCard(isDark),

                const SizedBox(height: 10),
                _buildSection("Account", [
                  _menuRow(Icons.person_outline, "Personal Data", isDark),
                  _menuRow(Icons.emoji_events_outlined, "Achievement", isDark),
                  _buildToggleRow(
                    Icons.notifications_none_outlined,
                    "Pop-up Notification",
                    notificationsEnabled,
                    isDark,
                    (val) => _service.updateNotificationPreference(val),
                  ),
                  _menuRow(Icons.pie_chart_outline, "Activity History", isDark),
                ], isDark),
                _buildThemeSection(isDark, themeProvider),
                _buildSection("Other", [
                  _menuRow(
                    Icons.contact_support_outlined,
                    "Contact Us",
                    isDark,
                  ),
                  _menuRow(
                    Icons.privacy_tip_outlined,
                    "Privacy Policy",
                    isDark,
                  ),
                ], isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔥 Professional Premium Chat Action Card Widget
  Widget _buildCommunityChatCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff92A3FD), Color(0xff9DCEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff92A3FD).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Fitness Community",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Chat with trainers and partners",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact(); // Premium vibration feel
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatDashboardScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff92A3FD),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              "Open",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isDark, String name, String program) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "Profile",
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: widget.onBack,
        icon: Icon(
          Icons.arrow_back_ios,
          color: isDark ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          icon: Icon(
            Icons.more_horiz,
            color: isDark ? Colors.white : Colors.black,
          ),
          onSelected: (val) async {
            if (val == 'share') {
              await _shareProfile(name, program);
            } else if (val == 'logout') {
              _confirmLogout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_outlined, size: 18),
                  SizedBox(width: 10),
                  Text("Share Profile"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Logout", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Future<void> _shareProfile(String name, String program) async {
    final String appLink =
        "https://play.google.com/store/apps/details?id=com.fitquest.app";
    final String message =
        "Check out $name's fitness progress in the $program on FitQuest! 💪\n\nDownload now: $appLink";

    try {
      await Share.share(message);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not share profile")));
    }
  }

  Widget _buildProfileHeader(
    bool isDark,
    String name,
    String program,
    String? firestoreUrl,
    String? localPath,
  ) {
    return Row(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: _buildImageProvider(firestoreUrl, localPath),
              ),
              if (_isUploading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                program,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        _buildGradientButton("Edit", _handleImagePicker),
      ],
    );
  }

  Widget _buildImageProvider(String? firestoreUrl, String? localPath) {
    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        width: 70,
        height: 70,
      );
    }
    if (firestoreUrl != null && firestoreUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: firestoreUrl,
        fit: BoxFit.cover,
        width: 70,
        height: 70,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 1)),
        errorWidget: (context, url, error) =>
            Image.asset(AppAssets.Profile_images, fit: BoxFit.cover),
      );
    }
    return Image.asset(
      AppAssets.Profile_images,
      fit: BoxFit.cover,
      width: 70,
      height: 70,
    );
  }

  Widget _buildPhysicalStats(bool isDark, String h, String w, String a) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statCard(h, "Height", isDark),
        _statCard(w, "Weight", isDark),
        _statCard(a, "Age", isDark),
      ],
    );
  }

  Widget _statCard(String val, String title, bool isDark) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              color: Color(0xff92A3FD),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...items,
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String txt, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff00FAD9), size: 22),
          const SizedBox(width: 15),
          Text(txt, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark ? Colors.white24 : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    IconData icon,
    String title,
    bool value,
    bool isDark,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff00FAD9), size: 22),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Switch(
            value: value,
            activeTrackColor: const Color(0xffC58BF2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(bool isDark, ThemeProvider provider) {
    return _buildSection("Settings", [
      _buildToggleRow(
        isDark ? Icons.dark_mode : Icons.light_mode,
        "Dark Mode",
        isDark,
        isDark,
        (val) => provider.toggleTheme(val),
      ),
    ], isDark);
  }

  Widget _buildGradientButton(String txt, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffCC8FED), Color(0xff6B50F6)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          txt,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
