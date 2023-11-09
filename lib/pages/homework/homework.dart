import 'dart:convert';

import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/custom_widgets/file_download_button.dart';
import 'package:schueler_portal/data_loader.dart';

import '../../api/api_client.dart';

class HomeworkWidget extends StatefulWidget {
  const HomeworkWidget({super.key});

  @override
  State<HomeworkWidget> createState() => _HomeworkWidgetState();
}

class _HomeworkWidgetState extends State<HomeworkWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hausaufgaben"),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 2,
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
            ],
          ),
          body: TabBarView(
            children: [
              const PastHomeworksWidget(),
              RefreshableCachingFutureBuilder(
                dataLoaderFuture: DataLoader.getHausaufgaben,
                cache: DataLoader.cache.hausaufgaben,
                builder: (context, snapshot) {
                  List<Hausaufgabe> data = snapshot;

                  data.sort((a, b) => a.dueAt.compareTo(b.dueAt));

                  List<Hausaufgabe> erledigteHausaufgaben =
                      data.where((element) => element.completed).toList();
                  List<Hausaufgabe> nichtErledigteHausaufgaben =
                      data.where((element) => !element.completed).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Zu erledigen",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (nichtErledigteHausaufgaben.isEmpty) ...[
                        const Text("Keine unerledigten Hausaufgaben"),
                      ] else ...[
                        HomeworkListWidget(
                          hausaufgaben: nichtErledigteHausaufgaben,
                          resort: () => setState(() {}),
                        )
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        "Erledigt",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (erledigteHausaufgaben.isEmpty) ...[
                        const Text("Noch nichts erledigt"),
                      ] else ...[
                        HomeworkListWidget(
                          hausaufgaben: erledigteHausaufgaben,
                          resort: () => setState(() {}),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeworkListWidget extends StatelessWidget {
  final List<Hausaufgabe> hausaufgaben;
  final Function()? resort;

  const HomeworkListWidget(
      {super.key, required this.hausaufgaben, this.resort});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: hausaufgaben
          .map((e) => SingleHomeworkWidget(hausaufgabe: e, resort: resort))
          .toList(),
    );
  }
}

class SingleHomeworkWidget extends StatefulWidget {
  final Hausaufgabe hausaufgabe;
  final void Function()? resort;

  const SingleHomeworkWidget(
      {super.key, required this.hausaufgabe, this.resort});

  @override
  State<StatefulWidget> createState() => _SingleHomeworkWidget();
}

class _SingleHomeworkWidget extends State<SingleHomeworkWidget> {
  bool isLoading = false;
  late bool hausaufgabeErledigt;
  final scrollControler = ScrollController();

  Future<void> toggleDone() async {
    setState(() => isLoading = true);

    final resp = await ApiClient.postAndParse<Map<String, dynamic>>(
        "/hausaufgaben/${widget.hausaufgabe.id}/toggle-completed",
        (p0) => jsonDecode(p0));

    if (resp.statusCode != 200) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => hausaufgabeErledigt = resp.data!["completed"] == true);
    if (widget.resort != null) widget.resort!();

    if (DataLoader.cache.hausaufgaben.data != null) {
      DataLoader.cache.hausaufgaben.data!
          .firstWhere((e) => e.id == widget.hausaufgabe.id)
          .completed = hausaufgabeErledigt;
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    hausaufgabeErledigt = widget.hausaufgabe.completed;
    return SizedBox(
      height: 100,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                insetPadding: const EdgeInsets.all(10),
                scrollable: true,
                title: Text(widget.hausaufgabe.subject.long),
                content: Column(
                  children: [
                    Text(widget.hausaufgabe.homework),
                    if (widget.hausaufgabe.files.isNotEmpty) const Divider(),
                    Column(
                      children: widget.hausaufgabe.files
                          .map((e) => FileDownloadButton(file: e))
                          .toList(),
                    ),
                    const Divider(),
                    Text("aufgegeben von ${widget.hausaufgabe.teacher}"),
                    Text(
                        "am ${DateFormat("dd.MM.yyyy").format(widget.hausaufgabe.date)}"),
                    Text(
                      "Abgabe am ${DateFormat("dd.MM.yyyy").format(widget.hausaufgabe.dueAt)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Ok'),
                  ),
                ],
              );
            },
          );
        },
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
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
                      if (isLoading) ...[
                        const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(),
                        )
                      ] else ...[
                        Checkbox(
                          value: hausaufgabeErledigt,
                          onChanged: (_) => toggleDone(),
                        ),
                      ],
                      const SizedBox(width: 7)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PastHomeworksWidget extends StatefulWidget {
  const PastHomeworksWidget({super.key});

  @override
  State<PastHomeworksWidget> createState() => _PastHomeworksWidgetState();
}

class _PastHomeworksWidgetState extends State<PastHomeworksWidget>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  TabController? tabController;

  @override
  void dispose() {
    super.dispose();
    tabController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CachingFutureBuilder(
      future: DataLoader.getPastHomework(1),
      cacheGetter: () => DataLoader.cache.pastHomework.values.firstOrNull?.data,
      builder: (context, data) {
        int pages = data.pagination.lastPage;
        tabController ??= TabController(length: pages, vsync: this);
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 10,
            bottom: TabBar(
              controller: tabController,
              onTap: (value) => setState(() => selectedIndex = value),
              tabs: List.generate(pages, (i) => Tab(text: "${i + 1}")),
            ),
          ),
          body: TabBarView(
            controller: tabController,
            children: [
              HomeworkListWidget(hausaufgaben: data.data),
              for (int i = 1; i < pages; ++i)
                RefreshIndicator(
                  onRefresh: () async {
                    DataLoader.cache.pastHomework.clear();
                    await DataLoader.getPastHomework(i + 1);
                    setState(() {});
                  },
                  child: CachingFutureBuilder(
                    cacheGetter: () =>
                        DataLoader.cache.pastHomework[i + 1]?.data,
                    future: DataLoader.getPastHomework(i + 1),
                    builder: (context, data) =>
                        HomeworkListWidget(hausaufgaben: data.data),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
