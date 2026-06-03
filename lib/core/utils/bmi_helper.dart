import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BMIMetricResult {
  final double score;
  final String status;
  final String statusImage;
  final String advice;
  final double prime;
  final double ponderalIndex;
  final double minHealthyWeight;
  final double maxHealthyWeight;
  final String timestamp;

  BMIMetricResult({
    required this.score,
    required this.status,
    required this.statusImage,
    required this.advice,
    required this.prime,
    required this.ponderalIndex,
    required this.minHealthyWeight,
    required this.maxHealthyWeight,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'status': status,
      'status_image':
          statusImage, // Parsed safely inside snake_case format keys
      'advice': advice,
      'prime': prime,
      'ponderalIndex': ponderalIndex,
      'minHealthyWeight': minHealthyWeight,
      'maxHealthyWeight': maxHealthyWeight,
      'timestamp': timestamp,
    };
  }

  factory BMIMetricResult.fromJson(Map<String, dynamic> json) {
    return BMIMetricResult(
      score: (json['score'] ?? 0.0).toDouble(),
      status: json['status'] ?? "N/A",
      statusImage:
          json['status_image'] ??
          "assets/images/bmi_normal.png", // Safe structural design fallback
      advice: json['advice'] ?? "",
      prime: (json['prime'] ?? 0.0).toDouble(),
      ponderalIndex: (json['ponderalIndex'] ?? 0.0).toDouble(),
      minHealthyWeight: (json['minHealthyWeight'] ?? 0.0).toDouble(),
      maxHealthyWeight: (json['maxHealthyWeight'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class BMIHelper {
  static const String _localCacheKey = "cached_fitquest_bmi_metrics";

  // ✅ CALCULATOR: Processes advanced parameters matching clinical specifications guidelines natively
  static BMIMetricResult calculateAdvancedBMI({
    required double weightKg,
    required double heightCm,
  }) {
    if (weightKg <= 1.0 ||
        heightCm <= 1.0 ||
        weightKg.isNaN ||
        heightCm.isNaN) {
      return BMIMetricResult(
        score: 0.0,
        status: "N/A",
        statusImage: "assets/images/bmi_normal.png",
        advice: "Verify height and weight inputs inside profile settings.",
        prime: 0.0,
        ponderalIndex: 0.0,
        minHealthyWeight: 0.0,
        maxHealthyWeight: 0.0,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    final double heightInMeters = heightCm / 100.0;
    final double heightSquared = heightInMeters * heightInMeters;

    final double bmiValue = weightKg / heightSquared;
    final double bmiPrime = bmiValue / 25.0;
    final double pIndex = weightKg / (heightSquared * heightInMeters);
    final double minWeight = 18.5 * heightSquared;
    final double maxWeight = 24.9 * heightSquared;

    String status;
    String statusImage;
    String advice;

    // ✅ TARGETED SPECIFICATION MAPPING GATES: Matches conditions indices precisely from charts
    if (bmiValue < 16.0) {
      status = "Severe Thinness";
      statusImage =
          "assets/images/bmi_underweight.png"; // Map onto corresponding vector layouts keys
      advice =
          "Critical underweight status observed. Consult a medical professional immediately.";
    } else if (bmiValue >= 16.0 && bmiValue < 17.0) {
      status = "Moderate Thinness";
      statusImage = "assets/images/bmi_underweight.png";
      advice =
          "Moderate lean mass tier. Consider increasing daily caloric density with nutrient-rich foods.";
    } else if (bmiValue >= 17.0 && bmiValue < 18.5) {
      status = "Mild Thinness";
      statusImage = "assets/images/bmi_underweight.png";
      advice =
          "Marginally below optimum parameters. Focus on balanced progressive strength training.";
    } else if (bmiValue >= 18.5 && bmiValue < 25.0) {
      status = "Normal Weight";
      statusImage = "assets/images/bmi_normal.png";
      advice =
          "Excellent! You are within a highly optimal metabolic health range. Keep it up!";
    } else if (bmiValue >= 25.0 && bmiValue < 30.0) {
      status = "Overweight";
      statusImage = "assets/images/bmi_overweight.png";
      advice =
          "Elevated weight ratio detected. Incorporate a mild caloric deficit and cardiovascular training.";
    } else if (bmiValue >= 30.0 && bmiValue < 35.0) {
      status = "Obese Class I";
      statusImage = "assets/images/bmi_obese.png";
      advice =
          "Class 1 obesity metrics. Prioritize calorie-controlled nutrition plans consistently.";
    } else if (bmiValue >= 35.0 && bmiValue < 40.0) {
      status = "Obese Class II";
      statusImage = "assets/images/bmi_obese.png";
      advice =
          "Class 2 advanced risk profile. Advisable to coordinate lifestyle changes with metrics tracking.";
    } else {
      status = "Obese Class III";
      statusImage = "assets/images/bmi_obese.png";
      advice =
          "Critical mass concentration. Immediate focus required on structured nutritional restriction plans.";
    }

    return BMIMetricResult(
      score: (bmiValue * 10).round() / 10,
      status: status,
      statusImage: statusImage,
      advice: advice,
      prime: (bmiPrime * 100).round() / 100,
      ponderalIndex: (pIndex * 10).round() / 10,
      minHealthyWeight: (minWeight * 10).round() / 10,
      maxHealthyWeight: (maxWeight * 10).round() / 10,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  // ✅ CLOUD SYNCHRONIZATION PIPELINE: Propagates structural vector strings directly onto Firestore fields
  static Future<void> syncBMIToCloudAndLocal(BMIMetricResult result) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final Map<String, dynamic> jsonPayload = result.toJson();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_localCacheKey}_$uid', jsonEncode(jsonPayload));
    } catch (e) {
      debugPrint("❌ Offline cache serialization fail: $e");
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await docRef.set({
        'last_bmi_score': result.score,
        'last_bmi_status': result.status,
        'last_bmi_image': result
            .statusImage, // ✅ PERSISTED: Synchronized image paths token onto remote server
        'last_sync_timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await docRef.collection('bmi_history').add({
        ...jsonPayload,
        'server_timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint("🎯 Real-time Data Overwrite Completed: ${result.score}");
    } catch (e) {
      debugPrint("❌ Cloud Firestore network write block failure: $e");
    }
  }

  static Stream<DocumentSnapshot> getBMILiveStream() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  static Stream<QuerySnapshot> getBMIHistoryStream() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bmi_history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<BMIMetricResult?> getOfflineCachedBMI() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString('${_localCacheKey}_$uid');
      if (cachedJson != null) {
        return BMIMetricResult.fromJson(jsonDecode(cachedJson));
      }
    } catch (e) {
      debugPrint("Offline lookup failed: $e");
    }
    return null;
  }
}
