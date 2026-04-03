// ignore_for_file: unused_element

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/data/services/local_storage_service.dart';
import 'package:fitness_app/data/services/cloudinary_service.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'progress_photos';
  // Class ke start mein ye helper property add karein
  CollectionReference get _userPhotosRef {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('progress_photos');
  }

  Stream<QuerySnapshot> getProgressPhotos() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress_photos') // 🔥 Same path jo save ke waqt use kiya
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> uploadProgressPhoto(File imageFile) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      String fileName = "progress_${DateTime.now().millisecondsSinceEpoch}.jpg";

      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("users")
          .child(userId)
          .child("progress_photos")
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress_photos')
          .add({
            'imageUrl': downloadUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'fileName': fileName,
          });

      return downloadUrl;
    } catch (e) {
      print("Upload Error: $e");
      throw Exception("Failed to upload image");
    }
  }

  // --- 2. Specific Month Photos (For Comparison) ---
  Future<QuerySnapshot> getPhotosByMonth(String monthName) async {
    // Purana _firestore.collection(_collection) delete kar ke ye likhein:
    return await _userPhotosRef.where('month', isEqualTo: monthName).get();
  }

  // 🔥 Professional Serialization: Timestamp Fix for Local Storage
  // Agar aapko kabhi pura map save karna ho, toh ye function use karein
  Map<String, dynamic> _makeEncodable(Map<String, dynamic> data) {
    Map<String, dynamic> encodableData = Map.from(data);
    encodableData.forEach((key, value) {
      if (value is Timestamp) {
        encodableData[key] = value.toDate().toIso8601String();
      }
    });
    return encodableData;
  }

  // --- 3. Delete Progress Logic (Atomic Batch) ---
  Future<void> deleteProgressByMonth(String month) async {
    try {
      var querySnapshot = await _userPhotosRef
          .where('month', isEqualTo: month)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      var batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint("✅ Deleted successfully: $month");
    } catch (e) {
      debugPrint("❌ Delete Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getWeightLogs() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    var snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weight_logs') // Ensure karein ye collection bani ho
        .orderBy('date', descending: false)
        .limit(7)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- 4. Save Last View Date (Local Storage) ---
  Future<void> saveLastCheckDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Timestamp ki jagah hum direct ISO String save kar rahe hain (Best Practice)
      String formattedDate = DateTime.now().toIso8601String();
      await prefs.setString('last_gallery_view', formattedDate);
      debugPrint("✅ Cache Success: Date saved as String");
    } catch (e) {
      debugPrint("❌ Cache Error: $e");
    }
  }

  // --- 5. Get Last View Date ---
  Future<String?> getLastCheckDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_gallery_view');
  }

  // --- 6. Save/Get Selected Pose ---
  Future<void> saveSelectedPose(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_pose_index', index);
  }

  Future<int?> getLastSelectedPose() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selected_pose_index');
  }

  // --- 7. Upload Photo Record ---
  Future<void> uploadPhotoRecord({
    required String url,
    required int poseIndex,
    required String monthName,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'imageUrl': url,
        'poseIndex': poseIndex,
        'month': monthName,
        'date': FieldValue.serverTimestamp(), // 🔥 Best: Use Server Side Time
      });
      debugPrint("✅ Photo Record Uploaded to Firebase");
    } catch (e) {
      debugPrint("❌ Upload Error: $e");
    }
  }

  // 🔥 8. Real App Feature: Clear All Local Cache
  Future<void> clearAllLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_gallery_view');
    await prefs.remove('selected_pose_index');
    debugPrint("✅ Local Cache Cleared");
  }

  // Future<void> deleteProgressPhoto(String docId, String imageUrl) async {
  //   try {
  //     // 🔥 1. Current User ki ID yahan se milegi
  //     String? userId = FirebaseAuth.instance.currentUser?.uid;

  //     if (userId == null) {
  //       throw Exception("User not logged in");
  //     }

  //     // 2. Firebase Storage se asal image delete karein
  //     Reference photoRef = FirebaseStorage.instance.refFromURL(imageUrl);
  //     await photoRef.delete();

  //     // 3. Firestore se document delete karein
  //     // ✅ Ab 'userId' yahan error nahi dega
  //     await _firestore
  //         .collection('users')
  //         .doc(userId)
  //         .collection('progress_photos')
  //         .doc(docId)
  //         .delete();
  //   } catch (e) {
  //     throw Exception("Delete Failed: $e");
  //   }
  // }
  // ProgressService.dart mein isay replace karein
  // 🔥 ProgressService.dart mein isay theek karein
  // ProgressService.dart mein ye badlein

  // --- 9. NEW: Upload Progress Photo WITH Local Backup ---
  Future<Map<String, String?>> uploadProgressPhotoWithLocalBackup(
    File imageFile,
  ) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String fileName = "progress_${DateTime.now().millisecondsSinceEpoch}.jpg";

      // 1. Save to local storage first
      String? localPath = await LocalStorageService.saveProgressPhotoLocally(
        imageFile,
      );
      debugPrint("📱 Local Save: $localPath");

      // 2. Upload to Firebase Storage
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("users")
          .child(userId)
          .child("progress_photos")
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 3. Save metadata to Firestore with local path reference
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress_photos')
          .add({
            'imageUrl': downloadUrl,
            'localPath': localPath,
            'fileName': fileName,
            'createdAt': FieldValue.serverTimestamp(),
            'publicId': fileName,
          });

      debugPrint("✅ Photo uploaded to cloud and saved locally");
      return {'url': downloadUrl, 'localPath': localPath};
    } catch (e) {
      debugPrint("❌ Upload Error: $e");
      return {'url': null, 'localPath': null};
    }
  }

  // --- 10. NEW: Delete Photo from BOTH Local and Cloud (Supports Cloudinary & Firebase Storage) ---
  Future<bool> deleteProgressPhotoComplete({
    required String docId,
    String? imageUrl,
    String? localPath,
    String? fileName,
    String? publicId,
  }) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint("❌ User not logged in");
        return false;
      }

      bool localDeleted = true;
      bool cloudDeleted = true;

      // 1. Delete from local storage
      if (localPath != null && localPath.isNotEmpty) {
        localDeleted = await LocalStorageService.deleteLocalImage(localPath);
      }

      // 2. Delete from Cloud Storage (Cloudinary or Firebase)
      // 🔥 If publicId is provided (Cloudinary), use it; otherwise try Firebase Storage
      if (publicId != null && publicId.isNotEmpty) {
        // Cloudinary deletion
        try {
          bool cloudinaryDeleted =
              await CloudinaryService.deleteImageFromCloudinary(publicId);
          debugPrint(
            "☁️ Deleted from Cloudinary: $publicId (Result: $cloudinaryDeleted)",
          );
          cloudDeleted = cloudinaryDeleted;
        } catch (e) {
          debugPrint("⚠️ Cloudinary deletion failed: $e");
          cloudDeleted = false;
        }
      } else if (fileName != null && fileName.isNotEmpty) {
        // Firebase Storage deletion
        try {
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child("users")
              .child(userId)
              .child("progress_photos")
              .child(fileName);
          await storageRef.delete();
          debugPrint("☁️ Deleted from Firebase Storage: $fileName");
        } catch (e) {
          debugPrint("⚠️ Firebase Storage deletion failed: $e");
          cloudDeleted = false;
        }
      }

      // 3. Delete from Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('progress_photos')
            .doc(docId)
            .delete();
        debugPrint("🗂️ Deleted from Firestore: $docId");
      } catch (e) {
        debugPrint("⚠️ Firestore deletion failed: $e");
        return false;
      }

      debugPrint("✅ Photo deleted successfully from all sources");
      return localDeleted && cloudDeleted;
    } catch (e) {
      debugPrint("❌ Complete Delete Error: $e");
      return false;
    }
  }

  // --- 11. NEW: Get Local Progress Photos ---
  Future<List<File>> getLocalProgressPhotos() async {
    try {
      return await LocalStorageService.getLocalProgressPhotos();
    } catch (e) {
      debugPrint("❌ Error fetching local photos: $e");
      return [];
    }
  }

  // --- 12. NEW: Get Storage Statistics ---
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      int localPhotoCount = await LocalStorageService.getLocalPhotoCount();
      double localSize = await LocalStorageService.getLocalPhotosSizeInMB();

      return {
        'localPhotoCount': localPhotoCount,
        'localSizeMB': localSize,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      debugPrint("❌ Error getting storage stats: $e");
      return {
        'localPhotoCount': 0,
        'localSizeMB': 0.0,
        'timestamp': DateTime.now(),
      };
    }
  }

  // --- 13. NEW: Clear All Local Photos ---
  Future<bool> clearAllLocalPhotos() async {
    try {
      bool cleared = await LocalStorageService.clearAllLocalPhotos();
      if (cleared) {
        debugPrint("✅ All local photos cleared");
      }
      return cleared;
    } catch (e) {
      debugPrint("❌ Error clearing local photos: $e");
      return false;
    }
  }

  // Old method kept for backward compatibility
  Future<void> deleteProgressPhoto(String docId) async {
    // Sirf docId rakhein
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress_photos')
          .doc(docId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
