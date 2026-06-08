import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

/// Legacy route — redirects to the single edit-profile flow.
class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  static String routeName = 'profile';
  static String routePath = '/profile';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.goNamed('edit_profile');
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
