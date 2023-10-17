import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';
import 'package:schueler_portal/main.dart';

import 'api/response_models/api/news.dart';

class DataLoader {
  static Stundenplan? cachedStundenplan;
  static Vertretungsplan? cachedVertretungsplan;
  static List<News>? cachedNews;
  static List<Hausaufgabe>? cachedHomework;

  static fetchData() {
    apiClient.getNews().then((value) => cachedNews = value);
    apiClient.getStundenplan().then((value) => cachedStundenplan = value);
    apiClient
        .getVertretungsplan()
        .then((value) => cachedVertretungsplan = value);
    apiClient.getHomework().then((value) => cachedHomework = value);
  }

  static Future<Stundenplan> getStundenplan() async {
    while (cachedStundenplan == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cachedStundenplan!;
  }

  static Future<Vertretungsplan> getVertretungsplan() async {
    while (cachedVertretungsplan == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cachedVertretungsplan!;
  }

  static Future<List<News>> getNews() async {
    while (cachedNews == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cachedNews!;
  }

  static Future<List<Hausaufgabe>> getHomework() async {
    while (cachedHomework == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cachedHomework!;
  }
}
