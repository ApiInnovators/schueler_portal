
import 'package:flutter/material.dart';

import 'api/response_models/api/chat.dart';


class ChatRoom extends StatefulWidget {
  final Chat chat;

  const ChatRoom({super.key, required this.chat});

  @override
  State<StatefulWidget> createState() => _ChatRoom();
}

class _ChatRoom extends State<ChatRoom> {
  @override
  Widget build(BuildContext context) {
    return const Text("Nothing here yet");
  }
}
