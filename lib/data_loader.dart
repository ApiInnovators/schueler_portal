import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';
import 'package:schueler_portal/main.dart';

import 'api/response_models/api/news.dart';

class DataLoader {
  static Stundenplan? _cachedStundenplan;
  static Vertretungsplan? _cachedVertretungsplan;
  static List<News>? _cachedNews;
  static List<Hausaufgabe>? _cachedHomework;

  static fetchData() {
    apiClient.getNews().then((value) => _cachedNews = value);
    apiClient.getStundenplan().then((value) => _cachedStundenplan = value);
    apiClient
        .getVertretungsplan()
        .then((value) => _cachedVertretungsplan = value);
    apiClient.getHomework().then((value) => _cachedHomework = value);
  }

  static Future<Stundenplan> getStundenplan() async {
    while (_cachedStundenplan == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return _cachedStundenplan!;
  }

  static Future<Vertretungsplan> getVertretungsplan() async {
    while (_cachedVertretungsplan == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return _cachedVertretungsplan!;
  }

  static Future<List<News>> getNews() async {
    while (_cachedNews == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return _cachedNews!;
  }

  static Future<List<Hausaufgabe>> getHomework() async {
    while (_cachedHomework == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return _cachedHomework!;
  }
}
