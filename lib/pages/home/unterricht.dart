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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            timeIntervalHeight: 100,
                          ),
                          onTap: calenderTapped,
                        );
                      }),
                ),
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

    bool hausaufgabe = u.homework != null;
    int files = u.content.files.length;

    String subject = u.subject.long;

    if (hausaufgabe) subject += " [HA]";

    if (files > 0) {
      subject += " [$files Datei";
      if (files > 1) subject += "en";
      subject += "]";
    }

    subject += "\n${u.content.text}";

    return subject.trim();
  }

  @override
  Color getColor(int index) =>
      ColorUtils.stringToColor(unterricht[index].subject.long);

  @override
  String getNotes(int index) => unterricht[index].content.text;
}
