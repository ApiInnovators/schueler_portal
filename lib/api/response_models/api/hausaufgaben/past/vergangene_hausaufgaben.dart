// To parse this JSON data, do
//
//     final vergangeneHausaufgaben = vergangeneHausaufgabenFromJson(jsonString);

import 'dart:convert';

import '../../hausaufgaben.dart';

VergangeneHausaufgaben vergangeneHausaufgabenFromJson(String str) =>
    VergangeneHausaufgaben.fromJson(json.decode(str));

String vergangeneHausaufgabenToJson(VergangeneHausaufgaben data) =>
    json.encode(data.toJson());

class VergangeneHausaufgaben {
  final List<Datum> data;
  final Pagination pagination;

  VergangeneHausaufgaben({
    required this.data,
    required this.pagination,
  });

  factory VergangeneHausaufgaben.fromJson(Map<String, dynamic> json) =>
      VergangeneHausaufgaben(
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        pagination: Pagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "pagination": pagination.toJson(),
      };
}

class Datum {
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

  Datum({
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

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"],
        homework: json["homework"],
        dueAt: DateTime.parse(json["due_at"]),
        back: json["back"],
        files: List<FileElement>.from(
            json["files"].map((x) => FileElement.fromJson(x))),
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
        "due_at":
            "${dueAt.year.toString().padLeft(4, '0')}-${dueAt.month.toString().padLeft(2, '0')}-${dueAt.day.toString().padLeft(2, '0')}",
        "back": back,
        "files": List<dynamic>.from(files.map((x) => x.toJson())),
        "teacher": teacher,
        "date":
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "substitute": substitute,
        "subject": subject.toJson(),
        "submissions": List<dynamic>.from(submissions.map((x) => x)),
        "completed": completed,
      };
}

class Pagination {
  final int currentPage;
  final int from;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: json["current_page"],
        from: json["from"],
        lastPage: json["last_page"],
        perPage: json["per_page"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "from": from,
        "last_page": lastPage,
        "per_page": perPage,
        "total": total,
      };
}
