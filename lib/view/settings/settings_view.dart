import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitness_app/data/services/settings_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GallerySettingsView extends StatefulWidget {
  const GallerySettingsView({super.key});

  @override
  State<GallerySettingsView> createState() => _GallerySettingsViewState();
}

class _GallerySettingsViewState extends State<GallerySettingsView> {
  final SettingsService _settingsService = SettingsService();
  bool _isReminderOn = true;
  bool _isHighQuality = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoredPreferences();
  }

  // 🔥 1. Load Local Storage Data
  Future<void> _loadStoredPreferences() async {
    final reminders = await _settingsService.getGalleryReminders();
    final hdPreview = await _settingsService.getHdPreview();
    setState(() {
      _isReminderOn = reminders;
      _isHighQuality = hdPreview;
      _isLoading = false;
    });
  }

  // 🔥 2. Update Preferences
  Future<void> _updatePreference(String key, bool value) async {
    if (key == 'gallery_reminders') {
      await _settingsService.updateGalleryReminders(value);
    } else if (key == 'hd_preview') {
      await _settingsService.updateHdPreview(value);
    }
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${key == 'gallery_reminders' ? 'Reminders' : 'HD Preview'} updated",
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF9B81FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 🔥 3. Dynamic Support Sheet (Copy & Connect Logic)
  void _showSupportOptions(BuildContext context, bool isDark) {
    const String myNumber = "+923273062720";
    const String myEmail = "sufiyanfarooq33@gmail.com";

    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1B20) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Contact Support",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            _buildContactTile(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              title: "WhatsApp",
              value: myNumber,
              onCopy: () => _copyToClipboard(context, myNumber, "Number"),
              onConnect: () => _launchWhatsApp(myNumber),
            ),

            const SizedBox(height: 15),

            _buildContactTile(
              context,
              icon: Icons.alternate_email_rounded,
              title: "Email",
              value: myEmail,
              onCopy: () => _copyToClipboard(context, myEmail, "Email"),
              onConnect: () => _launchEmail(myEmail),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $type Copied"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri url = Uri.parse("https://wa.me/${phone.replaceAll('+', '')}");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchEmail(String email) async {
    final Uri url = Uri.parse("mailto:$email?subject=FitQuest Support");
    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDark ? const Color(0xFF1D1B20) : Colors.white;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: surfaceColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildSectionHeader("Preferences"),
          _buildToggleTile(
            Icons.notifications_active_outlined,
            "Reminders",
            "Monthly photo alerts",
            _isReminderOn,
            (val) {
              setState(() => _isReminderOn = val);
              _updatePreference('gallery_reminders', val);
            },
          ),
          _buildToggleTile(
            Icons.high_quality_outlined,
            "HD Preview",
            "High-res images",
            _isHighQuality,
            (val) {
              setState(() => _isHighQuality = val);
              _updatePreference('hd_preview', val);
            },
          ),

          const SizedBox(height: 25),
          _buildSectionHeader("Support"),
          _buildActionTile(
            Icons.help_center_outlined,
            "Help Center",
            "Contact Us",
            isDark,
            () => _showSupportOptions(context, isDark),
          ),
          _buildActionTile(
            Icons.privacy_tip_outlined,
            "Privacy Policy",
            "View Policy",
            isDark,
            () {},
          ),

          const SizedBox(height: 50),
          Center(
            child: Text(
              "Version 1.0.2",
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF9B81FF),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    String sub,
    bool val,
    Function(bool) onChange,
  ) {
    return ListTile(
      leading: _buildIconBox(icon),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Switch.adaptive(
        value: val,
        activeColor: const Color(0xFF9B81FF),
        onChanged: onChange,
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String trailing,
    bool isDark,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: _buildIconBox(icon),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        trailing,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF9B81FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF9B81FF), size: 20),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onCopy,
    required VoidCallback onConnect,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9B81FF)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: onCopy),
          IconButton(
            icon: const Icon(
              Icons.open_in_new,
              size: 18,
              color: Color(0xFF9B81FF),
            ),
            onPressed: onConnect,
          ),
        ],
      ),
    );
  }
}
