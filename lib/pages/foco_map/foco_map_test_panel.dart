import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_design_system.dart';
import '/services/focomap_test_data_generator.dart';
import '/auth/firebase_auth/auth_util.dart';

class FoCoMapTestPanel extends StatefulWidget {
  const FoCoMapTestPanel({
    super.key,
    this.onDataGenerated,
  });

  final VoidCallback? onDataGenerated;

  @override
  State<FoCoMapTestPanel> createState() => _FoCoMapTestPanelState();
}

class _FoCoMapTestPanelState extends State<FoCoMapTestPanel>
    with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Test data configuration
  int _roundCount = 5;
  int _shotsPerRound = 30;
  bool _includeLiveRound = true;
  bool _isGenerating = false;
  String _statusMessage = '';
  Color _statusColor = Colors.blue;

  // Quick presets
  final List<TestPreset> _presets = [
    TestPreset(
      name: 'Quick Test',
      description: 'Minimal data for quick testing',
      rounds: 3,
      shotsPerRound: 20,
      includeLive: true,
    ),
    TestPreset(
      name: 'Full Season',
      description: 'Complete season worth of data',
      rounds: 20,
      shotsPerRound: 50,
      includeLive: true,
    ),
    TestPreset(
      name: 'Tournament Week',
      description: 'Intensive tournament preparation data',
      rounds: 7,
      shotsPerRound: 72,
      includeLive: false,
    ),
    TestPreset(
      name: 'Practice Rounds',
      description: 'Practice session data with partial rounds',
      rounds: 10,
      shotsPerRound: 25,
      includeLive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateTestData() async {
    if (currentUser == null) {
      _updateStatus('Please sign in to generate test data', Colors.orange);
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating test data...';
      _statusColor = Colors.blue;
    });

    try {
      final result = await FoCoMapTestDataGenerator.generateCompleteTestData(
        userId: currentUser!.uid,
        roundCount: _roundCount,
        shotsPerRound: _shotsPerRound,
        includeLiveRound: _includeLiveRound,
      );

      if (result['success']) {
        _updateStatus(
          'Successfully generated ${result['roundsGenerated']} rounds with ${result['shotsGenerated']} shots!',
          Colors.green,
        );
        widget.onDataGenerated?.call();
        
        // Auto-close after success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        final errors = (result['errors'] as List).join('\n');
        _updateStatus('Error: $errors', Colors.red);
      }
    } catch (e) {
      _updateStatus('Failed to generate data: $e', Colors.red);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    if (currentUser == null) {
      _updateStatus('Please sign in to clear test data', Colors.orange);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Clear All Test Data?',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
                color: Colors.white,
              ),
        ),
        content: Text(
          'This will permanently delete all your FoCoMap data. This action cannot be undone.',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                color: Colors.white70,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Clearing test data...';
      _statusColor = Colors.orange;
    });

    try {
      await FoCoMapTestDataGenerator.clearTestData(currentUser!.uid);
      _updateStatus('All test data cleared successfully', Colors.green);
      widget.onDataGenerated?.call();
    } catch (e) {
      _updateStatus('Failed to clear data: $e', Colors.red);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _updateStatus(String message, Color color) {
    setState(() {
      _statusMessage = message;
      _statusColor = color;
    });
  }

  void _applyPreset(TestPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _roundCount = preset.rounds;
      _shotsPerRound = preset.shotsPerRound;
      _includeLiveRound = preset.includeLive;
    });
    _updateStatus('Applied "${preset.name}" preset', Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Data Generator',
                          style: FlutterFlowTheme.of(context).headlineMedium.override(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate realistic golf data for testing',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                color: Colors.white60,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white60),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Presets
                      Text(
                        'Quick Presets',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...(_presets.map((preset) => _buildPresetCard(preset))),

                      const SizedBox(height: 24),

                      // Custom Configuration
                      Text(
                        'Custom Configuration',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Round count slider
                      _buildSliderOption(
                        label: 'Number of Rounds',
                        value: _roundCount,
                        min: 1,
                        max: 30,
                        onChanged: (value) {
                          setState(() {
                            _roundCount = value.round();
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // Shots per round slider
                      _buildSliderOption(
                        label: 'Shots per Round',
                        value: _shotsPerRound.toDouble(),
                        min: 10,
                        max: 100,
                        onChanged: (value) {
                          setState(() {
                            _shotsPerRound = value.round();
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // Include live round toggle
                      GlassDesignSystem.glassBackground(
                        borderRadius: BorderRadius.circular(16),
                        tintColor: Colors.white,
                        opacity: 0.05,
                        child: SwitchListTile(
                          title: Text(
                            'Include Live Round',
                            style: FlutterFlowTheme.of(context).bodyLarge.override(
                                  color: Colors.white,
                                ),
                          ),
                          subtitle: Text(
                            'Add an active round for real-time testing',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  color: Colors.white60,
                                ),
                          ),
                          value: _includeLiveRound,
                          onChanged: (value) {
                            setState(() {
                              _includeLiveRound = value;
                            });
                          },
                          activeColor: FlutterFlowTheme.of(context).primary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Data preview
                      _buildDataPreview(),

                      const SizedBox(height: 24),

                      // Status message
                      if (_statusMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _statusColor == Colors.green
                                    ? Icons.check_circle
                                    : _statusColor == Colors.red
                                        ? Icons.error
                                        : Icons.info,
                                color: _statusColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FFButtonWidget(
                        onPressed: _isGenerating ? null : _clearTestData,
                        text: 'Clear All Data',
                        options: FFButtonOptions(
                          height: 50,
                          color: Colors.transparent,
                          textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                fontFamily: 'Inter',
                                color: Colors.red,
                              ),
                          elevation: 0,
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FFButtonWidget(
                        onPressed: _isGenerating ? null : _generateTestData,
                        text: _isGenerating ? 'Generating...' : 'Generate Test Data',
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 20),
                        options: FFButtonOptions(
                          height: 50,
                          color: FlutterFlowTheme.of(context).primary,
                          textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                fontFamily: 'Inter',
                                color: Colors.white,
                              ),
                          elevation: 2,
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetCard(TestPreset preset) {
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassDesignSystem.glassBackground(
          borderRadius: BorderRadius.circular(16),
          tintColor: Colors.white,
          opacity: 0.05,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dataset,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        preset.description,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              color: Colors.white60,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${preset.rounds} rounds • ${preset.shotsPerRound} shots/round',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderOption({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    color: Colors.white,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.round().toString(),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: FlutterFlowTheme.of(context).primary,
            inactiveTrackColor: Colors.white10,
            thumbColor: FlutterFlowTheme.of(context).primary,
            overlayColor: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDataPreview() {
    final totalShots = _roundCount * _shotsPerRound;
    final estimatedTime = (totalShots * 0.1).round(); // Rough estimate

    return GlassDesignSystem.glassBackground(
      borderRadius: BorderRadius.circular(16),
      tintColor: Colors.blue,
      opacity: 0.05,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Preview',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPreviewRow('Total Rounds:', '$_roundCount rounds'),
            _buildPreviewRow('Shots per Round:', '$_shotsPerRound shots'),
            _buildPreviewRow('Total Data Points:', '$totalShots shots'),
            _buildPreviewRow('Estimated Time:', '~$estimatedTime seconds'),
            if (_includeLiveRound)
              _buildPreviewRow('Live Round:', 'Yes (partial round)'),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  color: Colors.white60,
                ),
          ),
          Text(
            value,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// Test preset model
class TestPreset {
  final String name;
  final String description;
  final int rounds;
  final int shotsPerRound;
  final bool includeLive;

  TestPreset({
    required this.name,
    required this.description,
    required this.rounds,
    required this.shotsPerRound,
    required this.includeLive,
  });
}