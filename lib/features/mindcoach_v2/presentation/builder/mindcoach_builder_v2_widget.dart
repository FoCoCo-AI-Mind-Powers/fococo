import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/adaptive_ui/adaptive_ui.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_context_resolver.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/glass_design_system.dart';

class MindCoachBuilderV2Widget extends StatefulWidget {
  const MindCoachBuilderV2Widget({
    super.key,
    required this.onGenerateRequested,
  });

  final Future<void> Function(MindCoachV2GenerateRequest request)
      onGenerateRequested;

  @override
  State<MindCoachBuilderV2Widget> createState() =>
      _MindCoachBuilderV2WidgetState();
}

class _MindCoachBuilderV2WidgetState extends State<MindCoachBuilderV2Widget> {
  final TextEditingController _goalController = TextEditingController();
  final MindCoachV2ContextResolver _contextResolver =
      MindCoachV2ContextResolver();

  MindCoachV2ContextMode _mode = MindCoachV2ContextMode.offDay;
  String _tone = 'calm';
  String _vark = 'ReadWrite';
  String _length = 'standard';
  bool _submitting = false;
  bool _contextLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final context = await _contextResolver.inferContextMode(currentUserUid);
    if (!mounted) {
      return;
    }
    setState(() {
      _contextLoaded = true;
      _mode = context == MindCoachV2ContextMode.duringRound
          ? MindCoachV2ContextMode.offDay
          : context;
    });
  }

  Future<void> _generate() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.onGenerateRequested(
        MindCoachV2GenerateRequest(
          contextMode: _mode,
          entrySource: 'builder',
          preferredDeliveryLength: _length,
          goal: _goalController.text.trim(),
          tone: _tone,
          varkMode: _vark,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
    }
  }

  void _onDropdownTap() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (!_contextLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final glassDecoration = InputDecoration(
      labelStyle: TextStyle(color: theme.primaryText),
      hintStyle: TextStyle(color: theme.secondaryText),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.primaryText.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primary, width: 2),
      ),
      filled: true,
      fillColor: theme.secondaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassDesignSystem.glassBackground(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Experience Builder',
                  style: theme.headlineSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Available for before-round, after-round, and off-day sessions.',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<MindCoachV2ContextMode>(
                  initialValue: _mode,
                  decoration: glassDecoration.copyWith(labelText: 'Context'),
                  dropdownColor: theme.secondaryBackground,
                  items: const [
                    MindCoachV2ContextMode.beforeRound,
                    MindCoachV2ContextMode.afterRound,
                    MindCoachV2ContextMode.offDay,
                  ]
                      .map(
                        (mode) => DropdownMenuItem<MindCoachV2ContextMode>(
                          value: mode,
                          child: Text(mode.wireValue.replaceAll('_', ' ')),
                        ),
                      )
                      .toList(),
                  onTap: _onDropdownTap,
                  onChanged: (value) {
                    if (value == null) return;
                    HapticFeedback.mediumImpact();
                    setState(() => _mode = value);
                  },
                ),
                const SizedBox(height: 12),
                FoCoCoAdaptiveTextField(
                  controller: _goalController,
                  placeholder: 'Example: calm first tee nerves',
                  maxLines: 3,
                  decoration: glassDecoration.copyWith(
                    labelText: 'Goal (optional)',
                    hintText: 'Example: calm first tee nerves',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _tone,
                  decoration: glassDecoration.copyWith(labelText: 'Tone'),
                  dropdownColor: theme.secondaryBackground,
                  items: const ['calm', 'directive', 'reassuring']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onTap: _onDropdownTap,
                  onChanged: (value) {
                    if (value == null) return;
                    HapticFeedback.mediumImpact();
                    setState(() => _tone = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _vark,
                  decoration: glassDecoration.copyWith(labelText: 'VARK mode'),
                  dropdownColor: theme.secondaryBackground,
                  items: const ['Visual', 'Aural', 'ReadWrite', 'Kinesthetic']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onTap: _onDropdownTap,
                  onChanged: (value) {
                    if (value == null) return;
                    HapticFeedback.mediumImpact();
                    setState(() => _vark = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _length,
                  decoration: glassDecoration.copyWith(labelText: 'Length'),
                  dropdownColor: theme.secondaryBackground,
                  items: const ['micro', 'standard', 'deep']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onTap: _onDropdownTap,
                  onChanged: (value) {
                    if (value == null) return;
                    HapticFeedback.mediumImpact();
                    setState(() => _length = value);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FoCoCoAdaptiveButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            _generate();
                          },
                    label: _submitting ? 'Generating...' : 'Generate Experience',
                    enabled: !_submitting,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
