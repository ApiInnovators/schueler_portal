// To parse this JSON data, do
//
//     final baseRequest = baseRequestFromJson(jsonString);

import 'dart:convert';

BaseRequest baseRequestFromJson(String str) =>
    BaseRequest.fromJson(json.decode(str));

String baseRequestToJson(BaseRequest data) => json.encode(data.toJson());

class BaseRequest {
  String email;
  String password;
  String schulkuerzel;

  BaseRequest({
    required this.email,
    required this.password,
    required this.schulkuerzel,
  });

  factory BaseRequest.fromJson(Map<String, dynamic> json) => BaseRequest(
        email: json["email"],
        password: json["password"],
        schulkuerzel: json["schulkuerzel"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "schulkuerzel": schulkuerzel,
      };
}
