// To parse this JSON data, do
//
//     final chatDetails = chatDetailsFromJson(jsonString);

import 'dart:convert';

import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';

import '../chat.dart';

ChatDetails chatDetailsFromJson(String str) =>
    ChatDetails.fromJson(json.decode(str));

String chatDetailsToJson(ChatDetails data) => json.encode(data.toJson());

class ChatDetails {
  final int id;
  final String name;
  final bool? broadcast;
  final int createdAt;
  final Owner owner;
  final List<Member> members;
  final List<Message> messages;

  ChatDetails({
    required this.id,
    required this.name,
    required this.broadcast,
    required this.createdAt,
    required this.owner,
    required this.members,
    required this.messages,
  });

  factory ChatDetails.fromJson(Map<String, dynamic> json) => ChatDetails(
        id: json["id"],
        name: json["name"],
        broadcast: json["broadcast"],
        createdAt: json["createdAt"],
        owner: Owner.fromJson(json["owner"]),
        members:
            List<Member>.from(json["members"].map((x) => Member.fromJson(x))),
        messages: List<Message>.from(
            json["messages"].map((x) => Message.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "broadcast": broadcast,
        "createdAt": createdAt,
        "owner": owner.toJson(),
        "members": List<dynamic>.from(members.map((x) => x.toJson())),
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
      };
}

class Message {
  final int id;
  final String? text;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isDeletable;
  final bool read;
  final Owner editor;
  final FileElement? file;

  Message({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isDeleted,
    required this.isDeletable,
    required this.read,
    required this.editor,
    required this.file,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json["id"],
        text: json["text"],
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json["createdAt"] * 1000),
        isDeleted: json["isDeleted"],
        isDeletable: json["isDeletable"],
        read: json["read"],
        editor: Owner.fromJson(json["editor"]),
        file: json["file"] == null ? null : FileElement.fromJson(json["file"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "text": text,
        "createdAt": createdAt.millisecondsSinceEpoch ~/ 1000,
        "isDeleted": isDeleted,
        "isDeletable": isDeletable,
        "read": read,
        "editor": editor.toJson(),
        "file": file?.toJson(),
      };
}
