import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'golf_chat_visuals.dart';

/// Warm accent for GolfChat AI prose, headings, and tables (brand orange).
Color golfChatAiAccent(FlutterFlowTheme theme) => theme.primary;

/// Renders GolfChat assistant copy: themed Markdown plus inline tables/charts.
class GolfChatMessageBody extends StatelessWidget {
  const GolfChatMessageBody({
    super.key,
    required this.text,
    required this.visuals,
    required this.theme,
    required this.textColor,
  });

  final String text;
  final List<Map<String, dynamic>> visuals;
  final FlutterFlowTheme theme;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final segments = _splitMarkdownTables(text.trim());
    final styleSheet = _markdownStyle(theme, textColor);
    final accent = golfChatAiAccent(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final segment in segments) ...[
          if (segment.markdown.trim().isNotEmpty) ...[
            MarkdownBody(
              data: segment.markdown.trim(),
              shrinkWrap: true,
              styleSheet: styleSheet,
            ),
            if (segment.table != null) const SizedBox(height: 8),
          ],
          if (segment.table != null)
            GolfChatVisuals(
              visuals: [segment.table!],
              theme: theme,
              textColor: textColor,
              accentColor: accent,
            ),
        ],
        if (visuals.isNotEmpty) ...[
          if (segments.isNotEmpty) const SizedBox(height: 8),
          GolfChatVisuals(
            visuals: visuals,
            theme: theme,
            textColor: textColor,
            accentColor: accent,
          ),
        ],
      ],
    );
  }

  MarkdownStyleSheet _markdownStyle(
    FlutterFlowTheme theme,
    Color textColor,
  ) {
    final accent = golfChatAiAccent(theme);
    final base = theme.bodyMedium.copyWith(color: textColor, height: 1.38);
    return MarkdownStyleSheet(
      p: base,
      pPadding: const EdgeInsets.only(bottom: 6),
      h1: theme.titleMedium.copyWith(
        color: accent,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      h2: theme.titleMedium.copyWith(
        color: accent,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      h3: theme.titleSmall.copyWith(
        color: accent,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.3,
      ),
      h3Padding: const EdgeInsets.only(top: 4, bottom: 6),
      strong: base.copyWith(
        color: accent,
        fontWeight: FontWeight.w700,
      ),
      em: base.copyWith(
        color: textColor.withValues(alpha: 0.88),
        fontStyle: FontStyle.italic,
      ),
      listBullet: base.copyWith(color: accent),
      listIndent: 20,
      blockSpacing: 8,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: accent.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      blockquote: base.copyWith(
        color: textColor.withValues(alpha: 0.78),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: accent.withValues(alpha: 0.55),
            width: 3,
          ),
        ),
      ),
      blockquotePadding:
          const EdgeInsets.only(left: 12, top: 2, bottom: 2),
    );
  }
}

class _MessageSegment {
  const _MessageSegment({required this.markdown, this.table});

  final String markdown;
  final Map<String, dynamic>? table;
}

List<_MessageSegment> _splitMarkdownTables(String text) {
  if (text.isEmpty) return const [];

  final lines = text.split('\n');
  final segments = <_MessageSegment>[];
  final prose = StringBuffer();

  var i = 0;
  while (i < lines.length) {
    if (_isTableHeader(lines, i)) {
      final proseBeforeTable = _takeProse(prose, stripTableHeading: true);
      final parsed = _parseMarkdownTable(lines, i);
      if (parsed != null) {
        segments.add(
          _MessageSegment(
            markdown: proseBeforeTable,
            table: parsed.spec,
          ),
        );
        i = parsed.nextIndex;
        continue;
      }
    }
    prose.writeln(lines[i]);
    i++;
  }

  final trailing = _takeProse(prose, stripTableHeading: false);
  if (trailing.isNotEmpty) {
    segments.add(_MessageSegment(markdown: trailing));
  }
  return segments;
}

String _takeProse(StringBuffer buffer, {required bool stripTableHeading}) {
  if (buffer.isEmpty) return '';
  var text = buffer.toString();
  buffer.clear();

  final proseLines = text.split('\n');
  while (proseLines.isNotEmpty && proseLines.last.trim().isEmpty) {
    proseLines.removeLast();
  }
  if (stripTableHeading &&
      proseLines.isNotEmpty &&
      proseLines.last.trim().startsWith('### ')) {
    proseLines.removeLast();
  }
  return proseLines.join('\n').trim();
}

bool _isTableHeader(List<String> lines, int index) {
  if (index + 1 >= lines.length) return false;
  return _isTableRow(lines[index]) && _isSeparatorRow(lines[index + 1]);
}

bool _isTableRow(String line) {
  final trimmed = line.trim();
  return trimmed.startsWith('|') && trimmed.contains('|');
}

bool _isSeparatorRow(String line) {
  final trimmed = line.trim();
  if (!trimmed.contains('-')) return false;
  return RegExp(r'^\|?[\s\-:|]+\|?$').hasMatch(trimmed);
}

class _ParsedTable {
  const _ParsedTable({
    required this.spec,
    required this.nextIndex,
    this.title,
  });

  final Map<String, dynamic> spec;
  final int nextIndex;
  final String? title;
}

_ParsedTable? _parseMarkdownTable(List<String> lines, int start) {
  final headerLine = lines[start].trim();
  final columns = _splitTableRow(headerLine);
  if (columns.isEmpty) return null;

  var index = start + 2;
  final rows = <List<String>>[];
  while (index < lines.length && _isTableRow(lines[index])) {
    final cells = _splitTableRow(lines[index].trim());
    if (cells.isEmpty) break;
    rows.add(cells);
    index++;
  }
  if (rows.isEmpty) return null;

  String? title;
  var titleScan = start - 1;
  while (titleScan >= 0 && lines[titleScan].trim().isEmpty) {
    titleScan--;
  }
  if (titleScan >= 0) {
    final candidate = lines[titleScan].trim();
    if (candidate.startsWith('### ')) {
      title = _cleanInlineMarkdown(candidate.substring(4));
    }
  }

  return _ParsedTable(
    spec: {
      'type': 'table',
      if (title != null && title.isNotEmpty) 'title': title,
      'columns': columns.map(_cleanInlineMarkdown).toList(),
      'rows': rows
          .map((row) => row.map(_cleanInlineMarkdown).toList())
          .toList(),
    },
    nextIndex: index,
    title: title,
  );
}

List<String> _splitTableRow(String line) {
  var trimmed = line.trim();
  if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
  if (trimmed.endsWith('|')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed
      .split('|')
      .map((cell) => cell.trim())
      .where((cell) => cell.isNotEmpty)
      .toList();
}

String _cleanInlineMarkdown(String value) {
  return value
      .replaceAll(RegExp(r'\*\*'), '')
      .replaceAll(RegExp(r'\*'), '')
      .trim();
}
