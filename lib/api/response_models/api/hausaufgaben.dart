// To parse this JSON data, do
//
//     final hausaufgabe = hausaufgabeFromJson(jsonString);

import 'dart:convert';

List<Hausaufgabe> hausaufgabeFromJson(String str) => List<Hausaufgabe>.from(json.decode(str).map((x) => Hausaufgabe.fromJson(x)));

String hausaufgabeToJson(List<Hausaufgabe> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Hausaufgabe {
  final int id;
  final String homework;
  final DateTime dueAt;
  final bool back;
  final List<FileElement> files;
  final String teacher;
  final DateTime date;
  final bool substitute;
  final Subject subject;
  final List<dynamic> submissions;
  final bool completed;

  Hausaufgabe({
    required this.id,
    required this.homework,
    required this.dueAt,
    required this.back,
    required this.files,
    required this.teacher,
    required this.date,
    required this.substitute,
    required this.subject,
    required this.submissions,
    required this.completed,
  });

  factory Hausaufgabe.fromJson(Map<String, dynamic> json) => Hausaufgabe(
    id: json["id"],
    homework: json["homework"],
    dueAt: DateTime.parse(json["due_at"]),
    back: json["back"],
    files: List<FileElement>.from(json["files"].map((x) => FileElement.fromJson(x))),
    teacher: json["teacher"],
    date: DateTime.parse(json["date"]),
    substitute: json["substitute"],
    subject: Subject.fromJson(json["subject"]),
    submissions: List<dynamic>.from(json["submissions"].map((x) => x)),
    completed: json["completed"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "homework": homework,
    "due_at": "${dueAt.year.toString().padLeft(4, '0')}-${dueAt.month.toString().padLeft(2, '0')}-${dueAt.day.toString().padLeft(2, '0')}",
    "back": back,
    "files": List<dynamic>.from(files.map((x) => x.toJson())),
    "teacher": teacher,
    "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
    "substitute": substitute,
    "subject": subject.toJson(),
    "submissions": List<dynamic>.from(submissions.map((x) => x)),
    "completed": completed,
  };
}

class FileElement {
  final int id;
  final String name;
  final String link;

  FileElement({
    required this.id,
    required this.name,
    required this.link,
  });

  factory FileElement.fromJson(Map<String, dynamic> json) => FileElement(
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

class Subject {
  final String short;
  final String long;

  Subject({
    required this.short,
    required this.long,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    short: json["short"],
    long: json["long"],
  );

  Map<String, dynamic> toJson() => {
    "short": short,
    "long": long,
  };
}
