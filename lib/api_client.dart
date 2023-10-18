import 'dart:convert';
import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/io_client.dart';
import 'package:http/src/response.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schueler_portal/api/request_models/base_request.dart';
import 'package:schueler_portal/api/request_models/download_file.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/news.dart';

import 'api/response_models/api/chat.dart';
import 'api/response_models/api/chat/id.dart';
import 'api/response_models/api/stundenplan.dart';
import 'api/response_models/api/user.dart';
import 'api/response_models/api/vertretungsplan.dart';

class ApiClient {
  IOClient client = IOClient();
  String baseUri = "http://192.168.178.42:8134/schueler_portal";

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

  Future<List<News>> getNews() async =>
      newsFromJson(utf8.decode((await _put("/news")).bodyBytes));

  Future<Vertretungsplan> getVertretungsplan() async => vertretungsplanFromJson(
      utf8.decode((await _put("/vertretungsplan")).bodyBytes));

  Future<Stundenplan> getStundenplan() async =>
      stundenplanFromJson(utf8.decode((await _put("/stundenplan")).bodyBytes));

  Future<List<Hausaufgabe>> getHomework() async =>
      hausaufgabeFromJson(utf8.decode((await _put("/hausaufgaben")).bodyBytes));

  Future<List<Chat>> getChats() async =>
      chatFromJson(utf8.decode((await _put("/chat")).bodyBytes));

  Future<ChatDetails> getChatDetails(int chatId) async => chatDetailsFromJson(
      utf8.decode((await _put("/chat--$chatId")).bodyBytes));

  Future<User> getUser() async =>
      userFromJson(utf8.decode((await _put("/user")).bodyBytes));

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
