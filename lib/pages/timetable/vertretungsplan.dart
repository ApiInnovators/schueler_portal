import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/custom_widgets/aligned_text.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/pages/timetable/stundenplan.dart';
import 'package:schueler_portal/user_data.dart';
import 'package:string_to_color/string_to_color.dart';

import '../../api/response_models/api/vertretungsplan.dart';

class VertretungsplanWidget extends StatelessWidget {
  const VertretungsplanWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshableCachingFutureBuilder(
      dataLoaderFuture: DataLoader.getVertretungsplan,
      cache: DataLoader.cache.vertretungsplan,
      builder: (context, snapshot) {
        bool onlyUsersVertretungen = true;

        return StatefulBuilder(
          builder: (context, setState) {
            List<Datum> datums = snapshot.data;
            if (onlyUsersVertretungen) {
              datums = datums
                  .where((element) =>
                      UserData.isCourseEnabled(element.uf))
                  .toList();
            }

            return Column(children: [
              Padding(
                padding: const EdgeInsets.only(left: 6, right: 6, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Nur deine Vertretungen"),
                    Switch(
                        value: onlyUsersVertretungen,
                        onChanged: (value) =>
                            setState(() => onlyUsersVertretungen = value)),
                  ],
                ),
              ),
              const Divider(),
              if (datums.isEmpty) ...[
                const Center(child: Text("Keine Vertretungen")),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      for (MapEntry<DateTime, List<Datum>> entry
                          in SplayTreeMap<DateTime, List<Datum>>.from(
                              groupBy(datums, (p0) => p0.date)).entries)
                        VertretungDayWidget(day: entry.key, data: entry.value)
                    ],
                  ),
                ),
              ],
            ]);
          },
        );
      },
    );
  }
}

class VertretungDayWidget extends StatelessWidget {
  final DateTime day;
  final List<Datum> data;

  const VertretungDayWidget({super.key, required this.day, required this.data});

  @override
  Widget build(BuildContext context) {
    String dayHeaderText = DateFormat("dd.MM.yyyy").format(day);

    var today = DateTime.now();
    if (day.isSameDate(today)) {
      dayHeaderText = "Heute";
    } else if (day.isSameDate(today.add(const Duration(days: 1)))) {
      dayHeaderText = "Morgen";
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              const Expanded(child: Divider(endIndent: 20)),
              Text(
                dayHeaderText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Expanded(child: Divider(indent: 20)),
            ],
          ),
        ),
        Column(
          children: List.generate(
            data.length,
            (i) => Column(
              children: [
                VertretungDatumWidget(datum: data[i]),
                if (data.last != data[i]) const Divider(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VertretungDatumWidget extends StatelessWidget {
  final Datum datum;

  const VertretungDatumWidget({super.key, required this.datum});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(
            children: [
              AlignedText(
                text: Text(
                  "${datum.hour}. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              AlignedText(
                text: Text(
                  "${datum.uf} ",
                  style: TextStyle(
                    color: ColorUtils.stringToColor(datum.uf),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AlignedText.fromString(datum.absTeacher),
              if (datum.reason != "-")
                AlignedText.fromString(": ${datum.reason}"),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: [
                AlignedText.fromString("Raum: ${datum.room}"),
                if (datum.vertrTeacher.isNotEmpty)
                  AlignedText.fromString("Vertretung: ${datum.vertrTeacher}"),
                if (datum.text.isNotEmpty) AlignedText.fromString(datum.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
