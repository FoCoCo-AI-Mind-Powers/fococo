// This file shows how to integrate the walkthrough and test panel into the existing FoCoMap widget

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'foco_map_walkthrough.dart';
import 'foco_map_test_panel.dart';

// Add these methods to the _FoCoMapWidgetState class:

class FoCoMapEnhancements {
  // Add this to initState() after other initializations
  static Future<void> checkAndShowWalkthrough(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWalkthrough = prefs.getBool('focomap_walkthrough_seen') ?? false;
    
    if (!hasSeenWalkthrough && context.mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => FoCoMapWalkthrough(
            onComplete: () async {
              await prefs.setBool('focomap_walkthrough_seen', true);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            onSkip: () async {
              await prefs.setBool('focomap_walkthrough_seen', true);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        );
      }
    }
  }

  // Add this method to show the test panel
  static void showTestPanel(BuildContext context, VoidCallback onDataGenerated) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoCoMapTestPanel(
        onDataGenerated: onDataGenerated,
      ),
    );
  }

  // Add this method to show the walkthrough on demand
  static void showWalkthroughManually(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FoCoMapWalkthrough(
        onComplete: () {
          Navigator.of(context).pop();
        },
        onSkip: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Enhanced UI components to add to the existing FoCoMap

  // Add this floating action button for test data (development mode)
  static Widget buildTestDataFAB(BuildContext context, VoidCallback onPressed) {
    return Positioned(
      bottom: 180,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Test Data Button
          FloatingActionButton(
            heroTag: "test_data_fab",
            onPressed: onPressed,
            backgroundColor: Colors.purple,
            child: const Icon(Icons.science, color: Colors.white),
            tooltip: 'Generate Test Data',
          ),
          const SizedBox(height: 8),
          Text(
            'Test Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Add this help button to the top navigation
  static Widget buildHelpButton(BuildContext context, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.help_outline,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // Add these tooltips to existing UI elements
  static Widget wrapWithTooltip({
    required Widget child,
    required String message,
  }) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }

  // Feature discovery overlay for first-time users
  static Widget buildFeatureDiscovery({
    required Widget child,
    required String featureId,
    required String title,
    required String description,
  }) {
    return Stack(
      children: [
        child,
        // This would be replaced with a proper feature discovery package
        // Example: feature_discovery or showcaseview
      ],
    );
  }

  // Progress indicator for data loading
  static Widget buildDataLoadingOverlay({
    required bool isLoading,
    required String message,
    required double progress,
  }) {
    if (!isLoading) return const SizedBox.shrink();
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (progress > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Interactive tutorial hints
  static List<TutorialHint> getTutorialHints() {
    return [
      TutorialHint(
        id: 'voice_button',
        message: 'Tap here to log your golf data using voice',
        targetKey: GlobalKey(),
        position: TutorialPosition.above,
      ),
      TutorialHint(
        id: 'layer_selector',
        message: 'Switch between MindMap, ShotMap, and SyncMap layers',
        targetKey: GlobalKey(),
        position: TutorialPosition.below,
      ),
      TutorialHint(
        id: 'live_mode',
        message: 'Enable live mode for real-time tracking during your round',
        targetKey: GlobalKey(),
        position: TutorialPosition.left,
      ),
      TutorialHint(
        id: 'marker_tap',
        message: 'Tap any marker to see detailed information',
        targetKey: GlobalKey(),
        position: TutorialPosition.center,
      ),
    ];
  }
}

// Tutorial hint model
class TutorialHint {
  final String id;
  final String message;
  final GlobalKey targetKey;
  final TutorialPosition position;

  TutorialHint({
    required this.id,
    required this.message,
    required this.targetKey,
    required this.position,
  });
}

enum TutorialPosition { above, below, left, right, center }

// Example integration code for the existing FoCoMap widget:
/*
// In _FoCoMapWidgetState:

@override
void initState() {
  super.initState();
  // ... existing initialization code ...
  
  // Check and show walkthrough
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FoCoMapEnhancements.checkAndShowWalkthrough(context);
  });
}

// In the build method, add these widgets to the Stack:

Stack(
  children: [
    // ... existing map and UI elements ...
    
    // Test data button (only in debug mode)
    if (kDebugMode)
      FoCoMapEnhancements.buildTestDataFAB(
        context,
        () {
          FoCoMapEnhancements.showTestPanel(context, () {
            _loadMapData(); // Refresh map after generating data
          });
        },
      ),
    
    // Help button in navigation bar
    Positioned(
      top: 60,
      right: 70,
      child: SafeArea(
        child: FoCoMapEnhancements.buildHelpButton(
          context,
          () {
            FoCoMapEnhancements.showWalkthroughManually(context);
          },
        ),
      ),
    ),
    
    // Data loading overlay
    FoCoMapEnhancements.buildDataLoadingOverlay(
      isLoading: _isLoadingData,
      message: 'Loading golf data...',
      progress: _loadingProgress,
    ),
  ],
)

// Wrap interactive elements with tooltips:
FoCoMapEnhancements.wrapWithTooltip(
  message: 'Toggle between map types',
  child: _buildMapTypeButton(),
)
*/