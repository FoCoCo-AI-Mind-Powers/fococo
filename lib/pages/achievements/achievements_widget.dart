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
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B4D2C),
        title: Text(
          'Achievements',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: Color(0xFFF59E0B),
            ),
            SizedBox(height: 16),
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B4D2C),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your golf achievements will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 