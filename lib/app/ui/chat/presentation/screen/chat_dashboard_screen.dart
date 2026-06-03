import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/app/ui/chat/presentation/screen/chat_requests_screen.dart';
import 'package:fitness_app/app/ui/chat/presentation/screen/chat_room_screen.dart';
import 'package:fitness_app/app/ui/chat/services/chat_service.dart'; // Path verify karlein
import 'package:fitness_app/app/ui/chat/services/status_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// ✅ IMPORT LINK: Connects your incoming request sheet smoothly
//import 'package:fitness_app/view/chat/chat_requests_screen.dart'; // Apna actual directory route confirm karlein

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

  Widget _buildUltraTopHeaderPanel() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor1,
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

                // ✅ INTERACTION HUB: Added real-time requests counter badge alongside settings popup
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('friends_network') // Sahi collection
                          .where(
                            'receiverId',
                            isEqualTo: _chatService.currentUserId,
                          ) // Sahi field!
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        // ✅ PRO TIP: Agar error aaye ya load ho raha ho toh crash se bachne ke liye default '0' requests show karein
                        if (snapshot.hasError ||
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return _buildNotificationIcon(context, 0);
                        }

                        int requestCount = snapshot.data?.docs.length ?? 0;

                        return _buildNotificationIcon(context, requestCount);
                      },
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      elevation: 10,
                      offset: const Offset(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onSelected: (value) {
                        if (value == "sent_requests") {
                          _showSentRequestsBottomSheet();
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
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    var rooms = snapshot.data!.docs;
                    int unreadRoomsCount = 0;

                    for (var roomDoc in rooms) {
                      var roomData = roomDoc.data() as Map<String, dynamic>;
                      String lastSenderId =
                          roomData['last_message_sender_id'] ?? '';
                      bool isRead = roomData['is_read'] ?? true;
                      if (lastSenderId != _chatService.currentUserId &&
                          !isRead) {
                        unreadRoomsCount++;
                      }
                    }

                    if (unreadRoomsCount == 0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "$unreadRoomsCount New Messages",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
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
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
                style: const TextStyle(color: AppColors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search fitness partners...",
                  hintStyle: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryColor1,
                    size: 22,
                  ),

                  // ✅ PROFESSIONAL CLEARANCE ICON
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: AppColors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController
                                .clear(); // Controller se text saaf karega
                            setState(
                              () => _searchQuery = "",
                            ); // Query reset karega
                            _searchFocusNode.unfocus(); // Keyboard hide karega
                          },
                        )
                      : null,

                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildNotificationIcon(BuildContext context, int count) {
    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0, // Sirf tab dikhe jab requests 0 se zyada hon
        backgroundColor: Colors.redAccent,
        label: Text(
          "$count",
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: const Icon(
          Icons.group_add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatRequestsScreen()),
        );
      },
    );
  }

  Widget _buildPremiumHorizontalPresenceTray() {
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          // ✅ 1. MY STATUS BUTTON (Add new status)
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 10.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadStatus, // Function neeche diya gaya hai
                  child: Stack(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFF7F8F8),
                        child: Icon(Icons.person, color: Colors.grey, size: 30),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 9,
                            backgroundColor: AppColors.primaryColor1,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "My Status",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ✅ 2. FRIENDS STATUSES STREAM
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
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
                  padding: const EdgeInsets.only(right: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: activeUsers.length,
                  itemBuilder: (context, index) {
                    var data =
                        activeUsers[index].data() as Map<String, dynamic>;
                    String name = (data['full_name'] ?? 'User')
                        .toString()
                        .split(" ")[0];
                    String imageUrl = data['profile_image'] ?? "";

                    return Padding(
                      padding: const EdgeInsets.only(right: 14.0),
                      child: Column(
                        children: [
                          // ✅ 3. GRADIENT STORY RING (Halo Effect)
                          Container(
                            padding: const EdgeInsets.all(
                              2.5,
                            ), // Ring ki thickness
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xffC58BF2),
                                  Color(0xff92A3FD),
                                ], // FitQuest style gradient
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(
                                2,
                              ), // White gap inside ring
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: data['statusData'] != null
                                    ? MemoryImage(
                                        base64Decode(data['statusData']),
                                      )
                                    : null,
                                child:
                                    imageUrl.isEmpty ||
                                        !imageUrl.startsWith('http')
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Image Picker & Upload Function
  // File ke top par yeh dono imports lazmi hone chahiye:
  // import 'dart:io';
  // import 'package:fitness_app/app/ui/chat/services/status_service.dart';

  Future<void> _pickAndUploadStatus() async {
    final picker = ImagePicker();
    // Image ya Video dono select ho sakti hain
    final pickedFile = await picker.pickMedia(imageQuality: 70);

    if (pickedFile != null) {
      // 1. UPLOADING INDICATOR: User ko batayein ke kaam background mein shuru ho gaya hai
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 15),
                Text("Uploading Status... Please wait."),
              ],
            ),
            backgroundColor: AppColors.primaryColor1,
            duration: Duration(seconds: 4), // Jab tak upload hota hai
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      try {
        // 2. REAL FIREBASE UPLOAD: Yahan tasveer actually database aur storage mein jayegi
        await StatusService().uploadStatus(File(pickedFile.path));

        // 3. SUCCESS NOTIFICATION: Upload mukammal hone par
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).hideCurrentSnackBar(); // Loading wala message hatayein
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Status Uploaded Successfully! 🚀"),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (error) {
        // 4. CRASH PROTECTION & ERROR HANDLING (Naya Debug Code)
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // ✅ YAHAN CHANGE KIYA HAI: 'const' hata diya aur $error laga diya
              content: Text("Upload failed: $error"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(
                seconds: 8,
              ), // 8 second tak show hoga taake aap parh sakein
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
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
    switch (_activeFilterTab) {
      case "All Chats":
        return _buildActiveChatRoomsList();
      case "Followers":
        return _buildFollowersList(); // Naya method banayein
      case "Following":
        return _buildFollowingList(); // Naya method banayein
      default:
        return _buildActiveChatRoomsList();
    }
  }

  // ✅ Followers List Engine
  Widget _buildFollowersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friends_network')
          .where('receiverId', isEqualTo: _chatService.currentUserId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No followers yet."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            // ✅ CRASH FIX: Safe Data Extraction
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var senderId = data['senderId'] ?? data['sender_uid'] ?? "";

            if (senderId.isEmpty) return const SizedBox.shrink();
            return _buildUserTile(senderId);
          },
        );
      },
    );
  }

  // ✅ Following List Engine
  Widget _buildFollowingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friends_network')
          .where('senderId', isEqualTo: _chatService.currentUserId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("You are not following anyone."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            // ✅ CRASH FIX: Safe Data Extraction
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var receiverId = data['receiverId'] ?? data['receiver_uid'] ?? "";

            if (receiverId.isEmpty) return const SizedBox.shrink();
            return _buildUserTile(receiverId);
          },
        );
      },
    );
  }

  Widget _buildUserTile(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        var data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        String name = data['full_name'] ?? data['name'] ?? 'User';
        bool isOnline = data['onlineStatus'] ?? false;

        return ListTile(
          // ✅ PRO UI: Asli tasveer aur Live Status
          leading: _buildPremiumDynamicAvatar(
            data['profile_image'] ?? "",
            isOnline,
            radius: 22,
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(
            Icons.messenger_outline_rounded,
            color: AppColors.primaryColor1,
          ),
          // ✅ BUG FIX: Ab click karne par chat open hogi!
          onTap: () => _openChat(userId, name),
        );
      },
    );
  }

  // ✅ 1. FIXED: Efficiently build friendship set (Ensure Firestore fields match these)
  Widget _buildActiveChatRoomsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getActiveChatRooms(),
      builder: (context, snapshot) {
        // ✅ INDEX TRACKER: Agar index abhi bhi ban raha hai Firebase mein
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Database Index is building...\nPlease wait 2-3 minutes.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryActive),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildPremiumEmptyStateLayout();
        }

        var rooms = snapshot.data!.docs;

        return StreamBuilder<QuerySnapshot>(
          stream: _chatService.getConnectionStream(),
          builder: (context, netSnapshot) {
            Set<String> approvedFriendUids = {};
            if (netSnapshot.hasData) {
              for (var doc in netSnapshot.data!.docs) {
                var d = doc.data() as Map<String, dynamic>;
                if (d['status'] == 'accepted') {
                  // ✅ BUG FIX: Naye aur purane dono IDs ko friend list mein add karein
                  approvedFriendUids.add(
                    (d['senderId'] ?? d['sender_uid'] ?? "").toString(),
                  );
                  approvedFriendUids.add(
                    (d['receiverId'] ?? d['receiver_uid'] ?? "").toString(),
                  );
                }
              }
            }

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
              itemCount: validRooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 85),
              itemBuilder: (context, index) {
                var roomData = validRooms[index].data() as Map<String, dynamic>;
                List participants = roomData['participants'] ?? [];
                String targetUserId = participants.firstWhere(
                  (id) => id != _chatService.currentUserId,
                  orElse: () => "",
                );

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUserId)
                      .snapshots(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData || !userSnap.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    var userData =
                        userSnap.data!.data() as Map<String, dynamic>;

                    String name =
                        userData['full_name'] ?? userData['name'] ?? 'User';
                    bool isOnline = userData['onlineStatus'] ?? false;
                    String imageUrl = userData['profile_image'] ?? "";

                    String lastMessage = roomData['last_message'] ?? '';
                    Timestamp lastTime =
                        roomData['last_message_time'] ?? Timestamp.now();
                    String lastSenderId =
                        roomData['last_message_sender_id'] ?? '';
                    bool isRead = roomData['is_read'] ?? true;
                    bool showUnreadBadge =
                        (lastSenderId != _chatService.currentUserId && !isRead);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: _buildPremiumDynamicAvatar(
                        imageUrl,
                        isOnline,
                        radius: 25,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: showUnreadBadge
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: showUnreadBadge ? Colors.black : Colors.grey,
                          fontWeight: showUnreadBadge
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: showUnreadBadge
                          ? Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryColor1,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                "1",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          : Text(
                              DateFormat('hh:mm a').format(lastTime.toDate()),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                      onTap: () {
                        FirebaseFirestore.instance
                            .collection('chat_rooms')
                            .doc(validRooms[index].id)
                            .update({'is_read': true});
                        _openChat(targetUserId, name);
                      },
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
                  color: AppColors.borderColor.withValues(alpha: 0.2),
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

  void _showSentRequestsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sent Requests",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getSentRequestsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryActive,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptySentState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var logData =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        String receiverId = logData['receiverId'] ?? "";

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(receiverId)
                              .get(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData)
                              return const SizedBox.shrink();
                            var uData =
                                userSnap.data!.data() as Map<String, dynamic>?;
                            if (uData == null) return const SizedBox.shrink();

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: _buildPremiumDynamicAvatar(
                                  uData['profile_image'] ?? "",
                                  false,
                                  radius: 22,
                                ),
                                title: Text(
                                  uData['full_name'] ??
                                      uData['name'] ??
                                      'FitQuest User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  "Pending request",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[50],
                                    foregroundColor: Colors.red,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                  ),
                                  onPressed: () async {
                                    bool? confirm =
                                        await _showCancelConfirmation();
                                    if (confirm == true) {
                                      await _chatService.cancelSentRequest(
                                        receiverId,
                                      );

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Follow request retracted securely.",
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
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

  Future<bool?> _showCancelConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Cancel Request",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to retract this outbound follow handshake loop?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Discard",
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.outbox_rounded, size: 45, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            "No active pending requests discovered.",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
            color: AppColors.grey.withValues(alpha: 0.3),
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

  void _openChat(String id, String name) async {
    String chatRoomId = _chatService.currentUserId.compareTo(id) > 0
        ? "${_chatService.currentUserId}_$id"
        : "${id}_${_chatService.currentUserId}";

    // Use set with merge:true to handle both new and existing rooms
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .set({
          'is_read': true,
          'last_message_sender_id': id,
          'participants': [_chatService.currentUserId, id],
        }, SetOptions(merge: true));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatRoomScreen(receiverId: id, receiverName: name),
        ),
      );
    }
  }
}
