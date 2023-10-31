// To parse this JSON data, do
//
//     final stundenplan = stundenplanFromJson(jsonString);

import 'dart:convert';

Stundenplan stundenplanFromJson(String str) =>
    Stundenplan.fromJson(json.decode(str));

String stundenplanToJson(Stundenplan data) => json.encode(data.toJson());

class Stundenplan {
  List<Datum> data;
  List<Zeittafel> zeittafel;

  Stundenplan({
    required this.data,
    required this.zeittafel,
  });

  factory Stundenplan.fromJson(Map<String, dynamic> json) => Stundenplan(
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        zeittafel: List<Zeittafel>.from(
            json["zeittafel"].map((x) => Zeittafel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "zeittafel": List<dynamic>.from(zeittafel.map((x) => x.toJson())),
      };
}

class Datum {
  int day;
  int hour;
  String uf;
  String? room;

  Datum({
    required this.day,
    required this.hour,
    required this.uf,
    required this.room,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        day: json["day"],
        hour: json["hour"],
        uf: json["uf"],
        room: json["room"],
      );

  Map<String, dynamic> toJson() => {
        "day": day,
        "hour": hour,
        "uf": uf,
        "room": room,
      };
}

class Zeittafel {
  int hour;
  String value;
  String name;

  Zeittafel({
    required this.hour,
    required this.value,
    required this.name,
  });

  factory Zeittafel.fromJson(Map<String, dynamic> json) => Zeittafel(
        hour: json["hour"],
        value: json["value"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "hour": hour,
        "value": value,
        "name": name,
      };
}
