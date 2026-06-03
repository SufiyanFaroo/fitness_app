import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/app/ui/chat/services/chat_request_service.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // ✅ Pro Loading Animation

class ChatRequestsScreen extends StatelessWidget {
  const ChatRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1D1B20) : Colors.white;
    final Color cardColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF7F8F8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Pending Requests",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ChatRequestService().getIncomingRequestsStream(),
        builder: (context, snapshot) {
          // ✅ 1. PRO LOADING: Shimmer Effect instead of basic spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoadingList(cardColor);
          }

          // ✅ 2. PRO EMPTY STATE: Visual placeholder when no requests exist
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildPremiumEmptyState(isDark);
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var data = requests[index].data() as Map<String, dynamic>;
              String senderUid = data['senderId'] ?? "";
              String requestId = requests[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(senderUid)
                    .get(),
                builder: (context, userSnapshot) {
                  // Wait for user data to load with a single shimmer tile
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildSingleShimmerTile(cardColor);
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  String userName =
                      userData['full_name'] ??
                      userData['name'] ??
                      'FitQuest User';
                  String userImage = userData['profile_image'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Softer, modern corners
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        backgroundImage:
                            userImage.isNotEmpty && userImage.startsWith('http')
                            ? NetworkImage(userImage)
                            : null,
                        child:
                            userImage.isEmpty || !userImage.startsWith('http')
                            ? Icon(
                                Icons.person_rounded,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                                size: 28,
                              )
                            : null,
                      ),
                      title: Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Wants to connect",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ 3. PREMIUM ACTION BUTTONS: Soft background highlights
                          _buildSoftActionButton(
                            icon: Icons.close_rounded,
                            color: Colors.red,
                            onTap: () async {
                              await ChatRequestService().handleRequestAction(
                                requestId: requestId,
                                senderUid: senderUid,
                                accept: false,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildSoftActionButton(
                            icon: Icons.check_rounded,
                            color: Colors.green,
                            onTap: () async {
                              await ChatRequestService().handleRequestAction(
                                requestId: requestId,
                                senderUid: senderUid,
                                accept: true,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Connected with $userName!"),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildSoftActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15), // Soft translucent background
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildPremiumEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              size: 50,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No pending chat requests right now.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoadingList(Color cardColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSingleShimmerTile(cardColor),
    );
  }

  Widget _buildSingleShimmerTile(Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(0.2),
        highlightColor: Colors.grey.withOpacity(0.1),
        child: Row(
          children: [
            const CircleAvatar(radius: 26, backgroundColor: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Container(height: 12, width: 80, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const CircleAvatar(radius: 18, backgroundColor: Colors.white),
            const SizedBox(width: 8),
            const CircleAvatar(radius: 18, backgroundColor: Colors.white),
          ],
        ),
      ),
    );
  }
}
