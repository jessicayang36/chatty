
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatty/features/threads/thread.dart';
import 'package:rxdart/rxdart.dart';

class ThreadService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  ThreadService(this._firestore, this._firebaseAuth);

  // create ID for direct 1:1 threads
  String _directThreadId(String a, String b) {
    final list = [a, b]..sort();
    return list.join('_');
  }

  // create thread document for direct 1:1 threads, returning thread id
  Future<String?> createDirectThread(String otherUid) async {
    final currUser = _firebaseAuth.currentUser;
    if (currUser == null) return null;
    if (otherUid == currUser.uid) return null;

    final threadId = _directThreadId(currUser.uid, otherUid);
    final ref = _firestore.collection('threads').doc(threadId);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);

      if (!snapshot.exists) {
        tx.set(ref, {
          'users': [currUser.uid, otherUid],
          'type': 'direct',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });

    return threadId;
  }

  // create thread document for group threads, returning thread id
  Future<String?> createGroupThread({
    required List<String> groupUids,
    String? title,
  }) async {
    final currUser = _firebaseAuth.currentUser;
    if (currUser == null) return null;
    if (!groupUids.contains(currUser.uid)) {
      groupUids = [currUser.uid, ...groupUids];
    }

    if (groupUids.length < 3) return null;

    final ref = _firestore.collection('threads').doc();

    await ref.set({
      'users': groupUids,
      'type': 'group',
      if (title != null) 'title': title,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  //Stream threads for current user ordered by lastUpdated desc
  Stream<List<Thread>> threadsStream() {
    return _firebaseAuth.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value(<Thread>[]); // not signed in: no threads
      }

      return _firestore
        .collection('threads')
        .where('users', arrayContains: user.uid)
        // .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Thread.fromFirestore(doc))
              .toList(),
        );
    });
  }
}