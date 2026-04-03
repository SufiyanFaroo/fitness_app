import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressPhoto {
  final String id;
  final String imageUrl;
  final DateTime date;

  ProgressPhoto({required this.id, required this.imageUrl, required this.date});

  // Firebase se data lene ke liye
  factory ProgressPhoto.fromFirestore(Map<String, dynamic> data, String id) {
    return ProgressPhoto(
      id: id,
      imageUrl: data['imageUrl'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
