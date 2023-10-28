import 'package:schueler_portal/api/response_models/api/stundenplan.dart';

class Tools {
  static DateTime hourStartToDateTime(int hour, DateTime day) {
    // hour is not zero based!

    DateTime local = day.toLocal();

    switch (hour) {
      case 1:
        return DateTime(local.year, local.month, local.day, 07, 55);
      case 2:
        return DateTime(local.year, local.month, local.day, 08, 40);
      case 3:
        return DateTime(local.year, local.month, local.day, 09, 35);
      case 4:
        return DateTime(local.year, local.month, local.day, 10, 20);
      case 5:
        return DateTime(local.year, local.month, local.day, 11, 25);
      case 6:
        return DateTime(local.year, local.month, local.day, 12, 10);
      case 7:
        return DateTime(local.year, local.month, local.day, 13, 15);
      case 8:
        return DateTime(local.year, local.month, local.day, 14, 00);
      case 9:
        return DateTime(local.year, local.month, local.day, 14, 45);
      case 10:
        return DateTime(local.year, local.month, local.day, 15, 30);
      case 11:
        return DateTime(local.year, local.month, local.day, 16, 15);
      case 12:
        return DateTime(local.year, local.month, local.day, 17, 00);
      case 13:
        return DateTime(local.year, local.month, local.day, 17, 45);
      case 14:
        return DateTime(local.year, local.month, local.day, 18, 30);
      case 15:
        return DateTime(local.year, local.month, local.day, 19, 15);
    }

    throw Exception();
  }

  static DateTime hourEndToDateTime(int hour, DateTime day) =>
      hourStartToDateTime(hour, day).add(const Duration(minutes: 45));

  static DateTime addDaysToDateTime(DateTime day, int days, bool skipWeekend) {
    if (skipWeekend) {
      if (days < 0) {
        if (day.weekday == DateTime.monday) {
          return day.subtract(const Duration(days: 3));
        } else if (day.weekday == DateTime.sunday) {
          return day.subtract(const Duration(days: 2));
        }
      } else {
        if (day.weekday == DateTime.friday) {
          return day.add(const Duration(days: 3));
        } else if (day.weekday == DateTime.saturday) {
          return day.add(const Duration(days: 2));
        }
      }
    }

    return day.add(Duration(days: days));
  }

  static Set<String> getStundenplanCourses(List<Datum> stundenplanData) =>
      stundenplanData.map((datum) => datum.uf).toSet();
}
