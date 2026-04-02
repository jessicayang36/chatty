import 'package:flutter/material.dart';
import 'package:chatty/features/profile/user_profile.dart';
import 'package:chatty/features/profile/user_service.dart';
import 'package:provider/provider.dart'; // import this for the context.read

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _friendCodeController = TextEditingController();
  UserProfile? _foundUser;

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  Future<void> getPersonWithFriendCode() async {
    final userService = context.read<UserService>();

    final friend = await userService.getUserByFriendCode(_friendCodeController.text);

    setState(() {
      _foundUser = friend;
    });
  }

  @override
  Widget build(BuildContext context) {

		final userService = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          }, 
          icon: Icon(Icons.arrow_back)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _friendCodeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter friend code',
              ),
            ),

            IconButton(
              onPressed: getPersonWithFriendCode,
              icon: const Icon(Icons.search),
            ),

            if (_foundUser != null)
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('${_foundUser!.firstName} ${_foundUser!.lastName}'),
                subtitle: Text(_foundUser!.email ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () async {
                    if (_foundUser?.friendCode != null) {
                      await userService.sendFriendRequest(_foundUser!.friendCode!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Friend request sent!")),
                        );
                        setState(() {
                          _foundUser = null;
                          _friendCodeController.clear();
                        });
                      }
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}