import '/flutter_flow/flutter_flow_util.dart';
import 'claude_style_ai_insights_widget.dart' show ClaudeStyleAiInsightsWidget;
import 'package:flutter/material.dart';

class ClaudeStyleAiInsightsModel
    extends FlutterFlowModel<ClaudeStyleAiInsightsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for message input
  FocusNode? messageInputFocusNode;
  TextEditingController? messageInputController;
  String? Function(BuildContext, String?)? messageInputControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    messageInputFocusNode?.dispose();
    messageInputController?.dispose();
  }
}
