import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';

import '../../api/response_models/api/chat.dart';
import 'chat_room.dart';
import '../../data_loader.dart';

class ChatsWidget extends StatefulWidget {
  const ChatsWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ChatsWidget();
}

class _ChatsWidget extends State<ChatsWidget> {
  List<Chat>? filteredChats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Chats"),
      ),
      body: RefreshableCachingFutureBuilder(
        future: DataLoader.getChats(),
        cacheGetter: () => DataLoader.cache.chats,
        onRefresh: () {
          DataLoader.cache.chats = null;
          DataLoader.cacheData();
          return DataLoader.getChats();
        },
        builder: (context, snapshot) {
          filteredChats ??= snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SearchAnchor(
                      builder:
                          (BuildContext context, SearchController controller) {
                        return SearchBar(
                          hintText: "Chat suchen...",
                          controller: controller,
                          onChanged: (value) {
                            setState(() {
                              filteredChats = snapshot.data!
                                  .where((element) => element.name
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        );
                      },
                      suggestionsBuilder:
                          (BuildContext context, SearchController controller) =>
                              []),
                ),
                if (filteredChats!.isEmpty) ...[
                  const Text("Keine Treffer"),
                ] else ...[
                  ChatsListWidget(data: filteredChats!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class ChatsListWidget extends StatelessWidget {
  final List<Chat> data;

  const ChatsListWidget({
    super.key,
    required this.data,
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
      children: [
        for (int i = 0; i < data.length; ++i) ...[
          SingleChatWidget(chat: data[i]),
          const SizedBox(height: 5),
        ],
      ],
    );
  }
}

class SingleChatWidget extends StatelessWidget {
  final Chat chat;

  const SingleChatWidget({super.key, required this.chat});

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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoom(chat: chat),
            ),
          );
        },
        child: Column(
          children: [
            Row(
              children: [
                Badge(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  label: Text(
                    chat.unreadMessagesCount.toString(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  isLabelVisible: chat.unreadMessagesCount > 0,
                  child: Icon(chat.members.length > 1 ||
                          chat.members.any((element) =>
                              element.type ==
                              ChatMemberType.APP_MODELS_USER_GROUP)
                      ? Icons.groups
                      : Icons.chat),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    chat.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                      chat.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    if (chat.latestMessage != null) ...[
                      Expanded(
                        child: Column(
                          children: [
                            if (chat.latestMessage!.text != null) ...[
                              Flexible(
                                child: Container(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    chat.latestMessage!.text!,
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                              ),
                            ] else ...[
                              const Text(
                                "Nachricht gelöscht",
                                style: TextStyle(fontStyle: FontStyle.italic),
                              )
                            ],
                            Container(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                timeDifferenceAsString(
                                    chat.latestMessage!.timestamp),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        "Noch keine Nachrichten",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
