import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  String? firstName;
  String? lastName;
  String? email;
  String? friendCode;

  UserProfile({
    required this.uid,
    this.firstName,
    this.lastName,
    this.email,
    this.friendCode,
  });

  // Factory constructor to create a UserProfile from a Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return UserProfile(
      uid: doc.id,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      email: data['email'] as String?,
      friendCode: data['friendCode'] as String?,
    );
  }
}