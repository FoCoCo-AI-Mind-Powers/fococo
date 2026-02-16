import 'package:flutter/material.dart';
import 'dart:ui';
import '/flutter_flow/flutter_flow_theme.dart';
import '/ai_integration/models/mind_coach_models.dart';
import '/ai_integration/services/mind_coach_session_service.dart';
import '/ai_integration/services/mind_coach_content_selector.dart';
import '/ai_integration/services/mind_coach_scenario_detector.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/user_record.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';

/// Premium MindCoach AI Session Widget with Advanced Glassmorphism
class MindCoachAISessionWidget extends StatefulWidget {
  const MindCoachAISessionWidget({
    super.key,
    this.existingSession,
  });

  /// Optional existing session to resume
  final MindCoachSession? existingSession;

  @override
  State<MindCoachAISessionWidget> createState() => _MindCoachAISessionWidgetState();
}

class _MindCoachAISessionWidgetState extends State<MindCoachAISessionWidget>
    with TickerProviderStateMixin {
  final MindCoachSessionService _sessionService = MindCoachSessionService.instance;
  final MindCoachContentSelector _contentSelector = MindCoachContentSelector.instance;
  final MindCoachScenarioDetector _scenarioDetector = MindCoachScenarioDetector.instance;

  int? _mindsetBefore;
  int? _mindsetAfter;
  MindCoachSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userMessage;
  final TextEditingController _messageController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Template options with enhanced metadata
  final List<Map<String, dynamic>> _templates = [
    {
      'id': 'MC_T01_PRE_ROUND_CLARITY',
      'name': 'Pre-Round Clarity',
      'icon': '🎯',
      'color': Colors.blue,
      'description': 'Set clear intentions before your round'
    },
    {
      'id': 'MC_T02_PRE_SHOT_FOCUS',
      'name': 'Pre-Shot Focus',
      'icon': '🎯',
      'color': Colors.green,
      'description': 'Sharpen focus before each shot'
    },
    {
      'id': 'MC_T03_POST_SHOT_RECOVERY',
      'name': 'Post-Shot Recovery',
      'icon': '🔄',
      'color': Colors.orange,
      'description': 'Bounce back from challenging shots'
    },
    {
      'id': 'MC_T04_ROUND_MANAGEMENT',
      'name': 'Round Management',
      'icon': '📊',
      'color': Colors.purple,
      'description': 'Manage your mental game throughout'
    },
    {
      'id': 'MC_T05_PRESSURE_MOMENT',
      'name': 'Pressure Moment',
      'icon': '⚡',
      'color': Colors.red,
      'description': 'Handle high-pressure situations'
    },
    {
      'id': 'MC_T06_CONFIDENCE_BUILD',
      'name': 'Confidence Build',
      'icon': '💪',
      'color': Colors.teal,
      'description': 'Build unshakeable confidence'
    },
    {
      'id': 'MC_T07_EMOTIONAL_CONTROL',
      'name': 'Emotional Control',
      'icon': '🧘',
      'color': Colors.indigo,
      'description': 'Master your emotions on course'
    },
    {
      'id': 'MC_T08_POST_ROUND_REFLECT',
      'name': 'Post-Round Reflection',
      'icon': '📝',
      'color': Colors.amber,
      'description': 'Reflect and learn from your round'
    },
  ];

  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // If resuming an existing session, load its data
    if (widget.existingSession != null) {
      _loadExistingSession(widget.existingSession!);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadExistingSession(MindCoachSession session) {
    setState(() {
      _currentSession = session;
      _mindsetBefore = session.mindsetBefore;
      _selectedTemplateId = session.templateId;
      final userMessage = session.context['user_message'] as String?;
      if (userMessage != null && userMessage.isNotEmpty) {
        _userMessage = userMessage;
        _messageController.text = userMessage;
      }
    });
  }

  Future<void> _startSession() async {
    if (_mindsetBefore == null) {
      setState(() {
        _errorMessage = 'Please select your mindset before starting';
      });
      return;
    }

    if (_selectedTemplateId == null) {
      setState(() {
        _errorMessage = 'Please select a coaching template';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = currentUserUid;
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Detect scenarios
      final scenarioTags = await _scenarioDetector.detectScenarios(
        userMessage: _userMessage,
        context: {},
        mindsetRating: _mindsetBefore,
      );

      // Get user VARK preferences
      final userDoc = await UserRecord.collection.doc(userId).get();
      final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;
      
      String determineVarkMode(VarkPreferencesStruct? prefs) {
        if (prefs == null) return 'ReadWrite';
        if (prefs.visual) return 'Visual';
        if (prefs.aural) return 'Aural';
        if (prefs.readWrite) return 'ReadWrite';
        if (prefs.kinesthetic) return 'Kinesthetic';
        return 'ReadWrite';
      }
      
      final varkMode = determineVarkMode(user?.varkPreferences);

      // Select content
      final content = await _contentSelector.selectContent(
        templateId: _selectedTemplateId!,
        varkMode: varkMode,
        level: 'Foundation',
        length: 'standard',
        scenarioTags: scenarioTags.isNotEmpty ? scenarioTags : null,
      );

      if (content == null) {
        throw Exception('No content found for template: $_selectedTemplateId');
      }

      // Create session
      final session = MindCoachSession(
        sessionId: '',
        userId: userId,
        timestamp: DateTime.now(),
        templateId: _selectedTemplateId!,
        contentId: content.contentId,
        scenarioTag: scenarioTags.isNotEmpty ? scenarioTags.first : null,
        varkMode: varkMode,
        level: 'Foundation',
        length: 'standard',
        cueUsed: 'AI Generated',
        routineType: 'MindCoach AI',
        mindsetBefore: _mindsetBefore!,
        context: {
          'user_message': _userMessage,
        },
        coachingTextDelivered: content.scriptText,
        followUpQuestion: content.followUpPrompt,
        successSignals: _sessionService.calculateSuccessSignals(
          mindsetBefore: _mindsetBefore!,
          sessionCompleted: false,
        ),
      );

      final sessionId = await _sessionService.createSession(session);
      
      setState(() {
        _currentSession = session.copyWith(sessionId: sessionId);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _completeSession() async {
    if (_mindsetAfter == null || _currentSession == null) return;

    try {
      final updatedSignals = _sessionService.calculateSuccessSignals(
        mindsetBefore: _currentSession!.mindsetBefore,
        mindsetAfter: _mindsetAfter,
        sessionCompleted: true,
      );

      await _sessionService.updateSession(
        _currentSession!.sessionId,
        {
          'mindsetAfter': _mindsetAfter,
          'successSignalFlags': updatedSignals,
        },
      );

      setState(() {
        _currentSession = null;
        _mindsetBefore = null;
        _mindsetAfter = null;
        _userMessage = null;
        _messageController.clear();
        _selectedTemplateId = null;
      });

      if (mounted) {
        // Show success animation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Session completed successfully!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: FlutterFlowTheme.of(context).success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        // Close modal after delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing session: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryBackground,
            theme.primaryBackground.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _currentSession != null
              ? _buildSessionDisplay(theme)
              : _buildSessionCreation(theme),
        ),
      ),
    );
  }

  Widget _buildSessionCreation(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Header with gradient
          _buildPremiumHeader(theme),
          const SizedBox(height: 32),

          // Template Selection with enhanced visuals
          _buildTemplateSection(theme),
          const SizedBox(height: 32),

          // Optional Message Input with glass effect
          _buildMessageInput(theme),
          const SizedBox(height: 32),

          // Mindset Before Selection
          _buildMindsetSection(theme, true),
          const SizedBox(height: 32),

          // Error Message
          if (_errorMessage != null) _buildErrorMessage(theme),
          if (_errorMessage != null) const SizedBox(height: 16),

          // Premium Start Button
          _buildStartButton(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: theme.aiGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.aiPrimary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MindCoach AI',
                    style: theme.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.primaryText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personalized mental coaching',
                    style: theme.bodyMedium.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Coaching Template',
          style: theme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the mental skill you want to develop',
          style: theme.bodySmall.copyWith(color: theme.secondaryText),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _templates.map((template) {
            final isSelected = _selectedTemplateId == template['id'];
            final templateColor = template['color'] as Color;
            
            return _buildPremiumTemplateCard(
              theme: theme,
              template: template,
              isSelected: isSelected,
              color: templateColor,
              onTap: () {
                setState(() {
                  _selectedTemplateId = template['id'] as String;
                  _errorMessage = null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPremiumTemplateCard({
    required FlutterFlowTheme theme,
    required Map<String, dynamic> template,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: isSelected ? null : theme.glassBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : theme.glassBorder.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template['icon'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      template['name'] as String,
                      style: theme.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? color : theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template['description'] as String,
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s on your mind?',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional - Help us personalize your session',
          style: theme.bodySmall.copyWith(color: theme.secondaryText),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              controller: _messageController,
              onChanged: (value) {
                setState(() {
                  _userMessage = value.isEmpty ? null : value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Describe your current situation or feelings...',
                hintStyle: theme.bodySmall.copyWith(color: theme.secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.glassBorder.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.glassBorder.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.aiPrimary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: theme.glassBackground,
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
              style: theme.bodyMedium.copyWith(color: theme.primaryText),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMindsetSection(FlutterFlowTheme theme, bool isBefore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBefore ? 'How are you feeling right now?' : 'How do you feel now?',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        _buildMindsetSelector(theme, isBefore),
      ],
    );
  }

  Widget _buildErrorMessage(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.error.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: theme.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: theme.bodyMedium.copyWith(
                    color: theme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: _isLoading
                ? null
                : LinearGradient(
                    colors: [
                      theme.aiPrimary,
                      theme.aiPrimary.withValues(alpha: 0.8),
                    ],
                  ),
            color: _isLoading ? theme.glassBackground : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isLoading
                ? null
                : [
                    BoxShadow(
                      color: theme.aiPrimary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _startSession,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.aiPrimary,
                          ),
                        ),
                      )
                    else ...[
                      Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _isLoading ? 'Generating Session...' : 'Start MindCoach Session',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: _isLoading ? theme.primaryText : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionDisplay(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Header with template info
          _buildSessionHeader(theme),
          const SizedBox(height: 32),

          // Coaching Text with glass effect
          _buildCoachingCard(theme),
          const SizedBox(height: 24),

          // Follow-up Question
          if (_currentSession!.followUpQuestion != null) ...[
            _buildReflectionCard(theme),
            const SizedBox(height: 24),
          ],

          // Mindset After Selection
          _buildMindsetSection(theme, false),
          const SizedBox(height: 32),

          // Complete Button
          _buildCompleteButton(theme),
          const SizedBox(height: 16),

          // Cancel Button
          _buildCancelButton(theme),
        ],
      ),
    );
  }

  Widget _buildSessionHeader(FlutterFlowTheme theme) {
    final template = _templates.firstWhere(
      (t) => t['id'] == _currentSession!.templateId,
      orElse: () => {
        'name': 'MindCoach Session',
        'icon': '🧠',
        'color': theme.aiPrimary,
      },
    );
    final templateColor = template['color'] as Color? ?? theme.aiPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                templateColor.withValues(alpha: 0.2),
                templateColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: templateColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      templateColor,
                      templateColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: templateColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  template['icon'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['name'] as String,
                      style: theme.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: templateColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _currentSession!.varkMode,
                            style: theme.bodySmall.copyWith(
                              color: templateColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${_currentSession!.level}',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
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

  Widget _buildCoachingCard(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.glassBorder.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: theme.aiGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Personalized Coaching',
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.aiPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _currentSession!.coachingTextDelivered,
                style: theme.bodyLarge.copyWith(
                  color: theme.primaryText,
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReflectionCard(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.info.withValues(alpha: 0.15),
                theme.info.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.info.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: theme.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reflection Question',
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _currentSession!.followUpQuestion!,
                style: theme.bodyLarge.copyWith(
                  color: theme.primaryText,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: _mindsetAfter == null
                ? null
                : LinearGradient(
                    colors: [
                      theme.success,
                      theme.success.withValues(alpha: 0.8),
                    ],
                  ),
            color: _mindsetAfter == null ? theme.glassBackground : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _mindsetAfter == null
                ? null
                : [
                    BoxShadow(
                      color: theme.success.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _mindsetAfter == null ? null : _completeSession,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _mindsetAfter == null
                          ? theme.secondaryText
                          : Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Complete Session',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: _mindsetAfter == null
                            ? theme.secondaryText
                            : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(FlutterFlowTheme theme) {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(
          'Cancel Session',
          style: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMindsetSelector(FlutterFlowTheme theme, bool isBefore) {
    final selectedValue = isBefore ? _mindsetBefore : _mindsetAfter;
    final onChanged = (int value) {
      setState(() {
        if (isBefore) {
          _mindsetBefore = value;
        } else {
          _mindsetAfter = value;
        }
        _errorMessage = null;
      });
    };

    final options = [
      {'value': 1, 'emoji': '😰', 'label': 'Struggling', 'color': Colors.red},
      {'value': 2, 'emoji': '😐', 'label': 'Needs Support', 'color': Colors.orange},
      {'value': 3, 'emoji': '😌', 'label': 'Neutral', 'color': Colors.grey},
      {'value': 4, 'emoji': '😊', 'label': 'Calm', 'color': Colors.blue},
      {'value': 5, 'emoji': '😎', 'label': 'Confident', 'color': Colors.green},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selectedValue == option['value'];
        final optionColor = option['color'] as Color;
        
        return GestureDetector(
          onTap: () => onChanged(option['value'] as int),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        optionColor.withValues(alpha: 0.25),
                        optionColor.withValues(alpha: 0.15),
                      ],
                    )
                  : null,
              color: isSelected ? null : theme.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? optionColor
                    : theme.glassBorder.withValues(alpha: 0.3),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: optionColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: optionColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        option['emoji'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      option['label'] as String,
                      style: theme.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? optionColor : theme.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Extension to create a copy of session with new sessionId
extension MindCoachSessionCopyWith on MindCoachSession {
  MindCoachSession copyWith({String? sessionId}) {
    return MindCoachSession(
      sessionId: sessionId ?? this.sessionId,
      userId: this.userId,
      timestamp: this.timestamp,
      templateId: this.templateId,
      contentId: this.contentId,
      scenarioTag: this.scenarioTag,
      varkMode: this.varkMode,
      level: this.level,
      length: this.length,
      cueUsed: this.cueUsed,
      routineType: this.routineType,
      mindsetBefore: this.mindsetBefore,
      mindsetAfter: this.mindsetAfter,
      context: this.context,
      coachingTextDelivered: this.coachingTextDelivered,
      followUpQuestion: this.followUpQuestion,
      userResponse: this.userResponse,
      successSignals: this.successSignals,
      sessionType: this.sessionType,
    );
  }
}
