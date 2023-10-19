// To parse this JSON data, do
//
//     final kontaktanfrageLehrer = kontaktanfrageLehrerFromJson(jsonString);

import 'dart:convert';

List<KontaktanfrageLehrer> kontaktanfrageLehrerFromJson(String str) => List<KontaktanfrageLehrer>.from(json.decode(str).map((x) => KontaktanfrageLehrer.fromJson(x)));

String kontaktanfrageLehrerToJson(List<KontaktanfrageLehrer> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class KontaktanfrageLehrer {
  final int userId;
  final String name;
  final dynamic info;

  KontaktanfrageLehrer({
    required this.userId,
    required this.name,
    required this.info,
  });

  factory KontaktanfrageLehrer.fromJson(Map<String, dynamic> json) => KontaktanfrageLehrer(
    userId: json["user_id"],
    name: json["name"],
    info: json["info"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "name": name,
    "info": info,
  };
}
