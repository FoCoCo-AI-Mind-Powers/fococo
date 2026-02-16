import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_context_resolver.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_contextLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Custom Experience Builder', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text(
          'Available for before-round, after-round, and off-day sessions.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<MindCoachV2ContextMode>(
          initialValue: _mode,
          decoration: const InputDecoration(labelText: 'Context'),
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
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _mode = value;
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _goalController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Goal (optional)',
            hintText: 'Example: calm first tee nerves',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _tone,
          decoration: const InputDecoration(labelText: 'Tone'),
          items: const ['calm', 'directive', 'reassuring']
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _tone = value;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _vark,
          decoration: const InputDecoration(labelText: 'VARK mode'),
          items: const ['Visual', 'Aural', 'ReadWrite', 'Kinesthetic']
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _vark = value;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _length,
          decoration: const InputDecoration(labelText: 'Length'),
          items: const ['micro', 'standard', 'deep']
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _length = value;
            });
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _generate,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate Experience'),
          ),
        ),
      ],
    );
  }
}
