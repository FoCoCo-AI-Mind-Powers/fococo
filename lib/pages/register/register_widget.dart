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
        backgroundColor: const Color(0xFF0B4D2C),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B4D2C), Color(0xFF2E8B57)],
                stops: [0.0, 1.0],
                begin: AlignmentDirectional(0.0, -1.0),
                end: AlignmentDirectional(0.0, 1.0),
              ),
            ),
            child: Column(
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
                        Text(
                          'Create Account',
                          style: FlutterFlowTheme.of(context).displayMedium.override(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join the mental game revolution',
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.0,
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(32, 48, 32, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          // Name Field
                          TextFormField(
                            controller: _model.nameTextController,
                            focusNode: _model.nameFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.grey[600],
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
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0B4D2C),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF0B4D2C),
                                size: 20,
                              ),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              height: 1.0,
                              color: FlutterFlowTheme.of(context).primaryBackground,
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
                                color: Colors.grey[600],
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
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0B4D2C),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Color(0xFF0B4D2C),
                                size: 20,
                              ),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              height: 1.0,
                              color: FlutterFlowTheme.of(context).primaryBackground,
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
                                color: Colors.grey[600],
                                height: 1.0,
                              ),
                              hintText: 'Create a password',
                              hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.grey[400],
                                height: 1.0,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0B4D2C),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF0B4D2C),
                                size: 20,
                              ),
                              suffixIcon: InkWell(
                                onTap: () => setState(() => _model.passwordVisibility = !_model.passwordVisibility),
                                child: Icon(
                                  _model.passwordVisibility 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              height: 1.0,
                              color: FlutterFlowTheme.of(context).primaryBackground,
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
                                color: Colors.grey[600],
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
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF0B4D2C),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF0B4D2C),
                                size: 20,
                              ),
                              suffixIcon: InkWell(
                                onTap: () => setState(() => _model.confirmPasswordVisibility = !_model.confirmPasswordVisibility),
                                child: Icon(
                                  _model.confirmPasswordVisibility 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              height: 1.0,
                              color: FlutterFlowTheme.of(context).primaryBackground,
                            ),
                            validator: _model.confirmPasswordTextControllerValidator.asValidator(context),
                          ),
                          const SizedBox(height: 32),
                          
                          // Create Account Button
                          FFButtonWidget(
                            onPressed: () async {
                              GoRouter.of(context).prepareAuthEvent();
                              if (_model.passwordTextController.text != _model.confirmPasswordTextController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Passwords don\'t match!')),
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
                            text: 'Create Account',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 56,
                              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                              color: const Color(0xFF0B4D2C),
                              textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                              elevation: 3,
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  height: 1.0,
                                ),
                              ),
                              InkWell(
                                onTap: () => context.goNamed('login'),
                                child: Text(
                                  'Sign In',
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: const Color(0xFF0B4D2C),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 