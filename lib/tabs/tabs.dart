import 'package:chatty/features/contacts/contacts_page.dart';
import 'package:flutter/material.dart';
import '../features/profile/profile_page.dart';
import 'package:chatty/features/threads/thread_list_page.dart';

class Tabs extends StatelessWidget{ 
  const Tabs({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold( 
          bottomNavigationBar: const TabBar(tabs: [
            Tab(icon: Icon(Icons.people)),
            Tab(icon: Icon(Icons.chat_bubble)),
            Tab(icon: Icon(Icons.person)),
          ]),
          body: const TabBarView(children: [
            ContactsPage(title: 'chatty'),
            ThreadListPage(),
            ProfilePage(),
          ]),
        ),
      ),
    );
  }
}