import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/services/auth_flow_service.dart';

/// Runs the post-auth onboarding / paywall gate after the app has warmed up.
///
/// Splash intentionally skips [AuthFlowService.resolvePostAuthDecision] during
/// the iOS launch window; this gate picks up the check once the tab shell is
/// mounted and Firestore is safe to touch.
class DeferredAuthFlowGate {
  DeferredAuthFlowGate._();

  static bool _ranThisSession = false;

  static Future<void> runIfNeeded(BuildContext context) async {
    if (_ranThisSession) {
      return;
    }
    _ranThisSession = true;

    // Match FoCoCo tab insight deferral — stay out of the launch Firestore window.
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!context.mounted) {
      return;
    }

    final decision = await AuthFlowService.instance.resolvePostAuthDecision();
    if (!context.mounted) {
      return;
    }

    if (decision.routeName == 'fococo') {
      return;
    }

    GoRouter.of(context).clearRedirectLocation();
    context.goNamed(decision.routeName, extra: decision.extra);
  }
}
