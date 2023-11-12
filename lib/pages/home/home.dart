import 'package:flutter/material.dart';
import 'package:schueler_portal/custom_widgets/caching_future_builder.dart';
import 'package:schueler_portal/custom_widgets/file_download_button.dart';
import 'package:schueler_portal/main.dart';
import 'package:schueler_portal/pages/home/settings/settings.dart';
import 'package:schueler_portal/pages/home/termine.dart';
import 'package:schueler_portal/pages/home/unterricht.dart';

import '../../api/response_models/api/news.dart';
import '../../data_loader.dart';

class HomeWidget extends StatelessWidget {
  final MyAppState myAppState;

  const HomeWidget({super.key, required this.myAppState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(
                        myAppState: myAppState,
                      ),
                    ),
                  ),
              icon: const Icon(Icons.settings))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Card(
              child: Column(
                children: [
                  const Text(
                    "News",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                  Expanded(
                    child: RefreshableCachingFutureBuilder(
                      dataLoaderFuture: DataLoader.getNews,
                      cache: DataLoader.cache.news,
                      builder: (context, news) => NewsWidget(news: news),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4, left: 4, bottom: 7),
            child: Row(
              children: [
                Expanded(
                  child: IconButton.filledTonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UnterrichtWidget(),
                        ),
                      );
                    },
                    alignment: Alignment.center,
                    icon: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list),
                        SizedBox(width: 7),
                        Text("Unterricht"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: IconButton.filledTonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermineWidget(),
                        ),
                      );
                    },
                    alignment: Alignment.center,
                    icon: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 7),
                        Text("Termine"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

    return Center(
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
                  FileDownloadButton(file: news[i].file!),
                if (i != news.length - 1) const Divider(),
              ],
            ),
          );
        }),
      ),
    );
  }
}
