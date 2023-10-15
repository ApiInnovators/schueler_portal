import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';
import 'package:schueler_portal/main.dart';

class DataLoader {

  static Stundenplan? _cachedStundenplan;
  static Vertretungsplan? _cachedVertretungsplan;

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
}