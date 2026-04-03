import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FitnessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current User ID safely
  String get uid => _auth.currentUser?.uid ?? "guest_user";

  // --- 1. Default Workouts Initialize karna ---
  Future<void> initializeUserWorkouts() async {
    try {
      List<Map<String, dynamic>> defaultWorkouts = [
        {
          'title': "Fullbody Workout",
          'kcal': "180",
          'mins': "20",
          'progress': 0.0,
        },
        {
          'title': "Lowerbody Workout",
          'kcal': "200",
          'mins': "30",
          'progress': 0.0,
        },
        {'title': "Ab Workout", 'kcal': "180", 'mins': "20", 'progress': 0.0},
      ];

      for (var workout in defaultWorkouts) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('workouts')
            .doc(workout['title'])
            .set({
              ...workout,
              'timestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error initializing workouts: $e");
    }
  }

  // --- 2. Dashboard aur Profile Stream ---
  Stream<DocumentSnapshot> getUserStream() {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // --- 3. Workout Tracker ke liye real-time data lena (7 items for Graph) ---
  Stream<QuerySnapshot> getLatestWorkoutsStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .snapshots();
  }

  // --- 4. Workout Progress Update (Manual or Automatic) ---
  // Workout Progress Update with better error handling
  // 🔥 Repository mein ye 4 parameters lazmi hone chahiye
  Future<void> updateWorkoutProgress(
    String title,
    double progress,
    int kcal,
    int mins,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(title) // Make sure 'title' is your Document ID
          .update({
            'progress': progress,
            'kcal': kcal, // Real-time calories
            'mins': mins, // Real-time minutes
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Firestore Update Error: $e");
    }
  }

  // --- 5. Notification Red Dot Clear karna ---
  Future<void> clearNotificationDot() async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'has_notification': false,
      });
    } catch (e) {
      print("Error clearing notification dot: $e");
    }
  }

  // --- 6. Local Dashboard Data Caching (Shared Preferences) ---
  Future<void> cacheDashboardData(
    String name,
    String weight,
    String height,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";

    Map<String, dynamic> dataToCache = {
      'full_name': name,
      'weight': weight,
      'height': height,
      'last_updated': DateTime.now()
          .toIso8601String(), // 🔥 Timestamp ki jagah String use karein
    };

    // ✅ Ab jsonEncode crash nahi karega
    await prefs.setString('dashboard_cache_$uid', jsonEncode(dataToCache));
  }

  // --- 7. Workout Data Cache ---
  Future<void> cacheWorkoutsLocally(List<QueryDocumentSnapshot> docs) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 🔥 FIX: Direct map ki bajaye pehle empty list banayein
      List<String> workoutList = [];

      // 🔥 FIX: toList() crash se bachne ke liye loop use karein
      for (var doc in docs) {
        if (doc.exists) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Document ID bhi add kar den taake local storage mein ID mil sakay
          data['id'] = doc.id;

          workoutList.add(jsonEncode(data));
        }
      }

      // Local storage mein save karein
      await prefs.setStringList('local_workouts_$uid', workoutList);
      debugPrint(
        "Workouts Cached Successfully! ✅ Total: ${workoutList.length}",
      );
    } catch (e) {
      debugPrint("Cache Logic Error: $e");
    }
  }

  // --- 8. Interactions Log karna ---
  Future<void> logInteraction(String action, String detail) async {
    final prefs = await SharedPreferences.getInstance();
    int count = (prefs.getInt('count_$action') ?? 0) + 1;
    await prefs.setInt('count_$action', count);

    await _firestore.collection('interactions').add({
      'uid': uid,
      'action': action,
      'detail': detail,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Aik simple example method
  Future<void> logDailyProgress(double progress) async {
    String todayDate = DateTime.now().toString().split(
      ' ',
    )[0]; // Result: 2026-03-10

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('activity_logs')
        .doc(todayDate)
        .set({
          'date': todayDate,
          'progress': progress,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
  // workout_service.dart ya FitnessRepository mein ye add karein:

  Future<void> updateScheduleStatus(String key, bool isCompleted) async {
    try {
      final String dateKey = DateTime.now().toString().split(
        ' ',
      )[0]; // Result: 2026-03-16
      final String uid = _auth.currentUser?.uid ?? "guest_user";

      // 1. LOCAL STORAGE (SharedPreferences) - For Offline Access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('status_${key}_$uid', isCompleted);
      await prefs.setString('last_activity_date_$uid', dateKey);

      // 2. FIREBASE FIRESTORE - Permanent Cloud Sync
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_history')
          .doc(dateKey)
          .set({
            'status': isCompleted ? 'Finished' : 'In Progress',
            'workout_name': key,
            'date': dateKey,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint("✅ Sync Successful: Local & Firebase updated.");
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
      // Agar internet nahi hai, toh humein crash nahi chahiye
      // Data sirf local storage mein para rahega
    }
  }

  // FitnessRepository class ke andar ye function hona chahiye
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      // Agar aap Firebase Storage use kar rahe hain:
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // --- 9. User Profile Data Update (Name, Weight, Profile Image URL etc.) ---
  Future<void> updateUser(Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
      debugPrint("User Profile Updated in Firestore! ✅");
    } catch (e) {
      debugPrint("Error updating user profile: $e");
    }
  }

  // 🔥 Yeh function FitnessRepository class mein add karein
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid) // uid aapne pehle hi define kiya hua hai repo mein
          .set(data, SetOptions(merge: true));
      debugPrint("Profile Data Synced to Firebase! ✅");
    } catch (e) {
      debugPrint("Firestore Update Error: $e");
    }
  }
}
