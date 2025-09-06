import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  late PageController _pageController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

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

    _pageController = PageController();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_model.currentQuestionIndex < _model.questions.length - 1) {
      setState(() {
        _model.currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _slideController.forward(from: 0);
    } else {
      _completeAssessment();
    }
  }

  void _completeAssessment() async {
    final scores = _calculateVARKScores();
    final dominantStyle = _getDominantStyle(scores);

    // Show results summary screen
    await _showResultsSummary(scores, dominantStyle);
  }

  Future<void> _showResultsSummary(
      Map<String, double> scores, String dominantStyle) async {
    final theme = FlutterFlowTheme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: theme.primaryBrandGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Assessment Complete!',
                    style: theme.headlineMedium.override(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your learning style has been identified',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Inter',
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Results Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Dominant Style Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme
                                .getVarkColor(dominantStyle)
                                .withValues(alpha: 0.1),
                            theme
                                .getVarkColor(dominantStyle)
                                .withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme
                              .getVarkColor(dominantStyle)
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
                              color: theme.getVarkColor(dominantStyle),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getVarkIcon(dominantStyle),
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your Learning Style',
                            style: theme.bodyMedium.override(
                              fontFamily: 'Inter',
                              color: theme.secondaryText,
                              fontSize: 14,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getVarkDisplayName(dominantStyle),
                            style: theme.headlineSmall.override(
                              fontFamily: 'Montserrat',
                              color: theme.getVarkColor(dominantStyle),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getVarkDescription(dominantStyle),
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

                    // Score Breakdown
                    Text(
                      'Your Learning Style Breakdown',
                      style: theme.titleMedium.override(
                        fontFamily: 'Montserrat',
                        color: theme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...['visual', 'aural', 'readWrite', 'kinesthetic'].map(
                      (style) => _buildScoreBar(style, scores[style]!, theme),
                    ),

                    const SizedBox(height: 32),

                    // What's Next
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.calmBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.calmAccent,
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
                                color: theme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'What\'s Next?',
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
                            'Your training content will be personalized based on your ${_getVarkDisplayName(dominantStyle)} learning style. You\'ll receive coaching modules, insights, and exercises tailored specifically for how you learn best.',
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
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: () => Navigator.pop(context),
                      text: 'Retake Quiz',
                      options: FFButtonOptions(
                        height: 52,
                        color: Colors.transparent,
                        textStyle: theme.titleMedium.override(
                          fontFamily: 'Montserrat',
                          color: theme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                        borderSide: BorderSide(
                          color: theme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FFButtonWidget(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _finalizeSaveAndNavigate(scores, dominantStyle);
                      },
                      text: 'Continue to App',
                      options: FFButtonOptions(
                        height: 52,
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
            ),
          ],
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

  Future<void> _finalizeSaveAndNavigate(
      Map<String, double> scores, String dominantStyle) async {
    // Save VARK preferences to user profile
    if (loggedIn && currentUserUid.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        'vark_preferences': VarkPreferencesStruct(
          visual: dominantStyle == 'visual',
          aural: dominantStyle == 'aural',
          readWrite: dominantStyle == 'readWrite',
          kinesthetic: dominantStyle == 'kinesthetic',
        ).toMap(),
        'vark_scores': scores,
        'onboarding_completed': true,
        'assessment_date': FieldValue.serverTimestamp(),
      });
    }

    // Navigate to subscription onboarding for new users
    context.goNamed('subscription_onboarding');
  }

  Map<String, double> _calculateVARKScores() {
    final scores = {
      'visual': 0.0,
      'aural': 0.0,
      'readWrite': 0.0,
      'kinesthetic': 0.0,
    };

    for (int i = 0; i < _model.answers.length; i++) {
      final answer = _model.answers[i];
      final questionType = _model.questions[i]['options'][answer]['type'];
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
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
                const Color(0xFF1B5E20), // Deep forest green
                const Color(0xFF2E7D32), // Golf course green
                const Color(0xFF388E3C), // Lighter golf green
                const Color(0xFF4CAF50), // Bright green
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Progress Indicator
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: MediaQuery.of(context).size.width *
                              ((_model.currentQuestionIndex + 1) /
                                  _model.questions.length),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Question Counter
                      Text(
                        'Question ${_model.currentQuestionIndex + 1} of ${_model.questions.length}',
                        style: theme.bodyLarge.override(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        'Discover Your Learning Style',
                        style: theme.headlineMedium.override(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Let\'s personalize your mental performance training',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Question Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _model.questions.length,
                      itemBuilder: (context, index) {
                        final question = _model.questions[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: FadeTransition(
                            opacity: _fadeController,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: Curves.easeOutCubic,
                              )),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Learning Style Icons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLearningStyleIcon(
                                          FontAwesomeIcons.eye,
                                          'Visual',
                                          const Color(0xFF2196F3)),
                                      const SizedBox(width: 16),
                                      _buildLearningStyleIcon(
                                          FontAwesomeIcons.volumeHigh,
                                          'Auditory',
                                          const Color(0xFF4CAF50)),
                                      const SizedBox(width: 16),
                                      _buildLearningStyleIcon(
                                          FontAwesomeIcons.pencil,
                                          'Read/Write',
                                          const Color(0xFFFF9800)),
                                      const SizedBox(width: 16),
                                      _buildLearningStyleIcon(
                                          FontAwesomeIcons.handPointer,
                                          'Kinesthetic',
                                          const Color(0xFF9C27B0)),
                                    ],
                                  ),
                                  const SizedBox(height: 40),

                                  // Question
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF2E7D32)
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.golf_course,
                                          color: const Color(0xFF2E7D32),
                                          size: 32,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          question['question'],
                                          style: theme.headlineSmall.override(
                                            fontFamily: 'Inter',
                                            color: const Color(0xFF1B5E20),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                        ),
                                        if (question['context'] != null) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            question['context'],
                                            style: theme.bodyMedium.override(
                                              fontFamily: 'Inter',
                                              color: const Color(0xFF388E3C),
                                              fontSize: 16,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Answer Options
                                  Text(
                                    'Choose the option that best describes how you would handle this situation:',
                                    style: theme.bodyLarge.override(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF1B5E20),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  ...List.generate(
                                    question['options'].length,
                                    (optionIndex) => _buildAnswerOption(
                                      question['options'][optionIndex],
                                      optionIndex,
                                      index,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearningStyleIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Inter',
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
        ),
      ],
    );
  }

  Widget _buildAnswerOption(
      Map<String, dynamic> option, int optionIndex, int questionIndex) {
    final isSelected = _model.answers.length > questionIndex &&
        _model.answers[questionIndex] == optionIndex;
    final theme = FlutterFlowTheme.of(context);

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

    final color = typeColors[option['type']] ?? const Color(0xFF2E7D32);
    final icon = typeIcons[option['type']] ?? Icons.help;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (_model.answers.length > questionIndex) {
                _model.answers[questionIndex] = optionIndex;
              } else {
                _model.answers.add(optionIndex);
              }
            });

            // Auto-advance after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              _nextQuestion();
            });
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
                          color: isSelected ? color : const Color(0xFF1B5E20),
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
                            fontSize: 14,
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
}
