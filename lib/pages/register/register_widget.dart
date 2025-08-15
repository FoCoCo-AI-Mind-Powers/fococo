import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF1B5E20),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => context.safePop(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B5E20), // Deep forest green
                  const Color(0xFF2E7D32), // Golf course green
                  const Color(0xFF388E3C), // Lighter golf green
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: AlignmentDirectional(0.0, -1.0),
                end: AlignmentDirectional(0.0, 1.0),
              ),
            ),
            child: Stack(
              children: [
                // Golf pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: GolfPatternPainter(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Header Section
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Golf ball with tee
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sports_golf,
                                color: Color(0xFF1B5E20),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Join the Club',
                              style: FlutterFlowTheme.of(context).displayMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start your journey to lower scores',
                              style: FlutterFlowTheme.of(context).bodyLarge.override(
                                fontFamily: 'Inter',
                                color: const Color(0xFFFFD54F), // Gold accent
                                fontSize: 16,
                                height: 1.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Form Section
                    Expanded(
                      flex: 4,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(32, 48, 32, 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Golf-themed welcome
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.golf_course,
                                      color: const Color(0xFF2E7D32),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Player Registration',
                                      style: FlutterFlowTheme.of(context).headlineSmall.override(
                                        fontFamily: 'Inter',
                                        color: const Color(0xFF1B5E20),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                
                                // Name Field
                                TextFormField(
                                  controller: _model.nameTextController,
                                  focusNode: _model.nameFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF2E7D32),
                                      height: 1.0,
                                    ),
                                    hintText: 'Enter your full name',
                                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: Colors.grey[400],
                                      height: 1.0,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2E7D32),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5FFF5), // Very light green tint
                                    contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF2E7D32),
                                      size: 20,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    height: 1.0,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                  validator: _model.nameTextControllerValidator.asValidator(context),
                                ),
                                const SizedBox(height: 20),
                                
                                // Email Field
                                TextFormField(
                                  controller: _model.emailTextController,
                                  focusNode: _model.emailFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF2E7D32),
                                      height: 1.0,
                                    ),
                                    hintText: 'Enter your email',
                                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: Colors.grey[400],
                                      height: 1.0,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2E7D32),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5FFF5),
                                    contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF2E7D32),
                                      size: 20,
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    height: 1.0,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _model.emailTextControllerValidator.asValidator(context),
                                ),
                                const SizedBox(height: 20),
                                
                                // Password Field
                                TextFormField(
                                  controller: _model.passwordTextController,
                                  focusNode: _model.passwordFocusNode,
                                  obscureText: !_model.passwordVisibility,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF2E7D32),
                                      height: 1.0,
                                    ),
                                    hintText: 'Create a strong password',
                                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: Colors.grey[400],
                                      height: 1.0,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2E7D32),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5FFF5),
                                    contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF2E7D32),
                                      size: 20,
                                    ),
                                    suffixIcon: InkWell(
                                      onTap: () => setState(() => _model.passwordVisibility = !_model.passwordVisibility),
                                      child: Icon(
                                        _model.passwordVisibility 
                                          ? Icons.visibility_outlined 
                                          : Icons.visibility_off_outlined,
                                        color: const Color(0xFF388E3C),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    height: 1.0,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                  validator: _model.passwordTextControllerValidator.asValidator(context),
                                ),
                                const SizedBox(height: 20),
                                
                                // Confirm Password Field
                                TextFormField(
                                  controller: _model.confirmPasswordTextController,
                                  focusNode: _model.confirmPasswordFocusNode,
                                  obscureText: !_model.confirmPasswordVisibility,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF2E7D32),
                                      height: 1.0,
                                    ),
                                    hintText: 'Confirm your password',
                                    hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: Colors.grey[400],
                                      height: 1.0,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2E7D32),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5FFF5),
                                    contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF2E7D32),
                                      size: 20,
                                    ),
                                    suffixIcon: InkWell(
                                      onTap: () => setState(() => _model.confirmPasswordVisibility = !_model.confirmPasswordVisibility),
                                      child: Icon(
                                        _model.confirmPasswordVisibility 
                                          ? Icons.visibility_outlined 
                                          : Icons.visibility_off_outlined,
                                        color: const Color(0xFF388E3C),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    height: 1.0,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                  validator: _model.confirmPasswordTextControllerValidator.asValidator(context),
                                ),
                                const SizedBox(height: 32),
                                
                                // Create Account Button with golf theme
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF2E7D32),
                                        const Color(0xFF388E3C),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: FFButtonWidget(
                                    onPressed: () async {
                                      GoRouter.of(context).prepareAuthEvent();
                                      if (_model.passwordTextController.text != _model.confirmPasswordTextController.text) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.warning_amber_rounded, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Text('Passwords don\'t match!'),
                                              ],
                                            ),
                                            backgroundColor: Colors.red.shade600,
                                          ),
                                        );
                                        return;
                                      }

                                      final user = await authManager.createAccountWithEmail(
                                        context,
                                        _model.emailTextController.text,
                                        _model.passwordTextController.text,
                                      );
                                      if (user == null) return;

                                      context.goNamedAuth('onboarding', context.mounted);
                                    },
                                    text: 'Tee Off Your Journey',
                                    icon: const Icon(
                                      Icons.sports_golf,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 56,
                                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                                      iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                                      color: Colors.transparent,
                                      textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                      ),
                                      elevation: 0,
                                      borderSide: const BorderSide(
                                        color: Colors.transparent,
                                        width: 0,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Sign In Link with golf ball divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        thickness: 1,
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Icon(
                                        Icons.sports_golf,
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
                                        size: 16,
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        thickness: 1,
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already on the course? ',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'Inter',
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        height: 1.0,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => context.goNamed('login'),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                              fontFamily: 'Inter',
                                              color: const Color(0xFF2E7D32),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: const Color(0xFF2E7D32),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

// Custom painter for golf course patterns
class GolfPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    
    // Draw golf ball patterns
    for (int i = 0; i < 3; i++) {
      final offset = Offset(
        size.width * 0.1 + (i * 80),
        size.height * 0.8 - (i * 40),
      );
      canvas.drawCircle(offset, 30, paint);
    }
    
    // Draw tee patterns
    final teePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 2; i++) {
      final x = size.width * (0.7 + i * 0.15);
      final y = size.height * (0.2 + i * 0.1);
      
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 4,
          height: 20,
        ),
        teePaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 