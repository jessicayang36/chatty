

import 'package:chatty/features/profile/user_profile.dart';
import 'package:chatty/features/authentication/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:chatty/features/profile/user_service.dart';
import 'package:provider/provider.dart';


class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() { // lifecycle method: flutter framework calls automatically when State object removed from the widget tree permanently.
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _updateAndSaveProfile() async {
    final userService = context.read<UserService>();
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill out both first and last name.")));
      }
      return;
    }

    if (currentUser == null) {
      // Safeguard.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No user logged in. Please restart the app.")));
      return;
    }

    final newFriendCode = userService.generateUniqueFriendCode();
    final userProfile = UserProfile(
      uid: currentUser.uid,
      email: currentUser.email,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      friendCode: await newFriendCode, 
    );

    try {
      // Use createUserDocument here since this is the first time we are saving the user's profile details.
      await userService.createUserDocument(userProfile);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your first name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your last name',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _updateAndSaveProfile, child: const Text("Save Profile"))
          ],
        ),
      ),
    );
  }
}