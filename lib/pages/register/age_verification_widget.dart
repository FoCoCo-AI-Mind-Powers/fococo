import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/login/login_widget.dart';
import 'package:flutter/material.dart';

class AgeVerificationWidget extends StatefulWidget {
  const AgeVerificationWidget({super.key});

  static String routeName = 'age_verification';
  static String routePath = '/age-verification';

  @override
  State<AgeVerificationWidget> createState() => _AgeVerificationWidgetState();
}

class _AgeVerificationWidgetState extends State<AgeVerificationWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            _buildGlowDivider(),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AGE VERIFICATION',
                      textAlign: TextAlign.center,
                      style: theme.labelMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3.0,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'FoCoCo is designed for golfers who meet the minimum age requirement in their country.\n\nWe\'re unable to create an account right now. Come back when you\'re ready—we\'ll be here.',
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 15,
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 32),
              child: Column(
                children: [
                  _buildGlowDivider(),
                  const SizedBox(height: 20),
                  _buildGlowButton(
                    text: 'Close',
                    onTap: () => context.go(LoginWidget.routePath),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowDivider() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF4CAF50),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildGlowButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
