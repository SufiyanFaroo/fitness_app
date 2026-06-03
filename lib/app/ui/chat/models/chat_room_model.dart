import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String
  chatRoomId; // Unique ID mapping string node parameters (e.g., "uid1_uid2")
  final List<String>
  participants; // Dual arrays indexing participant keys: [senderId, receiverId]
  final String
  lastMessage; // Plain string chunk cache to preview dashboard headers smoothly
  final String
  lastMessageSenderId; // Tracking node context key identifying the last sender
  final Timestamp lastMessageTime; // Exact server sorting coordinate bounds
  final Map<String, int>
  unreadCounts; // Dynamic isolation map registry tracking target user unseen metrics
  final bool
  isRead; // ✅ ADDED: State verification rule synchronized with dashboard streams

  ChatRoomModel({
    required this.chatRoomId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.unreadCounts,
    required this.isRead,
  });

  // 📦 1. SERIALIZATION: Model to JSON structure configuration blueprint
  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'participants': participants,
      'last_message': lastMessage,
      'last_message_sender_id': lastMessageSenderId,
      'last_message_time': lastMessageTime,
      'unread_counts': unreadCounts,
      'is_read': isRead,
    };
  }

  // 📥 2. DESERIALIZATION: Deep recursive defensive parsing mapping Firestore snapshot arrays safely
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    // ✅ CRASH PROTECTION BOOT: Robust defensive map casting logic safe against implicit object reference faults
    final Map<String, int> parsedUnread = {};
    if (json['unread_counts'] != null && json['unread_counts'] is Map) {
      (json['unread_counts'] as Map<String, dynamic>).forEach((key, value) {
        parsedUnread[key] = (value as num).toInt();
      });
    }

    return ChatRoomModel(
      chatRoomId: json['chatRoomId'] ?? '',
      participants: List<String>.from(json['participants'] ?? const []),
      lastMessage: json['last_message'] ?? '',
      lastMessageSenderId: json['last_message_sender_id'] ?? '',
      lastMessageTime: json['last_message_time'] ?? Timestamp.now(),
      unreadCounts: parsedUnread,
      isRead:
          json['is_read'] ??
          true, // Standard active data structure compatibility bridge fallback
    );
  }
}
