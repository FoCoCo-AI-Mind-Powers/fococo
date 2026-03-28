import '/flutter_flow/flutter_flow_util.dart';
import 'register_widget.dart' show RegisterWidget;
import 'package:flutter/material.dart';

class RegisterModel extends FlutterFlowModel<RegisterWidget> {
  // State fields for email
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;

  // State fields for password
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
  }

  @override
  void dispose() {
    emailFocusNode?.dispose();
    emailTextController?.dispose();
    emailFocusNode = null;
    emailTextController = null;

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
    passwordFocusNode = null;
    passwordTextController = null;
  }
}
