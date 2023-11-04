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
  final List<Hausaufgabe> data;
  final Pagination pagination;

  VergangeneHausaufgaben({
    required this.data,
    required this.pagination,
  });

  factory VergangeneHausaufgaben.fromJson(Map<String, dynamic> json) =>
      VergangeneHausaufgaben(
        data: List<Hausaufgabe>.from(json["data"].map((x) => Hausaufgabe.fromJson(x))),
        pagination: Pagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
        "pagination": pagination.toJson(),
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
