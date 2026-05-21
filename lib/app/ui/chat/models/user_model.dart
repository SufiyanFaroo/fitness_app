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

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      uid: id,
      name: json['full_name'] ?? json['name'] ?? 'FitQuest User',
      phoneNumber: json['phone_number'] ?? '---',
      profileImage: json['profile_image'] ?? '',
      onlineStatus: json['onlineStatus'] ?? false,
      lastSeen: json['lastSeen'] ?? Timestamp.now(),
    );
  }
}
