import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Hyperlink extends StatelessWidget {

  final String url;
  final String text;

  const Hyperlink({super.key, required this.url, required this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Text(
        text,
        style: const TextStyle(
            color: Color.fromARGB(255, 0, 0, 238),
            decoration: TextDecoration.underline),
      ),
      onTap: () => launchUrlString(url),
    );
  }
}
