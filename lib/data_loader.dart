import 'dart:async';

import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';
import 'package:schueler_portal/api_client.dart';

import 'api/response_models/api/chat.dart';
import 'api/response_models/api/news.dart';
import 'api/response_models/api/user.dart';

class DataLoader {
  static final cache = ApiCache();

  static final _completers = <Completer<void>>[];
  static List<Future<void>> _futures = [];

  static Future<void> cacheData() async {
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

    // Start the asynchronous operations
    ApiClient.putAndParse("/chat", chatFromJson)
        .then((value) {
      cache.chats = value;
      chatCompleter.complete();
    });

    ApiClient.putAndParse("/news", newsFromJson)
        .then((value) {
      cache.news = value;
      newsCompleter.complete();
    });

    ApiClient.putAndParse("/user", userFromJson)
        .then((value) {
      cache.user = value;
      userCompleter.complete();
    });

    ApiClient.putAndParse("/stundenplan", stundenplanFromJson)
        .then((value) {
      cache.stundenplan = value;
      stundenplanCompleter.complete();
    });

    ApiClient.putAndParse("/vertretungsplan", vertretungsplanFromJson)
        .then((value) {
      cache.vertretungsplan = value;
      vertretungsplanCompleter.complete();
    });

    ApiClient.putAndParse("/hausaufgaben", hausaufgabeFromJson)
        .then((value) {
      cache.hausaufgaben = value;
      hausaufgabenCompleter.complete();
    });

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
