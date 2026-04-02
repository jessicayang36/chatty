import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'package:chatty/features/profile/user_service.dart';
import 'package:chatty/features/authentication/login_page.dart';
import 'package:chatty/features/authentication/profile_setup_page.dart';
import 'package:chatty/features/profile/user_profile.dart';
import 'package:chatty/tabs/tabs.dart';
import "package:chatty/features/notification/messaging_service.dart";

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {

    final authService = context.watch<AuthService>(); // gets this from main
    final userService = context.watch<UserService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges, 
      builder: (context, snapshot) { // snapshot: represents the most recent interaction with the stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // will return user if it has data
          return StreamBuilder<UserProfile?>(
            stream: userService.currentUserProfileStream,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (profileSnapshot.hasData && profileSnapshot.data != null) {

                // initialize messaging service for notifications
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<MessagingService>().init();
                });

                return const Tabs();
              }
              return const ProfileSetupPage();
            },
          );
        }
        // return null, no data
        return const LoginPage();
      }
    );
  }
}