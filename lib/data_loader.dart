import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben/past/vergangene_hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/unterricht.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';
import 'package:schueler_portal/custom_widgets/my_future_builder.dart';
import 'package:schueler_portal/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/response_models/api/chat.dart';
import 'api/response_models/api/news.dart';
import 'api/response_models/api/termine.dart';
import 'api/response_models/api/user.dart';

class DataLoader {
  static final cache = ApiCache();

  static final _completers = <Completer<ApiResponse>>[];
  static List<Future<ApiResponse>> _futures = [];

  static var chatCompleter = Completer<ApiResponse<List<Chat>>>();
  static var newsCompleter = Completer<ApiResponse<List<News>>>();
  static var userCompleter = Completer<ApiResponse<User>>();
  static var stundenplanCompleter = Completer<ApiResponse<Stundenplan>>();
  static var vertretungsplanCompleter =
      Completer<ApiResponse<Vertretungsplan>>();
  static var hausaufgabenCompleter =
      Completer<ApiResponse<List<Hausaufgabe>>>();
  static var termineCompleter = Completer<ApiResponse<Termine>>();

  static Future<List<ApiResponse>> cacheData({bool showProgress = true}) {
    chatCompleter = Completer<ApiResponse<List<Chat>>>();
    newsCompleter = Completer<ApiResponse<List<News>>>();
    userCompleter = Completer<ApiResponse<User>>();
    stundenplanCompleter = Completer<ApiResponse<Stundenplan>>();
    vertretungsplanCompleter = Completer<ApiResponse<Vertretungsplan>>();
    hausaufgabenCompleter = Completer<ApiResponse<List<Hausaufgabe>>>();
    termineCompleter = Completer<ApiResponse<Termine>>();

    _addCompleter(chatCompleter, cache.chats.fetchData());
    _addCompleter(newsCompleter, cache.news.fetchData());
    _addCompleter(userCompleter, cache.user.fetchData());
    _addCompleter(stundenplanCompleter, cache.stundenplan.fetchData());
    _addCompleter(vertretungsplanCompleter, cache.vertretungsplan.fetchData());
    _addCompleter(hausaufgabenCompleter, cache.hausaufgaben.fetchData());
    _addCompleter(termineCompleter, cache.termine.fetchData());

    _futures = _completers.map((completer) => completer.future).toList();

    if (showProgress) _showProgressOfCaching();

    return Future.wait(_futures);
  }

  static void _addCompleter(
      Completer<ApiResponse> completer, Future fetchDataFuture) {
    _completers.add(completer);
    fetchDataFuture.then((_) => completer.complete(_));
  }

  static Future<void> _showProgressOfCaching() async {
    while (snackbarKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    int completedFunctions = 0;
    snackbarKey.currentState!.showMaterialBanner(
      MaterialBanner(
        elevation: 1,
        content: StatefulBuilder(
          builder: (context, setState) {
            return MyFutureBuilder(
              future: progressWait(_futures, (completed, total) {
                if (completed <= completedFunctions) return;
                setState(() {
                  completedFunctions = completed;
                });
              }),
              loadingIndicator: Row(
                children: [
                  const Text("Lade neue Daten"),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                        value: completedFunctions / _futures.length),
                  ),
                ],
              ),
              customBuilder: (context, data) {
                if (data.every((element) => element.statusCode == 200)) {
                  return const Text("Fertig");
                }

                if (data.every((element) => element.statusCode == 499)) {
                  return const Row(
                    children: [
                      Icon(Icons.cloud_off),
                      SizedBox(width: 10),
                      Text("Offline"),
                    ],
                  );
                }

                return const Text("Fehler beim laden neuer Daten");
              },
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: snackbarKey.currentState!.hideCurrentMaterialBanner,
            icon: const Icon(Icons.close),
          )
        ],
      ),
    );

    Future.wait(_futures).then((value) async {
      await Future.delayed(const Duration(milliseconds: 3000));
      snackbarKey.currentState!.clearMaterialBanners();
    });
  }

  static Future<List<T>> progressWait<T>(
    List<Future<T>> futures,
    void Function(int completed, int total) progress,
  ) {
    int total = futures.length;
    int completed = 0;

    void complete() {
      completed++;
      progress(completed, total);
    }

    return Future.wait<T>(
        [for (Future<T> future in futures) future.whenComplete(complete)]);
  }

  // Function to cancel and reset the operations
  static cancelAndReset() {
    for (Completer<ApiResponse> completer in _completers) {
      if (!completer.isCompleted) {
        completer.completeError("Operation canceled");
      }
    }
    _completers.clear();
    _futures.clear();
  }

  static Future<ApiResponse<User>> getUser() => userCompleter.future;

  static Future<ApiResponse<Vertretungsplan>> getVertretungsplan() =>
      vertretungsplanCompleter.future;

  static Future<ApiResponse<Stundenplan>> getStundenplan() =>
      stundenplanCompleter.future;

  static Future<ApiResponse<List<News>>> getNews() => newsCompleter.future;

  static Future<ApiResponse<List<Chat>>> getChats() => chatCompleter.future;

  static Future<ApiResponse<List<Hausaufgabe>>> getHausaufgaben() =>
      hausaufgabenCompleter.future;

  static Future<ApiResponse<Termine>> getTermine() => termineCompleter.future;

  static Future<ApiResponse<List<Unterricht>>> getUnterricht(
      DateTime day) async {
    if (!cache.unterricht.containsKey(day)) {
      ApiResponse<List<Unterricht>> unterricht = await ApiClient.getAndParse(
        "/unterricht/${DateFormat("yyyy-MM-dd").format(day)}",
        unterrichtFromJson,
      );

      cache.unterricht[day] = unterricht;
    }

    return cache.unterricht[day]!;
  }

  static Future<ApiResponse<VergangeneHausaufgaben>> getPastHomework(
      int page) async {
    if (!cache.pastHomework.containsKey(page)) {
      ApiResponse<VergangeneHausaufgaben> ha = await ApiClient.getAndParse(
        "/hausaufgaben/past/sorted/$page",
        vergangeneHausaufgabenFromJson,
      );

      cache.pastHomework[page] = ha;
    }

    return cache.pastHomework[page]!;
  }
}

class ApiCache {
  final LocallyCachedApiData<User> user = LocallyCachedApiData(
    "/user",
    (p0) => userFromJson(p0),
    (p0) => userToJson(p0),
    () => ApiClient.getAndParse("/user", userFromJson),
  );

  final LocallyCachedApiData<Vertretungsplan> vertretungsplan =
      LocallyCachedApiData(
    "/vertretungsplan",
    (p0) => vertretungsplanFromJson(p0),
    (p0) => vertretungsplanToJson(p0),
    () => ApiClient.getAndParse("vertretungsplan", vertretungsplanFromJson),
  );

  final LocallyCachedApiData<Stundenplan> stundenplan = LocallyCachedApiData(
    "/stundenplan",
    (p0) => stundenplanFromJson(p0),
    (p0) => stundenplanToJson(p0),
    () => ApiClient.getAndParse("/stundenplan", stundenplanFromJson),
  );

  final LocallyCachedApiData<List<News>> news = LocallyCachedApiData(
    "/news",
    (p0) => newsFromJson(p0),
    (p0) => newsToJson(p0),
    () => ApiClient.getAndParse("/news", newsFromJson),
  );

  final LocallyCachedApiData<List<Chat>> chats = LocallyCachedApiData(
    "/chat",
    (p0) => chatFromJson(p0),
    (p0) => chatToJson(p0),
    () => ApiClient.getAndParse("/chat", chatFromJson),
  );

  final LocallyCachedApiData<List<Hausaufgabe>> hausaufgaben =
      LocallyCachedApiData(
    "/hausaufgaben",
    (p0) => hausaufgabeFromJson(p0),
    (p0) => hausaufgabeToJson(p0),
    () => ApiClient.getAndParse("/hausaufgaben", hausaufgabeFromJson),
  );

  final LocallyCachedApiData<Termine> termine = LocallyCachedApiData(
    "/termine",
    (p0) => termineFromJson(p0),
    (p0) => termineToJson(p0),
    () => ApiClient.getAndParse("/termine", termineFromJson),
  );

  final Map<DateTime, ApiResponse<List<Unterricht>>> unterricht = {};
  final Map<int, ApiResponse<VergangeneHausaufgaben>> pastHomework = {};
}

class LocallyCachedApiData<T> {
  T? _data;

  static late final SharedPreferences prefs;
  final T Function(String) toObjectParser;
  final String Function(T) toStringParser;
  final Future<ApiResponse<T>> Function() dataInitializer;
  final String identifier;

  LocallyCachedApiData(
    this.identifier,
    this.toObjectParser,
    this.toStringParser,
    this.dataInitializer,
  );

  Future<void> setData(T data) async {
    _data = data;
    await prefs.setString(identifier, toStringParser(data));
  }

  Future<ApiResponse<T>> fetchData() async {
    ApiResponse<T> res = await dataInitializer();
    if (res.data != null) await setData(res.data as T);
    return res;
  }

  T? getCached() {
    if (_data == null) {
      // Data has not been stored in memory

      String? loadedString = prefs.getString(identifier);

      if (loadedString == null) return null;

      // Data was not stored in storage

      T parsed = toObjectParser(loadedString);
      setData(parsed);

      return parsed;
    }

    return _data;
  }

  static Future<void> init() async =>
      prefs = await SharedPreferences.getInstance();
}
