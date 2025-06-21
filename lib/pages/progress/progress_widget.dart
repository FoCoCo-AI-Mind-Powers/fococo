import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'progress_model.dart';
export 'progress_model.dart';

class ProgressWidget extends StatefulWidget {
  const ProgressWidget({super.key});

  static String routeName = 'progress';
  static String routePath = '/progress';

  @override
  State<ProgressWidget> createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget> {
  late ProgressModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProgressModel());
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
          'Progress',
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
              Icons.trending_up,
              size: 64,
              color: Color(0xFF059669),
            ),
            SizedBox(height: 16),
            Text(
              'Progress Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B4D2C),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your progress tracking will appear here',
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