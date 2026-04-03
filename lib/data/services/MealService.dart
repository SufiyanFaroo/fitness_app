import 'dart:convert'; // 🔥 Map ko String banane ke liye zaroori hai
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. Notification & Reminder Logic ---
  Future<void> saveNotifyStatus(String mealId, bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_$mealId', status);

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('meal_settings')
          .doc(mealId)
          .set({
            'notify': status,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }

  Future<bool> getNotifyStatus(String mealId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notify_$mealId') ?? false;
  }

  // --- 2. Nutrition & Goals Logic (FIXED) ---
  Future<void> updateNutritionGoals(Map<String, dynamic> goals) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // 🔥 Firebase Sync
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('nutrition')
          .set(goals, SetOptions(merge: true));

      // 🔥 Local Storage Sync (Cleaned Logic)
      final prefs = await SharedPreferences.getInstance();

      // Goals ka duplicate banana taake asli data kharab na ho
      Map<String, dynamic> localData = Map.from(goals);

      // Firestore ke 'FieldValue' objects local storage mein save nahi ho sakte, isliye delete kar rahe hain
      localData.removeWhere((key, value) => value is FieldValue);

      // Map ko String mein convert karke save karna
      await prefs.setString('local_nutrition', jsonEncode(localData));

      debugPrint("Nutrition goals synced: Cloud & Local");
    } catch (e) {
      debugPrint("Error updating nutrition: $e");
    }
  }

  // --- 3. Share Logic ---
  Future<void> shareDietPlan(String mealName) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'last_shared_meal': mealName,
        'last_shared_at': FieldValue.serverTimestamp(),
      });
    }
    final String shareText =
        "Hey! Check out this delicious $mealName recipe on FitQuest App!";
    await Share.share(shareText);
  }

  // --- 4. Favorite & Schedule Logic ---
  Future<void> toggleFavorite(String mealName, bool isFavorite) async {
    final uid = _auth.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fav_$mealName', isFavorite);

    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(mealName)
          .set({
            'mealName': mealName,
            'isFavorite': isFavorite,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }

  // 🔥 Task 10: Get Nutrition Data from Firebase (Real-time)
  Stream<DocumentSnapshot> getNutritionData() {
    final uid = _auth.currentUser?.uid;
    // Ensure karein ke path bilkul sahi ho jahan aapka data para hai
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('nutrition') // Ya 'weekly_stats' jo bhi aapne rakha hai
        .snapshots();
  }

  // 🔥 Task 9: Toggle Meal Reminders (Local Storage)
  Future<void> toggleMealReminders(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('meal_reminders_enabled', enabled);
      debugPrint("Local Storage: Meal Reminders set to $enabled");
    } catch (e) {
      debugPrint("Error saving reminders status: $e");
    }
  }
}
