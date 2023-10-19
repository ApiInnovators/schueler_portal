import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/failed_request.dart';

import 'api/response_models/api/chat.dart';
import 'chat_room.dart';
import 'data_loader.dart';

class ChatsWidget extends StatefulWidget {
  const ChatsWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ChatsWidget();
}

class _ChatsWidget extends State<StatefulWidget> {
  String searchText = "";

  Widget buildChats(List<Chat> data) {
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

    List<Chat> searchResult = data;

    if (searchText.isNotEmpty) {
      searchResult = searchResult
          .where((element) =>
              element.name.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: SearchAnchor(
            builder: (BuildContext context, SearchController controller) {
              return SearchBar(
                  hintText: "Chat suchen...",
                  controller: controller,
                  onChanged: (value) => setState(() {
                        searchText = value;
                      }));
            },
            suggestionsBuilder:
                (BuildContext context, SearchController controller) => [],
          ),
        ),
        searchResult.isEmpty
            ? const Text(
                "Keine Treffer",
                textAlign: TextAlign.center,
              )
            : Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(searchResult.length,
                        (i) => SingleChatWidget(chat: searchResult[i])),
                  ),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Chats"),
      ),
      body: FutureBuilder(
        future: DataLoader.getChats(),
        initialData: DataLoader.cache.chats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              if (snapshot.data!.statusCode == 200) {
                return buildChats(snapshot.data!.data!);
              } else {
                return FailedRequestWidget(apiResponse: snapshot.data!);
              }
            } else {
              return const Text("Error: Data not available");
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class SingleChatWidget extends StatefulWidget {
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
  State<StatefulWidget> createState() => _SingleChatsWidget();
}

class _SingleChatsWidget extends State<SingleChatWidget> {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: SizedBox(
          height: 100,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoom(chat: widget.chat),
                ),
              );
            },
            child: Column(
              children: [
                Row(
                  children: [
                    Badge(
                      label: Text(widget.chat.unreadMessagesCount.toString()),
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
                      onPressed: () {},
                      icon: Icon(widget.chat.pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        if (widget.chat.latestMessage != null) ...[
                          Expanded(
                            child: Column(
                              children: [
                                if (widget.chat.latestMessage!.text !=
                                    null) ...[
                                  Flexible(
                                    child: Container(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        widget.chat.latestMessage!.text!,
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const Text(
                                    "Nachricht gelöscht",
                                    style:
                                        TextStyle(fontStyle: FontStyle.italic),
                                  )
                                ],
                                Container(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    SingleChatWidget.timeDifferenceAsString(
                                        widget.chat.latestMessage!.timestamp),
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
        ),
      );
}
