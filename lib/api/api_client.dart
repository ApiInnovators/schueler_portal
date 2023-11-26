import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schueler_portal/api/response_models/api/chat/id.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/pages/user_login.dart';

import '../tools.dart';

class ApiClient {
  static IOClient client = IOClient(
    HttpClient()..connectionTimeout = const Duration(seconds: 5),
  );
  static const String baseUrl = "https://schueler-portal.apiinnovators.de";
  static bool _alreadyTriesToReauthenticate = false;

  static Future<Response> _handledRequest(BaseRequest request) async {
    try {
      log("Making request: ${request.url.path}");
      final response = await Response.fromStream(await client.send(request));
      log("Response: ${response.statusCode}");
      return response;
    } on SocketException {
      log("Error while sending request: Socket Exception (Offline?)");
      Tools.quickSnackbar("Offline", icon: const Icon(Icons.cloud_off));
      return Response("Internetverbindung überprüfen.", 499);
    } catch (e) {
      log("Error while sending request: $e");
      Tools.quickSnackbar("Unbekannter Fehler");
      return Response("Unbekannter Fehler.", 498);
    }
  }

  static Future<Response> send(BaseRequest request) async {
    if (!request.headers.containsKey("Authorization")) {
      request.headers["Authorization"] = "Bearer ${UserLogin.accessToken}";
    }

    final requestCopy = Tools.copyRequest(request);
    final response = await _handledRequest(request);

    if (response.statusCode == 401) {
      // Try to authenticate user

      if (_alreadyTriesToReauthenticate && requestCopy != null) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 30));
          return _alreadyTriesToReauthenticate;
        }).timeout(const Duration(seconds: 6));
        requestCopy.headers["Authorization"] =
            "Bearer ${UserLogin.accessToken}";
        return await _handledRequest(requestCopy);
      }

      if (UserLogin.login == null) return response;

      final authResp = await _reauthenticate(false);

      if (authResp.statusCode == 200 && requestCopy != null) {
        requestCopy.headers["Authorization"] =
            "Bearer ${UserLogin.accessToken}";
        return await _handledRequest(requestCopy);
      }
    }

    return response;
  }

  static Future<Response> _reauthenticate(bool recacheData) async {
    _alreadyTriesToReauthenticate = true;
    log("Trying to reauthenticate user");
    final authResp = await authenticate(UserLogin.login!, recacheData);

    if (authResp.statusCode == 422) {
      forceLogin();
    }

    _alreadyTriesToReauthenticate = false;

    return authResp;
  }

  static Future<ApiResponse<T>> sendAndParse<T>(
      BaseRequest request, T Function(String) parser) async {
    Response resp = await send(request);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return ApiResponse(resp, data: parser(utf8.decode(resp.bodyBytes)));
    }

    return ApiResponse(resp);
  }

  static Future<ApiResponse<bool>> hasValidToken(bool recacheData) async {
    final result =
        await send(Request("POST", Uri.parse("$baseUrl/token/is-valid")));

    if (result.statusCode != 200) return ApiResponse(result);

    if (result.body == "true") return ApiResponse(result, data: true);

    final authResp = await _reauthenticate(recacheData);

    if (authResp.statusCode == 200) {
      return ApiResponse(authResp, data: true);
    }

    return ApiResponse(authResp);
  }

  static Future<ApiResponse<T>> getAndParse<T>(
      String path, T Function(String) parser) {
    if (!path.startsWith("/")) path = "/$path";
    return sendAndParse(Request("GET", Uri.parse("$baseUrl$path")), parser);
  }

  static Future<ApiResponse<T>> postAndParse<T>(
      String path, T Function(String) parser,
      {String? body, String? contentType}) {
    if (!path.startsWith("/")) path = "/$path";
    Request req = Request("POST", Uri.parse("$baseUrl$path"));

    if (body != null) {
      req.body = body;
      if (contentType == null) {
        throw Exception("A content type should be specified");
      }
      req.headers["Content-Type"] = contentType;
    }

    return sendAndParse(req, parser);
  }

  static Future<ApiResponse<String>> authenticate(LoginData login, bool recacheData) async {
    final request =
        Request("POST", Uri.parse("$baseUrl/${login.schulkuerzel}/token"));
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.bodyFields = {'username': login.email, 'password': login.password};

    Response resp = await _handledRequest(request);

    if (resp.statusCode == 200) {
      final parsed = jsonDecode(resp.body);
      UserLogin.update(recacheData, newAccessToken: parsed["access_token"]);
      return ApiResponse(resp, data: parsed["access_token"]);
    }

    return ApiResponse(resp);
  }

  static Future<String> makeFilePath(FileElement file) async {
    final downloadsDirectory = await getDownloadsDirectory();
    return '${downloadsDirectory!.path}/${file.id}-${file.name}';
  }

  static Future<(bool exists, File file)> checkIfFileIsStored(
      FileElement file) async {
    final filePath = await makeFilePath(file);
    final f = File(filePath);
    return (await f.exists(), f);
  }

  static Future<File?> downloadFile(FileElement file,
      {bool checkIfCached = true, bool showToast = true}) async {
    String filePath = await makeFilePath(file);
    if (checkIfCached) {
      (bool, File) f = await checkIfFileIsStored(file);
      if (f.$1) return f.$2;
    }

    final request = Request("POST", Uri.parse("$baseUrl/download-file"));
    request.body = json.encode(file.toJson());
    request.headers["Content-Type"] = 'application/json';
    final response = await send(request);

    if (response.statusCode == 200) {
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      if (showToast) Tools.quickSnackbar("Download abgeschlossen");
      return file;
    }

    if (showToast) {
      Tools.quickSnackbar("Download fehlgeschlagen: ${response.reasonPhrase}");
    }

    return null;
  }

  static Future<ApiResponse<Message>> sendMessage(int chatId, String? text, File? file) async {
    final request = MultipartRequest(
      "POST",
      Uri.parse("${ApiClient.baseUrl}/chat/$chatId/message"),
    );

    if (text != null) {
      request.fields["text"] = text;
    }

    if (file != null) {
      request.files.add(
        await MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );
    }

    return ApiClient.sendAndParse<Message>(
      request,
          (p0) => Message.fromJson(jsonDecode(p0)),
    );
  }
}

class ApiResponse<T> extends Response {
  final T? data;

  ApiResponse(Response response, {this.data})
      : super(
          response.body,
          response.statusCode,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          request: response.request,
          reasonPhrase: response.reasonPhrase,
        );
}
