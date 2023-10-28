import 'package:flutter/material.dart';
import 'package:schueler_portal/pages/timetable/stundenplan.dart';
import 'package:schueler_portal/pages/timetable/vertretungsplan.dart';

class StundenplanPage extends StatefulWidget {
  static const List<String> tabTitles = ["Stundenplan", "Vertretungsplan"];

  const StundenplanPage({super.key});

  @override
  State<StundenplanPage> createState() => _StundenplanPageState();
}

class _StundenplanPageState extends State<StundenplanPage> {
  String title = StundenplanPage.tabTitles[0];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: StundenplanPage.tabTitles.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          bottom: TabBar(
            onTap: (value) =>
                setState(() => title = StundenplanPage.tabTitles[value]),
            tabs: List.generate(StundenplanPage.tabTitles.length,
                (i) => Tab(text: StundenplanPage.tabTitles[i])),
          ),
        ),
        body: const TabBarView(
          children: [
            StundenplanContainer(),
            VertretungsplanWidget(),
          ],
        ),
      ),
    );
  }
}
