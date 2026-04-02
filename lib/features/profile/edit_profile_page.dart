
import 'package:flutter/material.dart';
import 'package:chatty/features/profile/user_profile.dart';
import 'package:chatty/features/authentication/auth_service.dart';
import 'user_service.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile userProfile;
  const EditProfilePage({super.key, required this.userProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.userProfile.firstName);
    _lastNameController = TextEditingController(text: widget.userProfile.lastName);
  }

  void _updateAndSaveProfile() async {
    final userService = context.read<UserService>();
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill out both first and last name.")));
        return;
      }
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No user logged in. Please restart the app.")));
      return;
    }

    final userProfile = UserProfile(
      uid: currentUser.uid,
      email: currentUser.email,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
    );

    try {
      await userService.updateUserDocument(userProfile);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e.toString());
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              }, 
              child: Text("Back"),
            ),
            Text("Edit your profile"),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
              ),
            ),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
              ),
            ),
            ElevatedButton(onPressed: _updateAndSaveProfile, child: Text("Save"))
          ],
        ),
      )
    );
  }
}