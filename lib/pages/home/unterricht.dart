import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/api/response_models/api/unterricht.dart';
import 'package:schueler_portal/custom_widgets/aligned_text.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/custom_widgets/file_download_button.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/tools.dart';
import 'package:string_to_color/string_to_color.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class UnterrichtWidget extends StatefulWidget {
  const UnterrichtWidget({super.key});

  @override
  State<UnterrichtWidget> createState() => _UnterrichtWidgetState();
}

class _UnterrichtWidgetState extends State<UnterrichtWidget> {
  DateTime userRequestedDate = DateTime.now().dayOnly();
  final _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    _calendarController.displayDate = userRequestedDate;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unterricht"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                DataLoader.cache.unterricht.remove(userRequestedDate);
                await DataLoader.getUnterricht(userRequestedDate);
                setState(() {});
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: CachingFutureBuilder<List<Unterricht>>(
                    future: DataLoader.getUnterricht(userRequestedDate),
                    cacheGetter: () =>
                        DataLoader.cache.unterricht[userRequestedDate]?.data,
                    builder: (context, data) {
                      List<Unterricht> unterricht = data;

                      if (unterricht.isEmpty) {
                        return const Center(
                          child: Text("Keine Unterrichtsinhalte"),
                        );
                      }

                      int lastHour = unterricht
                          .reduce((currentUnterricht, nextUnterricht) =>
                              currentUnterricht.hourTo > nextUnterricht.hourTo
                                  ? currentUnterricht
                                  : nextUnterricht)
                          .hourTo;

                      DateTime endTime = Tools.hourEndToDateTime(
                        lastHour,
                        userRequestedDate,
                      );

                      return SfCalendar(
                        controller: _calendarController,
                        view: CalendarView.day,
                        viewNavigationMode: ViewNavigationMode.none,
                        firstDayOfWeek: 1,
                        dataSource: UnterrichtDataSource(unterricht),
                        timeSlotViewSettings: TimeSlotViewSettings(
                          startHour: 7.0 + 55.0 / 60.0,
                          endHour: endTime.hour + endTime.minute / 60.0,
                          timeIntervalHeight: -1,
                          timeFormat: "HH:mm",
                        ),
                        onTap: calenderTapped,
                        appointmentBuilder: appointmentBuilder,
                      );
                    }),
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
                    userRequestedDate =
                        Tools.addDaysToDateTime(userRequestedDate, -1, true);
                  });
                },
              ),
              Center(
                child: Text(
                    DateFormat("EEEE - dd.MM.yyyy").format(userRequestedDate)),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () {
                  setState(() {
                    userRequestedDate =
                        Tools.addDaysToDateTime(userRequestedDate, 1, true);
                  });
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  calenderTapped(CalendarTapDetails details) {
    if (details.targetElement != CalendarElement.appointment &&
        details.targetElement != CalendarElement.agenda) return;

    Unterricht unterricht = details.appointments![0] as Unterricht;

    showDialog(
      context: context,
      builder: (context) => UnterrichtDetailsWidget(unterricht: unterricht),
    );
  }

  Widget appointmentBuilder(
      BuildContext context, CalendarAppointmentDetails details) {
    final Unterricht u = details.appointments.first;

    final Color backgroundColor = ColorUtils.stringToColor(u.subject.short);
    Color foregroundColor = (backgroundColor.red * 0.299 +
                backgroundColor.green * 0.587 +
                backgroundColor.blue * 0.114) >
            200
        ? Colors.black
        : Colors.white;

    Color filesColor = Theme.of(context).colorScheme.onSecondaryContainer;

    return Container(
      width: details.bounds.width,
      height: details.bounds.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "${u.subject.long} - ${u.teacher}",
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (u.content.files.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                      ),
                      height: 15,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        child: Row(
                          children: [
                            Text(
                              u.content.files.length.toString(),
                              style: TextStyle(color: filesColor),
                            ),
                            Icon(Icons.attachment, color: filesColor),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Flexible(
              child: Text(
                u.content.text.trim(),
                style: TextStyle(color: foregroundColor),
                overflow: TextOverflow.fade,
              ),
            ),
            if (u.homework != null) ...[
              const Divider(),
              Text(
                "Hausaufgabe bis zum ${DateFormat("dd.MM.yyyy").format(u.date)}:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                ),
              ),
              Flexible(
                child: Text(
                  u.homework!.homework.trim(),
                  style: TextStyle(color: foregroundColor),
                  overflow: TextOverflow.fade,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class UnterrichtDetailsWidget extends StatelessWidget {
  final Unterricht unterricht;

  const UnterrichtDetailsWidget({super.key, required this.unterricht});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(10),
      scrollable: true,
      title: Text(unterricht.subject.long),
      content: Column(
        children: [
          AlignedText.fromString(unterricht.content.text.trim()),
          if (unterricht.content.files.isNotEmpty) ...[
            const Divider(),
            for (FileElement file in unterricht.content.files)
              FileDownloadButton(file: file),
          ],
          if (unterricht.homework != null) ...[
            const Divider(),
            const AlignedText(
              text: Text(
                "Hausaufgabe",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            AlignedText.fromString(unterricht.homework!.homework.trim()),
            AlignedText(
              text: Text(
                "Zu erledigen bis: ${DateFormat("dd.MM.yyyy").format(unterricht.homework!.dueAt)}",
                style: const TextStyle(fontSize: 10),
              ),
            ),
            for (FileElement file in unterricht.homework!.files)
              FileDownloadButton(file: file),
          ],
          const Divider(),
          Text("- ${unterricht.teacher}"),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Ok'),
        ),
      ],
    );
  }
}

class UnterrichtDataSource extends CalendarDataSource {
  final List<Unterricht> unterricht;

  UnterrichtDataSource(this.unterricht) {
    appointments = unterricht;
  }

  @override
  DateTime getStartTime(int index) => Tools.hourStartToDateTime(
        unterricht[index].hourFrom,
        unterricht[index].date,
      );

  @override
  DateTime getEndTime(int index) => Tools.hourEndToDateTime(
        unterricht[index].hourTo,
        unterricht[index].date,
      );

  @override
  String getSubject(int index) {
    final u = unterricht[index];
    return "${u.subject.long}\n${u.content.text}".trim();
  }

  @override
  String? getNotes(int index) {
    final u = unterricht[index];
    return '''${u.content.files.length};${u.homework != null}''';
  }

  @override
  Color getColor(int index) =>
      ColorUtils.stringToColor(unterricht[index].subject.long);
}
