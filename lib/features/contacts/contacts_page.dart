import 'package:chatty/features/contacts/add_friend_page.dart';
import 'package:flutter/material.dart';
import 'package:chatty/features/profile/user_service.dart';
import 'package:provider/provider.dart';
import 'package:chatty/features/profile/user_profile.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, required this.title});

  final String title;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    final userService = context.read<UserService>();

    final Set<String> accepting = {}; // friend UIDs currently being accepted, prevents double taps

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          // why have this widget?
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const AddFriendPage(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<UserProfile?>(
          stream: userService.currentUserProfileStream,
          // builder: connection between async stream data and ui. flutter calls this when stream emits new value. returns widget based on current data
          // context: standard build context
          // snapshot: contains current state of stream
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final userProfile = snapshot.data;

            if (userProfile == null) {
              return const Center(
                child: Text('Not logged in or profile not found.'),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Friend Requests:"),
                  StreamBuilder<List<UserProfile>>(
                    stream: userService.receivedFriendRequestsProfilesStream(),
                    builder: (context, friendRequestSnapshot) {
                      final friendRequests = friendRequestSnapshot.data ?? [];

                      if (friendRequestSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        // optional: show nothing while loading, or a small loader
                      }
                      if (friendRequests.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: friendRequests.length,
                        itemBuilder: (context, index) {
                          final friend = friendRequests[index];
                          final isAccepting = accepting.contains(friend.uid);
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              '${friend.firstName ?? ''} ${friend.lastName ?? ''}',
                            ),
                            subtitle: Text(friend.email ?? ''),
                            trailing: IconButton(
                              onPressed: isAccepting
                                ? null
                                : () async {
                                  setState(() => accepting.add(friend.uid));
                                  await userService.acceptFriendRequest(friend.uid);

                                  if (mounted) {
                                    setState(() => accepting.remove(friend.uid));
                                  }
                                },
                              icon: isAccepting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check),
                              color: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Text("Sent Friend Requests:"),
                  StreamBuilder<List<UserProfile>>(
                    stream: userService.sentFriendRequestsProfilesStream(),
                    builder: (context, sentFriendRequestSnapshot) {
                      final sentFriendRequests =
                          sentFriendRequestSnapshot.data ?? [];
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sentFriendRequests.length,
                        itemBuilder: (context, index) {
                          final friend = sentFriendRequests[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              '${friend.firstName ?? ''} ${friend.lastName ?? ''}',
                            ),
                            subtitle: Text(friend.email ?? ''),
                            // add a remove button?
                          );
                        },
                      );
                    },
                  ),

                  const Text("Friends"),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 500),
                    child: StreamBuilder<List<UserProfile>>(
                      stream: userService.friendsProfilesStream(),
                      builder: (context, friendsSnapshot) {
                        final friends = friendsSnapshot.data ?? [];
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(
                                '${friend.firstName ?? ''} ${friend.lastName ?? ''}',
                              ),
                              subtitle: Text(friend.email ?? ''),
                              onTap: () {
                                // go to chat page
                              },
                              trailing: IconButton(
                                onPressed: () {
                                  userService.deleteFriend(friend.uid);
                                }, 
                                icon: Icon(Icons.delete)
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
