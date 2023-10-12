// To parse this JSON data, do
//
//     final news = newsFromJson(jsonString);

import 'dart:convert';

List<News> newsFromJson(String str) =>
    List<News>.from(json.decode(str).map((x) => News.fromJson(x)));

String newsToJson(List<News> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class News {
  int id;
  String title;
  String content;
  FileClass file;
  DateTime validFrom;
  DateTime validTo;
  DateTime createdAt;
  DateTime updatedAt;
  bool valid;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.file,
    required this.validFrom,
    required this.validTo,
    required this.createdAt,
    required this.updatedAt,
    required this.valid,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
        id: json["id"],
        title: json["title"],
        content: json["content"],
        file: FileClass.fromJson(json["file"]),
        validFrom: DateTime.parse(json["valid_from"]),
        validTo: DateTime.parse(json["valid_to"]),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        valid: json["valid"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "content": content,
        "file": file.toJson(),
        "valid_from":
            "${validFrom.year.toString().padLeft(4, '0')}-${validFrom.month.toString().padLeft(2, '0')}-${validFrom.day.toString().padLeft(2, '0')}",
        "valid_to":
            "${validTo.year.toString().padLeft(4, '0')}-${validTo.month.toString().padLeft(2, '0')}-${validTo.day.toString().padLeft(2, '0')}",
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "valid": valid,
      };
}

class FileClass {
  int id;
  String name;
  String link;

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
