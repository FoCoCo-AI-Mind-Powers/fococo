import 'package:flutter/material.dart';

import 'caddyplay_widget.dart';

/// Compatibility wrapper: keep GolfSync route/name while rendering CaddyPlay.
class GolfSyncWidget extends StatelessWidget {
  const GolfSyncWidget({super.key});

  static String routeName = 'golf_sync';
  static String routePath = '/golf_sync';

  @override
  Widget build(BuildContext context) {
    return const CaddyPlayWidget();
  }
}
