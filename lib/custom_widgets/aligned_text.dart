import 'package:flutter/cupertino.dart';

class AlignedText extends Text {
  final AlignmentGeometry alignment;

  const AlignedText(
    super.data, {
    super.key,
    this.alignment = Alignment.centerLeft,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaleFactor,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  });

  @override
  Align build(BuildContext context) => Align(
        alignment: alignment,
        child: Text(
          data!,
          textAlign: textAlign,
          style: style,
          key: key,
          overflow: overflow,
          softWrap: softWrap,
          locale: locale,
          maxLines: maxLines,
          selectionColor: selectionColor,
          semanticsLabel: semanticsLabel,
          strutStyle: strutStyle,
          textDirection: textDirection,
          textHeightBehavior: textHeightBehavior,
          textScaleFactor: textScaleFactor,
          textWidthBasis: textWidthBasis,
        ),
      );
}
