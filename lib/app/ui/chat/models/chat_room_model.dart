import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String chatRoomId; // Unique ID (e.g., "uid1_uid2")
  final List<String> participants; // Dono users ki UIDs [senderId, receiverId]
  final String lastMessage; // Dashboard par preview dikhane ke liye
  final String lastMessageSenderId; // Kisne aakhri message bheja
  final Timestamp lastMessageTime; // Sorting ke liye (Latest chat sabse upar)
  final Map<String, int>
  unreadCounts; // Har user ke unread messages track karne ke liye

  ChatRoomModel({
    required this.chatRoomId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.unreadCounts,
  });

  // 1. Convert Model to JSON (Firestore mein save karne ke liye)
  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'participants': participants,
      'last_message': lastMessage,
      'last_message_sender_id': lastMessageSenderId,
      'last_message_time': lastMessageTime,
      'unread_counts': unreadCounts,
    };
  }

  // 2. Create Model from Firestore Document (UI mein data convert karne ke liye)
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    // Map parsing ko safe banane ke liye cast karna zaroori hai
    Map<String, int> parsedUnread = {};
    if (json['unread_counts'] != null) {
      json['unread_counts'].forEach((key, value) {
        parsedUnread[key] = (value as num).toInt();
      });
    }

    return ChatRoomModel(
      chatRoomId: json['chatRoomId'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['last_message'] ?? '',
      lastMessageSenderId: json['last_message_sender_id'] ?? '',
      lastMessageTime: json['last_message_time'] ?? Timestamp.now(),
      unreadCounts: parsedUnread,
    );
  }
}
