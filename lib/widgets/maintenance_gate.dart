import 'package:flutter/material.dart';
import 'package:fluid_background/fluid_background.dart';

import '/services/remote_config_service.dart';

/// FoCoCo tab shell tint — keep in sync with [FoCoCoTabWidget].
const Color kFoCoCoShellTint = Color(0xFF0F0514);

/// Shared boot / gate backdrop matching the FoCoCo tab [FluidBackground].
class FoCoCoShellBootBackdrop extends StatelessWidget {
  const FoCoCoShellBootBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  static const Color _primary = Color(0xFFFEA400);
  static const Color _secondary = Color(0xFF1E40AF);
  static const Color _tertiary = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kFoCoCoShellTint,
      child: ColoredBox(
        color: kFoCoCoShellTint,
        child: FluidBackground(
          initialColors: InitialColors.custom([
            _primary.withValues(alpha: 0.52),
            _secondary.withValues(alpha: 0.48),
            _tertiary.withValues(alpha: 0.42),
          ]),
          initialPositions: InitialOffsets.random(3),
          bubblesSize: 440,
          velocity: 82,
          bubbleMutationDuration: const Duration(minutes: 45),
          allowColorChanging: false,
          child: child,
        ),
      ),
    );
  }
}

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
    // Do not block first paint on a default Material loader — let the router
    // splash / FoCoCo shell show while remote config initializes.
    if (!_ready) {
      return widget.child;
    }

    final remote = RemoteConfigService();
    if (!remote.isMaintenanceMode) {
      return widget.child;
    }

    return FoCoCoShellBootBackdrop(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 56,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 24),
              Text(
                remote.maintenanceMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
