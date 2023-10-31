import 'dart:async';

import 'package:intl/intl.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/unterricht.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';

import 'api/response_models/api/chat.dart';
import 'api/response_models/api/news.dart';
import 'api/response_models/api/termine.dart';
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
    final termineCompleter = Completer<void>();

    _completers.addAll([
      chatCompleter,
      newsCompleter,
      userCompleter,
      stundenplanCompleter,
      vertretungsplanCompleter,
      hausaufgabenCompleter,
      termineCompleter,
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

    if (cache.termine == null) {
      ApiClient.putAndParse("/termine", termineFromJson).then((value) {
        cache.termine = value;
        termineCompleter.complete();
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

  static Future<ApiResponse<User>> getUser() =>
      _waitForProperty(() => cache.user);

  static Future<ApiResponse<Vertretungsplan>> getVertretungsplan() =>
      _waitForProperty(() => cache.vertretungsplan);

  static Future<ApiResponse<Stundenplan>> getStundenplan() =>
      _waitForProperty(() => cache.stundenplan);

  static Future<ApiResponse<List<News>>> getNews() =>
      _waitForProperty(() => cache.news);

  static Future<ApiResponse<List<Chat>>> getChats() =>
      _waitForProperty(() => cache.chats);

  static Future<ApiResponse<List<Hausaufgabe>>> getHausaufgaben() =>
      _waitForProperty(() => cache.hausaufgaben);

  static Future<ApiResponse<Termine>> getTermine() =>
      _waitForProperty(() => cache.termine);

  static Future<ApiResponse<List<Unterricht>>> getUnterricht(
      DateTime day) async {
    if (!cache.unterricht.containsKey(day)) {
      ApiResponse<List<Unterricht>> unterricht = await ApiClient.putAndParse(
        "/unterricht--${DateFormat("yyyy-MM-dd").format(day)}",
        unterrichtFromJson,
      );

      cache.unterricht[day] = unterricht;
    }

    return cache.unterricht[day]!;
  }
}

class ApiCache {
  ApiResponse<User>? user;
  ApiResponse<Vertretungsplan>? vertretungsplan;
  ApiResponse<Stundenplan>? stundenplan;
  ApiResponse<List<News>>? news;
  ApiResponse<List<Chat>>? chats;
  ApiResponse<List<Hausaufgabe>>? hausaufgaben;
  Map<DateTime, ApiResponse<List<Unterricht>>?> unterricht = {};
  ApiResponse<Termine>? termine;
}
