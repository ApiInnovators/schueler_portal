import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:schueler_portal/api/response_models/api/hausaufgaben.dart';

import '../api/api_client.dart';

class FileDownloadButton extends StatelessWidget {
  final FileElement file;

  const FileDownloadButton({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
      ),
      onPressed: () async {
        File? downloadedFile = await ApiClient.downloadFile(file);

        if (downloadedFile == null) return;

        OpenFile.open(downloadedFile.path);
      },
      icon: const Icon(Icons.file_download),
      label: Text(file.name),
    );
  }
}
