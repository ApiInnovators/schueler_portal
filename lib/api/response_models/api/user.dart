// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  final int id;
  final String name;
  final String email;
  final DateTime emailVerifiedAt;
  final bool hasPassword;
  final String role;
  final int ipId;
  final String info;
  final bool isDeleted;
  final bool adminMode;
  final dynamic latestMail;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerifiedAt,
    required this.hasPassword,
    required this.role,
    required this.ipId,
    required this.info,
    required this.isDeleted,
    required this.adminMode,
    required this.latestMail,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    name: json["name"],
    email: json["email"],
    emailVerifiedAt: DateTime.parse(json["emailVerifiedAt"]),
    hasPassword: json["hasPassword"],
    role: json["role"],
    ipId: json["ipId"],
    info: json["info"],
    isDeleted: json["isDeleted"],
    adminMode: json["adminMode"],
    latestMail: json["latestMail"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "emailVerifiedAt": emailVerifiedAt.toIso8601String(),
    "hasPassword": hasPassword,
    "role": role,
    "ipId": ipId,
    "info": info,
    "isDeleted": isDeleted,
    "adminMode": adminMode,
    "latestMail": latestMail,
  };
}
