import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/biometric_auth_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';
import 'comprehensive_onboarding_model.dart';
export 'comprehensive_onboarding_model.dart';

class ComprehensiveOnboardingWidget extends StatefulWidget {
  const ComprehensiveOnboardingWidget({super.key});

  static String routeName = 'comprehensive_onboarding';
  static String routePath = '/comprehensive_onboarding';

  @override
  State<ComprehensiveOnboardingWidget> createState() =>
      _ComprehensiveOnboardingWidgetState();
}

class _ComprehensiveOnboardingWidgetState
    extends State<ComprehensiveOnboardingWidget> with TickerProviderStateMixin {
  late ComprehensiveOnboardingModel _model;
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final BiometricAuthService _biometricService = BiometricAuthService();

  int _currentStep = 0;
  final int _totalSteps = 4; // Welcome, Profile, VARK, Biometric, Subscription

  // Profile setup
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();

  // VARK assessment
  int _currentQuestionIndex = 0;
  List<String> _varkAnswers = [];

  // Biometric setup
  bool _isBiometricAvailable = false;
  String _biometricName = 'Biometric Authentication';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ComprehensiveOnboardingModel());

    _pageController = PageController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    _checkBiometricAvailability();
    _initializeVarkQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _handicapController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final biometricName = await _biometricService.getPrimaryBiometricName();

    setState(() {
      _isBiometricAvailable = isAvailable;
      _biometricName = biometricName;
    });
  }

  void _initializeVarkQuestions() {
    _varkAnswers = List.filled(_model.varkQuestions.length, '');
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(theme),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcomeStep(theme),
                      _buildProfileStep(theme),
                      _buildVarkStep(theme),
                      _buildBiometricStep(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Progress indicator
  Widget _buildProgressIndicator(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.primary
                      : theme.secondaryText.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? theme.primary
                        : theme.secondaryText.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.bodySmall.copyWith(
                            color:
                                isActive ? Colors.white : theme.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              );
            }),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: theme.secondaryText.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  /// Welcome step
  Widget _buildWelcomeStep(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primary, theme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FontAwesomeIcons.brain,
              color: Colors.white,
              size: 60,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Welcome to FoCoCo',
            style: theme.headlineLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Your AI-powered mental coaching companion for golf excellence',
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 48),

          // Features preview
          _buildFeatureItem(
            theme: theme,
            icon: FontAwesomeIcons.brain,
            title: 'Personalized Learning',
            subtitle: 'Discover your unique learning style',
          ),

          const SizedBox(height: 16),

          _buildFeatureItem(
            theme: theme,
            icon: Icons.security,
            title: 'Secure & Private',
            subtitle: 'Your data is protected with biometric security',
          ),

          const SizedBox(height: 16),

          _buildFeatureItem(
            theme: theme,
            icon: FontAwesomeIcons.trophy,
            title: 'Premium Features',
            subtitle: 'Unlock advanced AI coaching and analytics',
          ),

          const Spacer(),

          FFButtonWidget(
            onPressed: _nextStep,
            text: 'Get Started',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              padding: EdgeInsets.zero,
              iconPadding: EdgeInsets.zero,
              color: theme.primary,
              textStyle: theme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  /// Profile setup step
  Widget _buildProfileStep(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Help us personalize your coaching experience',
            style: theme.bodyLarge.copyWith(
              color: theme.secondaryText,
            ),
          ),

          const SizedBox(height: 32),

          // Name field
          Text(
            'Display Name',
            style: theme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: theme.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 24),

          // Handicap field
          Text(
            'Golf Handicap (Optional)',
            style: theme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _handicapController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter your handicap',
              filled: true,
              fillColor: theme.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: FFButtonWidget(
                  onPressed: _previousStep,
                  text: 'Back',
                  options: FFButtonOptions(
                    height: 56,
                    padding: EdgeInsets.zero,
                    iconPadding: EdgeInsets.zero,
                    color: Colors.transparent,
                    textStyle: theme.titleMedium.copyWith(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    borderSide: BorderSide(color: theme.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FFButtonWidget(
                  onPressed: _nameController.text.isNotEmpty ? _nextStep : null,
                  text: 'Continue',
                  options: FFButtonOptions(
                    height: 56,
                    padding: EdgeInsets.zero,
                    iconPadding: EdgeInsets.zero,
                    color: theme.primary,
                    textStyle: theme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// VARK assessment step
  Widget _buildVarkStep(FlutterFlowTheme theme) {
    if (_currentQuestionIndex >= _model.varkQuestions.length) {
      return _buildVarkResults(theme);
    }

    final question = _model.varkQuestions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Style Assessment',
            style: theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_model.varkQuestions.length}',
            style: theme.bodyLarge.copyWith(
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            question.question,
            style: theme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ...question.options.asMap().entries.map((entry) {
            final option = entry.value;
            final isSelected =
                _varkAnswers[_currentQuestionIndex] == option.type;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _varkAnswers[_currentQuestionIndex] = option.type;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primary.withValues(alpha: 0.1)
                        : theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? theme.primary
                          : theme.secondaryText.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? theme.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.primary
                                : theme.secondaryText,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option.text,
                          style: theme.bodyMedium.copyWith(
                            color: theme.primaryText,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FFButtonWidget(
                  onPressed: _currentQuestionIndex > 0
                      ? _previousVarkQuestion
                      : _previousStep,
                  text: _currentQuestionIndex > 0 ? 'Previous' : 'Back',
                  options: FFButtonOptions(
                    height: 56,
                    padding: EdgeInsets.zero,
                    iconPadding: EdgeInsets.zero,
                    color: Colors.transparent,
                    textStyle: theme.titleMedium.copyWith(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    borderSide: BorderSide(color: theme.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FFButtonWidget(
                  onPressed: _varkAnswers[_currentQuestionIndex].isNotEmpty
                      ? _nextVarkQuestion
                      : null,
                  text: _currentQuestionIndex < _model.varkQuestions.length - 1
                      ? 'Next'
                      : 'Complete Assessment',
                  options: FFButtonOptions(
                    height: 56,
                    padding: EdgeInsets.zero,
                    iconPadding: EdgeInsets.zero,
                    color: theme.primary,
                    textStyle: theme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// VARK results display
  Widget _buildVarkResults(FlutterFlowTheme theme) {
    final scores = _calculateVarkScores();
    final dominantStyle = _getDominantStyle(scores);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Your Learning Style',
            style: theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withValues(alpha: 0.1),
                  theme.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  _getVarkIcon(dominantStyle),
                  color: theme.primary,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _getVarkName(dominantStyle),
                  style: theme.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getVarkDescription(dominantStyle),
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          FFButtonWidget(
            onPressed: _nextStep,
            text: 'Continue Setup',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              padding: EdgeInsets.zero,
              iconPadding: EdgeInsets.zero,
              color: theme.primary,
              textStyle: theme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  /// Biometric setup step
  Widget _buildBiometricStep(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Secure Your Account',
            style: theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isBiometricAvailable
                ? 'Enable $_biometricName for secure and convenient access'
                : 'Set up additional security for your account',
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(
              color: theme.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primary, theme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isBiometricAvailable ? _getBiometricIcon() : Icons.security,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          if (_isBiometricAvailable) ...[
            _buildSecurityFeature(
              theme: theme,
              icon: Icons.lock,
              title: 'App Protection',
              subtitle: 'Secure app access with $_biometricName',
            ),
            const SizedBox(height: 16),
            _buildSecurityFeature(
              theme: theme,
              icon: Icons.payment,
              title: 'Payment Security',
              subtitle: 'Protect subscription and payment actions',
            ),
          ] else ...[
            _buildSecurityFeature(
              theme: theme,
              icon: Icons.security,
              title: 'Account Security',
              subtitle: 'Your account is protected with secure authentication',
            ),
          ],
          const Spacer(),
          if (_isBiometricAvailable)
            FFButtonWidget(
              onPressed: _setupBiometric,
              text: 'Enable $_biometricName',
              options: FFButtonOptions(
                width: double.infinity,
                height: 56,
                padding: EdgeInsets.zero,
                iconPadding: EdgeInsets.zero,
                color: theme.primary,
                textStyle: theme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 0,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              _isBiometricAvailable ? 'Skip for now' : 'Continue',
              style: theme.bodyMedium.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets

  Widget _buildFeatureItem({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.primary,
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
                style: theme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              Text(
                subtitle,
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityFeature({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.secondaryText.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.performanceExcellent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.performanceExcellent,
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
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: theme.performanceExcellent,
            size: 20,
          ),
        ],
      ),
    );
  }

  // Navigation methods

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextVarkQuestion() {
    if (_currentQuestionIndex < _model.varkQuestions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      // Assessment complete, show results
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousVarkQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  Future<void> _setupBiometric() async {
    final result = await _biometricService.authenticate(
      reason: 'Set up $_biometricName for FoCoCo',
    );

    if (result.success) {
      await _biometricService.setBiometricEnabled(true);
      await _biometricService.setAppLockEnabled(true);
      await _biometricService.setPaymentProtectionEnabled(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_biometricName enabled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _completeOnboarding();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to enable $_biometricName'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Save profile data
    if (loggedIn && currentUserUid.isNotEmpty) {
      final scores = _calculateVarkScores();
      final dominantStyle = _getDominantStyle(scores);

      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        'displayName': _nameController.text,
        'handicap': _handicapController.text.isNotEmpty
            ? double.tryParse(_handicapController.text)
            : null,
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

    // Navigate to subscription onboarding
    context.goNamed('subscription_onboarding');
  }

  // Helper methods

  IconData _getBiometricIcon() {
    if (_biometricName.contains('Face')) {
      return FontAwesomeIcons.faceSmile;
    } else if (_biometricName.contains('Touch') ||
        _biometricName.contains('Fingerprint')) {
      return Icons.fingerprint;
    }
    return Icons.security;
  }

  Map<String, double> _calculateVarkScores() {
    final scores = {
      'visual': 0.0,
      'aural': 0.0,
      'readWrite': 0.0,
      'kinesthetic': 0.0
    };

    for (final answer in _varkAnswers) {
      if (answer.isNotEmpty) {
        scores[answer] = (scores[answer] ?? 0) + 1;
      }
    }

    final total = _varkAnswers.where((a) => a.isNotEmpty).length;
    if (total > 0) {
      scores.forEach((key, value) {
        scores[key] = (value / total) * 100;
      });
    }

    return scores;
  }

  String _getDominantStyle(Map<String, double> scores) {
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  IconData _getVarkIcon(String style) {
    switch (style) {
      case 'visual':
        return Icons.visibility;
      case 'aural':
        return Icons.hearing;
      case 'readWrite':
        return Icons.edit;
      case 'kinesthetic':
        return Icons.touch_app;
      default:
        return Icons.school;
    }
  }

  String _getVarkName(String style) {
    switch (style) {
      case 'visual':
        return 'Visual Learner';
      case 'aural':
        return 'Auditory Learner';
      case 'readWrite':
        return 'Reading/Writing Learner';
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
}
