import 'package:flutter/material.dart';
import 'package:highlight/languages/all.dart';
import 'package:highlight/highlight.dart';

class HighlightedCodeController extends TextEditingController {
  String language;
  final Highlight _highlight = Highlight()..registerLanguages(allLanguages);

  HighlightedCodeController({
    String? text,
    this.language = 'html',
  }) : super(text: text ?? '');

  static const _editorTheme = {
    'root': TextStyle(
      color: Color(0xFFD4D4D4),
      backgroundColor: Color(0xFF1E1E1E),
      fontFamily: 'monospace',
      fontSize: 13,
      height: 20 / 13,
    ),
    'keyword': TextStyle(color: Color(0xFF569CD6)),
    'string': TextStyle(color: Color(0xFFCE9178)),
    'number': TextStyle(color: Color(0xFFB5CEA8)),
    'comment': TextStyle(color: Color(0xFF6A9955)),
    'built_in': TextStyle(color: Color(0xFF4EC9B0)),
    'function': TextStyle(color: Color(0xFFDCDCAA)),
    'title': TextStyle(color: Color(0xFFDCDCAA)),
    'params': TextStyle(color: Color(0xFF9CDCFE)),
    'tag': TextStyle(color: Color(0xFF569CD6)),
    'attribute': TextStyle(color: Color(0xFF9CDCFE)),
    'selector-tag': TextStyle(color: Color(0xFF569CD6)),
    'selector-class': TextStyle(color: Color(0xFFD7BA7D)),
    'selector-id': TextStyle(color: Color(0xFFD7BA7D)),
    'type': TextStyle(color: Color(0xFF4EC9B0)),
    'meta': TextStyle(color: Color(0xFFD4D4D4)),
    'variable': TextStyle(color: Color(0xFF9CDCFE)),
    'literal': TextStyle(color: Color(0xFF569CD6)),
    'symbol': TextStyle(color: Color(0xFF569CD6)),
    'bullet': TextStyle(color: Color(0xFF569CD6)),
    'link': TextStyle(color: Color(0xFF569CD6)),
    'addition': TextStyle(color: Color(0xFFB5CEA8)),
    'deletion': TextStyle(color: Color(0xFFCE9178)),
    'emphasis': TextStyle(fontStyle: FontStyle.italic),
    'strong': TextStyle(fontWeight: FontWeight.bold),
  };

  String _langForHighlight(String lang) {
    switch (lang) {
      case 'javascript':
        return 'javascript';
      case 'css':
        return 'css';
      case 'html':
        return 'xml';
      default:
        return lang;
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ??
        const TextStyle(
          color: Color(0xFFD4D4D4),
          fontFamily: 'monospace',
          fontSize: 13,
          height: 20 / 13,
        );

    if (text.isEmpty) return TextSpan(text: '', style: baseStyle);

    try {
      final hlLang = _langForHighlight(language);
      final nodes = _highlight.parse(text, language: hlLang).nodes;
      if (nodes == null || nodes.isEmpty) {
        return TextSpan(text: text, style: baseStyle);
      }
      return _nodesToTextSpan(nodes, baseStyle);
    } catch (_) {
      return TextSpan(text: text, style: baseStyle);
    }
  }

  TextSpan _nodesToTextSpan(List<Node> nodes, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      if (node.value != null && node.value!.isNotEmpty) {
        final nodeStyle = node.className != null &&
                _editorTheme.containsKey(node.className)
            ? _editorTheme[node.className]
            : null;
        spans.add(TextSpan(
          text: node.value,
          style: nodeStyle != null ? baseStyle.merge(nodeStyle) : baseStyle,
        ));
      }
      if (node.children != null && node.children!.isNotEmpty) {
        if (node.className != null && _editorTheme.containsKey(node.className)) {
          spans.add(TextSpan(
            style: baseStyle.merge(_editorTheme[node.className]),
            children: [
              _nodesToTextSpan(node.children!, baseStyle),
            ],
          ));
        } else {
          spans.add(_nodesToTextSpan(node.children!, baseStyle));
        }
      }
    }
    return TextSpan(style: baseStyle, children: spans);
  }
}
