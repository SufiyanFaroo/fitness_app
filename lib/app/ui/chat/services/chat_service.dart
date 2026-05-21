import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter to easily access logged-in User's ID
  String get currentUserId => _auth.currentUser?.uid ?? "";

  // 1️⃣ Unique Room ID Generator (Sorted Systematically)
  String getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }

  // ==========================================
  // 🤝 FRIEND REQUEST NETWORK INFRASTRUCTURE
  // ==========================================

  // A. Send Friend Request (Creates a 'pending' link)
  Future<void> sendFriendRequest(String receiverId) async {
    if (currentUserId.isEmpty) return;
    String requestId = "${currentUserId}_$receiverId";

    await _firestore.collection('friends_network').doc(requestId).set({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // B. Accept Friend Request (Switches to 'accepted' & auto-creates Chat Room)
  Future<void> acceptFriendRequest(String senderId) async {
    if (currentUserId.isEmpty) return;
    String requestId = "${senderId}_$currentUserId";

    // Update status to accepted
    await _firestore.collection('friends_network').doc(requestId).update({
      'status': 'accepted',
    });

    // Automatically initialize a professional Chat Room object token
    String roomId = getChatRoomId(currentUserId, senderId);

    await _firestore.collection('chat_rooms').doc(roomId).set({
      'chatRoomId': roomId,
      'last_message': "Connected! Say hello 👋",
      'last_message_time': Timestamp.now(),
      'last_message_sender_id': senderId,
      'participants': [currentUserId, senderId],
    }, SetOptions(merge: true));
  }

  // C. Reject or Cancel Request Link
  Future<void> rejectFriendRequest(String senderId) async {
    if (currentUserId.isEmpty) return;
    String requestId = "${senderId}_$currentUserId";
    await _firestore.collection('friends_network').doc(requestId).delete();
  }

  // D. Stream Connection Network Status Lookup Matrix
  Stream<QuerySnapshot> getConnectionStream() {
    return _firestore.collection('friends_network').snapshots();
  }

  // ==========================================
  // 💬 MESSAGING ENGINE WITH PAGINATION CAP
  // ==========================================

  // 2️⃣ Send Text or Link Message Method
  Future<void> sendMessage(String receiverId, String text) async {
    if (currentUserId.isEmpty) return;

    String type = "text";
    if (text.contains("http://") || text.contains("https://")) {
      type = "link";
    }

    await _dispatchPayload(receiverId, currentUserId, text, type, null);
  }

  // 3️⃣ Send Image Message Method (Firebase Storage Attachment Pipeline)
  Future<void> sendImageMessage(String receiverId, File file) async {
    if (currentUserId.isEmpty) return;

    String roomId = getChatRoomId(currentUserId, receiverId);

    // Create reference inside Firebase Storage
    String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    Reference ref = _storage.ref().child("chats/$roomId/$fileName");

    // Upload bytes process
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    // Dispatch message payload to Firestore
    await _dispatchPayload(
      receiverId,
      currentUserId,
      "📷 Photo Attachment",
      "image",
      downloadUrl,
    );
  }

  // Helper method to write standard/media data into Firestore pipelines
  Future<void> _dispatchPayload(
    String receiverId,
    String senderId,
    String text,
    String type,
    String? mediaUrl,
  ) async {
    final Timestamp timestamp = Timestamp.now();
    String roomId = getChatRoomId(senderId, receiverId);

    DocumentReference msgDoc = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    Map<String, dynamic> messageData = {
      'messageId': msgDoc.id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'seen': false,
      'messageType': type,
      'mediaUrl': mediaUrl,
    };

    // Write message directly to Sub-collection
    await msgDoc.set(messageData);

    // Update Room Master data for dashboard previews
    await _firestore.collection('chat_rooms').doc(roomId).set({
      'chatRoomId': roomId,
      'last_message': text,
      'last_message_time': timestamp,
      'last_message_sender_id': senderId,
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

  // 4️⃣ Stream Active Chat Rooms with Pagination Limit (Shows top 7 latest active chats)
  Stream<QuerySnapshot> getActiveChatRooms() {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('last_message_time', descending: true)
        .limit(
          7,
        ) // ✅ PAGINATION: Automatically restricts first load to 7 chats for high-speed WhatsApp look
        .snapshots();
  }

  // 5️⃣ Stream Messages for active Chat Rooms
  Stream<QuerySnapshot> getMessages(String receiverId) {
    String roomId = getChatRoomId(currentUserId, receiverId);
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Bheji hui pending requests ko track karne ke liye dynamic query stream
  Stream<QuerySnapshot> getSentRequestsStream() {
    return _firestore
        .collection('friends_network')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
}
