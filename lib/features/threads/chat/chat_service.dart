
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatty/features/threads/chat/message.dart';
import 'package:chatty/features/profile/user_service.dart';


class ChatService {

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final UserService _userService;

  ChatService(this._firestore, this._firebaseAuth, this._userService);

  CollectionReference _threadsRef() => _firestore.collection('threads');
  CollectionReference _messagesRef(String threadId) =>
    _threadsRef().doc(threadId).collection('messages');

  Future<void> sendMessage({
    required String threadId,
    required String text,
  }) async {
    final currUser = _firebaseAuth.currentUser;
    if (currUser == null) return;

    final senderName = await _userService.getDisplayName(currUser.uid) ?? '';
    
    final threadRef = _threadsRef().doc(threadId);
    final msgRef = _messagesRef(threadId).doc();

    

    final messageData = Message(
      id: msgRef.id,
      senderId: currUser.uid,
      senderName: senderName,
      text: text,
      createdAt: null,
    );

    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((tx) async {
      tx.set(msgRef, messageData.toMapForWrite());
      tx.update(threadRef, {'lastUpdated': now});
    });
  }

  // Stream the newest messages for a thread (real-time).
  Stream<List<Message>> streamMessages(String threadId, {int limit = 50}) {
    return _messagesRef(threadId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Message.fromFirestore(d)).toList());
  }

  // editMessage
  // deleteMessage
  // markAsRead
} 
