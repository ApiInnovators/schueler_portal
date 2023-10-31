// To parse this JSON data, do
//
//     final unterricht = unterrichtFromJson(jsonString);

import 'dart:convert';

import 'hausaufgaben.dart';

List<Unterricht> unterrichtFromJson(String str) =>
    List<Unterricht>.from(json.decode(str).map((x) => Unterricht.fromJson(x)));

String unterrichtToJson(List<Unterricht> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Unterricht {
  final String teacher;
  final DateTime date;
  final int hourFrom;
  final int hourTo;
  final bool substitute;
  final Subject subject;
  final Content content;
  final Homework? homework;

  Unterricht({
    required this.teacher,
    required this.date,
    required this.hourFrom,
    required this.hourTo,
    required this.substitute,
    required this.subject,
    required this.content,
    required this.homework,
  });

  factory Unterricht.fromJson(Map<String, dynamic> json) => Unterricht(
        teacher: json["teacher"],
        date: DateTime.parse(json["date"]),
        hourFrom: json["hour_from"],
        hourTo: json["hour_to"],
        substitute: json["substitute"],
        subject: Subject.fromJson(json["subject"]),
        content: Content.fromJson(json["content"]),
        homework: json["homework"] == null
            ? null
            : Homework.fromJson(json["homework"]),
      );

  Map<String, dynamic> toJson() => {
        "teacher": teacher,
        "date":
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "hour_from": hourFrom,
        "hour_to": hourTo,
        "substitute": substitute,
        "subject": subject.toJson(),
        "content": content.toJson(),
        "homework": homework?.toJson(),
      };
}

class Content {
  final String text;
  final List<FileElement> files;

  Content({
    required this.text,
    required this.files,
  });

  factory Content.fromJson(Map<String, dynamic> json) => Content(
        text: json["text"],
        files: List<FileElement>.from(
            json["files"].map((x) => FileElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "files": List<dynamic>.from(files.map((x) => x.toJson())),
      };
}

class Homework {
  final int id;
  final String homework;
  final DateTime dueAt;
  final bool back;
  final List<FileElement> files;

  Homework({
    required this.id,
    required this.homework,
    required this.dueAt,
    required this.back,
    required this.files,
  });

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
        id: json["id"],
        homework: json["homework"],
        dueAt: DateTime.parse(json["due_at"]),
        back: json["back"],
        files: List<FileElement>.from(
            json["files"].map((x) => FileElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "homework": homework,
        "due_at":
            "${dueAt.year.toString().padLeft(4, '0')}-${dueAt.month.toString().padLeft(2, '0')}-${dueAt.day.toString().padLeft(2, '0')}",
        "back": back,
        "files": List<dynamic>.from(files.map((x) => x.toJson())),
      };
}
