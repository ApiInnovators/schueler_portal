import 'dart:async';

import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';
import 'package:schueler_portal/api/api_client.dart';

import 'api/response_models/api/chat.dart';
import 'api/response_models/api/news.dart';
import 'api/response_models/api/user.dart';

class DataLoader {
  static final cache = ApiCache();

  static final _completers = <Completer<void>>[];
  static List<Future<void>> _futures = [];

  static cacheData() {
    final chatCompleter = Completer<void>();
    final newsCompleter = Completer<void>();
    final userCompleter = Completer<void>();
    final stundenplanCompleter = Completer<void>();
    final vertretungsplanCompleter = Completer<void>();
    final hausaufgabenCompleter = Completer<void>();

    _completers.addAll([
      chatCompleter,
      newsCompleter,
      userCompleter,
      stundenplanCompleter,
      vertretungsplanCompleter,
      hausaufgabenCompleter,
    ]);

    if (cache.chats == null) {
      ApiClient.putAndParse("/chat", chatFromJson).then((value) {
        cache.chats = value;
        chatCompleter.complete();
      });
    }

    if (cache.news == null) {
      ApiClient.putAndParse("/news", newsFromJson).then((value) {
        cache.news = value;
        newsCompleter.complete();
      });
    }

    if (cache.user == null) {
      ApiClient.putAndParse("/user", userFromJson).then((value) {
        cache.user = value;
        userCompleter.complete();
      });
    }

    if (cache.stundenplan == null) {
      ApiClient.putAndParse("/stundenplan", stundenplanFromJson).then((value) {
        cache.stundenplan = value;
        stundenplanCompleter.complete();
      });
    }

    if (cache.vertretungsplan == null) {
      ApiClient.putAndParse("/vertretungsplan", vertretungsplanFromJson)
          .then((value) {
        cache.vertretungsplan = value;
        vertretungsplanCompleter.complete();
      });
    }

    if (cache.hausaufgaben == null) {
      ApiClient.putAndParse("/hausaufgaben", hausaufgabeFromJson).then((value) {
        cache.hausaufgaben = value;
        hausaufgabenCompleter.complete();
      });
    }

    _futures = _completers.map((completer) => completer.future).toList();
  }

  // Function to cancel and reset the operations
  static cancelAndReset() {
    for (Completer<void> completer in _completers) {
      if (!completer.isCompleted) {
        completer.completeError("Operation canceled");
      }
    }
    _completers.clear();
    _futures.clear();
  }

  static Future<T> _waitForProperty<T>(T? Function() getter) async {
    while (getter() == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return getter()!;
  }

  static Future<ApiResponse<User>> getUser() async =>
      await _waitForProperty(cache.getUser);

  static Future<ApiResponse<Vertretungsplan>> getVertretungsplan() async =>
      await _waitForProperty(cache.getVertretungsplan);

  static Future<ApiResponse<Stundenplan>> getStundenplan() async =>
      await _waitForProperty(cache.getStundenplan);

  static Future<ApiResponse<List<News>>> getNews() async =>
      await _waitForProperty(cache.getNews);

  static Future<ApiResponse<List<Chat>>> getChats() async =>
      await _waitForProperty(cache.getChats);

  static Future<ApiResponse<List<Hausaufgabe>>> getHausaufgaben() async =>
      _waitForProperty(cache.getHausaufgaben);
}

class ApiCache {
  ApiResponse<User>? user;
  ApiResponse<Vertretungsplan>? vertretungsplan;
  ApiResponse<Stundenplan>? stundenplan;
  ApiResponse<List<News>>? news;
  ApiResponse<List<Chat>>? chats;
  ApiResponse<List<Hausaufgabe>>? hausaufgaben;

  ApiResponse<User>? getUser() => user;

  ApiResponse<Vertretungsplan>? getVertretungsplan() => vertretungsplan;

  ApiResponse<Stundenplan>? getStundenplan() => stundenplan;

  ApiResponse<List<News>>? getNews() => news;

  ApiResponse<List<Chat>>? getChats() => chats;

  ApiResponse<List<Hausaufgabe>>? getHausaufgaben() => hausaufgaben;
}
