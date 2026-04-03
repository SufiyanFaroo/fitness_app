import 'dart:convert'; // jsonEncode ke liye zaroori hai
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Task 12: Real-time Firebase Stream ---
  Stream<DocumentSnapshot> getSleepData() {
    String uid = _auth.currentUser?.uid ?? "";
    return _db.collection('users').doc(uid).snapshots();
  }

  // --- 🔥 NEW: Cache Logic Fix (Task 4 & 10) ---
  Future<void> cacheSleepData(Map<String, dynamic> snapshotData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 🔥 Task 14: Deep Conversion Logic (Har level se Timestamp hatane ke liye)
      Map<String, dynamic> convertTimestamps(Map<String, dynamic> data) {
        Map<String, dynamic> cleanMap = {};
        data.forEach((key, value) {
          if (value is Timestamp) {
            cleanMap[key] = value.toDate().toIso8601String();
          } else if (value is Map<String, dynamic>) {
            cleanMap[key] = convertTimestamps(
              value,
            ); // Recursive call for nested maps
          } else if (value is List) {
            cleanMap[key] = value.map((item) {
              return (item is Timestamp)
                  ? item.toDate().toIso8601String()
                  : item;
            }).toList();
          } else {
            cleanMap[key] = value;
          }
        });
        return cleanMap;
      }

      Map<String, dynamic> finalData = convertTimestamps(snapshotData);
      await prefs.setString('cache_sleep_data', jsonEncode(finalData));

      print("✅ Cache Updated Successfully (No more Timestamp errors!)");
    } catch (e) {
      print("❌ Cache Logic Error: $e");
    }
  }

  // --- Task 4: Hybrid Save (Firebase + Local) ---
  Future<void> updateSleepSettings(String key, dynamic value) async {
    String uid = _auth.currentUser?.uid ?? "";
    final prefs = await SharedPreferences.getInstance();

    if (value is bool) {
      await prefs.setBool('sleep_$key', value);
    } else {
      await prefs.setString('sleep_$key', value.toString());
    }

    if (uid.isNotEmpty) {
      await _db.collection('users').doc(uid).set({
        'sleep_settings': {key: value},
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // --- Task 10: Delete Alarm from Firebase ---
  Future<void> deleteAlarm(String alarmTitle) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isNotEmpty) {
      await _db.collection('users').doc(uid).update({
        'alarms.$alarmTitle': FieldValue.delete(),
      });
    }
  }

  // --- Task 13: Edit/Update Alarm Time ---
  Future<void> updateAlarmTime(String alarmTitle, String newTime) async {
    String uid = _auth.currentUser?.uid ?? "";
    if (uid.isNotEmpty) {
      await _db.collection('users').doc(uid).set({
        'alarms': {
          alarmTitle: {
            'time': newTime,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
      }, SetOptions(merge: true));
    }
  }

  // --- Task 9: Get Status from Local Storage ---
  Future<bool> getLocalStatus(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // 'sleep_' prefix wahi hona chahiye jo save karte waqt use kiya tha
    return prefs.getBool('sleep_$key') ?? false;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = "user_123"; // Replace with your actual Auth UID

  // 🔥 Task: Save Alarm to Firebase & Local
  Future<void> saveAlarm({
    required String bedtime,
    required String sleepHours,
    required String repeat,
    required bool isVibrate,
  }) async {
    // Yahan Firestore logic hona chahiye
    Map<String, dynamic> alarmData = {
      'bedtime': bedtime,
      'sleep_hours': sleepHours,
      'repeat': repeat,
      'is_vibrate': isVibrate,
      'created_at': FieldValue.serverTimestamp(),
    };

    try {
      // 1. Save to Firebase
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('alarms')
          .add(alarmData);

      // 2. Save to Local Storage (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_alarm', jsonEncode(alarmData));

      print("✅ Alarm saved successfully in Cloud & Local!");
    } catch (e) {
      print("❌ Error saving alarm: $e");
    }
  }
}
