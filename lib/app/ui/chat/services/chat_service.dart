import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

// ✅ MODELS SPECIFICATION LINKS: Hooking your premium enterprise structural objects cleanly
import 'package:fitness_app/app/ui/chat/models/message_model.dart'; // Path verify karlein

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ FIXED ENCAPSULATION: Target reference link manually pass kar rahin hain taake 404 block khatam ho
  // Go to Firebase Console -> Storage -> top par likha link (e.g. gs://fitquest-app-xxxx.firebasestorage.app) se gs:// hata kar yahan likhein:
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket:
        "YOUR_PROJECT_ID.firebasestorage.app", // 👈 Apna proper Firebase Project ID bucket string likhein
  );

  String get currentUserId => _auth.currentUser?.uid ?? "";
  // Helper mapping algorithm to construct consistent deterministic room keys
  String getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }

  // 🚀 1. SOCIAL NETWORK HANDSHAKES MANAGEMENT
  Future<void> sendFriendRequest(String receiverId) async {
    if (currentUserId.isEmpty) return;
    final String requestId = "${currentUserId}_$receiverId";

    try {
      await _firestore.collection('friends_network').doc(requestId).set({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        "❌ Failure dispatching connection handshake follow payload: $e",
      );
    }
  }

  Future<void> acceptFriendRequest(String senderId) async {
    if (currentUserId.isEmpty) return;
    final String requestId = "${senderId}_$currentUserId";
    final String roomId = getChatRoomId(currentUserId, senderId);
    final Timestamp timestamp = Timestamp.now();

    try {
      // Step A: Update handshake state verification bounds cleanly
      await _firestore.collection('friends_network').doc(requestId).update({
        'status': 'accepted',
      });

      // Step B: Set up pristine Chat room session map matching ChatRoomModel properties blueprint
      await _firestore.collection('chat_rooms').doc(roomId).set({
        'chatRoomId': roomId,
        'last_message': "Connected! Say hello 👋",
        'last_message_time': timestamp,
        'last_message_sender_id': senderId,
        'participants': [currentUserId, senderId],
        'is_read': false,
        'unread_counts': {currentUserId: 1, senderId: 0},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint(
        "❌ Error finalizing handshake acceptance loop transaction: $e",
      );
    }
  }

  Future<void> rejectFriendRequest(String targetUserId) async {
    if (currentUserId.isEmpty) return;

    try {
      final String requestId = "${targetUserId}_$currentUserId";
      await _firestore.collection('friends_network').doc(requestId).delete();

      final String alternativeRequestId = "${currentUserId}_$targetUserId";
      await _firestore
          .collection('friends_network')
          .doc(alternativeRequestId)
          .delete();
    } catch (e) {
      debugPrint("❌ Request ejection database trace failure: $e");
    }
  }

  Stream<QuerySnapshot> getConnectionStream() {
    return _firestore.collection('friends_network').snapshots();
  }

  // 💬 2. MESSAGE TRANSMISSION DISPATCH PIPELINES
  Future<void> sendMessage(String receiverId, String text) async {
    if (currentUserId.isEmpty || text.trim().isEmpty) return;

    String type = "text";
    if (text.contains("http://") || text.contains("https://")) {
      type = "link";
    }

    await _dispatchPayload(receiverId, currentUserId, text.trim(), type, null);
  }

  Future<void> sendImageMessage(String receiverId, File file) async {
    if (currentUserId.isEmpty) return;

    final String roomId = getChatRoomId(currentUserId, receiverId);

    // ✅ PRODUCTION FILE TRACKER: Explicitly verify if the selected file path is physically readable
    if (!await file.exists()) {
      debugPrint(
        "❌ Media interceptor error: Selected local binary file is unreadable.",
      );
      return;
    }

    final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

    try {
      // Base chats directory dynamic mapping reference root path
      final Reference ref = _storage.ref().child("chats/$roomId/$fileName");

      // Explicit content type header initialization prevents binary parsing failure on storage buckets
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      // Initialise the upload pipe process channel explicitly
      final UploadTask uploadTask = ref.putFile(file, metadata);

      // ✅ FIXED ATOMIC BLOCKER: Continuous progress mapping wrapper prevents download URL generation before transfer success
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      if (snapshot.state == TaskState.success) {
        // Fetch token access endpoints safely only after success stream confirmation
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        await _dispatchPayload(
          receiverId,
          currentUserId,
          "📷 Photo Attachment",
          "image",
          downloadUrl,
        );
        debugPrint(
          "🎯 Image binary packet synchronized over cloud database routes.",
        );
      } else {
        debugPrint(
          "❌ Task aborted or cancelled prematurely during cloud stream compilation.",
        );
      }
    } catch (e) {
      debugPrint("❌ Core media system transmission failure: $e");
    }
  }

  // ✅ CORE DATA ENGINE: Restructured utilizing clean MessageModel architectural mapping layers explicitly
  Future<void> _dispatchPayload(
    String receiverId,
    String senderId,
    String text,
    String type,
    String? mediaUrl,
  ) async {
    final Timestamp timestamp = Timestamp.now();
    final String roomId = getChatRoomId(senderId, receiverId);

    final DocumentReference msgDoc = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    final MessageModel messagePayload = MessageModel(
      messageId: msgDoc.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: timestamp,
      seen: false,
      messageType: type,
      mediaUrl: mediaUrl,
    );

    try {
      // Commit chronological message payload trace packet down to sub-collection paths
      await msgDoc.set(messagePayload.toJson());

      // Update meta-properties matrix over the parent chat session directory room document snapshot node
      await _firestore.collection('chat_rooms').doc(roomId).set({
        'chatRoomId': roomId,
        'last_message': text,
        'last_message_time': timestamp,
        'last_message_sender_id': senderId,
        'participants': [senderId, receiverId],
        'is_read': false,
        // Atomic incremental strategy to scale unread counters tracking flags smoothly
        'unread_counts.$receiverId': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Service pipeline atomics write loop breakdown failure: $e");
    }
  }

  // 📡 3. REAL-TIME ENGINE QUERIES CHANNELS
  Stream<QuerySnapshot> getActiveChatRooms() {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('last_message_time', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessages(String receiverId) {
    final String roomId = getChatRoomId(currentUserId, receiverId);
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getSentRequestsStream() {
    return _firestore
        .collection('friends_network')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> cancelSentRequest(String receiverId) async {
    if (currentUserId.isEmpty) return;
    final String requestId = "${currentUserId}_$receiverId";

    try {
      await _firestore.collection('friends_network').doc(requestId).delete();
    } catch (e) {
      debugPrint(
        "❌ Error cancelling outbound request payload matrix trace: $e",
      );
    }
  }
}
