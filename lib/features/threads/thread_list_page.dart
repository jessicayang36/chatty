import 'package:chatty/features/threads/thread.dart';
import 'package:flutter/material.dart';
import 'package:chatty/features/threads/thread_service.dart';
import 'package:provider/provider.dart';
import 'package:chatty/features/profile/user_service.dart';
import 'package:chatty/features/profile/user_profile.dart';
import 'package:chatty/features/threads/create_thread_page.dart';
import 'package:chatty/features/threads/chat/chat_page.dart';

class ThreadListPage extends StatelessWidget {
  const ThreadListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final threadService = context.read<ThreadService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Profile')),
      body: StreamBuilder<List<Thread>>(
        stream: threadService.threadsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final threads = snapshot.data ?? [];

          if (threads.isEmpty) {
            return const Center(child: Text('No Threads yet'));
          }

          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              final userService = context.read<UserService>();
              
              return FutureBuilder<List<UserProfile>>(
                future: userService.getFriendsDetails(thread.users),
                builder: (context, snapshot) {
                  final names = snapshot.hasData
                    ? snapshot.data!
                        .where((u) => u.uid != userService.currentUid())
                        .map((u) => u.firstName ?? u.uid)
                        .join(', ')
                    : 'Loading...';

                  // TODO: FIX THE ORDERBY in user_service and thread_service. index in firebase

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      thread.title ?? names
                    ),
                    subtitle: Text(thread.lastMessage != null
                      ? thread.lastMessage!['text'] ?? ''
                      : ''
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(threadId: thread.uid, otherDisplayName: names,),
                        ),
                      );
                    },
                  );
                }
              );
            }
          );

        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_comment),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateThreadPage(),
            ),
          );
        },
      ),
    );

    
  }
}

