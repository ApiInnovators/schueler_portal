import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/api/response_models/api/chat.dart';
import 'package:schueler_portal/api/response_models/api/chat/id.dart';
import 'package:schueler_portal/api/response_models/api/kontaktanfrage.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/globals.dart';
import 'package:schueler_portal/pages/chats/chat_room.dart';
import 'package:schueler_portal/tools.dart';

class KontaktanfrageWidget extends StatelessWidget {
  const KontaktanfrageWidget({super.key});

  Future<void> confirmRequestPressed(int targetId) async {
    final resp = await ApiClient.postAndParse(
      "/chat-request?target_id=$targetId",
      (p0) => chatDetailsFromJson(p0),
    );

    if (resp.statusCode != 201) {
      Tools.quickSnackbar(
        "Kontaktanfrage konnte nicht gesendet werden (${resp.statusCode})",
      );
      return;
    }

    final chatDetails = resp.data!;
    final latestMsg = chatDetails.messages.lastOrNull;

    final chat = Chat(
      id: chatDetails.id,
      name: chatDetails.name,
      broadcast: chatDetails.broadcast,
      createdAt: chatDetails.createdAt,
      owner: chatDetails.owner,
      members: chatDetails.members,
      unreadMessagesCount: 0,
      latestMessage: latestMsg == null
          ? null
          : LatestMessage(
              timestamp: latestMsg.createdAt,
              text: latestMsg.text,
              file: latestMsg.file?.name,
            ),
      pinned: false,
    );

    DataLoader.cache.chats.data?.add(chat);

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatRoom(chat: chat, markAsRead: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kontaktanfrage"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              "Neue Kontaktanfrage stellen",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TypeAheadField<KontaktanfrageLehrer>(
                textFieldConfiguration: const TextFieldConfiguration(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Wer soll kontaktiert werden?",
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  if (DataLoader.cache.chatRequestTargets.data == null) {
                    return (await DataLoader.getChatRequestTargets()).data ??
                        const Iterable.empty();
                  }

                  return DataLoader.cache.chatRequestTargets.data!.where((e) =>
                      e.name.toLowerCase().contains(pattern.toLowerCase()));
                },
                itemBuilder: (context, itemData) =>
                    ListTile(title: Text(itemData.name)),
                onSuggestionSelected: (suggestion) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Kontaktanfrage"),
                        content: Text(
                          "Kontaktanfrage an ${suggestion.name} schicken?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              confirmRequestPressed(suggestion.userId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Ja'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Nein'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
