// To parse this JSON data, do
//
//     final news = newsFromJson(jsonString);

import 'dart:convert';

import 'hausaufgaben.dart';

List<News> newsFromJson(String str) =>
    List<News>.from(json.decode(str).map((x) => News.fromJson(x)));

String newsToJson(List<News> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class News {
  final int id;
  final String title;
  final String content;
  final FileElement? file;
  final DateTime validFrom;
  final DateTime validTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool valid;
  final List<String>? restrictedToUserGroups;

  News({
    required this.id,
    required this.title,
    required this.content,
    this.file,
    required this.validFrom,
    required this.validTo,
    required this.createdAt,
    required this.updatedAt,
    required this.valid,
    this.restrictedToUserGroups,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
        id: json["id"],
        title: json["title"],
        content: json["content"],
        file: json["file"] == null ? null : FileElement.fromJson(json["file"]),
        validFrom: DateTime.parse(json["valid_from"]),
        validTo: DateTime.parse(json["valid_to"]),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        valid: json["valid"],
        restrictedToUserGroups: json["restricted_to_user_groups"] == null
            ? []
            : List<String>.from(
                json["restricted_to_user_groups"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "content": content,
        "file": file?.toJson(),
        "valid_from":
            "${validFrom.year.toString().padLeft(4, '0')}-${validFrom.month.toString().padLeft(2, '0')}-${validFrom.day.toString().padLeft(2, '0')}",
        "valid_to":
            "${validTo.year.toString().padLeft(4, '0')}-${validTo.month.toString().padLeft(2, '0')}-${validTo.day.toString().padLeft(2, '0')}",
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "valid": valid,
        "restricted_to_user_groups": restrictedToUserGroups == null
            ? []
            : List<dynamic>.from(restrictedToUserGroups!.map((x) => x)),
      };
}
