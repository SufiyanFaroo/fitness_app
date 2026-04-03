// ignore_for_file: avoid_print
import 'package:fitness_app/data/services/notification_service.dart';
import 'package:fitness_app/core/utils/app_assets.dart';
import 'package:fitness_app/core/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
      appBar: _buildAppBar(context, isDark),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff92A3FD)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final String docId = notifications[index].id;

              // Header Logic: Today/Yesterday comparison
              bool showHeader =
                  index == 0 ||
                  data['day'] !=
                      (notifications[index - 1].data()
                          as Map<String, dynamic>)['day'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    _buildSectionHeader(data['day'] ?? "Today", isDark),
                  _buildNotificationItem(data, docId, index, isDark),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- AppBar Widget (Optimized for Equal Box Sizes) ---
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 65, // Equal spacing for leading box
      leading: Center(
        child: _buildTopBtn(
          Icons.arrow_back_ios_new,
          () => Navigator.pop(context),
          isDark,
          size: 15,
        ),
      ),
      title: Text(
        'Notification',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        Theme(
          data: Theme.of(context).copyWith(
            cardColor: isDark ? const Color(0xFF1D1B20) : Colors.white,
          ),
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero, // Alignment fix
            icon: _buildTopBtnIcon(Icons.more_horiz, isDark, size: 20),
            offset: const Offset(0, 50),
            onSelected: (value) async {
              if (value == 'clear_all') {
                await _service.clearAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Notifications Cleared"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Clear All',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15), // End padding to match leading
      ],
    );
  }

  // --- Individual Notification Item ---
  Widget _buildNotificationItem(
    Map<String, dynamic> data,
    String docId,
    int index,
    bool isDark,
  ) {
    final Color iconBgColor = index % 2 == 0
        ? const Color(0xff92A3FD).withValues(alpha: 0.12)
        : const Color(0xffC58BF2).withValues(alpha: 0.12);

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: _buildSwipeBackground(),
      onDismissed: (direction) => _service.deleteNotification(docId),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  AppAssets.getNotificationIcon(data['image'] ?? ""),
                  height: 25,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.notifications, color: Color(0xff92A3FD)),
                ),
              ),
            ),
            title: Text(
              data['title'] ?? "",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              data['time'] ?? "",
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            trailing: _buildPopupMenu(docId, isDark),
          ),
          Divider(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            thickness: 0.8,
          ),
        ],
      ),
    );
  }

  // --- Helper UI Components ---
  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.delete_forever, color: Colors.white),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 100,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          const SizedBox(height: 20),
          Text(
            "No Notifications",
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBtn(
    IconData icon,
    VoidCallback onTap,
    bool isDark, {
    double size = 15,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: _buildTopBtnIcon(icon, isDark, size: size),
    );
  }

  // Fixed Equal Box Size Logic
  Widget _buildTopBtnIcon(IconData icon, bool isDark, {double size = 15}) {
    return Container(
      height: 35, // Fixed square height
      width: 35, // Fixed square width
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: isDark ? Colors.white : Colors.black,
        size: size,
      ),
    );
  }

  Widget _buildPopupMenu(String docId, bool isDark) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      onSelected: (val) {
        if (val == 'delete') _service.deleteNotification(docId);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Text('Remove', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
