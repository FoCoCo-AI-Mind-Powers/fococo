import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/biometric_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_model.dart';
export 'login_model.dart';

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

  // Biometric state
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricName = 'Biometric';
  bool _isCheckingBiometric = false;
  bool _hasFaceBiometric = false;

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

    // Initialize logo rotation animation
    _logoRotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // Full rotation in radians
    ).animate(CurvedAnimation(
      parent: _logoRotationController,
      curve: Curves.linear,
    ));

    // Check biometric availability
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _logoRotationController.dispose();
    // Model's dispose() method handles disposing FocusNodes and TextControllers
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

    setState(() {
      _isCheckingBiometric = true;
    });

    try {
      final String? email = await _biometricService.authenticateForLogin();

      if (email != null) {
        // Biometric authentication successful, sign in the user
        GoRouter.of(context).prepareAuthEvent();

        // For biometric login, we need to handle this differently since we don't have password
        // We'll assume the user is already authenticated via biometric and redirect
        context.goNamedAuth('dashboard', context.mounted);
      } else {
        _showErrorSnackBar(
            '${_biometricName} authentication failed or cancelled');
      }
    } catch (e) {
      _showErrorSnackBar(
          '${_biometricName} authentication error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingBiometric = false;
        });
      }
    }
  }

  Future<void> _showPasswordRecoveryDialog() async {
    final TextEditingController emailController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final dialogTheme = FlutterFlowTheme.of(dialogContext);
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  dialogTheme.secondaryBackground.withValues(alpha: 0.95),
                  dialogTheme.secondaryBackground.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dialogTheme.secondaryBackground.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1B5E20).withValues(alpha: 0.2),
                              const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Color(0xFF1B5E20),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password',
                              style: dialogTheme.titleMedium.override(
                                fontFamily: 'Inter',
                                color: const Color(0xFF1B5E20),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              'Enter your email to receive reset instructions',
                              style: dialogTheme.bodySmall.override(
                                fontFamily: 'Inter',
                                color: const Color(0xFF2E7D32),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Email Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        hintStyle: dialogTheme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: Colors.grey,
                          height: 1.4,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF2E7D32),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: dialogTheme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: const Color(0xFF1B5E20),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: dialogTheme.bodyMedium.override(
                              fontFamily: 'Inter',
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty) {
                              _showErrorSnackBar(
                                  'Please enter your email address');
                              return;
                            }

                            Navigator.of(dialogContext).pop();

                            try {
                              await authManager.resetPassword(
                                email: email,
                                context: dialogContext,
                              );
                            } catch (e) {
                              _showErrorSnackBar(
                                  'Failed to send reset email. Please try again.');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Send Reset Link',
                            style: dialogTheme.bodyMedium.override(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: Container(
          width: screenWidth,
          height: screenHeight,
          color: theme.primaryBackground,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: safeAreaTop + 80,
                  bottom: safeAreaBottom + 20,
                ),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Logo Section - FoCoCo Logo Image with rotation
                              AnimatedBuilder(
                                animation: _logoRotationAnimation,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _logoRotationAnimation.value,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: RadialGradient(
                                          colors: [
                                            theme.secondaryBackground
                                                .withValues(alpha: 0.1),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 1.0],
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          'assets/images/logo/Logo.png',
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Tagline - Enhanced Typography
                              Column(
                                children: [
                                  Text(
                                    'FoCoCo',
                                    textAlign: TextAlign.center,
                                    style: theme.titleMedium.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFFFFD54F),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your Mind Powers the Game',
                                    textAlign: TextAlign.center,
                                    style: theme.bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: theme.primaryText,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Header with Enhanced Golf Icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF1B5E20)
                                              .withValues(alpha: 0.15),
                                          const Color(0xFF2E7D32)
                                              .withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF1B5E20)
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.golf_course,
                                      color: const Color(0xFF1B5E20),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Welcome to the Course',
                                      style: theme.headlineSmall.override(
                                        fontFamily: 'Inter',
                                        color: const Color(0xFF1B5E20),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Sign in to track your progress and lower your handicap',
                                textAlign: TextAlign.center,
                                style: theme.bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: const Color(0xFF2E7D32),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Google Sign In Button
                              _buildAuthButton(
                                onTap: () async {
                                  try {
                                    GoRouter.of(context).prepareAuthEvent();
                                    final user = await authManager
                                        .signInWithGoogle(context);
                                    if (user == null) return;

                                    context.goNamedAuth(
                                        'dashboard', context.mounted);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Google Sign In failed. Please try again or use another method.'),
                                        backgroundColor: Colors.red.shade400,
                                      ),
                                    );
                                  }
                                },
                                icon: Image.asset(
                                  'assets/images/google-logo.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                ),
                                text: 'Continue with Google',
                                backgroundColor: theme.secondaryBackground,
                                textColor: theme.primaryText,
                                theme: theme,
                              ),

                              const SizedBox(height: 12),

                              // Apple Sign In (iOS only)
                              if (Theme.of(context).platform ==
                                  TargetPlatform.iOS) ...[
                                _buildAuthButton(
                                  onTap: () async {
                                    try {
                                      GoRouter.of(context).prepareAuthEvent();
                                      final user = await authManager
                                          .signInWithApple(context);
                                      if (user == null) return;

                                      context.goNamedAuth(
                                          'dashboard', context.mounted);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Apple Sign In failed. Please try again or use another method.'),
                                          backgroundColor: Colors.red.shade400,
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    FontAwesomeIcons.apple,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                    size: 18,
                                  ),
                                  text: 'Continue with Apple',
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                  textColor: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.black
                                      : Colors.white,
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Enhanced Divider
                              _buildDivider(),

                              const SizedBox(height: 20),

                              // Email Input Field
                              TextFormField(
                                controller: _model.emailAddressTextController,
                                focusNode: _model.emailAddressFocusNode,
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: theme.bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF1B5E20),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  hintText: 'Enter your email',
                                  hintStyle: theme.bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: const Color(0xFF1B5E20)
                                          .withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1B5E20),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.error,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.error,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: theme.secondaryBackground,
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          16, 16, 16, 16),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF1B5E20),
                                    size: 20,
                                  ),
                                ),
                                style: theme.bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: theme.primaryText,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: _model
                                    .emailAddressTextControllerValidator
                                    .asValidator(context),
                              ),

                              const SizedBox(height: 16),

                              // Password Input Field
                              TextFormField(
                                controller: _model.passwordTextController,
                                focusNode: _model.passwordFocusNode,
                                autofocus: false,
                                obscureText: !_model.passwordVisibility,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: theme.bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF1B5E20),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  hintText: 'Enter your password',
                                  hintStyle: theme.bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: const Color(0xFF1B5E20)
                                          .withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1B5E20),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.error,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: theme.error,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: theme.secondaryBackground,
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          16, 16, 16, 16),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF1B5E20),
                                    size: 20,
                                  ),
                                  suffixIcon: InkWell(
                                    onTap: () => setState(
                                      () => _model.passwordVisibility =
                                          !_model.passwordVisibility,
                                    ),
                                    focusNode: FocusNode(skipTraversal: true),
                                    child: Icon(
                                      _model.passwordVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF1B5E20),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                style: theme.bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: theme.primaryText,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                validator: _model
                                    .passwordTextControllerValidator
                                    .asValidator(context),
                              ),

                              const SizedBox(height: 12),

                              // Remember Me & Forgot Password Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Remember Me Checkbox
                                  InkWell(
                                    onTap: () => setState(
                                      () => _model.rememberMeValue =
                                          !(_model.rememberMeValue ?? false),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value:
                                              _model.rememberMeValue ?? false,
                                          onChanged: (val) => setState(
                                            () => _model.rememberMeValue = val,
                                          ),
                                          activeColor: const Color(0xFF1B5E20),
                                        ),
                                        Text(
                                          'Remember me',
                                          style: theme.bodyMedium.override(
                                            fontFamily: 'Inter',
                                            color: const Color(0xFF1B5E20),
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Forgot Password Link
                                  InkWell(
                                    onTap: _showPasswordRecoveryDialog,
                                    child: Text(
                                      'Forgot password?',
                                      style: theme.bodyMedium.override(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Sign In Button
                              Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF1B5E20),
                                      const Color(0xFF2E7D32),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1B5E20)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      GoRouter.of(context).prepareAuthEvent();

                                      final user =
                                          await authManager.signInWithEmail(
                                        context,
                                        _model.emailAddressTextController.text,
                                        _model.passwordTextController.text,
                                      );
                                      if (user == null) {
                                        return;
                                      }

                                      context.goNamedAuth(
                                          'dashboard', context.mounted);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Sign In',
                                        style: theme.titleMedium.override(
                                          fontFamily: 'Montserrat',
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Biometric Authentication Button (if available and enabled)
                              if (_isBiometricAvailable &&
                                  _isBiometricEnabled) ...[
                                _buildAuthButton(
                                  onTap: _authenticateWithBiometric,
                                  icon: _isCheckingBiometric
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Icon(
                                          _getBiometricIcon(),
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                  text: _isCheckingBiometric
                                      ? 'Authenticating...'
                                      : 'Sign in with $_biometricName',
                                  backgroundColor: const Color(0xFF1B5E20),
                                  textColor: Colors.white,
                                  theme: theme,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Sign Up Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Don\'t have an account? ',
                                    style: theme.bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF1B5E20),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => context.goNamed('register'),
                                    child: Text(
                                      'Sign Up',
                                      style: theme.bodyMedium.override(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Enhanced Terms and Privacy
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD54F)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.flag,
                                      color: const Color(0xFFFFD54F),
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'By continuing, you agree to play by our Terms of Service and Privacy Policy',
                                      textAlign: TextAlign.center,
                                      style: theme.bodySmall.override(
                                        fontFamily: 'Inter',
                                        color: theme.secondaryText,
                                        fontSize: 10,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Normal Auth Button Builder
  Widget _buildAuthButton({
    required VoidCallback onTap,
    required Widget icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required FlutterFlowTheme theme,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: backgroundColor.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: backgroundColor.computeLuminance() > 0.5
                    ? Colors.grey.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  text,
                  style: theme.titleMedium.override(
                    fontFamily: 'Inter',
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Divider
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  const Color(0xFF2E7D32).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.sports_golf,
              color: const Color(0xFF2E7D32),
              size: 10,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF2E7D32).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getBiometricIcon() {
    // Check for face biometric using both the status flag and name
    if (_hasFaceBiometric || _biometricName.toLowerCase().contains('face')) {
      return FontAwesomeIcons.faceSmile;
    } else if (_biometricName.toLowerCase().contains('touch') ||
        _biometricName.toLowerCase().contains('fingerprint')) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }
}
