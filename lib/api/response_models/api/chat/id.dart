// To parse this JSON data, do
//
//     final chatDetails = chatDetailsFromJson(jsonString);

import 'dart:convert';

ChatDetails chatDetailsFromJson(String str) => ChatDetails.fromJson(json.decode(str));

String chatDetailsToJson(ChatDetails data) => json.encode(data.toJson());

class ChatDetails {
  final int id;
  final String name;
  final bool broadcast;
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
    members: List<Member>.from(json["members"].map((x) => Member.fromJson(x))),
    messages: List<Message>.from(json["messages"].map((x) => Message.fromJson(x))),
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

class Member {
  final int id;
  final String type;
  final String name;
  final String info;

  Member({
    required this.id,
    required this.type,
    required this.name,
    required this.info,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json["id"],
    type: json["type"],
    name: json["name"],
    info: json["info"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "name": name,
    "info": info,
  };
}

class Message {
  final int id;
  final String? text;
  final int createdAt;
  final bool isDeleted;
  final bool isDeletable;
  final bool read;
  final Owner editor;
  final FileClass? file;

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
    createdAt: json["createdAt"],
    isDeleted: json["isDeleted"],
    isDeletable: json["isDeletable"],
    read: json["read"],
    editor: Owner.fromJson(json["editor"]),
    file: json["file"] == null ? null : FileClass.fromJson(json["file"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "text": text,
    "createdAt": createdAt,
    "isDeleted": isDeleted,
    "isDeletable": isDeletable,
    "read": read,
    "editor": editor.toJson(),
    "file": file?.toJson(),
  };
}

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

enum Role {
  IP_USER,
  STUDENT
}

final roleValues = EnumValues({
  "ip-user": Role.IP_USER,
  "student": Role.STUDENT
});

class FileClass {
  final int id;
  final String name;
  final String link;

  FileClass({
    required this.id,
    required this.name,
    required this.link,
  });

  factory FileClass.fromJson(Map<String, dynamic> json) => FileClass(
    id: json["id"],
    name: json["name"],
    link: json["link"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "link": link,
  };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
