import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get uid => _auth.currentUser?.uid ?? "";

  // --- 1. Logout Logic ---
  Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear Local Storage
      await _auth.signOut(); // Firebase Sign Out
      debugPrint("✅ User logged out successfully");
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  // --- 2. Notifications Preference ---
  Future<void> updateNotificationPreference(bool value) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'notifications_enabled': value,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      debugPrint("✅ Notification preference updated: $value");
    } catch (e) {
      debugPrint("Notification Update Error: $e");
    }
  }

  // --- 3. Professional Image Cropping ---
  Future<File?> cropImage(File imageFile) async {
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Profile Image',
            toolbarColor: const Color(0xff92A3FD),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Edit Image',
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
        ],
      );
      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      debugPrint("Cropping Error: $e");
      return null;
    }
  }

  // --- 4. Profile Image Upload ---
  Future<void> uploadProfileImage(File imageFile) async {
    if (uid.isEmpty) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final String ext = p.extension(imageFile.path);
      final File fileToUpload = await imageFile.copy(
        '${tempDir.path}/profile_$uid$ext',
      );

      final ref = _storage.ref().child('user_profiles').child('$uid$ext');
      await ref.putFile(fileToUpload);

      final String downloadUrl = await ref.getDownloadURL();

      // Firestore Update
      await _firestore.collection('users').doc(uid).update({
        'profile_image': downloadUrl,
        'last_updated': FieldValue.serverTimestamp(),
      });

      // Update Local Storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_profile_url', downloadUrl);
      debugPrint("✅ Profile image uploaded successfully");
    } catch (e) {
      debugPrint("Upload Error: $e");
      rethrow;
    }
  }
}
