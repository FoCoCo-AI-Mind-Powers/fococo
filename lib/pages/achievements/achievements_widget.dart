import '/ai_integration/widgets/navbar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'achievements_model.dart';
export 'achievements_model.dart';

class AchievementsWidget extends StatefulWidget {
  const AchievementsWidget({super.key});

  static String routeName = 'achievements';
  static String routePath = '/achievements';

  @override
  State<AchievementsWidget> createState() => _AchievementsWidgetState();
}

class _AchievementsWidgetState extends State<AchievementsWidget> {
  late AchievementsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AchievementsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: buildFoCoCoAppBar(
        context,
        title: Text(
          'Achievements',
          style: theme.headlineMedium.override(
            fontFamily: 'Inter',
            color: theme.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: theme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your golf achievements will appear here',
              style: TextStyle(
                fontSize: 16,
                color: theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 