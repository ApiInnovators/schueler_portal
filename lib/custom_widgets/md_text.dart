import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/material.dart';

class MarkdownText extends EasyRichText {
  static Map<String, TextStyle> patternToStyle = {
    "**": const TextStyle(fontWeight: FontWeight.bold),
    "__": const TextStyle(decoration: TextDecoration.underline),
    "//": const TextStyle(fontStyle: FontStyle.italic),
  };

  MarkdownText(super.text, {super.key, super.defaultStyle, super.overflow})
      : super(
          patternList: patternToStyle.entries.map((entry) {
            final s = entry.key.replaceAll("*", "\\*");
            return EasyRichTextPattern(
              targetString: '($s)(.*?)($s)',
              matchBuilder: (context, match) {
                if (match == null) throw Exception();
                return TextSpan(
                  text: match[0]!.replaceAll(entry.key, ''),
                  style: entry.value,
                );
              },
            );
          }).toList(),
        );
}
