import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phoneNumber;
  final String profileImage;
  final bool onlineStatus;
  final Timestamp lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.phoneNumber,
    required this.profileImage,
    required this.onlineStatus,
    required this.lastSeen,
  });

  // 📦 1. SERIALIZATION: Convert Model to JSON structure configuration blueprint
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'full_name': name,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'onlineStatus':
          onlineStatus, // Maps with your chat tracker screens queries keys
      'lastSeen': lastSeen,
    };
  }

  // 📥 2. DESERIALIZATION: Create Model from Firestore Document payload safely with strict fallbacks
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      uid: id,
      name: json['full_name'] ?? json['name'] ?? 'FitQuest User',
      phoneNumber: json['phone_number'] ?? json['phone'] ?? '---',
      profileImage: json['profile_image'] ?? '',
      onlineStatus: json['onlineStatus'] ?? false,
      lastSeen: json['lastSeen'] ?? Timestamp.now(),
    );
  }
}
