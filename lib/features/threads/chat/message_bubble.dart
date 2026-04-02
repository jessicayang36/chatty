import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // for Timestamp type

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? time;
  final String? senderName;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.time,
    this.senderName,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat.jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? Theme.of(context).colorScheme.primary : Colors.grey[200];
    final color = isMe ? Colors.white : Colors.black87;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMe ? 12 : 0),
      bottomRight: Radius.circular(isMe ? 0 : 12),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        if (!isMe && senderName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              senderName!,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),

        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(color: color),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(time),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
