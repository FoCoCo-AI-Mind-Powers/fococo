import 'package:flutter/material.dart';
import '/backend/schema/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// Widget for displaying AI insights in a card format
class AIInsightWidget extends StatefulWidget {
  const AIInsightWidget({
    Key? key,
    required this.insight,
    this.onTap,
    this.onRate,
  }) : super(key: key);

  final AiInsightsRecord insight;
  final VoidCallback? onTap;
  final Function(int rating, String? feedback)? onRate;

  @override
  State<AIInsightWidget> createState() => _AIInsightWidgetState();
}

class _AIInsightWidgetState extends State<AIInsightWidget> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.insight.insightTitle,
              style: FlutterFlowTheme.of(context).headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.insight.insightContent,
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
            const SizedBox(height: 16),
            if (widget.insight.userRating == 0)
              FFButtonWidget(
                onPressed: () => widget.onRate?.call(5, null),
                text: 'Rate Insight',
                options: FFButtonOptions(
                  height: 40,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    height: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 