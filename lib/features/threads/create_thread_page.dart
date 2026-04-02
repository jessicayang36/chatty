import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatty/features/profile/user_service.dart';
import 'package:chatty/features/profile/user_profile.dart';
import 'package:chatty/features/threads/thread_service.dart';
import 'package:chatty/features/threads/chat/chat_page.dart';

class CreateThreadPage extends StatefulWidget {
  const CreateThreadPage({super.key});

  @override
  State<CreateThreadPage> createState() => _CreateThreadPageState();
}

class _CreateThreadPageState extends State<CreateThreadPage> {
  final Set<String> selected = {};
  bool isCreating = false;

  @override
  Widget build(BuildContext context) {
    final userService = context.read<UserService>();
    final threadService = context.read<ThreadService>();
    final navigator = Navigator.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New chat'),
        actions: [
          TextButton(
            onPressed: selected.isEmpty || isCreating? null: () async {
              setState(() => isCreating = true);

              final threadId = selected.length == 1
                ? await threadService.createDirectThread(selected.first)
                : await threadService.createGroupThread(
                    groupUids: selected.toList(),
                    title: null,
                  );

              if (!mounted) return;
              navigator.pop();

              navigator.push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(threadId: threadId!),
                ),
              );
            },
            child: isCreating
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Text('Create'),
          ),
        ],
      ),

      body: FutureBuilder<List<UserProfile>>(
        future: userService.getFriends(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snap.data ?? [];
          if (friends.isEmpty) {
            return const Center(child: Text('No friends yet'));
          }

          return ListView(
            children: friends.map((f) {
              final isSelected = selected.contains(f.uid);
              return CheckboxListTile(
                value: isSelected,
                title: Text(f.firstName ?? f.uid),
                subtitle: Text(f.email ?? ''),
                onChanged: (v) {
                  setState(() {
                    v == true ? selected.add(f.uid) : selected.remove(f.uid);
                  });
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
