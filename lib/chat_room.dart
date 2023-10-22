import 'package:mime/mime.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:schueler_portal/api/response_models/api/chat/id.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api_client.dart';
import 'package:schueler_portal/my_future_builder.dart';
import 'package:schueler_portal/user_login.dart';
import 'package:string_to_color/string_to_color.dart';

import 'api/response_models/api/chat.dart';

class ChatRoom extends StatelessWidget {
  final Chat chat;

  const ChatRoom({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chat.name), centerTitle: true),
      body: MyFutureBuilder(
        future: ApiClient.putAndParse("chat--${chat.id}", chatDetailsFromJson),
        customBuilder: (context, snapshot) {
          ChatDetails chatDetails = snapshot.data!.data!;

          Map<DateTime, List<Message>> groupedMessagesByDate = groupBy(
              chatDetails.messages,
              (obj) => DateUtils.dateOnly(
                  DateTime.fromMillisecondsSinceEpoch(obj.createdAt * 1000)));

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    children: [
                      Text(
                          "Erstellt am ${DateFormat("dd.MM.yyyy").format(DateTime.fromMillisecondsSinceEpoch(chat.createdAt * 1000))}"),
                      for (MapEntry<DateTime, List<Message>> entry
                          in groupedMessagesByDate.entries) ...[
                        ChatDaySection(
                          dateTime: entry.key,
                          messages: entry.value,
                          chatRoom: this,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.attachment),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Nachricht eingeben",
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {},
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatDaySection extends StatelessWidget {
  final DateTime dateTime;
  final List<Message> messages;
  final ChatRoom chatRoom;

  const ChatDaySection({
    super.key,
    required this.dateTime,
    required this.messages,
    required this.chatRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            DateFormat("dd.MM.yyyy").format(dateTime),
            style: TextStyle(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        Column(
          children: List.generate(
            messages.length,
            (i) =>
                ChatRoomMessageWidget(message: messages[i], chatRoom: chatRoom),
          ),
        )
      ],
    );
  }
}

class ChatRoomMessageWidget extends StatelessWidget {
  final Message message;
  final ChatRoom chatRoom;

  const ChatRoomMessageWidget({
    super.key,
    required this.message,
    required this.chatRoom,
  });

  @override
  Widget build(BuildContext context) {
    bool isCurrentUser = message.editor.id == UserLogin.user.id;

    return isCurrentUser
        ? UserMessage(
            message: message,
            chatRoom: chatRoom,
          )
        : MemberMessage(
            message: message,
            chatRoom: chatRoom,
          );
  }
}

class MemberMessage extends ChatRoomMessageWidget {
  const MemberMessage({
    super.key,
    required super.message,
    required super.chatRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // asymmetric padding
      padding: const EdgeInsets.fromLTRB(16.0, 4, 64.0, 4),
      child: Align(
        // align the child within the container
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          // chat bubble decoration
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      message.editor.name,
                      style: TextStyle(
                        color: ColorUtils.stringToColor(message.editor.name),
                      ),
                    ),
                    if (!message.read)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child:
                              const Text("Neu", style: TextStyle(fontSize: 10)),
                        ),
                      )
                  ],
                ),
                if (message.isDeleted)
                  const Text(
                    "Nachricht wurde gelöscht",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                if (message.text != null) Text(message.text!),
                if (message.file != null) ...[
                  MessageFileAttachment(file: message.file!),
                ],
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                      DateFormat("HH:mm").format(
                          DateTime.fromMillisecondsSinceEpoch(
                              message.createdAt * 1000)),
                      style: TextStyle(color: Colors.black.withOpacity(0.5))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserMessage extends ChatRoomMessageWidget {
  const UserMessage({
    super.key,
    required super.message,
    required super.chatRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // asymmetric padding
      padding: const EdgeInsets.fromLTRB(64.0, 4, 16.0, 4),
      child: Align(
        // align the child within the container
        alignment: Alignment.centerRight,
        child: DecoratedBox(
          // chat bubble decoration
          decoration: BoxDecoration(
            color: Colors.blue[200],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (message.isDeleted)
                  const Text(
                    "Du hast diese nachricht gelöscht",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                if (message.text != null) Text(message.text!),
                if (message.file != null) ...[
                  MessageFileAttachment(file: message.file!),
                ],
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    DateFormat("HH:mm").format(
                        DateTime.fromMillisecondsSinceEpoch(
                            message.createdAt * 1000)),
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MessageFileAttachment extends StatelessWidget {
  final FileElement file;

  const MessageFileAttachment({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final String? mimeType = lookupMimeType(file.name);

    if (mimeType != null && mimeType.startsWith("image/")) {
      return MyFutureBuilder(
        future: ApiClient.downloadFile(file, showToast: false),
        customBuilder: (context, snapshot) => Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    "${file.name} (${(snapshot.data!.lengthSync() / 1048576.0).toStringAsFixed(2)}MB)",
                    style: const TextStyle(fontSize: 10))),
            IconButton(
              onPressed: () {
                OpenFile.open(snapshot.data!.path);
              },
              style: IconButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
                padding: EdgeInsets.zero,
              ),
              icon: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(snapshot.data!),
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        OpenFile.open((await ApiClient.downloadFile(file))!.path);
      },
      icon: const Icon(Icons.file_download),
      label: Text(file.name),
      style: ElevatedButton.styleFrom(foregroundColor: Colors.black),
    );
  }
}
