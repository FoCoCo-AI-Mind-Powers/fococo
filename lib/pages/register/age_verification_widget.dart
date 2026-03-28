import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/auth_flow_service.dart';
import '/pages/login/login_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AgeVerificationWidget extends StatefulWidget {
  const AgeVerificationWidget({super.key});

  static String routeName = 'age_verification';
  static String routePath = '/age-verification';

  @override
  State<AgeVerificationWidget> createState() => _AgeVerificationWidgetState();
}

class _AgeVerificationWidgetState extends State<AgeVerificationWidget> {
  bool _isGoogleSigningIn = false;
  bool _isAppleSigningIn = false;

  Future<void> _navigateAfterAuth() async {
    final decision = await AuthFlowService.instance.resolvePostAuthDecision();
    if (!mounted) return;
    GoRouter.of(context).clearRedirectLocation();
    context.goNamed(decision.routeName, extra: decision.extra);
  }

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
            // Top glow divider (at top of screen below status bar)
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            _buildGlowDivider(),
            const SizedBox(height: 40),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AGE VERIFICATION header
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

                    // Thin divider line below header
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

                    // Message
                    Text(
                      'FoCoCo is designed for golfers who meet the minimum age requirement in their country.\n\nWe\'re unable to create an account right now. Come back when you\'re ready\u2014we\'ll be here.',
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

            // Bottom actions
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 32),
              child: Column(
                children: [
                  _buildGlowDivider(),
                  const SizedBox(height: 20),

                  // Close button (goes back to Entry screen, clears stack)
                  _buildGlowButton(
                    text: 'Close',
                    onTap: () {
                      context.go(LoginWidget.routePath);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Sign in with Apple (iOS only)
                  if (Theme.of(context).platform == TargetPlatform.iOS)
                    _buildSocialButton(
                      icon: Icon(
                        FontAwesomeIcons.apple,
                        color: Colors.white,
                        size: 18,
                      ),
                      text: 'Sign in with Apple',
                      isLoading: _isAppleSigningIn,
                      onTap: () async {
                        if (_isAppleSigningIn) return;
                        setState(() => _isAppleSigningIn = true);
                        try {
                          GoRouter.of(context).prepareAuthEvent();
                          final user = await authManager.signInWithApple(context);
                          if (user == null) return;
                          await _navigateAfterAuth();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Apple Sign In failed. Please try again.'),
                                backgroundColor: Colors.red.shade400,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isAppleSigningIn = false);
                        }
                      },
                    ),

                  if (Theme.of(context).platform == TargetPlatform.iOS)
                    const SizedBox(height: 12),

                  // Sign in with Google
                  _buildSocialButton(
                    icon: Image.asset(
                      'assets/images/google-logo.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    text: 'Sign in with Google',
                    isLoading: _isGoogleSigningIn,
                    onTap: () async {
                      if (_isGoogleSigningIn) return;
                      setState(() => _isGoogleSigningIn = true);
                      try {
                        GoRouter.of(context).prepareAuthEvent();
                        final user = await authManager.signInWithGoogle(context);
                        if (user == null) return;
                        await _navigateAfterAuth();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Google Sign In failed. Please try again.'),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isGoogleSigningIn = false);
                      }
                    },
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
          color: const Color(0xFF1A3320).withValues(alpha: 0.4),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : icon,
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
