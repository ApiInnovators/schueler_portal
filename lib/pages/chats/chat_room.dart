import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/api/response_models/api/chat/id.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/user.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/custom_widgets/file_download_button.dart';
import 'package:schueler_portal/custom_widgets/md_text.dart';
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
  final messageTextController = TextEditingController();
  File? filePickerResult;
  bool _isSending = false;

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

  void sendPressed() async {
    String? text = messageTextController.text.trim().isEmpty
        ? null
        : messageTextController.text;

    if (text == null && filePickerResult == null) {
      Tools.quickSnackbar(
        "Nachricht ist leer",
        icon: const Icon(Icons.error_outline),
      );
      return;
    }

    setState(() => _isSending = true);
    final sendResp = await sendMessage(text, filePickerResult);
    setState(() => _isSending = false);

    if (sendResp.statusCode != 200) {
      Tools.quickSnackbar("Senden fehlgeschlagen (${sendResp.statusCode})");
      return;
    }

    final msg = sendResp.data!;

    addMessage(msg);

    setState(() => filePickerResult = null);

    DataLoader.cache.chats.data
        ?.firstWhere((e) => e.id == widget.chat.id)
        .latestMessage = LatestMessage(
      timestamp: DateTime.fromMillisecondsSinceEpoch(msg.createdAt * 1000),
      text: msg.text,
      file: msg.file?.name,
    );

    widget.markAsRead();
  }

  Future<ApiResponse<Message>> sendMessage(String? text, File? file) async {
    final request = MultipartRequest(
      "POST",
      Uri.parse("${ApiClient.baseUrl}/chat/${chatDetails!.id}/message"),
    );

    if (text != null) {
      request.fields["text"] = text;
    }

    if (file != null) {
      request.files.add(
        await MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );
    }

    return ApiClient.sendAndParse<Message>(
      request,
      (p0) => Message.fromJson(jsonDecode(p0)),
    );
  }

  void addMessage(Message msg) {
    setState(() => chatDetails?.messages.add(msg));
  }

  Widget contextMenu(
      BuildContext context, EditableTextState editableTextState) {
    final List<ContextMenuButtonItem> buttonItems =
        editableTextState.contextMenuButtonItems;
    final TextEditingValue value = editableTextState.textEditingValue;

    if (value.selection.start == value.selection.end) {
      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: editableTextState.contextMenuAnchors,
        buttonItems: buttonItems,
      );
    }

    const Map<String, String> map = {
      "Unterstrichen": "__",
      "Kursiv": "//",
      "Fett": "**"
    };

    String text = messageTextController.text;
    for (var e in map.entries) {
      buttonItems.insert(
        0,
        ContextMenuButtonItem(
          label: e.key,
          onPressed: () {
            ContextMenuController.removeAny();
            messageTextController.text =
                text.substring(0, value.selection.start) +
                    e.value +
                    text.substring(value.selection.start, value.selection.end) +
                    e.value +
                    text.substring(value.selection.end, text.length);
          },
        ),
      );
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
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
                    DataLoader.cache.chats.data
                        ?.firstWhere((e) => e.id == widget.chat.id)
                        .unreadMessagesCount = 0;
                    // No need to set the read variable in the messages
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
                    SizedBox(height: filePickerResult == null ? 70 : 90),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Card(
                  margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (filePickerResult != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.file_present),
                            Flexible(
                              child: Text(
                                filePickerResult!.uri.pathSegments.last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                      ],
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              if (filePickerResult != null) {
                                setState(() => filePickerResult = null);
                                return;
                              }

                              final picked =
                                  await FilePicker.platform.pickFiles();
                              setState(() {
                                if (picked == null) {
                                  filePickerResult = null;
                                } else {
                                  filePickerResult =
                                      File(picked.files.single.path!);
                                }
                              });
                            },
                            icon: filePickerResult == null
                                ? const Icon(Icons.attach_file)
                                : const Icon(Icons.highlight_remove_outlined),
                          ),
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 100),
                              child: TextFormField(
                                controller: messageTextController,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Nachricht eingeben",
                                ),
                                contextMenuBuilder: contextMenu,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: _isSending
                                ? const SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(),
                                  )
                                : const Icon(Icons.send),
                            onPressed: _isSending ? null : sendPressed,
                          )
                        ],
                      ),
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
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            DateFormat("dd.MM.yyyy").format(dateTime),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
          ),
        ),
        for (int i = 0; i < messages.length; ++i)
          ChatRoomMessageWidget(
            message: messages[i],
            chatRoom: chatRoom,
            isCurrentUser: messages[i].editor.id == userId,
            previousMessageHasSameOwner: i < 1
                ? false
                : messages[i].editor.id == messages[i - 1].editor.id,
          ),
      ],
    );
  }
}

class ChatRoomMessageWidget extends StatelessWidget {
  final Message message;
  final ChatRoom chatRoom;
  final bool isCurrentUser;
  final bool previousMessageHasSameOwner;

  const ChatRoomMessageWidget({
    super.key,
    required this.message,
    required this.chatRoom,
    required this.isCurrentUser,
    required this.previousMessageHasSameOwner,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrentUser) {
      return UserMessage(
        message: message,
        chatRoom: chatRoom,
        previousMessageHasSameOwner: previousMessageHasSameOwner,
      );
    }

    return MemberMessage(
      message: message,
      chatRoom: chatRoom,
      previousMessageHasSameOwner: previousMessageHasSameOwner,
    );
  }
}

class MemberMessage extends ChatRoomMessageWidget {
  const MemberMessage({
    super.key,
    required super.message,
    required super.chatRoom,
    required super.previousMessageHasSameOwner,
  }) : super(isCurrentUser: false);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: 8,
          right: 50,
          bottom: 0,
          top: previousMessageHasSameOwner ? 2 : 10,
        ),
        child: Badge(
          backgroundColor: Theme.of(context).colorScheme.primary,
          isLabelVisible: !message.read,
          label: Text(
            "Neu",
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          offset: const Offset(-9, -4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(10),
                bottomRight: const Radius.circular(10),
                topRight: const Radius.circular(10),
                topLeft: Radius.circular(previousMessageHasSameOwner ? 10 : 0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 10, top: 10, bottom: 5),
              child: Column(
                children: [
                  if (!previousMessageHasSameOwner)
                    Text(
                      message.editor.name,
                      style: TextStyle(
                        color: ColorUtils.stringToColor(message.editor.name),
                      ),
                    ),
                  if (message.isDeleted)
                    Text(
                      "Nachricht wurde gelöscht",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer
                            .withOpacity(0.6),
                      ),
                    ),
                  if (message.text != null)
                    MarkdownText(
                      message.text!,
                      defaultStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer),
                    ),
                  if (message.file != null) ...[
                    MessageFileAttachment(file: message.file!),
                  ],
                  Text(
                    DateFormat("HH:mm").format(
                      DateTime.fromMillisecondsSinceEpoch(
                        message.createdAt * 1000,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer
                          .withOpacity(0.5),
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
    required super.previousMessageHasSameOwner,
  }) : super(isCurrentUser: true);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(
          right: 8,
          left: 50,
          top: previousMessageHasSameOwner ? 2 : 10,
          bottom: 0,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.only(
              bottomLeft: const Radius.circular(10),
              bottomRight: const Radius.circular(10),
              topLeft: const Radius.circular(10),
              topRight: Radius.circular(previousMessageHasSameOwner ? 10 : 0),
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isDeleted) ...[
                  Text(
                    "Du hast diese nachricht gelöscht",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withOpacity(0.6),
                    ),
                  ),
                ] else ...[
                  if (message.text != null)
                    MarkdownText(
                      message.text!,
                      defaultStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  if (message.file != null)
                    MessageFileAttachment(file: message.file!),
                ],
                Text(
                  DateFormat("HH:mm").format(
                    DateTime.fromMillisecondsSinceEpoch(
                        message.createdAt * 1000),
                  ),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withOpacity(0.5),
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
        customBuilder: (context, snapshot) {
          if (snapshot == null) {
            return const Text("Fehler beim Laden der Datei");
          }

          return Column(
            children: [
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 280,
                      maxHeight: 280,
                    ),
                    child: Image.file(snapshot),
                  ),
                ),
              ),
              Text(
                "${file.name} (${(snapshot.lengthSync() / 1048576.0).toStringAsFixed(2)}MB)",
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ],
          );
        },
      );
    }

    return FileDownloadButton(file: file);
  }
}
