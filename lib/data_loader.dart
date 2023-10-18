import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart';
import 'package:schueler_portal/main.dart';

import 'api/response_models/api/chat.dart';
import 'api/response_models/api/news.dart';
import 'api/response_models/api/user.dart';

class DataLoader {
  static Stundenplan? cachedStundenplan;
  static Vertretungsplan? cachedVertretungsplan;
  static List<News>? cachedNews;
  static List<Hausaufgabe>? cachedHomework;
  static List<Chat>? cachedChats;
  static User? cachedUser;

  static fetchData() {
    apiClient.getUser().then((value) => cachedUser = value);
    apiClient.getNews().then((value) => cachedNews = value);
    apiClient.getStundenplan().then((value) => cachedStundenplan = value);
    apiClient
        .getVertretungsplan()
        .then((value) => cachedVertretungsplan = value);
    apiClient.getHomework().then((value) => cachedHomework = value);
    apiClient.getChats().then((value) => cachedChats = value);
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

  static Future<List<Chat>> getChats() async {
    while (cachedChats == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cachedChats!;
  }

  static Future<User> getUser() async {
    while (cachedUser == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return cachedUser!;
  }
}
