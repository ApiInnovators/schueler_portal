import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/api/response_models/api/chat/id.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/user.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/custom_widgets/file_download_button.dart';
import 'package:schueler_portal/custom_widgets/my_future_builder.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/tools.dart';
import 'package:string_to_color/string_to_color.dart';

import '../../api/response_models/api/chat.dart';

class ChatRoom extends StatefulWidget {
  final Chat chat;
  final void Function() markAsRead;

  const ChatRoom({super.key, required this.chat, required this.markAsRead});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  ChatDetails? chatDetails;

  void showMitglieder() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Mitglieder"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Row(children: [
                  const Icon(Icons.person_2),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      chatDetails!.owner.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ]),
                for (Member mitglied in chatDetails!.members.sorted((a, b) {
                  if (a.type == ChatMemberType.APP_MODELS_USER_GROUP &&
                      b.type == ChatMemberType.APP_MODELS_USER) {
                    return 1;
                  }
                  return -1;
                })) ...[
                  if (mitglied.type ==
                      ChatMemberType.APP_MODELS_USER_GROUP) ...[
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.groups),
                            const SizedBox(width: 10),
                            Flexible(child: Text(mitglied.name)),
                          ],
                        ),
                        Text(
                          mitglied.info!,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 10),
                        Flexible(child: Text(mitglied.name)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text('Schließen'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
        centerTitle: true,
        actions: [
          if (chatDetails != null)
            IconButton.filledTonal(
              onPressed: showMitglieder,
              icon: const Icon(Icons.groups),
            ),
        ],
      ),
      body: CachingFutureBuilder<User>(
        future: DataLoader.getUser(),
        cacheGetter: DataLoader.cache.user.getCached,
        builder: (context, userData) {
          if (chatDetails == null) {
            return ApiFutureBuilder(
              future: ApiClient.getAndParse(
                  "chat/${widget.chat.id}", chatDetailsFromJson),
              additionalFutures: [
                if (widget.chat.unreadMessagesCount > 0)
                  ApiClient.postAndParse(
                      "chat/${widget.chat.id}/read", (p0) => ()).then((resp) {
                    if (resp.statusCode != 204) return;
                    if (DataLoader.cache.chats.data != null) {
                      DataLoader.cache.chats.data!
                          .firstWhere((e) => e.id == widget.chat.id)
                          .unreadMessagesCount = 0;
                      // No need to set the read variable in the messages
                    }
                    widget.markAsRead();
                  }),
              ],
              builder: (p0, p1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => chatDetails = p1);
                });
                return const SizedBox.shrink();
              },
            );
          }

          Map<DateTime, List<Message>> groupedMessagesByDate = groupBy(
            chatDetails!.messages,
            (obj) => DateTime.fromMillisecondsSinceEpoch(obj.createdAt * 1000)
                .dayOnly(),
          );

          return Stack(
            children: [
              SingleChildScrollView(
                reverse: true,
                child: Column(
                  children: [
                    Center(
                      child: Text(
                          "Erstellt am ${DateFormat("dd.MM.yyyy").format(DateTime.fromMillisecondsSinceEpoch(widget.chat.createdAt * 1000))}"),
                    ),
                    for (MapEntry<DateTime, List<Message>> entry
                        in groupedMessagesByDate.entries) ...[
                      ChatDaySection(
                        dateTime: entry.key,
                        messages: entry.value,
                        chatRoom: widget,
                        userId: userData.id,
                      ),
                    ],
                    const SizedBox(height: 70),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Card(
                  margin:
                      const EdgeInsets.only(left: 10, right: 10, bottom: 10),
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
  final int userId;

  const ChatDaySection({
    super.key,
    required this.dateTime,
    required this.messages,
    required this.chatRoom,
    required this.userId,
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
          ),
        ),
        Column(
          children: List.generate(
            messages.length,
            (i) => ChatRoomMessageWidget(
              message: messages[i],
              chatRoom: chatRoom,
              isCurrentUser: messages[i].editor.id == userId,
            ),
          ),
        )
      ],
    );
  }
}

class ChatRoomMessageWidget extends StatelessWidget {
  final Message message;
  final ChatRoom chatRoom;
  final bool isCurrentUser;

  const ChatRoomMessageWidget({
    super.key,
    required this.message,
    required this.chatRoom,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrentUser) return UserMessage(message: message, chatRoom: chatRoom);

    return MemberMessage(message: message, chatRoom: chatRoom);
  }
}

class MemberMessage extends ChatRoomMessageWidget {
  const MemberMessage({
    super.key,
    required super.message,
    required super.chatRoom,
  }) : super(isCurrentUser: false);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // asymmetric padding
      padding: const EdgeInsets.fromLTRB(16.0, 4, 64.0, 4),
      child: Align(
        // align the child within the container
        alignment: Alignment.centerLeft,
        child: Badge(
          backgroundColor: Theme.of(context).colorScheme.primary,
          isLabelVisible: !message.read,
          label: Text(
            "Neu",
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          offset: const Offset(-9, -4),
          child: DecoratedBox(
            // chat bubble decoration
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
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
                    ],
                  ),
                  if (message.isDeleted)
                    Text(
                      "Nachricht wurde gelöscht",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondary
                            .withOpacity(0.6),
                      ),
                    ),
                  if (message.text != null)
                    Text(
                      message.text!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  if (message.file != null) ...[
                    MessageFileAttachment(file: message.file!),
                  ],
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat("HH:mm").format(
                        DateTime.fromMillisecondsSinceEpoch(
                            message.createdAt * 1000),
                      ),
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondary
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
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
  }) : super(isCurrentUser: true);

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
            color: Theme.of(context).colorScheme.primary,
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
                  Text(
                    "Du hast diese nachricht gelöscht",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.6),
                    ),
                  ),
                if (message.text != null)
                  Text(
                    message.text!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                if (message.file != null) ...[
                  MessageFileAttachment(file: message.file!),
                ],
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    DateFormat("HH:mm").format(
                      DateTime.fromMillisecondsSinceEpoch(
                          message.createdAt * 1000),
                    ),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.5),
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
                "${file.name} (${(snapshot!.lengthSync() / 1048576.0).toStringAsFixed(2)}MB)",
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            IconButton(
              onPressed: () {
                OpenFile.open(snapshot.path);
              },
              style: IconButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
                padding: EdgeInsets.zero,
              ),
              icon: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(snapshot),
              ),
            ),
          ],
        ),
      );
    }

    return FileDownloadButton(file: file);
  }
}
