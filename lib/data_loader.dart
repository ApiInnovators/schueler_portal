import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';
import 'package:schueler_portal/api_client.dart';
import 'package:schueler_portal/main.dart';

import 'api/response_models/api/chat.dart';
import 'api/response_models/api/news.dart';
import 'api/response_models/api/user.dart';

class DataLoader {
  static final cache = ApiCache();

  static cacheData() async {
    apiClient
        .putAndParse("/chat", chatFromJson)
        .then((value) => cache.chats = value);
    apiClient
        .putAndParse("/news", newsFromJson)
        .then((value) => cache.news = value);
    apiClient
        .putAndParse("/user", userFromJson)
        .then((value) => cache.user = value);
    apiClient
        .putAndParse("/stundenplan", stundenplanFromJson)
        .then((value) => cache.stundenplan = value);
    apiClient
        .putAndParse("/vertretungsplan", vertretungsplanFromJson)
        .then((value) => cache.vertretungsplan = value);
    apiClient
        .putAndParse("/hausaufgaben", hausaufgabeFromJson)
        .then((value) => cache.hausaufgaben = value);
  }

  static Future<ApiResponse<User>> getUser() async {
    while (cache.user == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cache.user!;
  }

  static Future<ApiResponse<Vertretungsplan>> getVertretungsplan() async {
    while (cache.vertretungsplan == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cache.vertretungsplan!;
  }

  static Future<ApiResponse<Stundenplan>> getStundenplan() async {
    while (cache.stundenplan == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cache.stundenplan!;
  }

  static Future<ApiResponse<List<News>>> getNews() async {
    while (cache.news == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cache.news!;
  }

  static Future<ApiResponse<List<Chat>>> getChats() async {
    while (cache.chats == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cache.chats!;
  }

  static Future<ApiResponse<List<Hausaufgabe>>> getHausaufgaben() async {
    while (cache.hausaufgaben == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cache.hausaufgaben!;
  }
}

class ApiCache {
  ApiResponse<User>? user;
  ApiResponse<Vertretungsplan>? vertretungsplan;
  ApiResponse<Stundenplan>? stundenplan;
  ApiResponse<List<News>>? news;
  ApiResponse<List<Chat>>? chats;
  ApiResponse<List<Hausaufgabe>>? hausaufgaben;
}
