import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FoCoMap Tutorial Service
/// Provides interactive tutorials and onboarding for map features
class FoCoMapTutorialService {
  static final FoCoMapTutorialService _instance =
      FoCoMapTutorialService._internal();
  factory FoCoMapTutorialService() => _instance;
  FoCoMapTutorialService._internal();

  TutorialCoachMark? _tutorialCoachMark;
  List<TargetFocus> _targets = [];

  // Tutorial completion tracking
  static const String _tutorialCompletedKey = 'focomap_tutorial_completed';
  static const String _liveModeIntroKey = 'focomap_live_mode_intro';
  static const String _filterTutorialKey = 'focomap_filter_tutorial';
  static const String _layerTutorialKey = 'focomap_layer_tutorial';

  /// Check if main tutorial has been completed
  Future<bool> hasCompletedMainTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Mark main tutorial as completed
  Future<void> markMainTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// Check if live mode intro has been shown
  Future<bool> hasSeenLiveModeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_liveModeIntroKey) ?? false;
  }

  /// Mark live mode intro as seen
  Future<void> markLiveModeIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_liveModeIntroKey, true);
  }

  /// Start the main FoCoMap tutorial
  Future<void> startMainTutorial(
    BuildContext context, {
    required GlobalKey backButtonKey,
    required GlobalKey titleKey,
    required GlobalKey mapTypeKey,
    required GlobalKey liveToggleKey,
    required GlobalKey filtersKey,
    required GlobalKey layerMindMapKey,
    required GlobalKey layerShotMapKey,
    required GlobalKey layerSyncMapKey,
    required GlobalKey voiceButtonKey,
    required GlobalKey addDataKey,
  }) async {
    _targets.clear();

    // Welcome target
    _targets.add(
      TargetFocus(
        identify: "welcome",
        keyTarget: titleKey,
        alignSkip: Alignment.bottomRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) =>
                _buildWelcomeContent(context, controller),
          ),
        ],
      ),
    );

    // Map layers explanation
    _targets.add(
      TargetFocus(
        identify: "layers",
        keyTarget: layerMindMapKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) =>
                _buildLayersContent(context, controller),
          ),
        ],
      ),
    );

    // Live mode explanation
    _targets.add(
      TargetFocus(
        identify: "live_mode",
        keyTarget: liveToggleKey,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) =>
                _buildLiveModeContent(context, controller),
          ),
        ],
      ),
    );

    // Filters explanation
    _targets.add(
      TargetFocus(
        identify: "filters",
        keyTarget: filtersKey,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) =>
                _buildFiltersContent(context, controller),
          ),
        ],
      ),
    );

    // Voice input explanation
    _targets.add(
      TargetFocus(
        identify: "voice",
        keyTarget: voiceButtonKey,
        alignSkip: Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) =>
                _buildVoiceContent(context, controller),
          ),
        ],
      ),
    );

    // Sample data explanation
    _targets.add(
      TargetFocus(
        identify: "sample_data",
        keyTarget: addDataKey,
        alignSkip: Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) =>
                _buildSampleDataContent(context, controller),
          ),
        ],
      ),
    );

    // Map type selector
    _targets.add(
      TargetFocus(
        identify: "map_type",
        keyTarget: mapTypeKey,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) =>
                _buildMapTypeContent(context, controller),
          ),
        ],
      ),
    );

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black.withValues(alpha: 0.8),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () {
        markMainTutorialCompleted();
      },
      onSkip: () {
        markMainTutorialCompleted();
        return true;
      },
    );

    _tutorialCoachMark?.show(context: context);
  }

  /// Start live mode specific tutorial
  Future<void> startLiveModeTutorial(
    BuildContext context, {
    required GlobalKey liveIndicatorKey,
    required GlobalKey locationPanelKey,
    required GlobalKey scorePanelKey,
  }) async {
    if (await hasSeenLiveModeIntro()) return;

    _targets.clear();

    _targets.add(
      TargetFocus(
        identify: "live_indicator",
        keyTarget: liveIndicatorKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) =>
                _buildLiveIndicatorContent(context, controller),
          ),
        ],
      ),
    );

    _targets.add(
      TargetFocus(
        identify: "location_panel",
        keyTarget: locationPanelKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) =>
                _buildLocationPanelContent(context, controller),
          ),
        ],
      ),
    );

    _targets.add(
      TargetFocus(
        identify: "score_panel",
        keyTarget: scorePanelKey,
        alignSkip: Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) =>
                _buildScorePanelContent(context, controller),
          ),
        ],
      ),
    );

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.green.withValues(alpha: 0.8),
      textSkip: "GOT IT",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        markLiveModeIntroSeen();
      },
      onSkip: () {
        markLiveModeIntroSeen();
        return true;
      },
    );

    _tutorialCoachMark?.show(context: context);
  }

  /// Show quick tip for specific feature
  void showQuickTip(
    BuildContext context, {
    required GlobalKey targetKey,
    required String title,
    required String description,
    required IconData icon,
    Color? color,
  }) {
    _targets.clear();

    _targets.add(
      TargetFocus(
        identify: "quick_tip",
        keyTarget: targetKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildQuickTipContent(
              context,
              controller,
              title,
              description,
              icon,
              color ?? Colors.blue,
            ),
          ),
        ],
      ),
    );

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: (color ?? Colors.blue).withValues(alpha: 0.6),
      textSkip: "GOT IT",
      paddingFocus: 8,
      opacityShadow: 0.7,
      onFinish: () {},
      onSkip: () => true,
    );

    _tutorialCoachMark?.show(context: context);
  }

  // Content builders for different tutorial steps

  Widget _buildWelcomeContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Welcome to FoCoMap!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'FoCoMap visualizes your golf mental performance data on an interactive map. Let\'s explore the key features!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text('Skip Tour'),
              ),
              ElevatedButton(
                onPressed: () => controller.next(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Tour'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayersContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.layers, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Map Layers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Switch between three powerful views:',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _buildLayerItem('🧠 MindMap', 'Mental performance by location'),
          _buildLayerItem('🏌️ ShotMap', 'Technical shots and outcomes'),
          _buildLayerItem('🔄 SyncMap', 'Combined mental + technical view'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => controller.next(),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveModeContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.live_tv, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Live Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Enable live tracking during your round:',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('📍 Real-time GPS tracking'),
          _buildFeatureItem('🎤 Voice input for quick logging'),
          _buildFeatureItem('📊 Live performance updates'),
          _buildFeatureItem('🎯 Course context awareness'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '💡 Tip: Live mode requires Plus or Prime subscription',
              style: TextStyle(fontSize: 14, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => controller.next(),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list,
                    color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Smart Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Filter your data to find patterns:',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('🏌️ Club types (Driver, Irons, etc.)'),
          _buildFeatureItem('🧠 Mental cues (Visualization, Breathing)'),
          _buildFeatureItem('🏞️ Course types (Links, Parkland, etc.)'),
          _buildFeatureItem('📈 Performance levels'),
          const SizedBox(height: 16),
          const Text(
            'View real-time analytics and insights!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => controller.next(),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Voice Input',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Speak naturally about your round:',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _buildVoiceExample('"Felt confident on that drive"'),
          _buildVoiceExample('"7 iron from 150, missed short right"'),
          _buildVoiceExample('"Used breathing cue, great recovery"'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '🎤 AI automatically categorizes your input!',
              style: TextStyle(fontSize: 14, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => controller.next(),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleDataContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_location,
                    color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sample Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Try the demo with sample data:',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('🏌️ 25 sample rounds'),
          _buildFeatureItem('📍 500+ shot locations'),
          _buildFeatureItem('🇵🇹 8 Portuguese golf courses'),
          _buildFeatureItem('📊 Realistic performance patterns'),
          const SizedBox(height: 16),
          const Text(
            'Perfect for exploring all features!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => controller.next(),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.satellite_alt,
                    color: Colors.teal, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Map Views',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose your preferred map style:',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('🗺️ Standard - Clear street view'),
          _buildFeatureItem('🛰️ Satellite - Aerial imagery'),
          _buildFeatureItem('🔄 Hybrid - Best of both worlds'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '🎉 You\'re all set! Start exploring your golf data.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => controller.next(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Finish'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicatorContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Live Mode Active!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'The pulsing red dot indicates live tracking is active. Your location and voice inputs are being recorded in real-time.',
            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => controller.next(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPanelContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location Panel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Shows your current status and subscription tier. Live mode features are available based on your plan.',
            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => controller.next(),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildScorePanelContent(
      BuildContext context, TutorialCoachMarkController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mental Score Panel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Displays your current mental performance score and course information during live rounds.',
            style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => controller.next(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Playing!'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipContent(
    BuildContext context,
    TutorialCoachMarkController controller,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
                fontSize: 16, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => controller.next(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildLayerItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }

  Widget _buildVoiceExample(String example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        example,
        style: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
      ),
    );
  }

  /// Reset all tutorials (for testing)
  Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
    await prefs.remove(_liveModeIntroKey);
    await prefs.remove(_filterTutorialKey);
    await prefs.remove(_layerTutorialKey);
  }

  /// Dispose resources
  void dispose() {
    _tutorialCoachMark?.finish();
  }
}
