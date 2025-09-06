import 'package:flutter/material.dart';
import '/pages/splash/enhanced_splash_widget.dart';

/// Test widget to verify the enhanced splash screen integration
class SplashTestWidget extends StatelessWidget {
  const SplashTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EnhancedSplashWidget(),
    );
  }
}

