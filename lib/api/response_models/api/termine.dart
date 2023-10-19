// To parse this JSON data, do
//
//     final termine = termineFromJson(jsonString);

import 'dart:convert';

Termine termineFromJson(String str) => Termine.fromJson(json.decode(str));

String termineToJson(Termine data) => json.encode(data.toJson());

class Termine {
  final List<dynamic> calendar;
  final Leistungsnachweise leistungsnachweise;

  Termine({
    required this.calendar,
    required this.leistungsnachweise,
  });

  factory Termine.fromJson(Map<String, dynamic> json) => Termine(
    calendar: List<dynamic>.from(json["calendar"].map((x) => x)),
    leistungsnachweise: Leistungsnachweise.fromJson(json["leistungsnachweise"]),
  );

  Map<String, dynamic> toJson() => {
    "calendar": List<dynamic>.from(calendar.map((x) => x)),
    "leistungsnachweise": leistungsnachweise.toJson(),
  };
}

class Leistungsnachweise {
  final List<Schulaufgaben> schulaufgaben;
  final List<ExTemporalen> exTemporalen;

  Leistungsnachweise({
    required this.schulaufgaben,
    required this.exTemporalen,
  });

  factory Leistungsnachweise.fromJson(Map<String, dynamic> json) => Leistungsnachweise(
    schulaufgaben: List<Schulaufgaben>.from(json["schulaufgaben"].map((x) => Schulaufgaben.fromJson(x))),
    exTemporalen: List<ExTemporalen>.from(json["ex_temporalen"].map((x) => ExTemporalen.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "schulaufgaben": List<dynamic>.from(schulaufgaben.map((x) => x.toJson())),
    "ex_temporalen": List<dynamic>.from(exTemporalen.map((x) => x.toJson())),
  };
}

class ExTemporalen {
  final int id;
  final String klasse;
  final String fach;
  final DateTime date;
  final String? typ;

  ExTemporalen({
    required this.id,
    required this.klasse,
    required this.fach,
    required this.date,
    this.typ,
  });

  factory ExTemporalen.fromJson(Map<String, dynamic> json) => ExTemporalen(
    id: json["id"],
    klasse: json["klasse"],
    fach: json["fach"],
    date: DateTime.parse(json["date"]),
    typ: json["typ"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "klasse": klasse,
    "fach": fach,
    "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
    "typ": typ,
  };
}

class Schulaufgaben {
  final int id;
  final String klasse;
  final String fach;
  final DateTime date;
  final String typ;

  Schulaufgaben({
    required this.id,
    required this.klasse,
    required this.fach,
    required this.date,
    required this.typ,
  });

  factory Schulaufgaben.fromJson(Map<String, dynamic> json) => Schulaufgaben(
    id: json["id"],
    klasse: json["klasse"],
    fach: json["fach"],
    date: DateTime.parse(json["date"]),
    typ: json["typ"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "klasse": klasse,
    "fach": fach,
    "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
    "typ": typ,
  };
}
