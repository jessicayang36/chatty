import 'package:chatty/features/authentication/auth_gate.dart';
import 'package:chatty/features/threads/thread_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/authentication/auth_service.dart';
import 'features/profile/user_service.dart';
import 'package:chatty/features/threads/chat/chat_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chatty/features/notification/messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // initialize Firebase in this background isolate:
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // minimal handling — logging, quick local DB updates, etc.
  // avoid long-running work here.
  print('Background message received: ${message.messageId}, data: ${message.data}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAuth>(
          create: (_) => FirebaseAuth.instance
        ),
        Provider<FirebaseFirestore>(
          create: (_) => FirebaseFirestore.instance,
        ),
        Provider<FirebaseMessaging>(
          create: (_) => FirebaseMessaging.instance,
        ),
        ProxyProvider<FirebaseAuth, AuthService>( 
          // FirebaseAuth (first value = thing it depends on)
          // AuthService(second value  = new value it will create and provide)
          update: (context, firebaseAuth, previousAuthService) => AuthService(firebaseAuth)
            // update is called whenever the value it depends on changes, creates the authservice
            // context: standard BuildContext, gives access to tree
            // firebaseAuth: the instance passed from higher up in the tree
            // previousAuthService: previous instance of authService created

            // AuthService(firebaseAuth): the single instance of AuthService here
        ),
        ProxyProvider2<FirebaseFirestore, FirebaseAuth, UserService>(
          update: (context, firestore, auth, previousUserService) => UserService(firestore, auth),
        ),
        ProxyProvider2<FirebaseFirestore, FirebaseAuth, ThreadService>(
          update: (context, firestore, auth, previousThreadService) => ThreadService(firestore, auth),
        ),
        ProxyProvider3<FirebaseFirestore, FirebaseAuth, UserService, ChatService>(
          update: (context, firestore, auth, userService, previousChatService) => ChatService(firestore, auth, userService),
        ),
        ProxyProvider3<FirebaseAuth, UserService, FirebaseMessaging, MessagingService>(
          update: (context, auth, userService, firebaseMessaging, previousMessagingService) => MessagingService(auth, userService, firebaseMessaging),
        ),
      ], 
      child: MaterialApp(
        title: 'Chatty',
        home: const AuthGate(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
      ),
    );
  }
}
