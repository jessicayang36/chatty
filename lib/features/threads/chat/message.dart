import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String? senderName; // denormalized name
  final String text;
  final DateTime? createdAt;
  final bool deleted;

  Message({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.text,
    this.createdAt,
    this.deleted = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAtRaw = data['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    }

    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
      deleted: (data['deleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMapForWrite() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'deleted': deleted,
    };
  }
}
