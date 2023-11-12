import 'package:flutter/material.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart'
    as vertretungsplan_package;
import 'package:schueler_portal/custom_widgets/aligned_text.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/user_data.dart';
import 'package:string_to_color/string_to_color.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../api/response_models/api/stundenplan.dart' as stundenplan_package;
import '../../tools.dart';

class StundenplanContainer extends StatefulWidget {
  const StundenplanContainer({super.key});

  @override
  State<StatefulWidget> createState() => _StundenplanContainer();
}

class _StundenplanContainer extends State<StundenplanContainer> {
  DateTime userRequestedDate = DateTime.now();
  bool showOnlyUsersLessons = true;

  @override
  initState() {
    super.initState();
    if (userRequestedDate.weekday == DateTime.sunday) {
      userRequestedDate = userRequestedDate.add(const Duration(days: 1));
    } else if (userRequestedDate.weekday == DateTime.saturday) {
      userRequestedDate = userRequestedDate.add(const Duration(days: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, top: 8),
          child: Row(
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
        ),
        const Divider(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                DataLoader.cache.stundenplan.fetchData(),
                DataLoader.cache.vertretungsplan.fetchData(),
              ]);
              setState(() {});
            },
            child: MultiCachingFutureBuilder(
              futures: [
                DataLoader.getStundenplan(),
                DataLoader.getVertretungsplan()
              ],
              cacheGetter: () => [
                DataLoader.cache.stundenplan.getCached(),
                DataLoader.cache.vertretungsplan.getCached(),
              ],
              builder: (context, snapshot) {
                return StundenplanWidget(
                  scheduleData: snapshot.firstWhere(
                          (e) => e is stundenplan_package.Stundenplan)
                      as stundenplan_package.Stundenplan,
                  vertretungsplan: snapshot.firstWhere(
                          (e) => e is vertretungsplan_package.Vertretungsplan)
                      as vertretungsplan_package.Vertretungsplan,
                  showOnlyUsersLessons: showOnlyUsersLessons,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class StundenplanWidget extends StatelessWidget {
  final stundenplan_package.Stundenplan scheduleData;
  final vertretungsplan_package.Vertretungsplan vertretungsplan;
  final calendarController = CalendarController();
  final bool showOnlyUsersLessons;
  static DateTime lastDisplayedDate = DateTime.now();
  static CalendarView lastCalendarView = CalendarView.day;

  StundenplanWidget({
    super.key,
    required this.scheduleData,
    required this.vertretungsplan,
    required this.showOnlyUsersLessons,
  }) {
    calendarController.displayDate = lastDisplayedDate;
  }

  Widget appointmentBuilder(
      BuildContext context, CalendarAppointmentDetails details) {
    final Appointment appointment = details.appointments.first;

    int? hour = Tools.dateTimeToHour(appointment.startTime);
    Color backgroundColor = appointment.color;
    Color foregroundColor = (backgroundColor.red * 0.299 +
                backgroundColor.green * 0.587 +
                backgroundColor.blue * 0.114) >
            200
        ? Colors.black
        : Colors.white;

    return Container(
      width: details.bounds.width,
      height: details.bounds.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.all(Radius.circular(showOnlyUsersLessons ? 5 : 2)),
      ),
      child: (() {
        if (showOnlyUsersLessons && lastCalendarView != CalendarView.week) {
          String subj = "$hour. ${appointment.subject}";
          if (appointment.location != null) {
            subj += " (${appointment.location})";
          }

          if (appointment.notes != null && appointment.notes!.isNotEmpty) {
            if (appointment.notes!.contains("Grund: entfällt")) {
              subj += " - entfällt";
            } else {
              subj += " - Vertretung";
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: AlignedText(
              text: Text(subj, style: TextStyle(color: foregroundColor)),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              appointment.subject,
              style: TextStyle(color: foregroundColor),
            ),
          ),
        );
      }()),
    );
  }

  @override
  Widget build(BuildContext context) {
    scheduleData.data.sort((a, b) {
      int cmp1 = a.day - b.day;
      if (cmp1 != 0) return cmp1;

      int cmp2 = a.hour - b.hour;
      if (cmp2 != 0) return cmp2;

      return a.uf.compareTo(b.uf);
    });
    return SfCalendar(
      controller: calendarController,
      onViewChanged: (details) {
        if (details.visibleDates.length == 1) {
          lastDisplayedDate = details.visibleDates[0];
        }
        if (calendarController.view != null) {
          lastCalendarView = calendarController.view!;
        }
      },
      dataSource: StundenplanDataSource(
          showOnlyUsersLessons
              ? scheduleData.data
                  .where((element) => UserData.isCourseEnabled(element.uf))
                  .toList()
              : scheduleData.data,
          vertretungsplan.data),
      view: lastCalendarView,
      allowedViews: const [
        CalendarView.day,
        CalendarView.schedule,
        CalendarView.week,
      ],
      showNavigationArrow: true,
      showDatePickerButton: true,
      allowViewNavigation: true,
      firstDayOfWeek: DateTime.monday,
      appointmentBuilder: appointmentBuilder,
      onTap: (calendarTapDetails) => calendarTaped(context, calendarTapDetails),
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7.0 + 55.0 / 60.0,
        endHour: 18.0 + 15.0 / 60.0,
        nonWorkingDays: [DateTime.saturday, DateTime.sunday],
        timeFormat: "HH:mm",
        timeIntervalHeight: -1,
      ),
    );
  }

  void calendarTaped(
      BuildContext context, CalendarTapDetails calendarTapDetails) {
    if (calendarTapDetails.appointments == null) return;
    showDialog(
      context: context,
      builder: (context) {
        final Appointment appointment = calendarTapDetails.appointments!.first;
        return AlertDialog(
          title: Text(appointment.subject),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appointment.location != null)
                Text("Raum: ${appointment.location!}"),
              if (appointment.notes != null &&
                  appointment.notes!.isNotEmpty) ...[
                const Divider(),
                const Text(
                  "Vertretung",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(appointment.notes!),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }
}

class StundenplanDataSource extends CalendarDataSource {
  final List<stundenplan_package.Datum> stunden;
  final List<vertretungsplan_package.Datum> vertretungen;

  StundenplanDataSource(this.stunden, this.vertretungen) {
    appointments = stunden;
  }

  @override
  String getRecurrenceRule(int index) {
    String byDay = "";

    switch (stunden[index].day) {
      case 0:
        byDay = "MO";
        break;
      case 1:
        byDay = "TU";
        break;
      case 2:
        byDay = "WE";
        break;
      case 3:
        byDay = "TH";
        break;
      case 4:
        byDay = "FR";
        break;
    }

    return "FREQ=WEEKLY;INTERVAL=1;BYDAY=$byDay";
  }

  // The only thing that matters is that the weekdays are correct
  @override
  DateTime getStartTime(int index) => Tools.hourStartToDateTime(
        stunden[index].hour,
        DateTime(2018, 1, stunden[index].day + 1),
      );

  @override
  DateTime getEndTime(int index) => Tools.hourEndToDateTime(
        stunden[index].hour,
        DateTime(2018, 1, stunden[index].day + 1),
      );

  vertretungsplan_package.Datum? findVertretung(
      stundenplan_package.Datum stunde) {
    for (vertretungsplan_package.Datum vertretung in vertretungen) {
      if (vertretung.date.weekday - 1 == stunde.day &&
          vertretung.uf == stunde.uf &&
          vertretung.hour == stunde.hour) {
        return vertretung;
      }
    }
    return null;
  }

  @override
  String getSubject(int index) => stunden[index].uf;

  @override
  String? getLocation(int index) => stunden[index].room;

  @override
  String? getNotes(int index) {
    vertretungsplan_package.Datum? vertretung = findVertretung(stunden[index]);

    if (vertretung == null) return null;

    return """Betrifft: ${vertretung.absTeacher}
Vertretung: ${vertretung.vertrTeacher}
Vertretungs Fach: ${vertretung.vertrUf}
Raum: ${vertretung.room}
Grund: ${vertretung.reason}
${vertretung.text}""";
  }

  @override
  Color getColor(int index) => ColorUtils.stringToColor(stunden[index].uf);
}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
