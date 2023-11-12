import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/custom_widgets/md_text.dart';
import 'package:schueler_portal/pages/chats/kontaktanfrage.dart';

import '../../api/response_models/api/chat.dart';
import '../../custom_widgets/aligned_text.dart';
import '../../data_loader.dart';
import 'chat_room.dart';

class ChatsWidget extends StatefulWidget {
  const ChatsWidget({super.key});

  @override
  State<ChatsWidget> createState() => _ChatsWidgetState();
}

class _ChatsWidgetState extends State<ChatsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Chats"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const KontaktanfrageWidget(),
                ),
              ),
              icon: const SizedBox(
                width: 100,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      Text("Kontaktanfrage"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshableCachingFutureBuilder<List<Chat>>(
        dataLoaderFuture: DataLoader.getChats,
        cache: DataLoader.cache.chats,
        builder: (context, snapshot) =>
            ChatsListWidget(data: snapshot, rebuild: () => setState(() {})),
      ),
    );
  }
}

class ChatsListWidget extends StatelessWidget {
  final List<Chat> data;
  final void Function() rebuild;

  const ChatsListWidget({
    super.key,
    required this.data,
    required this.rebuild,
  });

  @override
  Widget build(BuildContext context) {
    data.sort((a, b) {
      if (a.pinned && !b.pinned) {
        return -1; // a comes before b
      } else if (!a.pinned && b.pinned) {
        return 1; // b comes before a
      }

      if (a.unreadMessagesCount > 0 && b.unreadMessagesCount == 0) {
        return -1; // a comes before b
      } else if (a.unreadMessagesCount == 0 && b.unreadMessagesCount > 0) {
        return 1; // b comes before a
      }

      final aTimestamp = a.latestMessage?.timestamp;
      final bTimestamp = b.latestMessage?.timestamp;

      if (aTimestamp == null && bTimestamp != null) {
        return 1; // a comes after b
      } else if (aTimestamp != null && bTimestamp == null) {
        return -1; // b comes after a
      }

      return (bTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(aTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0));
    });

    return Column(
      children:
          data.map((e) => SingleChatWidget(chat: e, rebuild: rebuild)).toList(),
    );
  }
}

class SingleChatWidget extends StatefulWidget {
  final Chat chat;
  final void Function() rebuild;

  const SingleChatWidget(
      {super.key, required this.chat, required this.rebuild});

  static String timeDifferenceAsString(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 1) {
      return 'Gestern';
    } else if (difference.inDays > 1) {
      return 'vor ${difference.inDays} Tagen';
    } else if (difference.inHours > 0) {
      return DateFormat.jm()
          .format(dateTime); // Format time if it's more than an hour ago
    } else {
      return 'vor ${difference.inMinutes} minuten'; // Less than an hour ago
    }
  }

  @override
  State<SingleChatWidget> createState() => _SingleChatWidgetState();
}

class _SingleChatWidgetState extends State<SingleChatWidget> {
  late bool isPinned;
  bool isLoading = false;

  Future<void> pinPressed() async {
    setState(() => isLoading = true);

    final resp = await ApiClient.postAndParse<Map<String, dynamic>>(
        "/chat/${widget.chat.id}/toggle-pin", (p0) => jsonDecode(p0));

    if (resp.statusCode != 200) {
      setState(() => isLoading = false);
      return;
    }

    isPinned = resp.data!["pinned"] == true;

    DataLoader.cache.chats.data
        ?.firstWhere((e) => e.id == widget.chat.id)
        .pinned = isPinned;

    isLoading = false;

    widget.rebuild();
  }

  @override
  Widget build(BuildContext context) {
    isPinned = widget.chat.pinned;
    return SizedBox(
      height: 120,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoom(
                chat: widget.chat,
                markAsRead: widget.rebuild,
              ),
            ),
          );
        },
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 2),
            child: Column(
              children: [
                Row(
                  children: [
                    Badge(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      label: Text(
                        widget.chat.unreadMessagesCount.toString(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary),
                      ),
                      isLabelVisible: widget.chat.unreadMessagesCount > 0,
                      child: Icon(widget.chat.members.length > 1 ||
                              widget.chat.members.any((element) =>
                                  element.type ==
                                  ChatMemberType.APP_MODELS_USER_GROUP)
                          ? Icons.groups
                          : Icons.chat),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        widget.chat.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: isLoading ? null : pinPressed,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator())
                          : Icon(
                              isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                            ),
                    ),
                  ],
                ),
                Expanded(
                    child: (() {
                  if (widget.chat.latestMessage == null) {
                    return const Text(
                      "Noch keine Nachrichten",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    );
                  }

                  if (widget.chat.latestMessage!.text != null) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: MarkdownText(
                        widget.chat.latestMessage!.text!,
                        overflow: TextOverflow.fade,
                        defaultStyle: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  }

                  if (widget.chat.latestMessage!.file != null) {
                    return Row(
                      children: [
                        const Icon(Icons.attach_file),
                        Flexible(
                          child: AlignedText(
                            text: Text(
                              widget.chat.latestMessage!.file!,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return const AlignedText(
                    text: Text(
                      "Nachricht gelöscht",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  );
                }())),
                if (widget.chat.latestMessage != null)
                  AlignedText(
                    text: Text(
                      SingleChatWidget.timeDifferenceAsString(
                          widget.chat.latestMessage!.timestamp),
                      style: const TextStyle(fontSize: 10),
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
