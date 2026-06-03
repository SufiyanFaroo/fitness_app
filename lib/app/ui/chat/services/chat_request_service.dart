import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🚀 1. REQUEST SEND KERNA: Samne wale ko request bhejney ka function
  Future<void> sendChatRequest({required String receiverUid}) async {
    final String? senderUid = _auth.currentUser?.uid;
    if (senderUid == null || senderUid == receiverUid) return;

    // Unique document ID taake duplicate requests na bajein (SenderID_ReceiverID)
    final String requestId = "${senderUid}_$receiverUid";

    try {
      await _firestore.collection('chat_requests').doc(requestId).set({
        'sender_uid': senderUid,
        'receiver_uid': receiverUid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("🎯 Chat request sent successfully to: $receiverUid");
    } catch (e) {
      debugPrint("❌ Failed to send chat request: $e");
    }
  }

  // 👀 2. REQUESTS SEEN/LISTEN: Muja request aayi hai ya nahi? Live dekhne ke liye Stream
  // Is stream ko aap apne Request Pending Screen par StreamBuilder mein use karenge
  // 📁 chat_request_service.dart mein isey update karein:
  Stream<QuerySnapshot> getIncomingRequestsStream() {
    final String? currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return const Stream.empty();

    // ✅ BUG FIX: Yahan 'chat_requests' ki jagah 'friends_network' aur 'receiver_uid' ki jagah 'receiverId' aayega!
    return _firestore
        .collection('friends_network')
        .where('receiverId', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ✅ 3. REQUEST ACCEPT/REJECT: Request accept karne ya reject karne ka system
  Future<void> handleRequestAction({
    required String requestId,
    required String senderUid,
    required bool accept,
  }) async {
    try {
      final String? currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return;

      if (accept) {
        // Status update karein
        await _firestore.collection('chat_requests').doc(requestId).update({
          'status': 'accepted',
        });

        // 🤝 Dono users ko ek dusre ke friends/chats sub-collection mein add kar dein
        await _firestore
            .collection('users')
            .doc(currentUid)
            .collection('chats')
            .doc(senderUid)
            .set({
              'chat_active': true,
              'created_at': FieldValue.serverTimestamp(),
            });

        await _firestore
            .collection('users')
            .doc(senderUid)
            .collection('chats')
            .doc(currentUid)
            .set({
              'chat_active': true,
              'created_at': FieldValue.serverTimestamp(),
            });

        debugPrint("🎉 Chat request accepted!");
      } else {
        // Reject karne par document delete kar dein ya status update karein
        await _firestore.collection('chat_requests').doc(requestId).delete();
        debugPrint("🛑 Chat request rejected.");
      }
    } catch (e) {
      debugPrint("❌ Error handling request action: $e");
    }
  }
}
