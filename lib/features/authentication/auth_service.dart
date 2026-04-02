import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService(this._firebaseAuth);

  User? get currentUser => _firebaseAuth.currentUser; // get current user

  // stream provides continuous flow of data over time
  // .authStateChanges triggers event whenever the auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signInWithEmailPassword(String email, String password) async {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
  }

  Future<User?> signUpWithEmailPassword(String email, String password) async {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}