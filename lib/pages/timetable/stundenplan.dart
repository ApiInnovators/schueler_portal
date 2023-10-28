import 'package:flutter/material.dart';
import 'package:schueler_portal/api/api_client.dart';
import 'package:schueler_portal/api/response_models/api/vertretungsplan.dart'
    as vertretungsplan_package;
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/custom_widgets/my_future_builder.dart';
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
        Divider(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              DataLoader.cache.vertretungsplan = null;
              DataLoader.cache.stundenplan = null;
              DataLoader.cacheData();
              await DataLoader.getStundenplan();
              await DataLoader.getVertretungsplan();
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 600,
                child: MyFutureBuilder(
                  future: getData(),
                  customBuilder: (context, snapshot) => StundenplanWidget(
                    scheduleData: snapshot.data!.$1.data!,
                    vertretungsplan: snapshot.data!.$2.data!,
                    showOnlyUsersLessons: showOnlyUsersLessons,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<
          (
            ApiResponse<stundenplan_package.Stundenplan>,
            ApiResponse<vertretungsplan_package.Vertretungsplan>
          )>
      getData() async => (
            await DataLoader.getStundenplan(),
            await DataLoader.getVertretungsplan()
          );
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

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now().toLocal();
    DateTime today = DateTime(now.year, now.month, now.day);

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
          vertretungsplan.data,
          showOnlyUsersLessons),
      view: lastCalendarView,
      allowedViews: const [
        CalendarView.day,
        CalendarView.schedule,
      ],
      showNavigationArrow: true,
      showDatePickerButton: true,
      allowViewNavigation: true,
      firstDayOfWeek: DateTime.monday,
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7.0 + 55.0 / 60.0,
        endHour: 18.0 + 15.0 / 60.0,
        nonWorkingDays: [DateTime.saturday, DateTime.sunday],
      ),
      minDate: today.subtract(Duration(days: today.weekday - 1)),
    );
  }
}

class StundenplanDataSource extends CalendarDataSource {
  final List<stundenplan_package.Datum> stunden;
  final List<vertretungsplan_package.Datum> vertretungen;
  final bool onlyUsersLessons;

  StundenplanDataSource(
    this.stunden,
    this.vertretungen,
    this.onlyUsersLessons,
  ) {
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

  @override
  DateTime getStartTime(int index) {
    DateTime now = DateTime.now().toLocal();

    return Tools.hourStartToDateTime(
      stunden[index].hour,
      DateTime(now.year, now.month, stunden[index].day),
    );
  }

  @override
  DateTime getEndTime(int index) {
    DateTime now = DateTime.now().toLocal();

    return Tools.hourEndToDateTime(
      stunden[index].hour,
      DateTime(now.year, now.month, stunden[index].day),
    );
  }

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
  String getSubject(int index) {
    stundenplan_package.Datum stunde = stunden[index];
    String subject = stunde.uf;

    if (stunde.room != null) subject += " (${stunde.room})";

    vertretungsplan_package.Datum? vertretung = findVertretung(stunde);

    if (vertretung != null) subject += " - ${vertretung.reason}";

    return subject;
  }

  @override
  Color getColor(int index) => ColorUtils.stringToColor(stunden[index].uf);
}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
