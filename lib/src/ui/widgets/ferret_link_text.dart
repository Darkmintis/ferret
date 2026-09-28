import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/ferret_links.dart';
import '../ferret_body_viewer.dart';
import '../ferret_link_sheet.dart';

/// Selectable text whose `http(s)://` URLs are underlined and tappable.
/// Tapping opens [FerretLinkSheet] (never the browser directly).
class FerretLinkText extends StatefulWidget {
  const FerretLinkText(
    this.text, {
    super.key,
    this.style,
    this.prefix,
    this.highlightJsonKeys = false,
  });

  final String text;
  final TextStyle? style;

  /// Leading span rendered before [text] (e.g. a bold header name).
  final InlineSpan? prefix;

  /// Bold JSON keys like `"userId":` (body viewer).
  final bool highlightJsonKeys;

  @override
  State<FerretLinkText> createState() => _FerretLinkTextState();
}

class _FerretLinkTextState extends State<FerretLinkText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final scheme = Theme.of(context).colorScheme;
    final base = widget.style ?? DefaultTextStyle.of(context).style;
    final linkStyle = base.copyWith(
      color: scheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary,
    );

    final text = widget.text;
    final children = <InlineSpan>[?widget.prefix];
    var cursor = 0;
    for (final link in FerretLinks.matches(text)) {
      if (link.start > cursor) {
        children.add(_plain(text.substring(cursor, link.start), base));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => FerretLinkSheet.show(context, link.url);
      _recognizers.add(recognizer);
      children.add(
        TextSpan(
          text: text.substring(link.start, link.end),
          style: linkStyle,
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
        ),
      );
      cursor = link.end;
    }
    if (cursor < text.length) {
      children.add(_plain(text.substring(cursor), base));
    }

    return SelectableText.rich(TextSpan(style: base, children: children));
  }

  InlineSpan _plain(String segment, TextStyle base) => widget.highlightJsonKeys
      ? FerretBodyViewer.highlightJsonKeys(segment, base)
      : TextSpan(text: segment);
}
