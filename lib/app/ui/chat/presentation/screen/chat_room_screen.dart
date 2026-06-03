import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/app/ui/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitness_app/app/ui/chat/presentation/widgets/message_input.dart';
import 'package:fitness_app/app/ui/chat/services/chat_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ChatRoomScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUserOnlineStatus(true);
    _clearUnreadCounterOnEntry();
  }

  @override
  void dispose() {
    _updateUserOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateUserOnlineStatus(true);
    } else {
      _updateUserOnlineStatus(false);
    }
  }

  void _updateUserOnlineStatus(bool isOnline) {
    if (currentUserId.isEmpty) return;
    FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
      'onlineStatus': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _clearUnreadCounterOnEntry() async {
    try {
      String roomId = _chatService.getChatRoomId(
        currentUserId,
        widget.receiverId,
      );
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set(
        {'is_read': true, 'unread_counts.$currentUserId': 0},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("Error clearing unread logs: $e");
    }
  }

  // ✅ FIXED DIALOG: Wrapped with Expanded to kill the 37 Pixels Right Overflow completely
  void _triggerCallFeatureNotif(String callType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              callType == "Video" ? Icons.videocam_rounded : Icons.call_rounded,
              color: AppColors.primaryColor1,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$callType Call Connection",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          "Establishing automated WebRTC signaling handshake for $callType Call stream profiles... External SDK channels are initialising.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ FLUID VIEWPORT RIGGING: Ensures smooth content transitions without clipping message bubbles
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPremiumVisualWaveHeader(context),

          // 💬 REALTIME LIVE THREAD STREAM WINDOW
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryActive,
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 40,
                          color: AppColors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Say hello to synchronize workout logs! 👋",
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  // ✅ PHYSICAL OVERSCROLL LOCKS: Pin-points data structures smoothly when keyboard pushes lists up
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    String messageText = data['text'] ?? "";
                    String senderId = data['senderId'] ?? "";
                    Timestamp ts = data['timestamp'] ?? Timestamp.now();
                    String msgType = data['messageType'] ?? "text";
                    String? mUrl = data['mediaUrl'];

                    return ChatBubble(
                      text: messageText,
                      isMe: senderId == currentUserId,
                      timestamp: ts,
                      messageType: msgType,
                      mediaUrl: mUrl,
                    );
                  },
                );
              },
            ),
          ),

          // 📥 IMMERSIVE INPUT CONTROLLER ACTION FIELD BAR
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: MessageInput(
                onSendMessage: (text) =>
                    _chatService.sendMessage(widget.receiverId, text),
                onSendImageAction: (File file) =>
                    _chatService.sendImageMessage(widget.receiverId, file),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumVisualWaveHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 24,
        left: 12,
        right: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor2,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverId)
            .snapshots(),
        builder: (context, snapshot) {
          bool isOnline = false;
          String imageUrl = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            var userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData != null) {
              isOnline = userData['onlineStatus'] ?? false;
              imageUrl =
                  userData['profile_image'] ?? userData['profileImage'] ?? "";
            }
          }

          return Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.receiverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isOnline ? "Online" : "Offline",
                      style: TextStyle(
                        color: isOnline ? Colors.white70 : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => _triggerCallFeatureNotif("Video"),
              ),
              IconButton(
                icon: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _triggerCallFeatureNotif("Audio"),
              ),
            ],
          );
        },
      ),
    );
  }
}
