import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatty/features/profile/user_service.dart';
import 'package:chatty/features/threads/thread_service.dart';

// on this page have the files, photos, stuff. 
// can star photos

class ThreadPage extends StatefulWidget {
  final String threadId;
  final String? otherDisplayName;
  const ThreadPage({super.key, required this.threadId, this.otherDisplayName});

  @override
  State<StatefulWidget> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  
  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();
    final threadService = context.read<ThreadService>();
    final navigator = Navigator.of(context);

    return Scaffold(
      appBar: AppBar(
        title: widget.otherDisplayName != null ? Text(widget.otherDisplayName!) : Text(widget.threadId),
        actions: [
          IconButton(
            onPressed: () {
              navigator.pop();
            }, 
            icon: Icon(Icons.arrow_back)
          )
        ],
      ),
    );
  }

}