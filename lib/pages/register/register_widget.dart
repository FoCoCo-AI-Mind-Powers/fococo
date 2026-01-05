import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'register_model.dart';
export 'register_model.dart';

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  static String routeName = 'register';
  static String routePath = '/register';

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  late RegisterModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegisterModel());

    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    _model.confirmPasswordTextController ??= TextEditingController();
    _model.confirmPasswordFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    // Let the model handle disposal to avoid double-disposal
    _model.dispose();
    super.dispose();
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
                              // Logo Section - FoCoCo Logo Image
                              Container(
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
                                    'Join the Mental Performance Journey',
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
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF1B5E20)
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person_add,
                                      color: const Color(0xFF1B5E20),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Create Your Account',
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
                                'Start your mental performance journey today',
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
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Google Sign In failed. Please try again or use another method.'),
                                        backgroundColor:
                                            Colors.red.shade400,
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
                                      GoRouter.of(context)
                                          .prepareAuthEvent();
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
                                          backgroundColor:
                                              Colors.red.shade400,
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

                              // Name Input Field
                              TextFormField(
                                controller: _model.nameTextController,
                                focusNode: _model.nameFocusNode,
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: theme.bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF1B5E20),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  hintText: 'Enter your full name',
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
                                    Icons.person_outline,
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
                                validator: _model
                                    .nameTextControllerValidator
                                    .asValidator(context),
                              ),

                              const SizedBox(height: 16),

                              // Email Input Field
                              TextFormField(
                                controller: _model.emailTextController,
                                focusNode: _model.emailFocusNode,
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
                                    .emailTextControllerValidator
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
                                  hintText: 'Create a strong password',
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
                                    focusNode:
                                        FocusNode(skipTraversal: true),
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

                              const SizedBox(height: 16),

                              // Confirm Password Input Field
                              TextFormField(
                                controller:
                                    _model.confirmPasswordTextController,
                                focusNode: _model.confirmPasswordFocusNode,
                                autofocus: false,
                                obscureText:
                                    !_model.confirmPasswordVisibility,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: theme.bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF1B5E20),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  hintText: 'Confirm your password',
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
                                      () => _model.confirmPasswordVisibility =
                                          !_model.confirmPasswordVisibility,
                                    ),
                                    focusNode:
                                        FocusNode(skipTraversal: true),
                                    child: Icon(
                                      _model.confirmPasswordVisibility
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
                                    .confirmPasswordTextControllerValidator
                                    .asValidator(context),
                              ),

                              const SizedBox(height: 20),

                              // Sign Up Button
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
                                      GoRouter.of(context)
                                          .prepareAuthEvent();
                                      if (_model.passwordTextController
                                              .text !=
                                          _model
                                              .confirmPasswordTextController
                                              .text) {
                                        _showErrorSnackBar(
                                            'Passwords don\'t match!');
                                        return;
                                      }

                                      final user = await authManager
                                          .createAccountWithEmail(
                                        context,
                                        _model.emailTextController.text,
                                        _model.passwordTextController.text,
                                      );
                                      if (user == null) {
                                        return;
                                      }

                                      // Send email verification
                                      try {
                                        await currentUser
                                            ?.sendEmailVerification();

                                        // Show success message
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Account created! Please check your email to verify your account.',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            backgroundColor:
                                                Colors.green.shade600,
                                            behavior: SnackBarBehavior
                                                .floating,
                                            duration:
                                                Duration(seconds: 5),
                                          ),
                                        );
                                      } catch (e) {
                                        // Show warning if email verification fails
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Account created, but failed to send verification email. You can resend it from your profile.',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            backgroundColor:
                                                Colors.orange.shade600,
                                            behavior: SnackBarBehavior
                                                .floating,
                                            duration:
                                                Duration(seconds: 5),
                                          ),
                                        );
                                      }

                                      context.goNamedAuth(
                                          'vark_onboarding',
                                          context.mounted);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Sign Up',
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

                              // Sign In Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: theme.bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF1B5E20),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        context.goNamed('login'),
                                    child: Text(
                                      'Sign In',
                                      style: theme.bodyMedium.override(
                                        fontFamily: 'Inter',
                                        color: const Color(0xFF1B5E20),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration:
                                            TextDecoration.underline,
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
                                      borderRadius:
                                          BorderRadius.circular(8),
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
}
