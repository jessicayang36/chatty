import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatty/features/threads/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatty/features/threads/chat/message_bubble.dart';
import 'package:chatty/features/threads/chat/message.dart';
import 'package:chatty/features/threads/thread_page.dart';

class ChatPage extends StatefulWidget{
  final String threadId;
  final String? otherDisplayName;
  const ChatPage({super.key, required this.threadId, this.otherDisplayName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(ChatService chatService) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await chatService.sendMessage(
      threadId: widget.threadId,
      text: text,
    );

    _messageController.clear();
  }
    
  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();
    final navigator = Navigator.of(context);

    return Scaffold(
      appBar: AppBar(
        title: widget.otherDisplayName != null ? 
          TextButton(
            onPressed: () {
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => ThreadPage(threadId: widget.threadId, otherDisplayName: widget.otherDisplayName,),
                ),
              );
            }, 
            child: Text(widget.otherDisplayName!)
          ) : 
          Text(widget.threadId),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          }, 
          icon: Icon(Icons.arrow_back)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: chatService.streamMessages(widget.threadId, limit: 50),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) return const Center(child: Text('No messages yet'));

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final myUid = FirebaseAuth.instance.currentUser?.uid;
                      final isMe = msg.senderId == myUid;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: MessageBubble(
                          text: msg.text,
                          isMe: isMe,
                          time: msg.createdAt,
                          senderName: msg.senderName ?? (isMe ? '' : msg.senderId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),


            // Input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(chatService),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(chatService);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

