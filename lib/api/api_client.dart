import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/pages/user_login.dart';

import '../tools.dart';

class ApiClient {
  static IOClient client = IOClient();
  static const String baseUrl = "https://apiinnovators.de/schueler_portal";
  static String? accessToken;

  static Future<Response> _handledRequest(
      Future<IOStreamedResponse> Function() reqFunc) async {
    try {
      return Response.fromStream(await reqFunc());
    } on SocketException {
      return Response("Internetverbindung überprüfen.", 499);
    } catch (e) {
      return Response("Unbekannter Fehler.", 498);
    }
  }

  static Future<Response> send(BaseRequest request) async {
    if (!request.headers.containsKey("Authorization")) {
      request.headers["Authorization"] = "Bearer $accessToken";
    }

    final requestCopy = Tools.copyRequest(request);
    final response = await _handledRequest(() => client.send(request));

    if (response.statusCode == 401) {
      // Try to authenticate user

      if (UserLogin.login == null) return response;

      final authResp = await authenticate(UserLogin.login!);
      if (authResp.$1.statusCode == 200 && requestCopy != null) {
        UserLogin.updateLogin(UserLogin.login!, authResp.$2["access_token"]);
        requestCopy.headers["Authorization"] = "Bearer $accessToken";
        return await _handledRequest(() => client.send(requestCopy));
      }
    }

    return response;
  }

  static Future<ApiResponse<T>> sendAndParse<T>(
      BaseRequest request, T Function(String) parser) async {
    Response resp = await send(request);

    if (resp.statusCode == 200) {
      return ApiResponse(resp, data: parser(utf8.decode(resp.bodyBytes)));
    }

    return ApiResponse(resp);
  }

  static Future<bool> hasValidToken() async {
    if (accessToken == null) return false;
    final result =
        await send(Request("POST", Uri.parse("$baseUrl/token/is-valid")));
    return result.statusCode == 200 && result.body == "true";
  }

  static Future<ApiResponse<T>> getAndParse<T>(
      String path, T Function(String) parser) {
    if (!path.startsWith("/")) path = "/$path";
    return sendAndParse(Request("GET", Uri.parse("$baseUrl$path")), parser);
  }

  static Future<ApiResponse<T>> postAndParse<T>(String path, T Function(String) parser,
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

  static Future<(Response, dynamic)> authenticate(LoginData login) async {
    final request =
        Request("POST", Uri.parse("$baseUrl/${login.schulkuerzel}/token"));
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.bodyFields = {'username': login.email, 'password': login.password};

    Response resp = await _handledRequest(() => client.send(request));

    dynamic parsed;

    if (resp.statusCode == 200) {
      parsed = jsonDecode(resp.body);
      accessToken = parsed["access_token"];
    }

    return (resp, parsed);
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
      if (showToast) Tools.quickSnackbar("Download completed");
      return file;
    }

    if (showToast) {
      Tools.quickSnackbar("Download failed: ${response.reasonPhrase}");
    }

    return null;
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
