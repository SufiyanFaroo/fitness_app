import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";

  // Real-time notifications stream
  Stream<QuerySnapshot> getNotifications() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete single notification
  Future<void> deleteNotification(String id) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .doc(id)
        .delete();
  }

  // Clear all notifications
  Future<void> clearAll() async {
    var snapshots = await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}
