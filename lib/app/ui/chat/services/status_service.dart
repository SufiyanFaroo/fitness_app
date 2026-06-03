import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StatusService {
  // Singleton pattern for production performance
  static final StatusService _instance = StatusService._internal();
  factory StatusService() => _instance;
  StatusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload Function: Professional Error Handling
  Future<void> uploadStatus(File imageFile) async {
    String userId = _auth.currentUser?.uid ?? "";
    if (userId.isEmpty) throw Exception("User not authenticated.");

    try {
      // Image to Base64 (The free & fast professional way)
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      await _firestore.collection('status_updates').add({
        'userId': userId,
        'statusData': base64Image,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("Status synced successfully.");
    } catch (e) {
      debugPrint("Status upload error: $e");
      throw Exception("Upload failed: Check your internet.");
    }
  }

  // Stream for Real-time Status updates
  Stream<QuerySnapshot> getActiveStatuses() {
    DateTime yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return _firestore
        .collection('status_updates')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
