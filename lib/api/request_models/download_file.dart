// To parse this JSON data, do
//
//     final downloadFile = downloadFileFromJson(jsonString);

import 'dart:convert';

import 'package:schueler_portal/api/request_models/base_request.dart';

import '../response_models/api/hausaufgaben.dart';


DownloadFileRequest downloadFileRequestFromJson(String str) => DownloadFileRequest.fromJson(json.decode(str));

String downloadFileRequestToJson(DownloadFileRequest data) => json.encode(data.toJson());

class DownloadFileRequest extends BaseRequest {
  final FileElement fileElement;

  DownloadFileRequest({
    required super.email,
    required super.password,
    required super.schulkuerzel,
    required this.fileElement,
  });

  factory DownloadFileRequest.fromJson(Map<String, dynamic> json) => DownloadFileRequest(
    email: json["email"],
    password: json["password"],
    schulkuerzel: json["schulkuerzel"],
    fileElement: FileElement.fromJson(json["file_element"]),
  );

  @override
  Map<String, dynamic> toJson() => {
    "email": email,
    "password": password,
    "schulkuerzel": schulkuerzel,
    "file_element": fileElement.toJson(),
  };
}
