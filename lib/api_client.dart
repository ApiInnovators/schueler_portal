import 'dart:convert';

import 'package:http/io_client.dart';
import 'package:http/src/response.dart';
import 'package:schueler_portal/api/request_models/base_request.dart';
import 'package:schueler_portal/api/response_models/api/news.dart';

import 'api/response_models/api/stundenplan.dart';
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
      subUri = "$subUri/";
    }

    return await client.put(Uri.parse(baseUri + subUri),
        headers: {"Content-Type": "application/json"}, body: baseRequestJson);
  }

  Future<List<News>> getNews() async =>
      newsFromJson(utf8.decode((await _put("/news")).bodyBytes));

  Future<Vertretungsplan> getVertretungsplan() async => vertretungsplanFromJson(
      utf8.decode((await _put("/vertretungsplan")).bodyBytes));

  Future<Stundenplan> getStundenplan() async =>
      stundenplanFromJson(utf8.decode((await _put("/stundenplan")).bodyBytes));
}
