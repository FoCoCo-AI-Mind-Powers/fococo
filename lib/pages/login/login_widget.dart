import '/ai_integration/widgets/navbar_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/biometric_auth_service.dart';
import '/services/auth_flow_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_model.dart';
export 'login_model.dart';

const String _kLoginRememberMe = 'login_remember_me';
const String _kLoginEmail = 'login_email';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget>
    with TickerProviderStateMixin {
  late LoginModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final BiometricAuthService _biometricService = BiometricAuthService();

  // View mode: false = Entry, true = Sign In
  bool _showSignIn = false;

  // Biometric state
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricName = 'Biometric';
  bool _isCheckingBiometric = false;
  bool _hasFaceBiometric = false;

  // Sign-in loading state
  bool _isGoogleSigningIn = false;
  bool _isAppleSigningIn = false;
  bool _isEmailSigningIn = false;

  // Sign-in error message
  String? _signInError;

  // Logo rotation animation
  late AnimationController _logoRotationController;
  late Animation<double> _logoRotationAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    // Logo rotation animation
    _logoRotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _logoRotationController,
      curve: Curves.linear,
    ));

    _checkBiometricAvailability();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_kLoginRememberMe) ?? false;
      final email = prefs.getString(_kLoginEmail) ?? '';
      if (!mounted) return;
      setState(() {
        _model.rememberMeValue = rememberMe;
        if (email.isNotEmpty) {
          _model.emailAddressTextController?.text = email;
        }
      });
    } catch (e) {
      debugPrint('Error loading remember me: $e');
    }
  }

  Future<void> _saveRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = _model.rememberMeValue ?? false;
      await prefs.setBool(_kLoginRememberMe, remember);
      if (remember) {
        final email =
            _model.emailAddressTextController?.text.trim() ?? '';
        await prefs.setString(_kLoginEmail, email);
      } else {
        await prefs.remove(_kLoginEmail);
      }
    } catch (e) {
      debugPrint('Error saving remember me: $e');
    }
  }

  @override
  void dispose() {
    _logoRotationController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final status = await _biometricService.getBiometricStatus();
      if (mounted) {
        setState(() {
          _isBiometricAvailable = status['isAvailable'] ?? false;
          _isBiometricEnabled = status['isEnabled'] ?? false;
          _biometricName = status['biometricName'] ?? 'Biometric';
          _hasFaceBiometric = status['hasFace'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isCheckingBiometric) return;
    setState(() => _isCheckingBiometric = true);
    try {
      final String? email = await _biometricService.authenticateForLogin();
      if (email != null) {
        GoRouter.of(context).prepareAuthEvent();
        await _navigateAfterAuth();
      } else {
        _showError('$_biometricName authentication failed or cancelled');
      }
    } catch (e) {
      _showError('$_biometricName authentication error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isCheckingBiometric = false);
    }
  }

  Future<void> _navigateAfterAuth() async {
    final decision = await AuthFlowService.instance.resolvePostAuthDecision();
    if (!mounted) return;
    GoRouter.of(context).clearRedirectLocation();
    context.goNamed(decision.routeName, extra: decision.extra);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showPasswordRecoveryDialog() async {
    final TextEditingController emailController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1030),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Reset Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email to receive reset instructions',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Email address',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFF4CAF50), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Always show success — never confirm if email exists
                try {
                  await authManager.resetPassword(
                    email: emailController.text.trim(),
                    context: context,
                  );
                } catch (_) {}
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'If an account exists, you\'ll receive a reset email shortly.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Send Reset Link',
                  style: TextStyle(color: Color(0xFF4CAF50))),
            ),
          ],
        );
      },
    );
  }

  IconData _getBiometricIcon() {
    if (_hasFaceBiometric || _biometricName.toLowerCase().contains('face')) {
      return FontAwesomeIcons.faceSmile;
    } else if (_biometricName.toLowerCase().contains('touch') ||
        _biometricName.toLowerCase().contains('fingerprint')) {
      return Icons.fingerprint;
    }
    return Icons.security;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        resizeToAvoidBottomInset: true,
        appBar: buildFoCoCoAppBar(
          context,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: _showSignIn
              ? IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 28),
                  onPressed: () {
                    setState(() {
                      _showSignIn = false;
                      _signInError = null;
                      _model.emailAddressTextController?.clear();
                      _model.passwordTextController?.clear();
                    });
                  },
                )
              : null,
          title: Text(
            _showSignIn ? 'Sign In' : 'FoCoCo',
            style: theme.headlineSmall.override(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: _showSignIn ? 0.5 : 1.5,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ));
                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _showSignIn
                    ? _buildSignInView(theme, bottomPadding)
                    : _buildEntryView(theme, bottomPadding),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Entry View (Screen 1) ───────────────────────────────────────────────────

  Widget _buildEntryView(FlutterFlowTheme theme, double bottomPadding) {
    return SingleChildScrollView(
      key: const ValueKey('entry'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 32),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Atmospheric glow + logo area
            Stack(
              alignment: Alignment.center,
              children: [
                // Atmospheric radial glow
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Brand text
                Column(
                  children: [
                    // Rotating logo
                    AnimatedBuilder(
                      animation: _logoRotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _logoRotationAnimation.value,
                          child: Image.asset(
                            'assets/images/logo/Logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'FoCoCo',
                      style: theme.headlineLarge.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Mind Powers the Game.',
                      style: theme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Create Account button (primary — green glow)
            _buildGlowButton(
              text: 'Create Account',
              onTap: () => context.pushNamed('register'),
              isPrimary: true,
            ),

            const SizedBox(height: 14),

            // Sign In button (secondary — no glow)
            _buildGlowButton(
              text: 'Sign In',
              onTap: () => setState(() => _showSignIn = true),
              isPrimary: false,
            ),

            const SizedBox(height: 40),

            // Social buttons
            if (Theme.of(context).platform == TargetPlatform.iOS) ...[
              _buildSocialButton(
                icon: const Icon(FontAwesomeIcons.apple,
                    color: Colors.white, size: 18),
                text: 'Sign in with Apple',
                isLoading: _isAppleSigningIn,
                onTap: () async {
                  if (_isAppleSigningIn) return;
                  setState(() => _isAppleSigningIn = true);
                  try {
                    GoRouter.of(context).prepareAuthEvent();
                    final user =
                        await authManager.signInWithApple(context);
                    if (user == null) return;
                    await _navigateAfterAuth();
                  } catch (e) {
                    _showError(
                        'Apple Sign In failed. Please try again or use another method.');
                  } finally {
                    if (mounted) setState(() => _isAppleSigningIn = false);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
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
                  final user =
                      await authManager.signInWithGoogle(context);
                  if (user == null) return;
                  await _navigateAfterAuth();
                } catch (e) {
                  _showError(
                      'Google Sign In failed. Please try again or use another method.');
                } finally {
                  if (mounted) setState(() => _isGoogleSigningIn = false);
                }
              },
            ),

            const SizedBox(height: 16),

            _buildGlowDivider(),
          ],
        ),
      ),
    );
  }

  // ─── Sign In View (Flow B) ───────────────────────────────────────────────────

  Widget _buildSignInView(FlutterFlowTheme theme, double bottomPadding) {
    return SingleChildScrollView(
      key: const ValueKey('signin'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message
            if (_signInError != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  _signInError!,
                  style: const TextStyle(
                      color: Color(0xFFFF8A65), fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email field
            _buildFormTextField(
              controller: _model.emailAddressTextController!,
              focusNode: _model.emailAddressFocusNode!,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              obscure: false,
              suffixIcon: null,
            ),

            _buildGlowDivider(),

            const SizedBox(height: 16),

            // Password field
            _buildFormTextField(
              controller: _model.passwordTextController!,
              focusNode: _model.passwordFocusNode!,
              hintText: 'Password',
              keyboardType: TextInputType.visiblePassword,
              obscure: !_model.passwordVisibility,
              suffixIcon: InkWell(
                onTap: () => setState(
                    () => _model.passwordVisibility = !_model.passwordVisibility),
                child: Icon(
                  _model.passwordVisibility
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ),

            _buildGlowDivider(),

            const SizedBox(height: 12),

            // Remember me + Forgot password row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _model.rememberMeValue =
                      !(_model.rememberMeValue ?? false)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _model.rememberMeValue ?? false,
                          onChanged: (val) =>
                              setState(() => _model.rememberMeValue = val),
                          activeColor: const Color(0xFF4CAF50),
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showPasswordRecoveryDialog,
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white38,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sign In button
            _buildGlowButton(
              text: _isEmailSigningIn ? 'Signing in...' : 'Sign In',
              isPrimary: true,
              onTap: _isEmailSigningIn
                  ? () {}
                  : () async {
                      setState(() {
                        _isEmailSigningIn = true;
                        _signInError = null;
                      });
                      try {
                        GoRouter.of(context).prepareAuthEvent();
                        final user = await authManager.signInWithEmail(
                          context,
                          _model.emailAddressTextController!.text,
                          _model.passwordTextController!.text,
                        );
                        if (user == null) {
                          setState(() {
                            _signInError = 'Email or password incorrect.';
                            _isEmailSigningIn = false;
                          });
                          return;
                        }
                        await _saveRememberMe();
                        await _navigateAfterAuth();
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _signInError = 'Email or password incorrect.';
                            _isEmailSigningIn = false;
                          });
                        }
                      }
                    },
            ),

            const SizedBox(height: 16),

            // Biometric (if available)
            if (_isBiometricAvailable && _isBiometricEnabled) ...[
              _buildSocialButton(
                icon: _isCheckingBiometric
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : Icon(_getBiometricIcon(),
                        color: Colors.white, size: 20),
                text: _isCheckingBiometric
                    ? 'Authenticating...'
                    : 'Sign in with $_biometricName',
                isLoading: false,
                onTap: _authenticateWithBiometric,
              ),
              const SizedBox(height: 12),
            ],

            // Divider
            _buildGolfDivider(),

            const SizedBox(height: 16),

            // Social buttons
            if (Theme.of(context).platform == TargetPlatform.iOS) ...[
              _buildSocialButton(
                icon: const Icon(FontAwesomeIcons.apple,
                    color: Colors.white, size: 18),
                text: 'Sign in with Apple',
                isLoading: _isAppleSigningIn,
                onTap: () async {
                  if (_isAppleSigningIn) return;
                  setState(() => _isAppleSigningIn = true);
                  try {
                    GoRouter.of(context).prepareAuthEvent();
                    final user =
                        await authManager.signInWithApple(context);
                    if (user == null) return;
                    await _navigateAfterAuth();
                  } catch (e) {
                    _showError('Apple Sign In failed. Please try again.');
                  } finally {
                    if (mounted) setState(() => _isAppleSigningIn = false);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
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
                  final user =
                      await authManager.signInWithGoogle(context);
                  if (user == null) return;
                  await _navigateAfterAuth();
                } catch (e) {
                  _showError('Google Sign In failed. Please try again.');
                } finally {
                  if (mounted) setState(() => _isGoogleSigningIn = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared UI helpers ───────────────────────────────────────────────────────

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

  Widget _buildGolfDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.sports_golf,
              color: Colors.white.withValues(alpha: 0.25), size: 12),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlowButton({
    required String text,
    required VoidCallback onTap,
    bool isPrimary = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF4CAF50)
                : Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
          color: isPrimary
              ? const Color(0xFF1A3320).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.04),
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
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          color: Colors.white.withValues(alpha: 0.04),
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

  Widget _buildFormTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required TextInputType keyboardType,
    required bool obscure,
    required Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12), child: suffixIcon)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
