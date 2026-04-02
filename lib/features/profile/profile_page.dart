
import 'package:chatty/features/profile/edit_profile_page.dart';
import 'package:chatty/features/profile/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:chatty/features/authentication/auth_service.dart';
import 'package:chatty/features/profile/user_service.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget{
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      await authService.signOut();
      // AuthGate will handle navigation
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final userService = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: userService.currentUserProfileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userProfile = snapshot.data;

          if (userProfile == null) {
            return const Center(child: Text('Not logged in or profile not found.'));
          }

          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Email: ${userProfile.email ?? '1No email provided'}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Friend Code: ${userProfile.friendCode ?? 'None'}', style: Theme.of(context).textTheme.titleMedium),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            EditProfilePage(userProfile: userProfile)));
                  }, 
                  child: Text("Edit Profile")
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => _signOut(context), child: Text("Sign out"))
              ],
            ),
          );
        },
      ),
    );
  }

}