import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
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

  static Future<void> cacheData() async {
    chatCompleter = Completer<ApiResponse<List<Chat>>>();
    newsCompleter = Completer<ApiResponse<List<News>>>();
    userCompleter = Completer<ApiResponse<User>>();
    stundenplanCompleter = Completer<ApiResponse<Stundenplan>>();
    vertretungsplanCompleter = Completer<ApiResponse<Vertretungsplan>>();
    hausaufgabenCompleter = Completer<ApiResponse<List<Hausaufgabe>>>();
    termineCompleter = Completer<ApiResponse<Termine>>();

    _completers.addAll([
      chatCompleter,
      newsCompleter,
      userCompleter,
      stundenplanCompleter,
      vertretungsplanCompleter,
      hausaufgabenCompleter,
      termineCompleter,
    ]);

    cache.chats.fetchData().then((_) => chatCompleter.complete(_));
    cache.news.fetchData().then((_) => newsCompleter.complete(_));
    cache.user.fetchData().then((_) => userCompleter.complete(_));
    cache.stundenplan.fetchData().then((_) => stundenplanCompleter.complete(_));
    cache.vertretungsplan
        .fetchData()
        .then((_) => vertretungsplanCompleter.complete(_));
    cache.hausaufgaben
        .fetchData()
        .then((_) => hausaufgabenCompleter.complete(_));
    cache.termine.fetchData().then((_) => termineCompleter.complete(_));

    _futures = _completers.map((completer) => completer.future).toList();

    while (snackbarKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    Future<List<ApiResponse>> future = Future.wait(_futures);

    snackbarKey.currentState!.showMaterialBanner(
      MaterialBanner(
        elevation: 1,
        content: StatefulBuilder(
          builder: (context, setState) {
            return MyFutureBuilder(
              future: future,
              loadingIndicator: const Row(
                children: [
                  Text("Lade neue Daten"),
                  SizedBox(width: 10),
                  Expanded(child: LinearProgressIndicator()),
                ],
              ),
              customBuilder: (context, data) => const Text("Fertig"),
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

    await future;
    await Future.delayed(const Duration(milliseconds: 1000));
    snackbarKey.currentState!.clearMaterialBanners();
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
  final LocallyCachedApiData<User> user = LocallyCachedApiData(
    "/user",
    (p0) => userFromJson(p0),
    (p0) => userToJson(p0),
    () => ApiClient.putAndParse("/user", userFromJson),
  );

  final LocallyCachedApiData<Vertretungsplan> vertretungsplan =
      LocallyCachedApiData(
    "/vertretungsplan",
    (p0) => vertretungsplanFromJson(p0),
    (p0) => vertretungsplanToJson(p0),
    () => ApiClient.putAndParse("vertretungsplan", vertretungsplanFromJson),
  );

  final LocallyCachedApiData<Stundenplan> stundenplan = LocallyCachedApiData(
    "/stundenplan",
    (p0) => stundenplanFromJson(p0),
    (p0) => stundenplanToJson(p0),
    () => ApiClient.putAndParse("/stundenplan", stundenplanFromJson),
  );

  final LocallyCachedApiData<List<News>> news = LocallyCachedApiData(
    "/news",
    (p0) => newsFromJson(p0),
    (p0) => newsToJson(p0),
    () => ApiClient.putAndParse("/news", newsFromJson),
  );

  final LocallyCachedApiData<List<Chat>> chats = LocallyCachedApiData(
    "/chat",
    (p0) => chatFromJson(p0),
    (p0) => chatToJson(p0),
    () => ApiClient.putAndParse("/chat", chatFromJson),
  );

  final LocallyCachedApiData<List<Hausaufgabe>> hausaufgaben =
      LocallyCachedApiData(
    "/hausaufgaben",
    (p0) => hausaufgabeFromJson(p0),
    (p0) => hausaufgabeToJson(p0),
    () => ApiClient.putAndParse("/hausaufgaben", hausaufgabeFromJson),
  );

  final LocallyCachedApiData<Termine> termine = LocallyCachedApiData(
    "/termine",
    (p0) => termineFromJson(p0),
    (p0) => termineToJson(p0),
    () => ApiClient.putAndParse("/termine", termineFromJson),
  );

  final Map<DateTime, ApiResponse<List<Unterricht>>> unterricht = {};
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
    if (res.data != null) setData(res.data as T);
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

    return _data!;
  }

  static Future<void> init() async =>
      prefs = await SharedPreferences.getInstance();
}
