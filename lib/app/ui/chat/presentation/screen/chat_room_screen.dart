import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/app/ui/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitness_app/app/ui/chat/presentation/widgets/message_input.dart';
import 'package:fitness_app/app/ui/chat/services/chat_service.dart';
import 'package:fitness_app/core/constants/app_colors.dart'; // Brand token imports
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

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🏆 WAVE HEADER LAYER: Premium Curved Multi-Action Custom Panel
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 40,
                          color: AppColors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 10),
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
                  physics: const BouncingScrollPhysics(),
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
            child: MessageInput(
              onSendMessage: (text) =>
                  _chatService.sendMessage(widget.receiverId, text),
              onSendImageAction: (File file) =>
                  _chatService.sendImageMessage(widget.receiverId, file),
            ),
          ),
        ],
      ),
    );
  }

  // High-Fidelity Custom Wave App Bar Component matching your uploaded layout blueprint
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
          bottomRight: Radius.circular(
            0,
          ), // Signature custom asymmetrical premium layout rules
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
              imageUrl = userData['profile_image'] ?? "";
            }
          }

          return Row(
            children: [
              // Back Navigation Controller Action
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              // Target Participant Avatar Core Layer
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

              // Title Typography Stack
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

              // Multi-Action Communication Tray Icons
              IconButton(
                icon: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}
