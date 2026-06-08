import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Warm accent for GolfChat AI prose (brand orange).
Color golfChatAiAccent(FlutterFlowTheme theme) => theme.primary;

/// Renders GolfChat assistant copy as reflective plain text (no Markdown/charts).
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
    return SelectableText(
      text.trim(),
      style: theme.bodyMedium.copyWith(
        color: textColor,
        height: 1.38,
      ),
    );
  }
}
