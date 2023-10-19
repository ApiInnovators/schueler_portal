import 'dart:convert';
import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/io_client.dart';
import 'package:http/src/response.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schueler_portal/api/request_models/base_request.dart';
import 'package:schueler_portal/api/request_models/download_file.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';


class ApiClient {
  IOClient client = IOClient();
  String baseUri = "https://apiinnovators.de/schueler_portal";

  late BaseRequest baseRequest;
  late String baseRequestJson;

  ApiClient(String email, String password, String schulkuerzel) {
    updateCredentials(email, password, schulkuerzel);
  }

  updateCredentials(String email, String password, String schulkuerzel) {
    baseRequest = BaseRequest(
        email: email, password: password, schulkuerzel: schulkuerzel);
    baseRequestJson = baseRequestToJson(baseRequest);
  }

  Future<Response> _put(String subUri) async {
    if (!subUri.startsWith("/")) {
      subUri = "/$subUri";
    }

    return await client.put(Uri.parse(baseUri + subUri),
        headers: {"Content-Type": "application/json"}, body: baseRequestJson);
  }

  Future<Response> _post(String subUri, String body) async {
    if (!subUri.startsWith("/")) {
      subUri = "$subUri/";
    }

    return await client.post(Uri.parse(baseUri + subUri),
        headers: {"Content-Type": "application/json"}, body: body);
  }

  Future<ApiResponse<T>> putAndParse<T>(
      String url, T Function(String) parser) async {
    Response resp = await _put(url);

    if (resp.statusCode == 200) {
      return ApiResponse(resp, data: parser(utf8.decode(resp.bodyBytes)));
    }

    return ApiResponse(resp);
  }

  Future<File?> downloadFile(FileElement file,
      {bool checkIfCached = true}) async {
    final downloadsDirectory = await getDownloadsDirectory();
    final filePath = '${downloadsDirectory!.path}/${file.id}-${file.name}';

    if (checkIfCached) {
      final f = File(filePath);
      if (await f.exists()) {
        return f;
      }
    }

    DownloadFileRequest fileRequest = DownloadFileRequest(
      email: baseRequest.email,
      password: baseRequest.password,
      schulkuerzel: baseRequest.schulkuerzel,
      fileElement: file,
    );

    final response =
        await _post("/download_file", downloadFileRequestToJson(fileRequest));

    if (response.statusCode == 200) {
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      Fluttertoast.showToast(msg: "Download completed");
      return file;
    }

    Fluttertoast.showToast(msg: "Download failed: ${response.reasonPhrase}");
    return null;
  }
}

class ApiResponse<T> extends Response {
  final T? data;

  ApiResponse(Response response, {this.data})
      : super(
          response.reasonPhrase ?? "",
          response.statusCode,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          request: response.request,
        );
}
