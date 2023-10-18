// To parse this JSON data, do
//
//     final chat = chatFromJson(jsonString);

import 'dart:convert';

import 'chat/id.dart';

List<Chat> chatFromJson(String str) => List<Chat>.from(json.decode(str).map((x) => Chat.fromJson(x)));

String chatToJson(List<Chat> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Chat {
  final int id;
  final String name;
  final bool broadcast;
  final int createdAt;
  final Owner owner;
  final List<Member> members;
  final int unreadMessagesCount;
  final LatestMessage? latestMessage;
  final bool pinned;

  Chat({
    required this.id,
    required this.name,
    required this.broadcast,
    required this.createdAt,
    required this.owner,
    required this.members,
    required this.unreadMessagesCount,
    required this.latestMessage,
    required this.pinned,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json["id"],
    name: json["name"],
    broadcast: json["broadcast"],
    createdAt: json["createdAt"],
    owner: Owner.fromJson(json["owner"]),
    members: List<Member>.from(json["members"].map((x) => Member.fromJson(x))),
    unreadMessagesCount: json["unreadMessagesCount"],
    latestMessage: json["latestMessage"] == null ? null : LatestMessage.fromJson(json["latestMessage"]),
    pinned: json["pinned"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "broadcast": broadcast,
    "createdAt": createdAt,
    "owner": owner.toJson(),
    "members": List<dynamic>.from(members.map((x) => x.toJson())),
    "unreadMessagesCount": unreadMessagesCount,
    "latestMessage": latestMessage?.toJson(),
    "pinned": pinned,
  };
}

class LatestMessage {
  final DateTime timestamp;
  final String? text;
  final String? file;

  LatestMessage({
    required this.timestamp,
    required this.text,
    required this.file,
  });

  factory LatestMessage.fromJson(Map<String, dynamic> json) => LatestMessage(
    timestamp: DateTime.fromMillisecondsSinceEpoch(json["timestamp"] * 1000),
    text: json["text"],
    file: json["file"],
  );

  Map<String, dynamic> toJson() => {
    "timestamp": (timestamp.millisecondsSinceEpoch / 1000) as int,
    "text": text,
    "file": file,
  };
}

class Member {
  final int id;
  final ChatMemberType type;
  final String name;
  final String? info;

  Member({
    required this.id,
    required this.type,
    required this.name,
    required this.info,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json["id"],
    type: typeValues.map[json["type"]]!,
    name: json["name"],
    info: json["info"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": typeValues.reverse[type],
    "name": name,
    "info": info,
  };
}

enum ChatMemberType {
  APP_MODELS_USER,
  APP_MODELS_USER_GROUP
}

final typeValues = EnumValues({
  "App\\Models\\User": ChatMemberType.APP_MODELS_USER,
  "App\\Models\\UserGroup": ChatMemberType.APP_MODELS_USER_GROUP
});

class Owner {
  final int id;
  final String name;
  final Role role;
  final dynamic info;

  Owner({
    required this.id,
    required this.name,
    required this.role,
    required this.info,
  });

  factory Owner.fromJson(Map<String, dynamic> json) => Owner(
    id: json["id"],
    name: json["name"],
    role: roleValues.map[json["role"]]!,
    info: json["info"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "role": roleValues.reverse[role],
    "info": info,
  };
}

final roleValues = EnumValues({
  "ip-user": Role.IP_USER
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
