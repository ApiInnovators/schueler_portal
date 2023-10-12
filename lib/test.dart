import 'package:http/io_client.dart';
import 'package:http/src/response.dart';
import 'package:schueler_portal/api/request_models/base_request.dart';
import 'package:schueler_portal/api/response_models/api/news.dart';

import 'api/response_models/api/stundenplan.dart';
import 'api/response_models/api/vertretungsplan.dart';

class ApiClient {
  IOClient client = IOClient();
  String baseUri = "http://10.0.2.2:8134/schueler_portal";

  late BaseRequest baseRequest;
  late String baseRequestJson;

  ApiClient(String email, String password, String schulkuerzel) {
    updateCredentials(email, password, schulkuerzel);
  }

  updateCredentials(String email, String password, String schulkuerzel) {
    baseRequest = BaseRequest(
        email: email,
        password: password,
        schulkuerzel: schulkuerzel);
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
      newsFromJson((await _put("/news")).body);

  Future<Vertretungsplan> getVertretungsplan() async =>
      vertretungsplanFromJson((await _put("/vertretungsplan")).body);

  Future<Stundenplan> getStundenplan() async =>
      stundenplanFromJson((await _put("/stundenplan")).body);
}
