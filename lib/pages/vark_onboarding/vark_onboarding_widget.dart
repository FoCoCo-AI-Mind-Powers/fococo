import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vark_onboarding_model.dart';
export 'vark_onboarding_model.dart';

class VarkOnboardingWidget extends StatefulWidget {
  const VarkOnboardingWidget({super.key});

  static String routeName = 'vark_onboarding';
  static String routePath = '/vark_onboarding';

  @override
  State<VarkOnboardingWidget> createState() => _VarkOnboardingWidgetState();
}

class _VarkOnboardingWidgetState extends State<VarkOnboardingWidget>
    with TickerProviderStateMixin {
  late VarkOnboardingModel _model;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late PageController _pageController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Loading and error states
  bool _isSaving = false;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VarkOnboardingModel());

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pageController = PageController();
    _fadeController.forward();

    // Load any saved progress
    _loadSavedProgress();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _pageController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_model.currentStep < _model.totalSteps - 1) {
      // Auto-save progress when moving to next step
      _autoSaveProgress();

      setState(() {
        _model.currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _slideController.forward(from: 0);
    } else {
      _completeOnboarding();
    }
  }

  void _autoSaveProgress() async {
    try {
      final Map<String, dynamic> tempData = {
        'currentStep': _model.currentStep,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _saveToLocalStorage(tempData);
    } catch (e) {
      // Silent fail for auto-save
      print('Auto-save failed: $e');
    }
  }

  void _previousStep() {
    if (_model.currentStep > 0) {
      setState(() {
        _model.currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    // Calculate VARK scores if we're on the results page
    if (_model.currentStep == 5) {
      setState(() {
        _isSaving = true;
        _hasError = false;
      });

      _showLoadingDialog();

      try {
        await _saveUserProfile();

        // Clear local storage on successful save
        await _clearLocalStorage();

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showSuccessDialog();

          // Navigate after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.goNamed('subscription_onboarding');
            }
          });
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          setState(() {
            _hasError = true;
          });

          _showErrorDialog(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  String _getSecondaryStyle(Map<String, double> scores) {
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedScores.length > 1 ? sortedScores[1].key : sortedScores[0].key;
  }

  // Step 1: Welcome & Purpose Setting
  Widget _buildWelcomeStep(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Logo
          ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _fadeController,
              curve: Curves.easeOutBack,
            )),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.golf_course,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Welcome Text
          FadeTransition(
            opacity: _fadeController,
            child: Column(
              children: [
                Text(
                  'Welcome to FoCoCo',
                  style: theme.displaySmall.override(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Your Personal Mental Performance Journey',
                  textAlign: TextAlign.center,
                  style: theme.headlineSmall.override(
                    fontFamily: 'Inter',
                    color: const Color(0xFFE0A800),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 32),

                // Purpose Cards
                ...[
                  _buildPurposeCard(
                    icon: FontAwesomeIcons.brain,
                    title: 'Personalized Coaching',
                    description:
                        'AI-powered insights tailored to your unique learning style',
                    color: const Color(0xFF4CAF50),
                    theme: theme,
                  ),
                  _buildPurposeCard(
                    icon: FontAwesomeIcons.chartLine,
                    title: 'Track Your Progress',
                    description:
                        'Measure your mental game improvement over time',
                    color: const Color(0xFF2196F3),
                    theme: theme,
                  ),
                  _buildPurposeCard(
                    icon: FontAwesomeIcons.trophy,
                    title: 'Achieve Peak Performance',
                    description:
                        'Unlock your full potential on the golf course',
                    color: const Color(0xFFE0A800),
                    theme: theme,
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // CTA Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 32),
            child: FFButtonWidget(
              onPressed: _nextStep,
              text: 'Begin Your Journey',
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
              options: FFButtonOptions(
                height: 56,
                color: const Color(0xFFE0A800),
                textStyle: theme.titleMedium.override(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required FlutterFlowTheme theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.titleSmall.override(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.bodySmall.override(
                    fontFamily: 'Inter',
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Personal Foundation
  Widget _buildPersonalFoundationStep(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primary,
                        theme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _model.getStepTitle(),
                        style: theme.headlineSmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        _model.getStepSubtitle(),
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText,
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Name Input
            Text(
              'What should your mental performance coach call you?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model.coachingNameController,
              onChanged: (value) => setState(() => _model.coachingName = value),
              decoration: InputDecoration(
                hintText: 'Enter your preferred name',
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: theme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Age Selection
            Text(
              'How old are you?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Age',
                        style: theme.bodyLarge,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${_model.age}',
                          style: theme.titleMedium.override(
                            fontFamily: 'Montserrat',
                            color: theme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: theme.primary,
                      inactiveTrackColor: theme.primary.withValues(alpha: 0.2),
                      thumbColor: theme.primary,
                      overlayColor: theme.primary.withValues(alpha: 0.2),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _model.age.toDouble(),
                      min: 18,
                      max: 80,
                      onChanged: (value) =>
                          setState(() => _model.age = value.round()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Golf Experience
            Text(
              'How long have you been on your golf journey?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                'Beginner',
                'Recreational',
                'Intermediate',
                'Advanced',
                'Competitive',
              ]
                  .map((level) => _buildSelectionChip(
                        label: level,
                        isSelected: _model.golfExperience == level,
                        onTap: () =>
                            setState(() => _model.golfExperience = level),
                        theme: theme,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Golf Draws
            Text(
              'What draws you most to golf?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                'Relaxation',
                'Competition',
                'Social',
                'Personal Challenge',
                'Professional',
              ]
                  .map((draw) => _buildSelectionChip(
                        label: draw,
                        isSelected: _model.golfDraws == draw,
                        onTap: () => setState(() => _model.golfDraws = draw),
                        theme: theme,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Handicap
            Text(
              'Current handicap (optional)',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Handicap',
                        style: theme.bodyLarge,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _model.handicap.toStringAsFixed(1),
                          style: theme.titleMedium.override(
                            fontFamily: 'Montserrat',
                            color: theme.secondary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: theme.secondary,
                      inactiveTrackColor:
                          theme.secondary.withValues(alpha: 0.2),
                      thumbColor: theme.secondary,
                      overlayColor: theme.secondary.withValues(alpha: 0.2),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _model.handicap,
                      min: -5,
                      max: 54,
                      divisions: 590,
                      onChanged: (value) =>
                          setState(() => _model.handicap = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Continue Button
            FFButtonWidget(
              onPressed: _model.canProceedToNextStep() ? _nextStep : null,
              text: 'Continue',
              options: FFButtonOptions(
                width: double.infinity,
                height: 56,
                color: _model.canProceedToNextStep()
                    ? theme.primary
                    : theme.secondaryText,
                disabledColor: theme.secondaryText.withValues(alpha: 0.3),
                textStyle: theme.titleMedium.override(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
                elevation: _model.canProceedToNextStep() ? 3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required FlutterFlowTheme theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primary : theme.alternate,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.bodyMedium.override(
            fontFamily: 'Inter',
            color: isSelected ? Colors.white : theme.primaryText,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // Step 3: Golf & Mental Game Profile
  Widget _buildMentalGameProfileStep(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.secondary,
                        theme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _model.getStepTitle(),
                        style: theme.headlineSmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        _model.getStepSubtitle(),
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText,
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Mental Challenges
            Text(
              'What mental challenges do you face on the course?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            Text(
              'Select all that apply',
              style: theme.bodySmall.override(
                fontFamily: 'Inter',
                color: theme.secondaryText,
                fontSize: 13,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),

            // Challenge Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _model.mentalChallengeOptions.length,
              itemBuilder: (context, index) {
                final challenge = _model.mentalChallengeOptions[index];
                final isSelected =
                    _model.mentalChallenges.contains(challenge['id']);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _model.mentalChallenges.remove(challenge['id']);
                      } else {
                        _model.mentalChallenges.add(challenge['id']);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.secondary.withValues(alpha: 0.1)
                          : theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? theme.secondary : theme.alternate,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          challenge['icon'],
                          color: isSelected
                              ? theme.secondary
                              : theme.secondaryText,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          challenge['label'],
                          textAlign: TextAlign.center,
                          style: theme.bodySmall.override(
                            fontFamily: 'Inter',
                            color: isSelected
                                ? theme.secondary
                                : theme.primaryText,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Mental Goals
            Text(
              'What mental breakthrough would transform your game?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model.mentalGoalsController,
              onChanged: (value) => setState(() => _model.mentalGoals = value),
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'E.g., "I want to stay calm and focused during pressure situations"',
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: theme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Playing Frequency
            Text(
              'How often do you play golf?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildFrequencyOption(
                  'Daily',
                  'I play almost every day',
                  Icons.star,
                  theme,
                ),
                _buildFrequencyOption(
                  '2-3 times per week',
                  'Regular practice and rounds',
                  Icons.calendar_today,
                  theme,
                ),
                _buildFrequencyOption(
                  'Weekly',
                  'Once a week on average',
                  Icons.weekend,
                  theme,
                ),
                _buildFrequencyOption(
                  'Monthly',
                  'A few times per month',
                  Icons.event,
                  theme,
                ),
                _buildFrequencyOption(
                  'Occasionally',
                  'When time permits',
                  Icons.access_time,
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Continue Button
            FFButtonWidget(
              onPressed: _model.canProceedToNextStep() ? _nextStep : null,
              text: 'Continue',
              options: FFButtonOptions(
                width: double.infinity,
                height: 56,
                color: _model.canProceedToNextStep()
                    ? theme.primary
                    : theme.secondaryText,
                disabledColor: theme.secondaryText.withValues(alpha: 0.3),
                textStyle: theme.titleMedium.override(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
                elevation: _model.canProceedToNextStep() ? 3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(
    String title,
    String subtitle,
    IconData icon,
    FlutterFlowTheme theme,
  ) {
    final isSelected = _model.playingFrequency == title;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _model.playingFrequency = title),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primary.withValues(alpha: 0.1)
                : theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primary : theme.alternate,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primary
                      : theme.secondaryText.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : theme.secondaryText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.bodyLarge.override(
                        fontFamily: 'Inter',
                        color: isSelected ? theme.primary : theme.primaryText,
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.bodySmall.override(
                        fontFamily: 'Inter',
                        color: theme.secondaryText,
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 4: VARK Assessment
  Widget _buildVARKAssessmentStep(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2196F3),
                        const Color(0xFF4CAF50),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _model.getStepTitle(),
                        style: theme.headlineSmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        _model.getStepSubtitle(),
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText,
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Question Progress
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_model.currentQuestionIndex + 1} of ${_model.varkQuestions.length}',
                      style: theme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: theme.secondaryText,
                        fontSize: 14,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '${((_model.currentQuestionIndex + 1) / _model.varkQuestions.length * 100).round()}%',
                      style: theme.bodyMedium.override(
                        fontFamily: 'Inter',
                        color: theme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_model.currentQuestionIndex + 1) /
                      _model.varkQuestions.length,
                  backgroundColor: theme.alternate,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Question Content
          Expanded(
            child: PageView.builder(
              controller:
                  PageController(initialPage: _model.currentQuestionIndex),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _model.varkQuestions.length,
              onPageChanged: (index) =>
                  setState(() => _model.currentQuestionIndex = index),
              itemBuilder: (context, index) {
                final question = _model.varkQuestions[index];

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primary.withValues(alpha: 0.05),
                              theme.secondary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.golf_course,
                              color: theme.primary,
                              size: 32,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              question['question'],
                              style: theme.headlineSmall.override(
                                fontFamily: 'Montserrat',
                                color: theme.primaryText,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            if (question['context'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                question['context'],
                                style: theme.bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: theme.secondaryText,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      ...List.generate(
                        question['options'].length,
                        (optionIndex) => _buildVARKOption(
                          question['options'][optionIndex],
                          optionIndex,
                          index,
                          theme,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Navigation Buttons
          if (_model.varkAnswers.length == _model.varkQuestions.length)
            Container(
              padding: const EdgeInsets.all(32),
              child: FFButtonWidget(
                onPressed: _nextStep,
                text: 'Continue to Results',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 56,
                  color: theme.primary,
                  textStyle: theme.titleMedium.override(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  elevation: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVARKOption(
    Map<String, dynamic> option,
    int optionIndex,
    int questionIndex,
    FlutterFlowTheme theme,
  ) {
    final isSelected = _model.varkAnswers.length > questionIndex &&
        _model.varkAnswers[questionIndex] == optionIndex;

    final typeColors = {
      'visual': const Color(0xFF2196F3),
      'aural': const Color(0xFF4CAF50),
      'readWrite': const Color(0xFFFF9800),
      'kinesthetic': const Color(0xFF9C27B0),
    };

    final typeIcons = {
      'visual': FontAwesomeIcons.eye,
      'aural': FontAwesomeIcons.volumeHigh,
      'readWrite': FontAwesomeIcons.pencil,
      'kinesthetic': FontAwesomeIcons.handPointer,
    };

    final color = typeColors[option['type']] ?? theme.primary;
    final icon = typeIcons[option['type']] ?? Icons.help;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (_model.varkAnswers.length > questionIndex) {
                _model.varkAnswers[questionIndex] = optionIndex;
              } else {
                _model.varkAnswers.add(optionIndex);
              }
            });

            // Auto-advance after a short delay
            if (_model.currentQuestionIndex < _model.varkQuestions.length - 1) {
              Future.delayed(const Duration(milliseconds: 500), () {
                setState(() => _model.currentQuestionIndex++);
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['text'],
                        style: theme.bodyLarge.override(
                          fontFamily: 'Inter',
                          color: isSelected ? color : theme.primaryText,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                      if (option['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          option['description'],
                          style: theme.bodySmall.override(
                            fontFamily: 'Inter',
                            color: (isSelected ? color : Colors.grey.shade600)
                                .withValues(alpha: 0.8),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 5: Mental Performance History
  Widget _buildMentalHistoryStep(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9C27B0),
                        const Color(0xFF673AB7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _model.getStepTitle(),
                        style: theme.headlineSmall.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        _model.getStepSubtitle(),
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: theme.secondaryText,
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Past Coaching Experience
            Text(
              'Have you worked with a mental game coach before?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                'Never',
                'Once or twice',
                'Occasionally',
                'Regularly',
              ]
                  .map((experience) => _buildRadioOption(
                        value: experience,
                        groupValue: _model.pastCoachingExperience,
                        onChanged: (value) => setState(
                            () => _model.pastCoachingExperience = value!),
                        theme: theme,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Current Mental Practices
            Text(
              'What mental game tools do you currently use?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            Text(
              'Select all that apply',
              style: theme.bodySmall.override(
                fontFamily: 'Inter',
                color: theme.secondaryText,
                fontSize: 13,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _model.mentalPracticeOptions.map((practice) {
                final isSelected =
                    _model.currentMentalPractices.contains(practice['id']);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (practice['id'] == 'none') {
                        _model.currentMentalPractices = ['none'];
                      } else {
                        _model.currentMentalPractices.remove('none');
                        if (isSelected) {
                          _model.currentMentalPractices.remove(practice['id']);
                        } else {
                          _model.currentMentalPractices.add(practice['id']);
                        }
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.tertiary.withValues(alpha: 0.1)
                          : theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.tertiary : theme.alternate,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          practice['icon'],
                          color:
                              isSelected ? theme.tertiary : theme.secondaryText,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          practice['label'],
                          style: theme.bodySmall.override(
                            fontFamily: 'Inter',
                            color:
                                isSelected ? theme.tertiary : theme.primaryText,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Biggest Breakthrough
            Text(
              'Describe a time when your mental game really clicked',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model.biggestBreakthroughController,
              onChanged: (value) =>
                  setState(() => _model.biggestBreakthrough = value),
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Share a positive experience or breakthrough moment...',
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: theme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Frustration Points
            Text(
              'What mental aspect of golf frustrates you most?',
              style: theme.titleMedium.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model.frustrationPointController,
              onChanged: (value) =>
                  setState(() => _model.frustrationPoint = value),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What gets in your head on the course?',
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: theme.bodyLarge,
            ),
            const SizedBox(height: 40),

            // Continue Button
            FFButtonWidget(
              onPressed: _model.canProceedToNextStep() ? _nextStep : null,
              text: 'Complete Assessment',
              options: FFButtonOptions(
                width: double.infinity,
                height: 56,
                color: _model.canProceedToNextStep()
                    ? theme.primary
                    : theme.secondaryText,
                disabledColor: theme.secondaryText.withValues(alpha: 0.3),
                textStyle: theme.titleMedium.override(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
                elevation: _model.canProceedToNextStep() ? 3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption<T>({
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    required FlutterFlowTheme theme,
  }) {
    final isSelected = value == groupValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primary.withValues(alpha: 0.1)
                : theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primary : theme.alternate,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.secondaryText,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                value.toString(),
                style: theme.bodyLarge.override(
                  fontFamily: 'Inter',
                  color: isSelected ? theme.primary : theme.primaryText,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBar(String style, double score, FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getVarkIcon(style),
                    color: theme.getVarkColor(style),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getVarkDisplayName(style),
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: theme.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              Text(
                '${score.round()}%',
                style: theme.bodyMedium.override(
                  fontFamily: 'Inter',
                  color: theme.getVarkColor(style),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: theme.getVarkColor(style).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.getVarkColor(style),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVarkIcon(String style) {
    switch (style) {
      case 'visual':
        return FontAwesomeIcons.eye;
      case 'aural':
        return FontAwesomeIcons.volumeHigh;
      case 'readWrite':
        return FontAwesomeIcons.pencil;
      case 'kinesthetic':
        return FontAwesomeIcons.handPointer;
      default:
        return Icons.help;
    }
  }

  String _getVarkDisplayName(String style) {
    switch (style) {
      case 'visual':
        return 'Visual Learner';
      case 'aural':
        return 'Auditory Learner';
      case 'readWrite':
        return 'Read/Write Learner';
      case 'kinesthetic':
        return 'Kinesthetic Learner';
      default:
        return 'Multi-Modal Learner';
    }
  }

  String _getVarkDescription(String style) {
    switch (style) {
      case 'visual':
        return 'You learn best through visual aids, diagrams, and imagery. Your coaching will include visual demonstrations and mental imagery exercises.';
      case 'aural':
        return 'You learn best through listening and verbal instruction. Your coaching will include audio guides and verbal cues.';
      case 'readWrite':
        return 'You learn best through reading and writing. Your coaching will include detailed written instructions and journaling exercises.';
      case 'kinesthetic':
        return 'You learn best through hands-on practice and physical experiences. Your coaching will include interactive drills and feel-based techniques.';
      default:
        return 'You have a balanced learning style that benefits from multiple approaches.';
    }
  }

  Future<void> _saveUserProfile() async {
    if (!loggedIn || currentUserUid.isEmpty) {
      throw Exception('User not logged in');
    }

    // Validate required fields
    _validateRequiredFields();

    // Calculate VARK scores
    _model.varkScores = _calculateVARKScores();
    _model.dominantLearningStyle = _getDominantStyle(_model.varkScores);
    _model.secondaryLearningStyle = _getSecondaryStyle(_model.varkScores);

    // Prepare all user data
    final Map<String, dynamic> userData = {
      // Personal Foundation
      'age': _model.age,
      'coachingName': _model.coachingName,
      'displayName': _model.coachingName, // Also update display name
      'golfExperience': _model.golfExperience,
      'golfDraws': _model.golfDraws,
      'handicap': _model.handicap,

      // Mental Game Profile
      'mentalChallenges': _model.mentalChallenges,
      'mentalGoals': _model.mentalGoals,
      'playingFrequency': _model.playingFrequency,

      // VARK Assessment
      'varkScores': _model.varkScores,
      'dominantLearningStyle': _model.dominantLearningStyle,
      'secondaryLearningStyle': _model.secondaryLearningStyle,
      'varkPreferences': VarkPreferencesStruct(
        visual: _model.dominantLearningStyle == 'visual',
        aural: _model.dominantLearningStyle == 'aural',
        readWrite: _model.dominantLearningStyle == 'readWrite',
        kinesthetic: _model.dominantLearningStyle == 'kinesthetic',
      ).toMap(),

      // Mental Performance History
      'pastCoachingExperience': _model.pastCoachingExperience,
      'currentMentalPractices': _model.currentMentalPractices,
      'biggestBreakthrough': _model.biggestBreakthrough,
      'frustrationPoint': _model.frustrationPoint,

      // Metadata
      'onboardingCompleted': true,
      'assessmentDate': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    };

    // Save to local storage first (backup)
    await _saveToLocalStorage(userData);

    // Attempt to save to Firestore with retry logic
    Exception? lastError;
    for (int i = 0; i <= _maxRetries; i++) {
      try {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUserUid)
            .update(userData)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Save operation timed out'),
            );

        // Success!
        _retryCount = 0;
        return;
      } catch (e) {
        lastError = Exception('Failed to save profile: ${e.toString()}');
        _retryCount = i;

        // Don't retry on last attempt
        if (i < _maxRetries) {
          // Exponential backoff
          await Future.delayed(Duration(seconds: i + 1));
        }
      }
    }

    // If we get here, all retries failed
    throw lastError ??
        Exception('Failed to save profile after $_maxRetries attempts');
  }

  Map<String, double> _calculateVARKScores() {
    final scores = {
      'visual': 0.0,
      'aural': 0.0,
      'readWrite': 0.0,
      'kinesthetic': 0.0,
    };

    for (int i = 0; i < _model.varkAnswers.length; i++) {
      final answer = _model.varkAnswers[i];
      final questionType = _model.varkQuestions[i]['options'][answer]['type'];
      scores[questionType] = scores[questionType]! + 1;
    }

    final total = scores.values.reduce((a, b) => a + b);
    if (total > 0) {
      scores.forEach((key, value) {
        scores[key] = (value / total) * 100;
      });
    }

    return scores;
  }

  String _getDominantStyle(Map<String, double> scores) {
    double maxScore = 0;
    String dominantStyle = 'visual';

    scores.forEach((style, score) {
      if (score > maxScore) {
        maxScore = score;
        dominantStyle = style;
      }
    });

    return dominantStyle;
  }

  void _validateRequiredFields() {
    final List<String> errors = [];

    if (_model.coachingName.isEmpty) {
      errors.add('Please enter your name');
    }
    if (_model.golfExperience.isEmpty) {
      errors.add('Please select your golf experience level');
    }
    if (_model.golfDraws.isEmpty) {
      errors.add('Please select what draws you to golf');
    }
    if (_model.mentalChallenges.isEmpty) {
      errors.add('Please select at least one mental challenge');
    }
    if (_model.mentalGoals.isEmpty) {
      errors.add('Please describe your mental goals');
    }
    if (_model.playingFrequency.isEmpty) {
      errors.add('Please select your playing frequency');
    }
    if (_model.varkAnswers.length < _model.varkQuestions.length) {
      errors.add('Please complete all VARK assessment questions');
    }
    if (_model.pastCoachingExperience.isEmpty) {
      errors.add('Please select your coaching experience');
    }
    if (_model.currentMentalPractices.isEmpty) {
      errors.add('Please select your current mental practices');
    }

    if (errors.isNotEmpty) {
      throw Exception(errors.join('\n'));
    }
  }

  // Local Storage Methods
  Future<void> _saveToLocalStorage(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save each step's data separately for easier retrieval
      await prefs.setInt('vark_current_step', _model.currentStep);

      // Personal Foundation
      await prefs.setInt('vark_age', _model.age);
      await prefs.setString('vark_coaching_name', _model.coachingName);
      await prefs.setString('vark_golf_experience', _model.golfExperience);
      await prefs.setString('vark_golf_draws', _model.golfDraws);
      await prefs.setDouble('vark_handicap', _model.handicap);

      // Mental Game Profile
      await prefs.setStringList(
          'vark_mental_challenges', _model.mentalChallenges);
      await prefs.setString('vark_mental_goals', _model.mentalGoals);
      await prefs.setString('vark_playing_frequency', _model.playingFrequency);

      // VARK Assessment
      await prefs.setString('vark_answers', jsonEncode(_model.varkAnswers));

      // Mental Performance History
      await prefs.setString(
          'vark_past_coaching', _model.pastCoachingExperience);
      await prefs.setStringList(
          'vark_current_practices', _model.currentMentalPractices);
      await prefs.setString(
          'vark_biggest_breakthrough', _model.biggestBreakthrough);
      await prefs.setString('vark_frustration_point', _model.frustrationPoint);

      // Save complete data as JSON backup
      await prefs.setString('vark_complete_data', jsonEncode(data));
      await prefs.setString(
          'vark_last_saved', DateTime.now().toIso8601String());
    } catch (e) {
      // Local storage errors are non-critical, log but don't throw
      print('Error saving to local storage: $e');
    }
  }

  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if there's saved progress
      if (!prefs.containsKey('vark_current_step')) {
        return;
      }

      // Show dialog asking if user wants to resume
      final lastSaved = prefs.getString('vark_last_saved');
      if (lastSaved != null && mounted) {
        final shouldResume = await _showResumeDialog(lastSaved);
        if (!shouldResume) {
          await _clearLocalStorage();
          return;
        }
      }

      // Load saved data
      setState(() {
        _model.currentStep = prefs.getInt('vark_current_step') ?? 0;

        // Personal Foundation
        _model.age = prefs.getInt('vark_age') ?? 25;
        _model.coachingName = prefs.getString('vark_coaching_name') ?? '';
        _model.coachingNameController.text = _model.coachingName;
        _model.golfExperience = prefs.getString('vark_golf_experience') ?? '';
        _model.golfDraws = prefs.getString('vark_golf_draws') ?? '';
        _model.handicap = prefs.getDouble('vark_handicap') ?? 18.0;

        // Mental Game Profile
        _model.mentalChallenges =
            prefs.getStringList('vark_mental_challenges') ?? [];
        _model.mentalGoals = prefs.getString('vark_mental_goals') ?? '';
        _model.mentalGoalsController.text = _model.mentalGoals;
        _model.playingFrequency =
            prefs.getString('vark_playing_frequency') ?? '';

        // VARK Assessment
        final answersJson = prefs.getString('vark_answers');
        if (answersJson != null) {
          _model.varkAnswers = List<int>.from(jsonDecode(answersJson));
        }

        // Mental Performance History
        _model.pastCoachingExperience =
            prefs.getString('vark_past_coaching') ?? '';
        _model.currentMentalPractices =
            prefs.getStringList('vark_current_practices') ?? [];
        _model.biggestBreakthrough =
            prefs.getString('vark_biggest_breakthrough') ?? '';
        _model.biggestBreakthroughController.text = _model.biggestBreakthrough;
        _model.frustrationPoint =
            prefs.getString('vark_frustration_point') ?? '';
        _model.frustrationPointController.text = _model.frustrationPoint;
      });

      // Navigate to the saved step
      _pageController.jumpToPage(_model.currentStep);
    } catch (e) {
      print('Error loading saved progress: $e');
    }
  }

  Future<void> _clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('vark_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing local storage: $e');
    }
  }

  // Dialog Methods
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2A4E)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Saving your profile...',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                ),
                if (_retryCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Retry attempt ${_retryCount + 1} of $_maxRetries',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Inter',
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 12,
                          height: 1.0,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Profile Saved!',
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your personalized journey begins now',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 14,
                      height: 1.0,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: FlutterFlowTheme.of(context).error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Save Failed',
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your progress has been saved locally. You can try again or continue later.',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Inter',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 12,
                    height: 1.4,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Continue Later',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
            ),
          ),
          FFButtonWidget(
            onPressed: () {
              Navigator.of(context).pop();
              _completeOnboarding(); // Retry
            },
            text: 'Try Again',
            options: FFButtonOptions(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: FlutterFlowTheme.of(context).primary,
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showResumeDialog(String lastSaved) async {
    final lastSavedDate = DateTime.parse(lastSaved);
    final timeAgo = DateTime.now().difference(lastSavedDate);

    String timeAgoText;
    if (timeAgo.inDays > 0) {
      timeAgoText = '${timeAgo.inDays} day${timeAgo.inDays > 1 ? 's' : ''} ago';
    } else if (timeAgo.inHours > 0) {
      timeAgoText =
          '${timeAgo.inHours} hour${timeAgo.inHours > 1 ? 's' : ''} ago';
    } else if (timeAgo.inMinutes > 0) {
      timeAgoText =
          '${timeAgo.inMinutes} minute${timeAgo.inMinutes > 1 ? 's' : ''} ago';
    } else {
      timeAgoText = 'just now';
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Resume Previous Session?',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
        ),
        content: Text(
          'You have an incomplete onboarding session from $timeAgoText. Would you like to continue where you left off?',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.4,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Start Fresh',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
            ),
          ),
          FFButtonWidget(
            onPressed: () => Navigator.of(context).pop(true),
            text: 'Resume',
            options: FFButtonOptions(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: FlutterFlowTheme.of(context).primary,
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show warning dialog
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Exit Onboarding?',
              style: theme.headlineSmall.override(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            content: Text(
              'Your progress will be saved. You can continue where you left off later.',
              style: theme.bodyMedium.override(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Stay',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Inter',
                    color: theme.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
              FFButtonWidget(
                onPressed: () async {
                  _autoSaveProgress();
                  if (mounted) {
                    Navigator.of(context).pop(true);
                    Navigator.of(context).pop();
                  }
                },
                text: 'Exit',
                options: FFButtonOptions(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: theme.primary,
                  textStyle: theme.titleSmall.override(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: theme.primaryBackground,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0A2A4E), // FoCoCo Blue
                  const Color(0xFF1B4E6B),
                  const Color(0xFF3B7F5F), // FoCoCo Green
                  const Color(0xFF4A9F7F),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
                begin: AlignmentDirectional.topCenter,
                end: AlignmentDirectional.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Enhanced Header with Progress
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        // Top Navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_model.currentStep > 0)
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios,
                                    color: Colors.white),
                                onPressed: _previousStep,
                              )
                            else
                              const SizedBox(width: 48),

                            // Step indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Step ${_model.currentStep + 1} of ${_model.totalSteps}',
                                style: theme.bodyMedium.override(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                            ),

                            // Skip button (only for certain steps)
                            if (_model.currentStep ==
                                4) // Mental history can be skipped
                              TextButton(
                                onPressed: _nextStep,
                                child: Text(
                                  'Skip',
                                  style: theme.bodyMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    height: 1.0,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Progress Bar
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: MediaQuery.of(context).size.width *
                                ((_model.currentStep + 1) / _model.totalSteps),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFE0A800), // FoCoCo Gold
                                  const Color(0xFFFFD54F),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE0A800)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Content Area
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildWelcomeStep(theme),
                        _buildPersonalFoundationStep(theme),
                        _buildMentalGameProfileStep(theme),
                        _buildVARKAssessmentStep(theme),
                        _buildMentalHistoryStep(theme),
                        _buildResultsStep(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Step 6: Results & Profile Summary
  Widget _buildResultsStep(FlutterFlowTheme theme) {
    // Calculate scores if not already done
    if (_model.varkScores.isEmpty) {
      _model.varkScores = _calculateVARKScores();
      _model.dominantLearningStyle = _getDominantStyle(_model.varkScores);
      _model.secondaryLearningStyle = _getSecondaryStyle(_model.varkScores);
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Success Animation
            ScaleTransition(
              scale: Tween<double>(
                begin: 0.5,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: _fadeController,
                curve: Curves.elasticOut,
              )),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.success,
                      theme.success.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.success.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Profile Complete!',
              style: theme.displaySmall.override(
                fontFamily: 'Montserrat',
                color: theme.primaryText,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personalized coaching journey is ready',
              style: theme.bodyLarge.override(
                fontFamily: 'Inter',
                color: theme.secondaryText,
                fontSize: 16,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 32),

            // Learning Style Result
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme
                        .getVarkColor(_model.dominantLearningStyle)
                        .withValues(alpha: 0.1),
                    theme
                        .getVarkColor(_model.dominantLearningStyle)
                        .withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme
                      .getVarkColor(_model.dominantLearningStyle)
                      .withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.getVarkColor(_model.dominantLearningStyle),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getVarkIcon(_model.dominantLearningStyle),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Primary Learning Style',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: theme.secondaryText,
                      fontSize: 14,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getVarkDisplayName(_model.dominantLearningStyle),
                    style: theme.headlineSmall.override(
                      fontFamily: 'Montserrat',
                      color: theme.getVarkColor(_model.dominantLearningStyle),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getVarkDescription(_model.dominantLearningStyle),
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: theme.primaryText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // VARK Score Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Learning Style Breakdown',
                    style: theme.titleMedium.override(
                      fontFamily: 'Montserrat',
                      color: theme.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...['visual', 'aural', 'readWrite', 'kinesthetic'].map(
                    (style) =>
                        _buildScoreBar(style, _model.varkScores[style]!, theme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.alternate,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: theme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Profile Summary',
                        style: theme.titleMedium.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProfileItem('Name', _model.coachingName, theme),
                  _buildProfileItem('Experience', _model.golfExperience, theme),
                  _buildProfileItem(
                      'Playing Frequency', _model.playingFrequency, theme),
                  _buildProfileItem(
                      'Primary Goal',
                      _model.mentalGoals.isNotEmpty
                          ? _model.mentalGoals
                          : 'Not specified',
                      theme),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // What's Next
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.tertiary.withValues(alpha: 0.1),
                    theme.accent4.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.tertiary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.tertiary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What Happens Next?',
                        style: theme.titleMedium.override(
                          fontFamily: 'Montserrat',
                          color: theme.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Based on your ${_getVarkDisplayName(_model.dominantLearningStyle)} learning style, we\'ll:',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: theme.primaryText,
                      fontSize: 14,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._getPersonalizedNextSteps().map((step) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: theme.bodySmall.override(
                                  fontFamily: 'Inter',
                                  color: theme.primaryText,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error Message
            if (_hasError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Save Failed',
                            style: theme.titleSmall.override(
                              fontFamily: 'Montserrat',
                              color: theme.error,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your progress has been saved locally. You can try again.',
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: theme.primaryText,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: _hasError ? 0 : 16),

            // Action Buttons
            FFButtonWidget(
              onPressed: _isSaving ? null : _completeOnboarding,
              text: _isSaving ? 'Saving...' : 'Start Your Journey',
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
              options: FFButtonOptions(
                width: double.infinity,
                height: 56,
                color: _isSaving ? theme.secondaryText : theme.primary,
                disabledColor: theme.secondaryText.withValues(alpha: 0.5),
                textStyle: theme.titleMedium.override(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
                elevation: _isSaving ? 0 : 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.bodySmall.override(
                fontFamily: 'Inter',
                color: theme.secondaryText,
                fontSize: 13,
                height: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.bodyMedium.override(
                fontFamily: 'Inter',
                color: theme.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getPersonalizedNextSteps() {
    switch (_model.dominantLearningStyle) {
      case 'visual':
        return [
          'Deliver coaching content with rich visualizations and diagrams',
          'Provide video demonstrations for mental techniques',
          'Create visual progress tracking and performance charts',
          'Use imagery-based exercises and mental maps',
        ];
      case 'aural':
        return [
          'Provide audio-guided meditation and focus exercises',
          'Deliver verbal coaching cues and mantras',
          'Include podcast-style learning modules',
          'Create rhythmic breathing and sound-based techniques',
        ];
      case 'readWrite':
        return [
          'Offer detailed written instructions and checklists',
          'Provide journaling templates and reflection prompts',
          'Create comprehensive written guides and articles',
          'Include note-taking features for insights',
        ];
      case 'kinesthetic':
        return [
          'Focus on hands-on drills and physical exercises',
          'Provide feel-based cues and body awareness techniques',
          'Create interactive practice sessions',
          'Emphasize experiential learning on the course',
        ];
      default:
        return [
          'Provide a balanced mix of all learning styles',
          'Allow flexibility to explore different content formats',
          'Track which methods work best for you',
          'Continuously adapt based on your preferences',
        ];
    }
  }
}

// Extension to add VARK color support to theme
extension VARKThemeExtension on FlutterFlowTheme {
  Color getVarkColor(String style) {
    switch (style) {
      case 'visual':
        return const Color(0xFF2196F3); // Blue
      case 'aural':
        return const Color(0xFF4CAF50); // Green
      case 'readWrite':
        return const Color(0xFFFF9800); // Orange
      case 'kinesthetic':
        return const Color(0xFF9C27B0); // Purple
      default:
        return primary;
    }
  }
}
