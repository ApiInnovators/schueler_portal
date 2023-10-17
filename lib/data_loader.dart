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

  static bool _loadsData = false;
  static bool _requestedRefresh = false;

  static bool isFetchingData() {
    return _loadsData;
  }

  static Future<void> fetchData() async {
    if (_loadsData) {
      _requestedRefresh = true;
      return;
    }

    _loadsData = true;

    _cachedStundenplan = await apiClient.getStundenplan();
    _cachedVertretungsplan = await apiClient.getVertretungsplan();
    _cachedNews = await apiClient.getNews();
    _cachedHomework = await apiClient.getHomework();

    _loadsData = false;

    if (_requestedRefresh) {
      _requestedRefresh = false;
      await fetchData();
    }
  }

  static Future<void> awaitFetch() async {
    while (_loadsData) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<Stundenplan> getStundenplan() async {
    await awaitFetch();
    return _cachedStundenplan!;
  }

  static Future<Vertretungsplan> getVertretungsplan() async {
    await awaitFetch();
    return _cachedVertretungsplan!;
  }

  static Future<List<News>> getNews() async {
    await awaitFetch();
    return _cachedNews!;
  }

  static Future<List<Hausaufgabe>> getHomework() async {
    await awaitFetch();
    return _cachedHomework!;
  }
}