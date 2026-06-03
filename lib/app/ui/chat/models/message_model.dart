import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final bool seen;
  final String messageType; // text, image, link, file
  final String?
  mediaUrl; // ✅ ADDED: Safe nullable parameter for dynamic image/media messages

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.seen,
    required this.messageType,
    this.mediaUrl,
  });

  // 📦 1. SERIALIZATION: Convert Model to JSON structure configuration blueprint
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'seen': seen,
      'messageType': messageType,
      'mediaUrl':
          mediaUrl, // Synchronized cleanly inside the document map payload
    };
  }

  // 📥 2. DESERIALIZATION: Create Model from Firestore Document safely with strict fallbacks
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? Timestamp.now(),
      seen: json['seen'] ?? false,
      messageType: json['messageType'] ?? 'text',
      mediaUrl:
          json['mediaUrl'], // Maps null safely if the message node is plain text
    );
  }
}
