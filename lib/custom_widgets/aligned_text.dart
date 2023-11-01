import 'package:flutter/material.dart';

class AlignedText extends StatelessWidget {
  final Text text;
  final AlignmentGeometry alignment;

  const AlignedText({
    super.key,
    required this.text,
    this.alignment = Alignment.centerLeft,
  });

  AlignedText.fromString(
    String string, {
    super.key,
    this.alignment = Alignment.centerLeft,
  }) : text = Text(string);

  @override
  Widget build(BuildContext context) =>
      Align(alignment: alignment, child: text);
}
