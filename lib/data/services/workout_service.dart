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

  // --- LOCAL STORAGE (Offline Support) ---
  Future<void> saveSwitchState(int index, bool value) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    // UID base key use karna achi baat hai taake multi-user login mein data mix na ho
    await prefs.setBool('workout_switch_${uid}_$index', value);
  }

  Future<List<bool>> getLocalSwitchStates(int count) async {
    final prefs = await SharedPreferences.getInstance();
    List<bool> states = [];
    for (int i = 0; i < count; i++) {
      // Default value false rakhein taake "No Active Workout" logic kaam kare
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
      print("Firebase Update Error: $e");
    }
  }

  // Stream for Real-time UI updates
  Stream<DocumentSnapshot>? getWorkoutStream() {
    if (uid.isEmpty) return null; // Safe check
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .doc('settings')
        .snapshots();
  }

  // --- SCHEDULE BACKEND LOGIC ---
  // --- SINGLE MERGED FUNCTION ---
  // Future<void> updateScheduleStatus(String taskTitle, bool isDone) async {
  //   final String currentUid = _auth.currentUser?.uid ?? "guest_user";
  //   if (currentUid == "guest_user") return;

  //   try {
  //     final String dateKey = DateTime.now().toString().split(' ')[0];
  //     final prefs = await SharedPreferences.getInstance();

  //     // 1. LOCAL STORAGE SYNC (Donon patterns save kar raha hai safety ke liye)
  //     await prefs.setBool('sched_${currentUid}_$taskTitle', isDone);
  //     await prefs.setBool('status_${taskTitle}_$currentUid', isDone);

  //     // 2. FIREBASE SYNC - Part A: Workout History (Today's Progress)
  //     await _firestore
  //         .collection('users')
  //         .doc(currentUid)
  //         .collection('workout_history')
  //         .doc(dateKey)
  //         .set({
  //           'status': isDone ? 'Finished' : 'In Progress',
  //           'workout_name': taskTitle,
  //           'date': dateKey,
  //           'timestamp': FieldValue.serverTimestamp(),
  //         }, SetOptions(merge: true));

  //     // 3. FIREBASE SYNC - Part B: Schedule Update
  //     await _firestore
  //         .collection('users')
  //         .doc(currentUid)
  //         .collection('workout_schedules')
  //         .doc(taskTitle.replaceAll(' ', '_'))
  //         .set({
  //           'title': taskTitle,
  //           'status': isDone ? 'Done' : 'Pending',
  //           'last_updated': FieldValue.serverTimestamp(),
  //         }, SetOptions(merge: true));

  //     debugPrint("✅ Full Sync Complete for: $taskTitle");
  //   } catch (e) {
  //     debugPrint("❌ Sync Error: $e");
  //   }
  // }

  Future<bool> getLocalScheduleStatus(String taskTitle) async {
    final prefs = await SharedPreferences.getInstance();
    // UID base key taake user data mix na ho
    return prefs.getBool('sched_${uid}_$taskTitle') ?? false;
  }
  // --- POPUP ACTIONS LOGIC ---

  // 1. Clear All Schedules (Local + Firebase)
  Future<void> clearAllSchedules() async {
    if (uid.isEmpty) return;

    // Local Storage Clear
    final prefs = await SharedPreferences.getInstance();
    // Saare keys jo 'schedule_' se start hote hain unhe reset karne ke liye
    final keys = prefs.getKeys().where((k) => k.startsWith('schedule_$uid'));
    for (String key in keys) {
      await prefs.remove(key);
    }

    // Firebase Clear (Schedules delete karna)
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

  // WorkoutService mein add karein
  Future<void> saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_${uid}_$key', value);

    // Firebase mein bhi sync karein taake preferences save rahein
    await _firestore.collection('users').doc(uid).set({
      'settings': {key: value},
    }, SetOptions(merge: true));
  }

  // WorkoutService.dart mein
  Future<bool> getSettingLocally(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // Humne tracker wale switches ki tarah hi pattern rakha hai
    return prefs.getBool('setting_${uid}_$key') ?? true;
  }
  // WorkoutService.dart mein add karein

  Future<void> saveNewSchedule({
    required String workout,
    required String difficulty,
    required String reps,
    required String weight,
    required DateTime time,
  }) async {
    if (uid.isEmpty) return;

    // Unique ID for the document
    String scheduleId = "sch_${DateTime.now().millisecondsSinceEpoch}";

    // 1. Firebase Sync
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
    } catch (e) {
      debugPrint("Firebase Save Error: $e");
    }

    // 2. Local Storage (Backup ke liye)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_added_workout_$uid', workout);
  }
  // workout_service.dart mein add karein

  Future<void> saveWorkoutSchedule({
    required String workout,
    required String difficulty,
    required String reps,
    required String weight,
    required DateTime time,
  }) async {
    if (uid.isEmpty) return;

    // Unique ID for the workout document
    String docId = "workout_${DateTime.now().millisecondsSinceEpoch}";

    // 1. Firebase Cloud Sync
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
    } catch (e) {
      debugPrint("Firebase Error: $e");
    }

    // 2. Local Storage (Last workout save karne ke liye)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_scheduled_workout', workout);
  }

  // workout_service.dart mein
  Future<List<String>> getWorkoutCategories() async {
    try {
      // Agar aapne Firestore mein 'categories' ka collection banaya hai:
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

    // Fallback: Agar Firebase se na mile toh ye default list return karega
    return [
      "Upperbody Workout",
      "Lowerbody Workout",
      "Ab Workout",
      "Cardio",
      "Yoga",
    ];
  }
  // workout_service.dart mein add karein

  Future<void> startWorkoutSession(
    String workoutName,
    int exerciseCount,
  ) async {
    if (uid.isEmpty) return;

    String sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";

    // 1. Local Storage (Current Session save karne ke liye)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_session_$uid', workoutName);

    // 2. Firebase Sync
    try {
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
  // workout_service.dart mein add karein

  Future<void> saveExerciseProgress({
    required String exerciseTitle,
    required String calories,
    required String level,
  }) async {
    if (uid.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Local Storage Sync (Offline use ke liye)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_exercise_$uid', exerciseTitle);

    // 2. Firebase Firestore Sync
    try {
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
    if (uid.isEmpty) return; // UID check jo aapne pehle likha tha

    try {
      await _firestore.collection('users').doc(uid).set({
        'full_name': name,
        'is_profile_complete': isComplete,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true taake purana data delete na ho

      debugPrint("Profile Updated in Firebase!");
    } catch (e) {
      debugPrint("Profile Error: $e");
    }
  }
  // workout_service.dart ke andar

  Future<void> saveWorkoutToHistory(String workoutName) async {
    if (uid.isEmpty) return;

    try {
      String todayDate = DateTime.now().toString().split(
        ' ',
      )[0]; // Result: 2026-03-16

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
  // workout_service.dart ke andar...

  // 🔥 FIREBASE STORAGE UPLOAD LOGIC
  Future<String?> uploadUserFile(File file, String folderName) async {
    if (uid.isEmpty) return null; // Pehle se maujood uid getter use karein

    try {
      // Unique file name taake purani files overwrite na hon
      String fileName = "${uid}_${DateTime.now().millisecondsSinceEpoch}";

      // Reference create karein (e.g., profiles/abc123_123456.jpg)
      Reference ref = FirebaseStorage.instance.ref().child(
        '$folderName/$fileName',
      );

      // Upload task
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Download URL hasil karein
      String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint("✅ File Uploaded! URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Upload Error: $e");
      return null;
    }
  }

  Future<void> updateProfilePicture(File imageFile) async {
    // 1. Pehle Storage mein upload karein
    String? imageUrl = await uploadUserFile(imageFile, 'user_profiles');

    if (imageUrl != null) {
      // 2. Phir Firestore mein URL save karein
      await _firestore.collection('users').doc(uid).update({
        'photo_url': imageUrl,
        'last_updated': FieldValue.serverTimestamp(),
      });
    }
  }

  // 1. Activity Log Save karne ke liye (Steps aur Water intake)
  Future<void> saveActivityData(String type, String value) async {
    if (uid.isEmpty) return;

    try {
      final String dateKey = DateTime.now().toString().split(
        ' ',
      )[0]; // 2026-03-16

      // A. Local Storage Sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${type}_${uid}_$dateKey', value);

      // B. Firebase Sync
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

  // 2. Local Data Fetch karne ke liye (Taake UI foran load ho)

  // 3. Real-time Firebase Updates ke liye (Stream)
  Stream<DocumentSnapshot> getActivityStream() {
    final String dateKey = DateTime.now().toString().split(' ')[0];
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('activity_logs')
        .doc(dateKey)
        .snapshots();
  }

  // --- SINGLE MERGED FUNCTION ---
  Future<void> updateScheduleStatus(String taskTitle, bool isDone) async {
    final String currentUid = _auth.currentUser?.uid ?? "guest_user";
    if (currentUid == "guest_user") return;

    try {
      // 🔥 1. Date ko String mein badlein (ye local storage ke liye safe hai)
      final String dateKey = DateTime.now().toString().split(' ')[0];
      final prefs = await SharedPreferences.getInstance();

      // Local Storage Sync
      await prefs.setBool('sched_${currentUid}_$taskTitle', isDone);

      // ✅ FIX: Timestamp ko direct save karne ki bajaye String save karein
      await prefs.setString(
        'last_updated_$currentUid',
        DateTime.now().toIso8601String(),
      );

      // 2. FIREBASE SYNC (Firebase mein serverTimestamp chalta hai)
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('workout_history')
          .doc(dateKey)
          .set({
            'status': isDone ? 'Finished' : 'In Progress',
            'workout_name': taskTitle,
            'date': dateKey,
            'timestamp':
                FieldValue.serverTimestamp(), // Firestore ke liye ye sahi hai
          }, SetOptions(merge: true));

      debugPrint("✅ Sync Successful!");
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
    }
  }

  // WorkoutService.dart ke andar ye function hona chahiye:
  // 🔥 FINAL UPDATED VERSION
  Future<String> getLocalActivityData(String type) async {
    try {
      final String dateKey = DateTime.now().toString().split(
        ' ',
      )[0]; // Result: 2026-03-16
      final prefs = await SharedPreferences.getInstance();

      // User ki UID check (auth se)
      final String currentUid = _auth.currentUser?.uid ?? "guest_user";

      // Default values
      String defaultValue = (type == "water") ? "0L" : "0";

      // Key format: water_abc123_2026-03-16
      String storageKey = '${type}_${currentUid}_$dateKey';

      return prefs.getString(storageKey) ?? defaultValue;
    } catch (e) {
      debugPrint("Error fetching local data: $e");
      return (type == "water") ? "0L" : "0";
    }
  }

  Future<void> saveGoal(String type, String value) async {
    final prefs = await SharedPreferences.getInstance();

    // Local storage ke liye Timestamp use na karein, simple String ya current time use karein
    await prefs.setString(
      '${type}_goal_time',
      DateTime.now().toIso8601String(),
    );
    await prefs.setString('${type}_goal_value', value);

    // Firebase ke liye Timestamp theek hai
    await _firestore.collection('users').doc(uid).set({
      '${type}_goal': value,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Latest 5 activities lane ke liye stream
  Stream<QuerySnapshot> getLatestActivitiesStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activity_logs') // 👈 Spelling check karein
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // WorkoutService.dart ke andar
  Future<void> logActivity(String title, String type) async {
    try {
      // Current user ki ID check karein
      final String currentUid = _auth.currentUser?.uid ?? "";

      if (currentUid.isEmpty) {
        debugPrint("❌ Log Error: No User Logged In");
        return;
      }

      // Firebase mein data add ho raha hai
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('activity_logs')
          .add({
            'title': title,
            'type': type, // 'water' ya 'steps'
            'timestamp':
                FieldValue.serverTimestamp(), // 🔥 Firebase Server Time
          });

      debugPrint("✅ Activity Logged Successfully: $title");
    } catch (e) {
      debugPrint("❌ Log Error: $e");
    }
  }

  // 1. Activity Log delete karne ke liye
  Future<void> deleteActivityLog(String docId) async {
    try {
      // 1. Current user ki ID nikalna
      final String? currentUid = _auth.currentUser?.uid;

      // 2. Check karna ke user login hai ya nahi
      if (currentUid == null || currentUid.isEmpty) {
        debugPrint("❌ Delete Error: User not logged in");
        return;
      }

      // 3. Firestore se document delete karna
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('activity_logs')
          .doc(docId)
          .delete();

      debugPrint("🗑️ Activity Deleted Successfully: $docId");
    } catch (e) {
      // 4. Agar koi error aaye toh console mein dikhana
      debugPrint("❌ Firestore Delete Error: $e");
      rethrow; // Taake UI ko bhi pata chale ke error aaya hai
    }
  }

  // 2. Nayi activity save karne ke liye
}
