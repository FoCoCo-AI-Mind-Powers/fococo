import '/ai_integration/widgets/navbar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/vark_onboarding/vark_onboarding_widget.dart';
import 'package:flutter/material.dart';

class AccountCreatedWidget extends StatefulWidget {
  const AccountCreatedWidget({super.key});

  static String routeName = 'account_created';
  static String routePath = '/account-created';

  @override
  State<AccountCreatedWidget> createState() => _AccountCreatedWidgetState();
}

class _AccountCreatedWidgetState extends State<AccountCreatedWidget> {
  static const Color _backgroundTop = Color(0xFF10081C);
  static const Color _backgroundBottom = Color(0xFF05020B);
  static const Color _glowColor = Color(0xFFA8FF7A);
  static const Color _textColor = Color(0xFFE8E3C7);

  Future<void> _onContinue() async {
    if (!mounted) return;
    GoRouter.of(context).clearRedirectLocation();
    context.goNamed(VarkOnboardingWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _backgroundBottom,
        appBar: buildFoCoCoAppBar(
          context,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'FoCoCo',
            style: theme.headlineSmall.override(
              fontFamily: 'Inter',
              color: _textColor,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildAtmosphericBackground(),
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Text(
                          'FoCoCo',
                          textAlign: TextAlign.center,
                          style: theme.headlineMedium.override(
                            fontFamily: 'Inter',
                            color: _textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 118,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildEnergyBand(
                                centerGlowWidth: 116,
                                intensity: 0.85,
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.9, end: 1.0),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOut,
                                builder: (context, scale, child) =>
                                    Transform.scale(scale: scale, child: child),
                                child: _buildCheckSeal(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Your account has been created.',
                          textAlign: TextAlign.center,
                          style: theme.bodyLarge.override(
                            fontFamily: 'Inter',
                            color: _textColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                          ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    MediaQuery.of(context).padding.bottom + 32,
                  ),
                  child: Column(
                    children: [
                      _buildEnergyBand(
                        centerGlowWidth: 150,
                        intensity: 0.95,
                      ),
                      const SizedBox(height: 18),
                      _buildGlowButton(
                        text: 'Continue',
                        onTap: _onContinue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtmosphericBackground() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _backgroundTop,
            Color(0xFF170C27),
            _backgroundBottom,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: _buildGlowOrb(
              size: 150,
              color: _glowColor.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 210,
            left: -48,
            child: _buildGlowOrb(
              size: 180,
              color: const Color(0xFF7B6BFF).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 255,
            right: -36,
            child: _buildGlowOrb(
              size: 165,
              color: _glowColor.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: _buildGlowOrb(
              size: 200,
              color: _glowColor.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb({
    required double size,
    required Color color,
  }) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyBand({
    required double centerGlowWidth,
    required double intensity,
  }) {
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _textColor.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: centerGlowWidth,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _glowColor.withValues(alpha: intensity),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _glowColor.withValues(alpha: intensity * 0.38),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckSeal() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _glowColor.withValues(alpha: 0.92),
          width: 1.7,
        ),
        gradient: RadialGradient(
          colors: [
            _glowColor.withValues(alpha: 0.16),
            _glowColor.withValues(alpha: 0.02),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withValues(alpha: 0.34),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.check_rounded,
        color: _glowColor.withValues(alpha: 0.98),
        size: 40,
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
            color: _glowColor.withValues(alpha: 0.72),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: 0.22),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
          gradient: LinearGradient(
            colors: [
              const Color(0xFF12111D).withValues(alpha: 0.86),
              const Color(0xFF1B1826).withValues(alpha: 0.72),
            ],
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
