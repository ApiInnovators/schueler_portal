import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';
import 'package:schueler_portal/custom_widgets/my_future_builder.dart';

import '../api/api_client.dart';

class FileDownloadButton extends StatefulWidget {
  final FileElement file;

  const FileDownloadButton({super.key, required this.file});

  @override
  State<FileDownloadButton> createState() => _FileDownloadButtonState();
}

class _FileDownloadButtonState extends State<FileDownloadButton> {
  DownloadStatus downloadStatus = DownloadStatus.notStarted;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        disabledBackgroundColor:
            Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.6),
      ),
      onPressed: downloadStatus == DownloadStatus.downloading
          ? null
          : () async {
              File? file;
              (bool, File) f = await ApiClient.checkIfFileIsStored(widget.file);

              if (!f.$1) {
                setState(() => downloadStatus = DownloadStatus.downloading);

                file = await ApiClient.downloadFile(widget.file);

                setState(() => downloadStatus = DownloadStatus.done);

                if (file == null) return;
              } else {
                file = f.$2;
              }

              OpenFile.open(file.path);
            },
      icon: MyFutureBuilder(
        future: ApiClient.checkIfFileIsStored(widget.file),
        customBuilder: (context, data) {
          if (data.$1) {
            return const Icon(Icons.check);
          }

          if (downloadStatus == DownloadStatus.downloading) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              ),
            );
          }

          return const Icon(Icons.download);
        },
      ),
      label: Text(widget.file.name),
    );
  }
}

enum DownloadStatus {
  downloading,
  done,
  notStarted,
}
