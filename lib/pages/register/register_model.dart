import '/flutter_flow/flutter_flow_util.dart';
import 'register_widget.dart' show RegisterWidget;
import 'package:flutter/material.dart';

class RegisterModel extends FlutterFlowModel<RegisterWidget> {
  // Form key for validation
  final formKey = GlobalKey<FormState>();
  
  // State fields for TextFields
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;

  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;

  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;

  FocusNode? confirmPasswordFocusNode;
  TextEditingController? confirmPasswordTextController;
  late bool confirmPasswordVisibility;
  String? Function(BuildContext, String?)? confirmPasswordTextControllerValidator;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    confirmPasswordVisibility = false;
    
    // Flexible password validation - accepts 3+ characters
    passwordTextControllerValidator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'Password is required';
      }
      if (val.length < 3) {
        return 'Password must be at least 3 characters';
      }
      return null;
    };
    
    // Confirm password validation
    confirmPasswordTextControllerValidator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'Please confirm your password';
      }
      if (val != passwordTextController?.text) {
        return 'Passwords do not match';
      }
      return null;
    };
    
    // Basic name validation
    nameTextControllerValidator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'Name is required';
      }
      if (val.length < 2) {
        return 'Name must be at least 2 characters';
      }
      return null;
    };
    
    // Basic email validation
    emailTextControllerValidator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'Email is required';
      }
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
        return 'Please enter a valid email';
      }
      return null;
    };
  }

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();

    confirmPasswordFocusNode?.dispose();
    confirmPasswordTextController?.dispose();
  }
} 