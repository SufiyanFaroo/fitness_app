import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/app/ui/chat/services/chat_service.dart'; // Path verify karlein
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_room_screen.dart';

class ChatDashboardScreen extends StatefulWidget {
  const ChatDashboardScreen({super.key});

  @override
  State<ChatDashboardScreen> createState() => _ChatDashboardScreenState();
}

class _ChatDashboardScreenState extends State<ChatDashboardScreen> {
  final ChatService _chatService = ChatService();
  String _searchQuery = "";
  String _activeFilterTab = "All Chats";

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildUltraTopHeaderPanel(),
            _buildPremiumPillFilterBar(),
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildGlobalSearchResults()
                  : _buildSelectedTabViewEngine(),
            ),
          ],
        ),
      ),
    );
  }

  // 1️⃣ Custom Top Header View Block with Embedded Three-Dot Modal Bridge
  Widget _buildUltraTopHeaderPanel() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor2,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Hello, Sufiyan",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // 🛑 THREE-DOT MENU: Professional Custom Option Router
                PopupMenuButton<String>(
                  elevation: 10,
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  // backgroundColor: Colors.white,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onSelected: (value) {
                    if (value == "sent_requests") {
                      _showSentRequestsBottomSheet(); // Modal popup invocation
                    }
                  },
                  itemBuilder: (context) => [
                    _buildPopupMenuItem(
                      "sent_requests",
                      Icons.outbox_rounded,
                      "Sent Requests Logs",
                    ),
                    _buildPopupMenuItem(
                      "unfollow",
                      Icons.person_remove_rounded,
                      "Unfollow Settings",
                    ),
                    const PopupMenuDivider(height: 1),
                    _buildPopupMenuItem(
                      "clear",
                      Icons.cleaning_services_rounded,
                      "Clear Caches",
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "You Received",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getActiveChatRooms(),
                  builder: (context, snapshot) {
                    int dynamicRoomCounter = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return Text(
                      "$dynamicRoomCounter Messages",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
                style: const TextStyle(color: AppColors.black, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "Search fitness partners...",
                  hintStyle: TextStyle(color: AppColors.greyText, fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryColor1,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPremiumHorizontalPresenceTray(),
        ],
      ),
    );
  }

  Widget _buildPremiumHorizontalPresenceTray() {
    return SizedBox(
      height: 80,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          var activeUsers = snapshot.data!.docs
              .where(
                (doc) =>
                    doc.id != _chatService.currentUserId &&
                    (doc.data() as Map)['onlineStatus'] == true,
              )
              .toList();
          if (activeUsers.isEmpty) return const SizedBox.shrink();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              var data = activeUsers[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: Column(
                  children: [
                    _buildPremiumDynamicAvatar(
                      data['profile_image'] ?? "",
                      true,
                      radius: 22,
                      hasWhiteBorder: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (data['full_name'] ?? 'User').toString().split(" ")[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPremiumPillFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 6.0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildSingleFilterPill("All Chats"),
            _buildSingleFilterPill("Followers"),
            _buildSingleFilterPill("Following"),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleFilterPill(String title) {
    bool isSelected = _activeFilterTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _searchFocusNode.unfocus();
          setState(() => _activeFilterTab = title);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabViewEngine() {
    return _activeFilterTab == "All Chats"
        ? _buildActiveChatRoomsList()
        : Center(child: Text("No connection data in $_activeFilterTab."));
  }

  // 2️⃣ ✅ FIXED: Direct Active Chats Rendering Engine (Strict Acceptance Verification Barrier)
  Widget _buildActiveChatRoomsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getActiveChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryActive),
          );
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return _buildPremiumEmptyStateLayout();

        var rooms = snapshot.data!.docs;

        return StreamBuilder<QuerySnapshot>(
          stream: _chatService.getConnectionStream(),
          builder: (context, netSnapshot) {
            // Mapping connection arrays into hash references
            Set<String> approvedFriendUids = {};
            if (netSnapshot.hasData) {
              for (var doc in netSnapshot.data!.docs) {
                var d = doc.data() as Map<String, dynamic>;
                if (d['status'] == 'accepted') {
                  approvedFriendUids.add(d['senderId']);
                  approvedFriendUids.add(d['receiverId']);
                }
              }
            }

            // Filtering down active folders elements layout
            var validRooms = rooms.where((roomDoc) {
              var rData = roomDoc.data() as Map<String, dynamic>;
              List participants = rData['participants'] ?? [];
              String targetUserId = participants.firstWhere(
                (id) => id != _chatService.currentUserId,
                orElse: () => "",
              );
              return approvedFriendUids.contains(targetUserId);
            }).toList();

            if (validRooms.isEmpty) return _buildPremiumEmptyStateLayout();

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: validRooms.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.borderColor,
                indent: 85,
              ),
              itemBuilder: (context, index) {
                var roomData = validRooms[index].data() as Map<String, dynamic>;
                String lastMsg = roomData['last_message'] ?? '';
                Timestamp lastTime =
                    roomData['last_message_time'] ?? Timestamp.now();
                List segments = roomData['participants'] ?? [];
                String targetUserId = segments.firstWhere(
                  (id) => id != _chatService.currentUserId,
                  orElse: () => "",
                );

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUserId)
                      .snapshots(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData || !userSnap.data!.exists)
                      return const SizedBox.shrink();
                    var userData =
                        userSnap.data!.data() as Map<String, dynamic>;
                    String name =
                        userData['full_name'] ?? userData['name'] ?? 'User';
                    bool isOnline = userData['onlineStatus'] ?? false;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: _buildPremiumDynamicAvatar(
                        userData['profile_image'] ?? "",
                        isOnline,
                        radius: 25,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            DateFormat('hh:mm a').format(lastTime.toDate()),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor1,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          "1",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => _openChat(targetUserId, name),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // 3️⃣ Global Discovery Result Handlers
  Widget _buildGlobalSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryActive),
          );

        var users = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['full_name'] ?? data['name'] ?? '')
              .toString()
              .toLowerCase();
          return doc.id != _chatService.currentUserId &&
              name.contains(_searchQuery);
        }).toList();

        if (users.isEmpty)
          return const Center(
            child: Text(
              "No registered fitness partners found.",
              style: TextStyle(color: AppColors.greyText),
            ),
          );

        return StreamBuilder<QuerySnapshot>(
          stream: _chatService.getConnectionStream(),
          builder: (context, netSnapshot) {
            Map<String, String> connectionStates = {};
            if (netSnapshot.hasData) {
              for (var doc in netSnapshot.data!.docs) {
                var d = doc.data() as Map<String, dynamic>;
                if (d['senderId'] == _chatService.currentUserId)
                  connectionStates[d['receiverId']] = "sent_${d['status']}";
                if (d['receiverId'] == _chatService.currentUserId)
                  connectionStates[d['senderId']] = "received_${d['status']}";
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: users.length,
              itemBuilder: (context, index) {
                var userData = users[index].data() as Map<String, dynamic>;
                String targetUid = users[index].id;
                String name =
                    userData['full_name'] ?? userData['name'] ?? 'User';
                String state = connectionStates[targetUid] ?? "none";

                return Card(
                  elevation: 0,
                  color: AppColors.borderColor.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: _buildPremiumDynamicAvatar(
                      userData['profile_image'] ?? "",
                      false,
                      radius: 24,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                        fontSize: 15,
                      ),
                    ),
                    trailing: _buildSocialActionButton(targetUid, state, name),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSocialActionButton(String targetUid, String state, String name) {
    if (state == "none") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryActive,
          shape: const StadiumBorder(),
        ),
        onPressed: () => _chatService.sendFriendRequest(targetUid),
        child: const Text(
          "Follow",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (state == "sent_pending") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          shape: const StadiumBorder(),
        ),
        onPressed: () => _chatService.rejectFriendRequest(targetUid),
        child: const Text(
          "Requested",
          style: TextStyle(color: Colors.black87, fontSize: 12),
        ),
      );
    } else if (state == "received_pending") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: const StadiumBorder(),
        ),
        onPressed: () => _chatService.acceptFriendRequest(targetUid),
        child: const Text(
          "Accept",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (state.contains("accepted")) {
      return IconButton(
        icon: const Icon(
          Icons.messenger_outline_rounded,
          color: AppColors.primaryColor1,
          size: 22,
        ),
        onPressed: () => _openChat(targetUid, name),
      );
    }
    return const SizedBox.shrink();
  }

  // 4️⃣ ✅ NEW COMPONENT: Premium Sent Requests Modal Sheet Interface Panel
  void _showSentRequestsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Sent Follow Requests",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.grey,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderColor),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getSentRequestsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No outbound requests pending.",
                          style: TextStyle(color: AppColors.grey),
                        ),
                      );
                    }
                    var sentLogs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: sentLogs.length,
                      itemBuilder: (context, index) {
                        var logData =
                            sentLogs[index].data() as Map<String, dynamic>;
                        String receiverId = logData['receiverId'] ?? "";

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(receiverId)
                              .get(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData || !userSnap.data!.exists)
                              return const SizedBox.shrink();
                            var uData =
                                userSnap.data!.data() as Map<String, dynamic>;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              leading: _buildPremiumDynamicAvatar(
                                uData['profile_image'] ?? "",
                                false,
                                radius: 22,
                              ),
                              title: Text(
                                uData['full_name'] ?? 'Member',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                "Waiting for approval...",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                              trailing: TextButton(
                                onPressed: () {
                                  _chatService.rejectFriendRequest(receiverId);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryColor1, size: 20),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    // Dynamic logic handles the snacker triggers
  }

  Widget _buildPremiumDynamicAvatar(
    String imageUrl,
    bool isOnline, {
    required double radius,
    bool hasWhiteBorder = false,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasWhiteBorder ? null : AppColors.primaryGradient,
            color: hasWhiteBorder ? Colors.white38 : null,
          ),
          padding: const EdgeInsets.all(2.5),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl.isEmpty
                ? Icon(
                    Icons.person,
                    color: AppColors.primaryColor1,
                    size: radius * 0.9,
                  )
                : null,
          ),
        ),
        if (isOnline)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumEmptyStateLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 50,
            color: AppColors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 14),
          const Text(
            "Your inbox is empty",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.black,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Search users to follow and start conversation loops.",
            style: TextStyle(color: AppColors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _openChat(String id, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatRoomScreen(receiverId: id, receiverName: name),
      ),
    );
  }
}
