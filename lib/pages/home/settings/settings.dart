import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/data_loader.dart';
import 'package:schueler_portal/main.dart';
import 'package:schueler_portal/pages/home/settings/information.dart';

import '../../../tools.dart';
import '../../../user_data.dart';

class SettingsPage extends StatelessWidget {
  final MyAppState myAppState;

  const SettingsPage({super.key, required this.myAppState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Einstellungen"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InformationPage()),
                );
              },
              icon: const Icon(Icons.info_outline)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SettingsColorPicker(myAppState: myAppState),
            const Divider(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoursesSelectorPage(),
                ),
              ),
              child: const Text("Kurse auswählen"),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsColorPicker extends StatefulWidget {
  final MyAppState myAppState;

  const SettingsColorPicker({super.key, required this.myAppState});

  @override
  State<SettingsColorPicker> createState() => _SettingsColorPickerState();
}

class _SettingsColorPickerState extends State<SettingsColorPicker> {
  Color pickerColor = UserData.getAccentColor();

  void changeColor(Color color) {
    setState(() => pickerColor = color);
    widget.myAppState.setAccentColor(color);
    UserData.setAccentColor(color);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Wähle eine Farbe'),
              content: SingleChildScrollView(
                child: MaterialPicker(
                  pickerColor: pickerColor,
                  onColorChanged: changeColor,
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Fertig'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 20,
              width: 20,
              color: widget.myAppState.accentColor,
            ),
            const SizedBox(width: 10),
            const Text("Akzentfarbe ändern"),
          ],
        ));
  }
}

class CoursesSelectorPage extends StatelessWidget {
  const CoursesSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kurse auswählen"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CachingFutureBuilder(
            future: DataLoader.getStundenplan(),
            cacheGetter: () => DataLoader.cache.stundenplan,
            builder: (context, snapshot) {
              final allCourses = Tools.getStundenplanCourses(
                snapshot.data!.data,
              ).toList();

              final grouped = SplayTreeMap<String, List<String>>.from(
                  groupBy(allCourses, (element) => element.split("_")[0]));

              return Column(children: [
                for (MapEntry<String, List<String>> entry
                    in grouped.entries) ...[
                  Column(
                    children: [
                      Row(children: <Widget>[
                        const Expanded(child: Divider(endIndent: 15)),
                        Text(entry.key),
                        const Expanded(child: Divider(indent: 15)),
                      ]),
                      for (String course in entry.value) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(course),
                            CourseSwitch(course: course),
                          ],
                        )
                      ]
                    ],
                  )
                ]
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class CourseSwitch extends StatefulWidget {
  final String course;

  const CourseSwitch({super.key, required this.course});

  @override
  State<CourseSwitch> createState() => _CourseSwitchState();
}

class _CourseSwitchState extends State<CourseSwitch> {
  late bool enabled = UserData.isCourseEnabled(widget.course);

  @override
  Widget build(BuildContext context) => Switch(
      value: enabled,
      onChanged: (value) {
        UserData.setCourseIsEnabled(
          widget.course,
          value,
        );
        setState(() => enabled = value);
      });
}
