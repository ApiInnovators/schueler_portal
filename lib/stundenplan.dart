import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart'
    as vertretungsplan_package;
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/user_data.dart';

import 'api/response_models/api/stundenplan.dart' as stundenplan_package;

class StundenplanContainer extends StatefulWidget {
  const StundenplanContainer({super.key});

  @override
  State<StatefulWidget> createState() => _StundenplanContainer();
}

class _StundenplanContainer extends State<StatefulWidget> {
  late DateTime userRequestedDate;
  bool showOnlyUsersLessons = true;

  _StundenplanContainer() {
    userRequestedDate = DateTime.now();
    if (userRequestedDate.weekday == DateTime.sunday) {
      userRequestedDate = userRequestedDate.add(const Duration(days: 1));
    } else if (userRequestedDate.weekday == DateTime.saturday)
      userRequestedDate = userRequestedDate.add(const Duration(days: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stundenplan"),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 10, right: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Nur deine Stunden"),
                Switch(
                    value: showOnlyUsersLessons,
                    onChanged: (value) {
                      setState(() {
                        showOnlyUsersLessons = value;
                      });
                    }),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    FutureBuilder(
                      future: DataLoader.getStundenplan(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.done) {
                          if (snapshot.hasData) {
                            return StundenplanWidget(
                              scheduleData: snapshot.data
                                  as stundenplan_package.Stundenplan,
                              stundenplanContainer: this,
                            );
                          } else {
                            return const Text("Error: Data not available");
                          }
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                    const SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          "Vertretungsplan",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    FutureBuilder(
                      future: DataLoader.getVertretungsplan(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.done) {
                          if (snapshot.hasData) {
                            return VertretungsplanWidget(
                              vertretungsplanData: snapshot.data
                                  as vertretungsplan_package.Vertretungsplan,
                              stundenplanContainer: this,
                            );
                          } else {
                            return const Text("Error: Data not available");
                          }
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () {
                    setState(() {
                      if (userRequestedDate.weekday == DateTime.monday) {
                        userRequestedDate =
                            userRequestedDate.subtract(const Duration(days: 3));
                      } else if (userRequestedDate.weekday == DateTime.sunday) {
                        userRequestedDate =
                            userRequestedDate.subtract(const Duration(days: 2));
                      } else {
                        userRequestedDate =
                            userRequestedDate.subtract(const Duration(days: 1));
                      }
                    });
                  },
                ),
                Center(
                  child: Text(DateFormat("EEEE - dd.MM.yyyy")
                      .format(userRequestedDate)),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () {
                    setState(() {
                      if (userRequestedDate.weekday == DateTime.friday) {
                        userRequestedDate =
                            userRequestedDate.add(const Duration(days: 3));
                      } else if (userRequestedDate.weekday ==
                          DateTime.saturday) {
                        userRequestedDate =
                            userRequestedDate.add(const Duration(days: 2));
                      } else {
                        userRequestedDate =
                            userRequestedDate.add(const Duration(days: 1));
                      }
                    });
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StundenplanWidget extends StatefulWidget {
  final stundenplan_package.Stundenplan scheduleData;
  final _StundenplanContainer stundenplanContainer;

  const StundenplanWidget(
      {super.key,
      required this.scheduleData,
      required this.stundenplanContainer});

  @override
  State<StatefulWidget> createState() => _StundenplanWidget(
      stundenplanContainer: stundenplanContainer, scheduleData: scheduleData);
}

class _StundenplanWidget extends State<StundenplanWidget> {
  final stundenplan_package.Stundenplan scheduleData;
  final _StundenplanContainer stundenplanContainer;

  _StundenplanWidget(
      {required this.stundenplanContainer, required this.scheduleData});

  Map<int, Map<int, List<stundenplan_package.Datum>>>
      groupLessonsByDayAndHour() {
    List<stundenplan_package.Datum> stundenplan = scheduleData.data;
    Map<int, Map<int, List<stundenplan_package.Datum>>> grouped = {};

    for (final lesson in stundenplan) {
      if (stundenplanContainer.showOnlyUsersLessons &&
          !UserData.registeredCourses.contains(lesson.uf)) {
        continue;
      }

      grouped.putIfAbsent(
          lesson.day, () => <int, List<stundenplan_package.Datum>>{});
      grouped[lesson.day]!
          .putIfAbsent(lesson.hour, () => <stundenplan_package.Datum>[]);

      grouped[lesson.day]![lesson.hour]!.add(lesson);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    var grouped = groupLessonsByDayAndHour();
    int weekday = stundenplanContainer.userRequestedDate.weekday - 1;

    if (!grouped.containsKey(weekday)) {
      return const Center(child: Text("Kein Unterricht"));
    }

    Map<int, List<stundenplan_package.Datum>> usersLessonsToday =
        grouped[weekday]!;

    Table table = Table(
      border: TableBorder.symmetric(inside: const BorderSide(width: 1)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: List.empty(growable: true),
    );

    int lastLesson = usersLessonsToday.keys.reduce(max);

    for (int i = 0; i < lastLesson; ++i) {
      String time = scheduleData.zeittafel[i].value;
      int hour = scheduleData.zeittafel[i].hour;

      TableRow tableRow = TableRow(children: <Widget>[
        Container(
          height: 40,
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Center(
            child: Text("$hour. $time", textAlign: TextAlign.center),
          ),
        ),
      ]);

      if (usersLessonsToday.containsKey(i + 1)) {
        String text = "";

        for (stundenplan_package.Datum element in usersLessonsToday[i + 1]!) {
          text += "\n${element.uf}";
          if (element.room != null) {
            text += " (${element.room})";
          }
        }

        tableRow.children.add(Center(child: Text(text.trim())));
      } else {
        tableRow.children.add(const SizedBox.shrink());
      }

      table.children.add(tableRow);
    }

    return Container(
        decoration: BoxDecoration(
            border: Border.all(width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(10))),
        child: table);
  }
}

class VertretungsplanWidget extends StatefulWidget {
  final vertretungsplan_package.Vertretungsplan vertretungsplanData;
  final _StundenplanContainer stundenplanContainer;

  const VertretungsplanWidget(
      {super.key,
      required this.stundenplanContainer,
      required this.vertretungsplanData});

  @override
  State<StatefulWidget> createState() => _VertretungsplanWidget(
        vertretungsplanData: vertretungsplanData,
        stundenplanContainer: stundenplanContainer,
      );
}

class _VertretungsplanWidget extends State<StatefulWidget> {
  final vertretungsplan_package.Vertretungsplan vertretungsplanData;
  final _StundenplanContainer stundenplanContainer;

  _VertretungsplanWidget(
      {required this.stundenplanContainer, required this.vertretungsplanData});

  Iterable<vertretungsplan_package.Datum> filterUserVertretung(
      List<vertretungsplan_package.Datum> data, DateTime date) sync* {
    for (final item in data) {
      if (date.isSameDate(item.date) &&
          (!stundenplanContainer.showOnlyUsersLessons ||
              UserData.registeredCourses.contains(item.uf))) {
        yield item;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Iterable<vertretungsplan_package.Datum> filteredUserVertretung =
        filterUserVertretung(
            vertretungsplanData.data, stundenplanContainer.userRequestedDate);

    if (filteredUserVertretung.isEmpty) {
      return const Text("Keine Vertretungen/Daten");
    }

    Table table = Table(
      border: TableBorder.symmetric(inside: const BorderSide(width: 1)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: List.empty(growable: true),
    );

    List<String> titles = [
      "Std.",
      "Betrifft",
      "Vertretung",
      "Fach",
      "Raum",
      "Grund"
    ];

    table.children.add(TableRow(
        children: List.generate(titles.length, (i) {
      return SizedBox(
          height: 40,
          child: Center(
              child: Text(
            titles[i],
            style: const TextStyle(fontWeight: FontWeight.bold),
          )));
    })));

    for (vertretungsplan_package.Datum element in filteredUserVertretung) {
      List<String> cellStrings = [
        element.hour.toString(),
        element.absTeacher,
        element.vertrTeacher,
        element.uf,
        element.room,
        element.reason
      ];

      TableRow tableRow = TableRow(
          children: List.generate(cellStrings.length, (i) {
        return SizedBox(
          height: 40,
          child: Center(
              child: Text(cellStrings[i].isEmpty ? "-" : cellStrings[i])),
        );
      }));

      table.children.add(tableRow);
    }

    return Container(
        decoration: BoxDecoration(
            border: Border.all(width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(10))),
        child: table);
  }
}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
