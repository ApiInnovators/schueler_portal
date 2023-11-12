import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Hyperlink extends StatelessWidget {
  final String url;
  final String text;

  const Hyperlink({super.key, required this.url, required this.text});

  @override
  Widget build(BuildContext context) {
    final Color linkColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      child: Text(
        text,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
      ),
      onTap: () => launchUrlString(url),
    );
  }
}
