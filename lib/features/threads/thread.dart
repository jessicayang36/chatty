import 'package:cloud_firestore/cloud_firestore.dart';

class Thread {
  final String uid;
  final List<String> users;
  final String type; // 'direct' | 'group'
  final String? title;
  final Map<String, dynamic>? lastMessage;
  final Timestamp? lastUpdated;

  Thread({
    required this.uid,
    required this.users,
    this.type = 'direct',
    this.title,
    this.lastMessage,
    this.lastUpdated,
  });

  factory Thread.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Thread(
      uid: doc.id,
      users: List<String>.from(data['users'] ?? <String>[]),
      type: data['type'] as String? ?? 'direct',
      title: data['title'] as String?,
      lastMessage: data['lastMessage'] as Map<String, dynamic>?,
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  // Convert object into Firestore-friendly map
  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'type': type,
      if (title != null) 'title': title,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
    };
  }
}
