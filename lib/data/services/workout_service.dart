import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get uid => _auth.currentUser?.uid ?? "";

  // ✅ FIX: Added exact getter property token required by UI tracker views mapping modules
  String get currentUserId => uid;

  // --- LOCAL STORAGE (Offline Support) ---
  Future<void> saveSwitchState(int index, bool value) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('workout_switch_${uid}_$index', value);
    } catch (e) {
      debugPrint("Local Storage switch save error: $e");
    }
  }

  Future<List<bool>> getLocalSwitchStates(int count) async {
    final prefs = await SharedPreferences.getInstance();
    List<bool> states = [];
    for (int i = 0; i < count; i++) {
      states.add(prefs.getBool('workout_switch_${uid}_$i') ?? false);
    }
    return states;
  }

  // --- FIREBASE SYNC (Cloud Support) ---
  Future<void> updateWorkoutOnFirebase(int index, bool isEnabled) async {
    if (uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .doc('settings')
          .set({
            'workout_$index': isEnabled,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firebase Update Error: $e");
    }
  }

  // Stream for Real-time UI updates
  Stream<DocumentSnapshot>? getWorkoutStream() {
    if (uid.isEmpty) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .doc('settings')
        .snapshots();
  }

  // ✅ FIXED: Injected the absolute stream query required to draw dynamic line chart vectors without crashing
  Stream<QuerySnapshot> getWeeklyAnalyticsStream() {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('workout_analytics')
        .orderBy('day_index', descending: false)
        .snapshots();
  }

  // --- SCHEDULE BACKEND LOGIC ---
  Future<bool> getLocalScheduleStatus(String taskTitle) async {
    if (uid.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sched_${uid}_$taskTitle') ?? false;
  }

  // 1. Clear All Schedules (Local + Firebase)
  Future<void> clearAllSchedules() async {
    if (uid.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('schedule_$uid'));
    for (String key in keys) {
      await prefs.remove(key);
    }

    try {
      var collection = _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_schedules');
      var snapshots = await collection.get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Clear Error: $e");
    }
  }

  Future<void> saveSetting(String key, bool value) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setting_${uid}_$key', value);

      await _firestore.collection('users').doc(uid).set({
        'settings': {key: value},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Settings Cache Fail: $e");
    }
  }

  Future<bool> getSettingLocally(String key) async {
    if (uid.isEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('setting_${uid}_$key') ?? true;
  }

  Future<void> saveNewSchedule({
    required String workout,
    required String difficulty,
    required String reps,
    required String weight,
    required DateTime time,
  }) async {
    if (uid.isEmpty) return;

    String scheduleId = "sch_${DateTime.now().millisecondsSinceEpoch}";

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_schedules')
          .doc(scheduleId)
          .set({
            'id': scheduleId,
            'workout': workout,
            'difficulty': difficulty,
            'reps': reps,
            'weight': weight,
            'time': time.toIso8601String(),
            'isCompleted': false,
            'created_at': FieldValue.serverTimestamp(),
          });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_added_workout_$uid', workout);
    } catch (e) {
      debugPrint("Firebase Save Error: $e");
    }
  }

  Future<void> saveWorkoutSchedule({
    required String workout,
    required String difficulty,
    required String reps,
    required String weight,
    required DateTime time,
  }) async {
    if (uid.isEmpty) return;

    String docId = "workout_${DateTime.now().millisecondsSinceEpoch}";

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_schedules')
          .doc(docId)
          .set({
            'id': docId,
            'workoutName': workout,
            'difficulty': difficulty,
            'repetitions': reps,
            'weight': weight,
            'scheduleTime': time.toIso8601String(),
            'isCompleted': false,
            'timestamp': FieldValue.serverTimestamp(),
          });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_scheduled_workout_$uid', workout);
    } catch (e) {
      debugPrint("Firebase Error: $e");
    }
  }

  // ✅ NEW METHOD: Modifies an existing schedule parameters configuration block inside Firestore collection fields
  Future<void> updateWorkoutSchedule({
    required String docId,
    required String workout,
    required String difficulty,
    required String reps,
    required String weight,
    required DateTime time,
  }) async {
    if (uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_schedules')
          .doc(docId)
          .update({
            'workoutName': workout,
            'difficulty': difficulty,
            'repetitions': reps,
            'weight': weight,
            'scheduleTime': time.toIso8601String(),
            'last_edited_at': FieldValue.serverTimestamp(),
          });
      debugPrint("✅ Schedule fields customized successfully: $docId");
    } catch (e) {
      debugPrint("❌ Firestore Update Operational Error: $e");
    }
  }

  // ✅ NEW METHOD: Drops a specific schedule document loop straight from user sub-collections completely
  Future<void> deleteWorkoutSchedule(String docId) async {
    if (uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_schedules')
          .doc(docId)
          .delete();
      debugPrint(
        "🗑️ Schedule record wiped straight from network registries: $docId",
      );
    } catch (e) {
      debugPrint("❌ Firestore Deletion Core Block Fault: $e");
    }
  }

  Future<List<String>> getWorkoutCategories() async {
    try {
      var snapshot = await _firestore
          .collection('settings')
          .doc('workout_types')
          .get();
      if (snapshot.exists) {
        return List<String>.from(snapshot.data()?['list'] ?? []);
      }
    } catch (e) {
      debugPrint("Categories Fetch Error: $e");
    }

    return [
      "Upperbody Workout",
      "Lowerbody Workout",
      "Ab Workout",
      "Cardio",
      "Yoga",
    ];
  }

  Future<void> startWorkoutSession(
    String workoutName,
    int exerciseCount,
  ) async {
    if (uid.isEmpty) return;

    String sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_session_$uid', workoutName);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_history')
          .doc(sessionId)
          .set({
            'workoutName': workoutName,
            'totalExercises': exerciseCount,
            'startTime': FieldValue.serverTimestamp(),
            'status': 'In Progress',
          });
    } catch (e) {
      debugPrint("Firebase Session Error: $e");
    }
  }

  Future<void> saveExerciseProgress({
    required String exerciseTitle,
    required String calories,
    required String level,
  }) async {
    if (uid.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_exercise_$uid', exerciseTitle);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('exercise_history')
          .doc(timestamp)
          .set({
            'title': exerciseTitle,
            'calories_burn': calories,
            'difficulty': level,
            'completed_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Firebase Save Error: $e");
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required bool isComplete,
  }) async {
    if (uid.isEmpty) return;

    try {
      await _firestore.collection('users').doc(uid).set({
        'full_name': name,
        'is_profile_complete': isComplete,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Profile Updated in Firebase!");
    } catch (e) {
      debugPrint("Profile Error: $e");
    }
  }

  Future<void> saveWorkoutToHistory(String workoutName) async {
    if (uid.isEmpty) return;

    try {
      String todayDate = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_history')
          .doc(todayDate)
          .set({
            'workout_name': workoutName,
            'status': 'Finished',
            'completed_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint("Workout History Saved!");
    } catch (e) {
      debugPrint("History Error: $e");
    }
  }

  Future<String?> uploadUserFile(File file, String folderName) async {
    if (uid.isEmpty) return null;

    try {
      String fileName = "${uid}_${DateTime.now().millisecondsSinceEpoch}";
      Reference ref = FirebaseStorage.instance.ref().child(
        '$folderName/$fileName',
      );

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint("✅ File Uploaded! URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Upload Error: $e");
      return null;
    }
  }

  Future<void> updateProfilePicture(File imageFile) async {
    if (uid.isEmpty) return;
    String? imageUrl = await uploadUserFile(imageFile, 'user_profiles');

    if (imageUrl != null) {
      await _firestore.collection('users').doc(uid).update({
        'photo_url': imageUrl,
        'last_updated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> saveActivityData(String type, String value) async {
    if (uid.isEmpty) return;

    try {
      final String dateKey = DateTime.now().toIso8601String().split('T')[0];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${type}_${uid}_$dateKey', value);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activity_logs')
          .doc(dateKey)
          .set({
            type: value,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint("✅ $type updated to $value");
    } catch (e) {
      debugPrint("❌ Activity Sync Error: $e");
    }
  }

  Stream<DocumentSnapshot>? getActivityStream() {
    if (uid.isEmpty) return null;
    final String dateKey = DateTime.now().toIso8601String().split('T')[0];
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('activity_logs')
        .doc(dateKey)
        .snapshots();
  }

  Future<void> updateScheduleStatus(String taskTitle, bool isDone) async {
    if (uid.isEmpty) return;

    try {
      final String dateKey = DateTime.now().toIso8601String().split('T')[0];
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('sched_${uid}_$taskTitle', isDone);
      await prefs.setString(
        'last_updated_$uid',
        DateTime.now().toIso8601String(),
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_history')
          .doc(dateKey)
          .set({
            'status': isDone ? 'Finished' : 'In Progress',
            'workout_name': taskTitle,
            'date': dateKey,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint("✅ Sync Successful!");
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
    }
  }

  Future<String> getLocalActivityData(String type) async {
    try {
      final String dateKey = DateTime.now().toIso8601String().split('T')[0];
      final prefs = await SharedPreferences.getInstance();
      String defaultValue = (type == "water") ? "0L" : "0";
      String storageKey = '${type}_${uid}_$dateKey';

      return prefs.getString(storageKey) ?? defaultValue;
    } catch (e) {
      debugPrint("Error fetching local data: $e");
      return (type == "water") ? "0L" : "0";
    }
  }

  Future<void> saveGoal(String type, String value) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'setting_${uid}_${type}_goal_time',
        DateTime.now().toIso8601String(),
      );
      await prefs.setString('setting_${uid}_${type}_goal_value', value);

      await _firestore.collection('users').doc(uid).set({
        '${type}_goal': value,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Save Goal Error: $e");
    }
  }

  Stream<QuerySnapshot> getLatestActivitiesStream() {
    if (uid.isEmpty) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('activity_logs')
        .orderBy('last_updated', descending: true)
        .snapshots();
  }

  Future<void> logActivity(String title, String type) async {
    if (uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activity_logs')
          .add({
            'title': title,
            'type': type,
            'timestamp': FieldValue.serverTimestamp(),
          });
      debugPrint("✅ Activity Logged Successfully: $title");
    } catch (e) {
      debugPrint("❌ Log Error: $e");
    }
  }

  Future<void> deleteActivityLog(String docId) async {
    if (uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activity_logs')
          .doc(docId)
          .delete();
      debugPrint("🗑️ Activity Deleted Successfully: $docId");
    } catch (e) {
      debugPrint("❌ Firestore Delete Error: $e");
      rethrow;
    }
  }
}
