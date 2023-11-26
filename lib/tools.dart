import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:schueler_portal/api/response_models/api/stundenplan.dart';
import 'package:schueler_portal/globals.dart';

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

  static int? dateTimeToHour(DateTime dateTime) {
    for (int i = 1; i < 16; ++i) {
      final start = hourStartToDateTime(i, dateTime);
      if (DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour,
              dateTime.minute)
          .isAtSameMomentAs(start)) {
        return i;
      }
    }
    return null;
  }

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

  static void quickSnackbar(String text, {Icon? icon}) async {
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 30));
      return snackbarKey.currentState == null;
    }).timeout(const Duration(seconds: 6));
    log("Showing snackbar: $text");

    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        content: Row(
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(text)),
          ],
        ),
      ),
    );
  }

  static BaseRequest? copyRequest(BaseRequest request) {
    BaseRequest requestCopy;

    if (request is Request) {
      requestCopy = Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is MultipartRequest) {
      requestCopy = MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else {
      return null;
    }

    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return requestCopy;
  }

  static String? dateDeltaString(DateTime a, DateTime b) {
    a = a.dayOnly();
    b = b.dayOnly();
    final Duration diff = b.difference(a);

    switch (diff.inDays) {
      case -1:
        return "Gestern";
      case -2:
        return "Vorgestern";
      case 0:
        return "Heute";
      case 1:
        return "Morgen";
      case 2:
        return "Übermorgen";
    }

    return null;
  }
}

extension DateUtils on DateTime {
  DateTime dayOnly() {
    final local = toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
