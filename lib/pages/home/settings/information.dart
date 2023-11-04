import 'package:flutter/material.dart';
import 'package:schueler_portal/custom_widgets/hyperlink.dart';

const String appRepoUrl = "https://github.com/Style-Innovators/schueler_portal";
const String backendRepoUrl =
    "https://github.com/Style-Innovators/SchuelerPortalBackend";
const String finnsProfileUrl = "https://github.com/Finnomator";

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Informationen"),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          children: [
            Hyperlink(url: appRepoUrl, text: "App Repo"),
            Hyperlink(url: backendRepoUrl, text: "Backend Repo"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Entwickelt von "),
                Hyperlink(url: finnsProfileUrl, text: "Finn Drünert")
              ],
            ),
          ],
        ),
      ),
    );
  }
}
