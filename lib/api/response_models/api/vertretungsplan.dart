// To parse this JSON data, do
//
//     final vertretungsplan = vertretungsplanFromJson(jsonString);

import 'dart:convert';

Vertretungsplan vertretungsplanFromJson(String str) => Vertretungsplan.fromJson(json.decode(str));

String vertretungsplanToJson(Vertretungsplan data) => json.encode(data.toJson());

class Vertretungsplan {
  List<Datum> data;
  List<dynamic> mitteilungen;

  Vertretungsplan({
    required this.data,
    required this.mitteilungen,
  });

  factory Vertretungsplan.fromJson(Map<String, dynamic> json) => Vertretungsplan(
    data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    mitteilungen: List<dynamic>.from(json["mitteilungen"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "mitteilungen": List<dynamic>.from(mitteilungen.map((x) => x)),
  };
}

class Datum {
  DateTime date;
  int hour;
  String datumClass;
  String uf;
  String vertrUf;
  String room;
  String reason;
  String text;
  String absTeacher;
  String vertrTeacher;

  Datum({
    required this.date,
    required this.hour,
    required this.datumClass,
    required this.uf,
    required this.vertrUf,
    required this.room,
    required this.reason,
    required this.text,
    required this.absTeacher,
    required this.vertrTeacher,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    date: DateTime.parse(json["date"]),
    hour: json["hour"],
    datumClass: json["class"],
    uf: json["uf"],
    vertrUf: json["vertr_uf"],
    room: json["room"],
    reason: json["reason"],
    text: json["text"],
    absTeacher: json["abs_teacher"],
    vertrTeacher: json["vertr_teacher"],
  );

  Map<String, dynamic> toJson() => {
    "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
    "hour": hour,
    "class": datumClass,
    "uf": uf,
    "vertr_uf": vertrUf,
    "room": room,
    "reason": reason,
    "text": text,
    "abs_teacher": absTeacher,
    "vertr_teacher": vertrTeacher,
  };
}
