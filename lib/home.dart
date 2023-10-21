import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:schueler_portal/my_future_builder.dart';

import 'api/response_models/api/news.dart';
import 'api_client.dart';
import 'data_loader.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<StatefulWidget> createState() => _HomeWidget();
}

class _HomeWidget extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Home",
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(10))),
                child: Column(
                  children: [
                    const Text(
                      "News",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    Expanded(
                      child: MyFutureBuilder(
                        future: DataLoader.getNews(),
                        customBuilder: (context, snapshot) =>
                            NewsWidget(news: snapshot.data!.data!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
                onPressed: () {},
                child: const Center(
                  child: Text("Unterricht"),
                )),
            ElevatedButton(
                onPressed: () {},
                child: const Center(
                  child: Text("Termine"),
                )),
            ElevatedButton(
                onPressed: () {},
                child: const Center(
                  child: Text("Kontaktanfrage"),
                ))
          ],
        ),
      ),
    );
  }
}

class NewsWidget extends StatelessWidget {
  final List<News> news;

  const NewsWidget({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      return const Center(child: Text("Keine Nachrichten"));
    }

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: List.generate(news.length, (i) {
            return Container(
              margin: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Center(
                      child: Text(
                    news[i].title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  )),
                  Center(
                      child: Text(
                    news[i].content,
                    style: const TextStyle(fontSize: 12),
                  )),
                  const SizedBox(
                    height: 10,
                  ),
                  if (news[i].file != null)
                    ElevatedButton(
                        onPressed: () async {
                          File? file =
                              await ApiClient.downloadFile(news[i].file!);
                          if (file != null) {
                            OpenFile.open(file.path);
                          }
                        },
                        child: Text(news[i].file!.name)),
                  if (i != news.length - 1) const Divider(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
