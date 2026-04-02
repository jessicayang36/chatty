import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatty/features/profile/user_profile.dart' as app;
// import 'package:chatty/features/profile/domain/user_profile.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:chatty/utils/code_generator.dart';

class UserService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
 
  UserService(this._firestore, this._firebaseAuth);

	// ---------------------------------------------------------------------------
  // USER PROFILE
	// ---------------------------------------------------------------------------

  Future<bool> doesUserProfileExist(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  // create a new user document in firestore
  Future<void> createUserDocument(app.UserProfile user) async {
    // get a reference to the users collection
    final usersCollection = _firestore.collection('users');
 
    // create a document for the user with their UID
    await usersCollection.doc(user.uid).set({
      'uid': user.uid, // TODO: maybe get rid of this
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'friendCode': user.friendCode,
    });
  }

  Future<void> updateUserDocument(app.UserProfile user) async {
    final usersCollection = _firestore.collection('users');
    await usersCollection.doc(user.uid).update({
      if (user.firstName != null) 'firstName': user.firstName,
      if (user.lastName != null) 'lastName': user.lastName,
    });
  }

  Future<app.UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      return app.UserProfile.fromFirestore(doc);
    }

    return null;
  }


  // Stream of current user's profile from Firestore. Emits null if user not logged in.
  Stream<app.UserProfile?> get currentUserProfileStream {
    return _firebaseAuth.authStateChanges().switchMap((user) {
      if (user != null) {
        // If the user is logged in, listen to their document in Firestore.
        return _firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
          if (snapshot.exists) {
            return app.UserProfile.fromFirestore(snapshot);
          }
          return null; // User is authenticated, but profile doc doesn't exist.
        });
      } else {
        // If the user is logged out, emit a single null value.
        return Stream.value(null);
      }
    });
  }

  // add fcm Token for user
  Future<void> addFcmToken(String uid, String token) async {
    await _firestore
      .collection("users")
      .doc(uid)
      .collection("tokens")
      .doc(token)
      .set({
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
  }

  // remove fcm Token for user
  Future<void> removeFcmToken(String uid, String token) async {
    await _firestore
      .collection("users")
      .doc(uid)
      .collection("tokens")
      .doc(token)
      .delete();
  }
  
  // Returns a list of tokens for a user (useful for server code / admin)
  Future<List<String>> getFcmTokens(String uid) async {
    final snap = await _firestore
      .collection('users')
      .doc(uid)
      .collection('tokens')
      .get();

    return snap.docs.map((d) => d.id).toList();
  }

  // ----- Helper Methods:

  // return uid of the current user
  String? currentUid() {
    return _firebaseAuth.currentUser?.uid;
  }

  // returns a display name for uid or null if not found
  Future<String?> getDisplayName(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final first = data['firstName'] as String?;
    final last = data['lastName'] as String?;
    if ((first ?? '').isNotEmpty || (last ?? '').isNotEmpty) {
      return '${first ?? ''}${first != null && last != null ? ' ' : ''}${last ?? ''}'.trim();
    }
    return data['email'] as String? ?? uid;
  }


	// ---------------------------------------------------------------------------
  // FRIEND 
	// ---------------------------------------------------------------------------

	// Generates a unique friend code for users
  Future<String> generateUniqueFriendCode() async {
    String fc = generateRandomCode(8);
    bool isUnique = false;

    while (!isUnique) {
      // Check if this code already exists in the database
      final result = await _firestore.collection('users').where('friendCode', isEqualTo: fc).get();
      if (result.docs.isEmpty) {
        isUnique = true;
      } else {
        fc = generateRandomCode(8);
      }
    }

    return fc;
  }

	// create a new friendship document in firestore
	Future<void> createFriendshipDocument(String requesterUid, String recipientUid) async {
		final users = [requesterUid, recipientUid]..sort();
		final friendshipId = users.join('_'); // uidA_uidB
		final ref = _firestore.collection('friendships').doc(friendshipId);

		// transaction prevents overwriting, race-conditions, multiple writes
		await _firestore.runTransaction((tx) async { 
			final snapshot = await tx.get(ref);

			if (snapshot.exists) {
				final data = snapshot.data()!;
				final existingStatus = (data['status'] as String?) ?? '';
				// If there's already an accepted friendship, do nothing.
				if (existingStatus == 'accepted') return;
				// If there's a pending request from same pair, do nothing.
				if (existingStatus == 'pending') return;

				// Otherwise overwrite
				if (existingStatus == 'declined' || existingStatus == 'removed') {
					tx.update(ref, {
						'status': 'pending',
						'requestedBy': requesterUid,
						'recipient': recipientUid,
						'createdAt': FieldValue.serverTimestamp(),
						'declinedAt': FieldValue.delete(),
						'acceptedAt': FieldValue.delete(),
						'removedAt': FieldValue.delete(),
					});
					return;
				}
			}

			// if no status, overwrite
			tx.set(ref, {
				'uid': friendshipId, // TODO: maybe get rid of this
				'users': users,
				'requestedBy': requesterUid,
				'recipient': recipientUid,
				'status': 'pending',
				'createdAt': FieldValue.serverTimestamp(),
			});
		});
	}

	// TODO: CHANGE BELOW TO TRANSACTIONS
  // This user sends out friend request to another user
	Future<void> sendFriendRequest(String friendCode) async {
		final friendQuery = await _firestore.collection('users').where('friendCode', isEqualTo: friendCode).limit(1).get();

		if (friendQuery.docs.isEmpty) return; // Friend code does not exist.

		final friendDoc = friendQuery.docs.first;
		final currentUser = _firebaseAuth.currentUser;

		if (currentUser == null) return;
		if (friendDoc.id == currentUser.uid) return; // Prevent user add themself

    await createFriendshipDocument(currentUser.uid, friendDoc.id);
	}

  // accept a friend request for current user
  Future<void> acceptFriendRequest(String friendUID) async {
    final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return;

    String combinedFriendId = ([friendUID, currentUser.uid]..sort()).join('_');
    await _firestore
      .collection('friendships')
      .doc(combinedFriendId)
      .update({'status': 'accepted'});
  }

  // decline a friend request for current user
  Future<void> declineFriendRequest(String friendUID) async {
    final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return;

    String combinedFriendId = ([friendUID, currentUser.uid]..sort()).join('_');
    await _firestore
      .collection('friendships')
      .doc(combinedFriendId)
      .update({'status': 'declined'});
  }

	// deletes friendship document for this user and given friend
	Future<void> deleteFriend(String friendUID) async {
		final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return;

		String combinedFriendId = ([friendUID, currentUser.uid]..sort()).join('_');
		final ref = _firestore.collection('friendships').doc(combinedFriendId);

		await _firestore.runTransaction((tx) async {
			final snap = await tx.get(ref);
			if (!snap.exists) return;
			final data = snap.data() ?? {};
			final status = (data['status'] as String?) ?? '';
			final docUsers = List<String>.from(data['users'] ?? []);

			if (status != 'accepted') return;

			if (!docUsers.contains(currentUser.uid)) {
				throw Exception('Not a participant in this friendship.');
			}

			tx.delete(ref);
		});
	}

	// TODO: implement blocks
	


  // Fetch profile objects for a list of friend UIDs
	Future<List<app.UserProfile>> getFriendsDetails(List<String> uids) async {
		if (uids.isEmpty) return [];

		const int batchSize = 10;
		final results = <app.UserProfile>[];
		// We will preserve order by mapping id -> profile
		final Map<String, app.UserProfile> idToProfile = {};

		for (var i = 0; i < uids.length; i += batchSize) {
			final chunk = uids.sublist(i, (i + batchSize).clamp(0, uids.length));
			final snap = await _firestore
					.collection('users')
					.where(FieldPath.documentId, whereIn: chunk)
					.get();

			for (final doc in snap.docs) {
				final profile = app.UserProfile.fromFirestore(doc);
				idToProfile[doc.id] = profile;
			}
		}

		// Reconstruct list in the original order, skipping missing profiles
		for (final uid in uids) {
			final p = idToProfile[uid];
			if (p != null) results.add(p);
		}

		return results;
	}

  // Get a single user profile by their friend code
  Future<app.UserProfile?> getUserByFriendCode(String friendCode) async {
    final snapshot = await _firestore
			.collection('users')
			.where('friendCode', isEqualTo: friendCode)
			.limit(1)
			.get();

    if (snapshot.docs.isNotEmpty) {
      return app.UserProfile.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

	// returns UIDs of accepted friends
	Future<List<String>> getFriendUIDs() async {
		final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return [];

		final q = await _firestore
			.collection('friendships')
			.where('users', arrayContains: currentUser.uid)
			.where('status', isEqualTo: 'accepted')
			.get();

		final uids = <String>{};
		for (final doc in q.docs) {
			final users = List<String>.from(doc.data()['users'] ?? []);
			if (users.length != 2) continue;
			final other = users.firstWhere((u) => u != currentUser.uid, orElse: () => '');
			if (other.isNotEmpty) uids.add(other);
		}
		return uids.toList();
	}

	// returns UIDs of friend requests this user has gotten (pending)
	Future<List<String>> getReceivedFriendRequestUIDs() async {
		final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return [];

		final q = await _firestore
			.collection('friendships')
			.where('recipient', isEqualTo: currentUser.uid)
			.where('status', isEqualTo: 'pending')
			// .orderBy('createdAt', descending: true)
			.get();

		final uids = <String>{};
		for (final doc in q.docs) {
			final users = List<String>.from(doc.data()['users'] ?? []);
			if (users.length != 2) continue;
			final other = users.firstWhere((u) => u != currentUser.uid, orElse: () => '');
			if (other.isNotEmpty) uids.add(other);
		}
		return uids.toList();
	}

	// returns UIDs of friend requests this user has sent (pending)
	Future<List<String>> getSentFriendRequestUIDs() async {
		final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return [];

		final q = await _firestore
			.collection('friendships')
			.where('requestedBy', isEqualTo: currentUser.uid)
			.where('status', isEqualTo: 'pending')
			// .orderBy('createdAt', descending: true)
			.get();

		final uids = <String>{};
		for (final doc in q.docs) {
			final users = List<String>.from(doc.data()['users'] ?? []);
			if (users.length != 2) continue;
			final other = users.firstWhere((u) => u != currentUser.uid, orElse: () => '');
			if (other.isNotEmpty) uids.add(other);
		}
		return uids.toList();
	}


	// convenience: return full profiles for friends
	Future<List<app.UserProfile>> getFriends() async {
		final uids = await getFriendUIDs();
		if (uids.isEmpty) return [];
		return getFriendsDetails(uids);
	}

	// convenience: return full profiles for friends
	Future<List<app.UserProfile>> getReceivedFriendRequests() async {
		final uids = await getReceivedFriendRequestUIDs();
		if (uids.isEmpty) return [];
		return getFriendsDetails(uids);
	}

	// convenience: full profiles for sent requests
	Future<List<app.UserProfile>> getSentFriendRequests() async {
		final uids = await getSentFriendRequestUIDs();
		if (uids.isEmpty) return [];
		return getFriendsDetails(uids);
	}


	// --- Streams ---

  // TODO: change streams to use authStateChanges() and switchMap() like thread_service threadsStream()

	// stream of accepted friend UIDs
	Stream<List<String>> friendUIDsStream() {
  final currentUser = _firebaseAuth.currentUser;
  if (currentUser == null) return const Stream.empty();

  return _firestore
    .collection('friendships')
    .where('users', arrayContains: currentUser.uid)
    .where('status', isEqualTo: 'accepted')
    .snapshots()
    .map((snap) {
      final set = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] ?? []);
        if (users.length != 2) continue;
        final other = users.firstWhere((u) => u != currentUser.uid, orElse: () => '');
        if (other.isNotEmpty) set.add(other);
      }
      return set.toList();
    });
}


	// stream of UIDs this user's received friend requests from (pending) 
	Stream<List<String>> receivedFriendRequestUIDsStream({bool orderByCreatedAt = false}) {
		final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return const Stream.empty();

		Query q = _firestore
				.collection('friendships')
				.where('recipient', isEqualTo: currentUser.uid)
				.where('status', isEqualTo: 'pending');

		// if (orderByCreatedAt) {
		// 	q = q.orderBy('createdAt', descending: true);
		// }

		return q.snapshots().map((snap) {
			final set = <String>{};
			for (final doc in snap.docs) {
				final data = doc.data() as Map<String, dynamic>?;
				final requestedBy = data?['requestedBy'] as String?;
				if (requestedBy != null && requestedBy.isNotEmpty) {
					set.add(requestedBy);
				}
			}
			return set.toList();
		});
	}

	// stream of UIDs this user has sent friend requests to (pending)
	Stream<List<String>> sentFriendRequestUIDsStream({bool orderByCreatedAt = false}) {
		final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return const Stream.empty();

		Query q = _firestore
				.collection('friendships')
				.where('requestedBy', isEqualTo: currentUser.uid)
				.where('status', isEqualTo: 'pending');

		// if (orderByCreatedAt) {
		// 	q = q.orderBy('createdAt', descending: true);
		// }

		return q.snapshots().map((snap) {
			final set = <String>{};
			for (final doc in snap.docs) {
				final data = doc.data() as Map<String, dynamic>?;
				final users = List<String>.from(data?['users'] ?? []);
				if (users.length != 2) continue;
				final other = users.firstWhere((u) => u != currentUser.uid, orElse: () => '');
				if (other.isNotEmpty) set.add(other);
			}
			return set.toList();
		});
	}


	// Stream for friend profiles details
	Stream<List<app.UserProfile>> friendsProfilesStream() {
		return friendUIDsStream().asyncMap((uids) async {
			if (uids.isEmpty) return <app.UserProfile>[];
			return getFriendsDetails(uids);
		});
	}

	// Stream for received friend request profile users details
	Stream<List<app.UserProfile>> receivedFriendRequestsProfilesStream() {
		// map UID stream to Future of profiles, then flatten using async* (or use Rx)
		return receivedFriendRequestUIDsStream().asyncMap((uids) async {
			if (uids.isEmpty) return <app.UserProfile>[];
			return getFriendsDetails(uids); // returns Future<List<app.UserProfile>>
		});
	}

// Stream for sent friend request profile users details
	Stream<List<app.UserProfile>> sentFriendRequestsProfilesStream() {
		return sentFriendRequestUIDsStream().asyncMap((uids) async {
			if (uids.isEmpty) return <app.UserProfile>[];
			return getFriendsDetails(uids);
		});
	}


  // helper method, checks friendship status of user and friend
	Future<String> checkFriendshipStatus(String friendUID) async {
		final currentUser = _firebaseAuth.currentUser;
		if (currentUser == null) return 'none';

		final users = [friendUID, currentUser.uid]..sort();
		final friendshipId = users.join('_');
		final doc = await _firestore.collection('friendships').doc(friendshipId).get();
		if (!doc.exists) return 'none';
		return (doc.data()?['status'] as String?) ?? 'none';
	}
}