import 'package:flutter/material.dart';

import '/services/remote_config_service.dart';

/// Blocks the app when Firestore `app_settings` maintenance mode is enabled.
class MaintenanceGate extends StatefulWidget {
  const MaintenanceGate({super.key, required this.child});

  final Widget child;

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await RemoteConfigService().initialize();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Material(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final remote = RemoteConfigService();
    if (!remote.isMaintenanceMode) {
      return widget.child;
    }

    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build_circle_outlined, size: 56),
              const SizedBox(height: 24),
              Text(
                remote.maintenanceMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
