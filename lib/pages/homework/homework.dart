
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/custom_widgets/file_download_button.dart';
import 'package:schueler_portal/data_loader.dart';


class HomeworkWidget extends StatefulWidget {
  const HomeworkWidget({super.key});

  @override
  State<StatefulWidget> createState() => _HomeworkWidget();
}

class _HomeworkWidget extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hausaufgaben"),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 3,
        initialIndex: 1,
        child: Scaffold(
          appBar: const TabBar(
            tabs: [
              Tab(
                text: "Vergangen",
              ),
              Tab(
                text: "Aktuell",
              ),
              Tab(
                text: "Heute",
              ),
            ],
          ),
          body: TabBarView(
            children: [
              const Text("Nothing here"),
              RefreshIndicator(
                  child: CachingFutureBuilder(
                    future: DataLoader.getHausaufgaben(),
                    cacheGetter: () => DataLoader.cache.hausaufgaben,
                    builder: (context, snapshot) {
                      List<Hausaufgabe> data = snapshot.data!;

                      data.sort((a, b) => a.dueAt.compareTo(b.dueAt));

                      List<Hausaufgabe> erledigteHausaufgaben =
                          data.where((element) => element.completed).toList();
                      List<Hausaufgabe> nichtErledigteHausaufgaben =
                          data.where((element) => !element.completed).toList();

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            const Text(
                              "Zu erledigen",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Column(
                              children: List.generate(
                                  nichtErledigteHausaufgaben.length,
                                  (i) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        child: SingleHomeworkWidget(
                                          hausaufgabe:
                                              nichtErledigteHausaufgaben[i],
                                        ),
                                      )),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Erledigt",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Column(
                              children: List.generate(
                                erledigteHausaufgaben.length,
                                (i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  child: SingleHomeworkWidget(
                                    hausaufgabe: erledigteHausaufgaben[i],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  onRefresh: () async {
                    DataLoader.cache.hausaufgaben = null;
                    DataLoader.cacheData();
                    await DataLoader.getHausaufgaben();
                    setState(() {});
                  }),
              const Text("Nothing here"),
            ],
          ),
        ),
      ),
    );
  }
}

class SingleHomeworkWidget extends StatefulWidget {
  final Hausaufgabe hausaufgabe;

  const SingleHomeworkWidget({super.key, required this.hausaufgabe});

  @override
  State<StatefulWidget> createState() => _SingleHomeworkWidget();
}

class _SingleHomeworkWidget extends State<SingleHomeworkWidget> {
  late bool hausaufgabeErledigt;
  final scrollControler = ScrollController();

  @override
  initState() {
    super.initState();
    hausaufgabeErledigt = widget.hausaufgabe.completed;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(0),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(builder: (context, setLocalState) {
                  return AlertDialog(
                    insetPadding: const EdgeInsets.all(10),
                    scrollable: true,
                    title: Text(widget.hausaufgabe.subject.long),
                    content: Column(
                      children: [
                        Text(widget.hausaufgabe.homework),
                        if (widget.hausaufgabe.files.isNotEmpty)
                          const Divider(),
                        Column(
                          children: List.generate(
                            widget.hausaufgabe.files.length,
                            (i) => FileDownloadButton(
                                file: widget.hausaufgabe.files[i]),
                          ),
                        ),
                        const Divider(),
                        Text("aufgegeben von ${widget.hausaufgabe.teacher}"),
                        Text(
                            "am ${DateFormat("dd.MM.yyyy").format(widget.hausaufgabe.date)}"),
                        Text(
                          "Abgabe am ${DateFormat("dd.MM.yyyy").format(widget.hausaufgabe.dueAt)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setLocalState(() {
                              setState(() {
                                hausaufgabeErledigt = !hausaufgabeErledigt;
                              });
                            });
                          },
                          child: Text(
                              "Als ${hausaufgabeErledigt ? "nicht " : ""}erledigt markieren"),
                        ),
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
                });
              },
            );
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.hausaufgabe.subject.long,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                      "${DateFormat(" (dd.MM.yy)").format(widget.hausaufgabe.date)} → ${DateFormat("dd.MM.yy").format(widget.hausaufgabe.dueAt)}"),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: FadingEdgeScrollView.fromSingleChildScrollView(
                        gradientFractionOnEnd: 0.8,
                        child: SingleChildScrollView(
                          controller: scrollControler,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              widget.hausaufgabe.homework,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.hausaufgabe.files.isNotEmpty)
                      Row(
                        children: [
                          const VerticalDivider(),
                          const Icon(Icons.attachment),
                          Text("${widget.hausaufgabe.files.length}"),
                        ],
                      ),
                    const VerticalDivider(),
                    Checkbox(
                        value: hausaufgabeErledigt,
                        onChanged: (bool? value) {
                          setState(() {
                            hausaufgabeErledigt = value == true;
                          });
                        }),
                    const SizedBox(width: 7)
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
