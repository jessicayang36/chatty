
import 'package:chatty/features/profile/user_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';


class MessagingService {

  // final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final UserService _userService;
  final FirebaseMessaging _firebaseMessaging;

  bool _initialized = false;

  MessagingService(this._firebaseAuth, this._userService, this._firebaseMessaging);
  
  Future<void> init() async {

    if (_initialized) return;
    _initialized = true;

    // ask for notification permission (iOS)
    await _firebaseMessaging.requestPermission();

    // get device token
    final token = await _firebaseMessaging.getToken();

    if (token != null) {
      await _saveTokenForCurrentUser(token);
    }

    // listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      await _saveTokenForCurrentUser(newToken);
    });

    // foreground & opened app handlers
    FirebaseMessaging.onMessage.listen((msg) {
      // handle foreground
      print('onMessage: ${msg.notification?.title}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      // handle taps
      print('onMessageOpenedApp: ${msg.data}');
    });
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await _userService.addFcmToken(user.uid, token);
  }

  Future<void> removeTokenForCurrentUser(String token) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await _userService.removeFcmToken(user.uid, token);
  }
  
}