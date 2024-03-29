import 'package:flutter/material.dart';
import 'package:schueler_portal/api/response_models/api/termine.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class TermineWidget extends StatefulWidget {
  const TermineWidget({super.key});

  @override
  State<TermineWidget> createState() => _TermineWidgetState();
}

class _TermineWidgetState extends State<TermineWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Termine"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await DataLoader.cache.termine.fetchData();
          setState(() {});
        },
        child: CachingFutureBuilder(
          future: DataLoader.getTermine(),
          cacheGetter: DataLoader.cache.termine.getCached,
          builder: (context, snapshot) {
            Termine termine = snapshot;

            return SfCalendar(
              view: CalendarView.schedule,
              dataSource: TermineDataSource(termine),
              firstDayOfWeek: 1,
              scheduleViewSettings: ScheduleViewSettings(
                monthHeaderSettings: MonthHeaderSettings(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  monthTextStyle: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer),
                  height: 80,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TermineDataSource extends CalendarDataSource {
  final Termine termine;

  TermineDataSource(this.termine) {
    appointments = List.empty(growable: true);
    appointments!.addAll(termine.leistungsnachweise.schulaufgaben);
    appointments!.addAll(termine.leistungsnachweise.exTemporalen);
  }

  Schulaufgaben _schulaufgabe(int i) =>
      termine.leistungsnachweise.schulaufgaben[i];

  ExTemporalen _extemporale(int i) => termine.leistungsnachweise
      .exTemporalen[i - termine.leistungsnachweise.schulaufgaben.length];

  @override
  DateTime getStartTime(int index) {
    if (index < termine.leistungsnachweise.schulaufgaben.length) {
      return _schulaufgabe(index).date;
    }

    return _extemporale(index).date;
  }

  @override
  DateTime getEndTime(int index) {
    if (index < termine.leistungsnachweise.schulaufgaben.length) {
      return _schulaufgabe(index).date;
    }

    return _extemporale(index).date;
  }

  @override
  String getSubject(int index) {
    String fach;
    String klasse;
    String typ = "";

    if (index < termine.leistungsnachweise.schulaufgaben.length) {
      fach = _schulaufgabe(index).fach;
      klasse = _schulaufgabe(index).klasse;
      if (_schulaufgabe(index).typ == "s") typ = "Schulaufgabe";
    } else {
      fach = _extemporale(index).fach;
      klasse = _extemporale(index).klasse;
      if (_extemporale(index).typ == "k") typ = "Kurzarbeit";
    }

    String res = fach;

    if (typ.isNotEmpty) res += " $typ";

    res += " ($klasse)";

    return res;
  }

  @override
  Color getColor(int index) {
    if (index < termine.leistungsnachweise.schulaufgaben.length) {
      return Colors.red;
    }

    return Colors.blue;
  }

  @override
  bool isAllDay(int index) {
    return true;
  }
}
