import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/ai_integration/gemini_ai_client.dart';
import '/ai_integration/models/assessment_models.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_assessment_model.dart';
export 'ai_assessment_model.dart';

class AiAssessmentWidget extends StatefulWidget {
  const AiAssessmentWidget({Key? key}) : super(key: key);

  static const String routeName = 'ai_assessment';
  static const String routePath = '/ai_assessment';

  @override
  State<AiAssessmentWidget> createState() => _AiAssessmentWidgetState();
}

class _AiAssessmentWidgetState extends State<AiAssessmentWidget>
    with TickerProviderStateMixin {
  late AiAssessmentModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // AI Service
  late GeminiAIClient _aiClient;

  // Assessment State
  AssessmentData? _assessmentData;
  int _currentQuestionIndex = 0;
  Map<String, QuestionResponse> _responses = {};
  bool _isGenerating = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  PageController? _pageController;
  Map<String, String?> _generatedImageUrls = {}; // Cache for generated images

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiAssessmentModel());

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();

    // Initialize AI client with proper API key
    // Note: GeminiAIClient uses Firebase AI internally, but we need to pass a non-empty key
    // The actual API key is retrieved from GeminiLiveAPIConfig in the service layer
    _aiClient = GeminiAIClient(apiKey: 'firebase_ai_logic');

    // Generate assessment on load
    _generateAssessment();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  /// Generate AI-powered assessment
  Future<void> _generateAssessment() async {
    if (!mounted) return;
    
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _assessmentData = null;
      _currentQuestionIndex = 0;
      _responses = {};
    });

    try {
      final userId = currentUserUid;
      
      // Guard against empty userId
      if (userId.isEmpty) {
        throw Exception('User must be logged in to generate assessment');
      }

      // Get user profile for personalization
      final userDoc = await UserRecord.collection.doc(userId).get();
      final userData = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

      Map<String, dynamic>? userProfile;
      if (userData != null) {
        userProfile = {
          'displayName': userData.displayName,
          'golfExperience': userData.golfExperience,
          'handicap': userData.handicap,
        };
      }

      // Generate assessment using Gemini
      final assessmentJson = await _aiClient.generateVarkAssessment(
        userId: userId,
        userProfile: userProfile,
        questionCount: 12,
      );

      // Validate assessment structure
      if (assessmentJson['questions'] == null) {
        throw Exception('Assessment generation failed: No questions generated');
      }

      // Parse assessment data with validation
      final questionsList = assessmentJson['questions'] as List?;
      if (questionsList == null || questionsList.isEmpty) {
        if (kDebugMode) {
          print('❌ Assessment JSON structure: ${assessmentJson.keys}');
        }
        throw Exception('Assessment generation failed: Empty questions list');
      }

      if (kDebugMode) {
        print('✅ Received ${questionsList.length} questions from API');
      }

      final questions = <AssessmentQuestion>[];
      for (var i = 0; i < questionsList.length; i++) {
        try {
          final questionMap = questionsList[i] as Map<String, dynamic>?;
          if (questionMap == null) {
            if (kDebugMode) {
              print('⚠️ Skipping invalid question at index $i');
            }
            continue;
          }

          // Transform API response format to expected format
          // API returns: questionText, options
          // Code expects: question, answers
          final transformedMap = <String, dynamic>{...questionMap};
          
          // Handle questionText -> question
          if (transformedMap['questionText'] != null && transformedMap['question'] == null) {
            transformedMap['question'] = transformedMap['questionText'];
          }
          
          // Handle questionId -> id
          if (transformedMap['questionId'] != null && transformedMap['id'] == null) {
            transformedMap['id'] = transformedMap['questionId'];
          }
          
          // Handle options -> answers
          if (transformedMap['options'] != null && transformedMap['answers'] == null) {
            final options = transformedMap['options'] as List?;
            if (options != null) {
              transformedMap['answers'] = options.map((opt) {
                final optionMap = opt as Map<String, dynamic>;
                return {
                  'id': optionMap['optionId'] ?? optionMap['id'] ?? 'a',
                  'text': optionMap['text'] ?? '',
                  'varkType': optionMap['varkType'] ?? 'visual',
                  'score': optionMap['score'] ?? 1,
                };
              }).toList();
            }
          }

          // Validate question structure after transformation
          if (transformedMap['question'] == null ||
              transformedMap['answers'] == null) {
            if (kDebugMode) {
              print('⚠️ Skipping incomplete question at index $i');
              print('   Available keys: ${transformedMap.keys}');
              print('   Has question: ${transformedMap['question'] != null || transformedMap['questionText'] != null}');
              print('   Has answers: ${transformedMap['answers'] != null || transformedMap['options'] != null}');
            }
            continue;
          }

          final question = AssessmentQuestion.fromJson(transformedMap);

          // Validate answers
          if (question.answers.isEmpty || question.answers.length < 4) {
            if (kDebugMode) {
              print(
                  '⚠️ Question ${question.id} has insufficient answers (${question.answers.length}), skipping');
            }
            continue;
          }

          if (kDebugMode) {
            print('✅ Successfully parsed question ${i + 1}: ${question.question.substring(0, question.question.length > 50 ? 50 : question.question.length)}...');
          }

          questions.add(question);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error parsing question at index $i: $e');
          }
          continue;
        }
      }

      // Ensure we have at least some questions
      if (questions.isEmpty) {
        throw Exception(
            'Assessment generation failed: No valid questions could be parsed. '
            'Please try again.');
      }

      // Generate image URLs from descriptions (using placeholder for now)
      final imageDescriptions =
          List<String>.from(assessmentJson['imageDescriptions'] as List? ?? []);

      // Create assessment data
      _assessmentData = AssessmentData(
        title: assessmentJson['title'] as String? ??
            'VARK Learning Style Assessment',
        description: assessmentJson['description'] as String? ??
            'Discover your optimal learning style for mental performance training',
        questions: questions,
        imageDescriptions: imageDescriptions,
        generatedAt: DateTime.now(),
      );

      // Initialize page controller
      _pageController = PageController(initialPage: 0);

      // Generate images for questions asynchronously
      if (mounted) {
        _generateImagesForQuestions();
      }

      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    } catch (e) {
      // Log error to user record silently
      try {
        final userId = currentUserUid;
        if (userId.isNotEmpty) {
          await UserRecord.collection.doc(userId).update({
            'lastAIError': e.toString().length > 500 
                ? e.toString().substring(0, 500) 
                : e.toString(),
            'lastAIErrorTimestamp': FieldValue.serverTimestamp(),
            'aiErrorCount': FieldValue.increment(1),
          });
        }
      } catch (logError) {
        if (kDebugMode) {
          print('⚠️ Failed to log error to user record: $logError');
        }
      }
      
      if (mounted) {
        setState(() {
          // Provide generic user-friendly error message (don't show technical details)
          _errorMessage = 'Unable to generate assessment. Please try again.';
          _isGenerating = false;
        });
      }
      
      if (kDebugMode) {
        print('❌ Assessment generation error: $e');
        print('Error type: ${e.runtimeType}');
      }
    }
  }

  /// Generate images for questions using Gemini
  Future<void> _generateImagesForQuestions() async {
    if (_assessmentData == null || !mounted) return;

    final userId = currentUserUid;
    
    for (final question in _assessmentData!.questions) {
      if (!mounted) break; // Stop if widget is disposed
      
      if (question.imageDescription != null && question.imageDescription!.isNotEmpty) {
        try {
          // Generate image using Gemini
          final imageUrl = await _aiClient.generateImage(
            prompt: question.imageDescription!,
            userId: userId,
          );
          
          if (imageUrl != null && mounted) {
            setState(() {
              _generatedImageUrls[question.id] = imageUrl;
            });
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error generating image for question ${question.id}: $e');
          }
          // Continue with other questions even if one fails
        }
      }
    }
  }

  /// Handle answer selection
  void _selectAnswer(AssessmentQuestion question, AssessmentAnswer answer) {
    if (!mounted) return;
    
    setState(() {
      _responses[question.id] = QuestionResponse(
        questionId: question.id,
        answerId: answer.id,
        selectedVarkType: answer.varkType,
        answeredAt: DateTime.now(),
      );
    });

    // Auto-advance to next question after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return; // Check if widget is still mounted
      
      if (_currentQuestionIndex < _assessmentData!.questions.length - 1) {
        if (mounted) {
          setState(() {
            _currentQuestionIndex++;
          });
        }
        _pageController?.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Last question answered, show completion option
        // Don't auto-complete, let user click button
      }
    });
  }

  /// Calculate VARK scores from responses
  VarkScores _calculateScores() {
    final scores = {
      'visual': 0,
      'aural': 0,
      'readWrite': 0,
      'kinesthetic': 0,
    };

    for (final response in _responses.values) {
      scores[response.selectedVarkType] =
          (scores[response.selectedVarkType] ?? 0) + 1;
    }

    final total = _responses.length;
    if (total == 0) {
      return VarkScores(
        visual: 0,
        aural: 0,
        readWrite: 0,
        kinesthetic: 0,
      );
    }

    return VarkScores(
      visual: (scores['visual']! / total) * 100,
      aural: (scores['aural']! / total) * 100,
      readWrite: (scores['readWrite']! / total) * 100,
      kinesthetic: (scores['kinesthetic']! / total) * 100,
    );
  }

  /// Complete assessment and save results
  Future<void> _completeAssessment() async {
    if (_responses.length < _assessmentData!.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please answer all questions before completing'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }

    if (!mounted) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = currentUserUid;
      final scores = _calculateScores();
      final dominantStyle = scores.getDominantStyle();
      final secondaryStyle = scores.getSecondaryStyle();
      final isMultiModal = scores.isMultiModal;

      // Create assessment result
      final assessmentResult = AssessmentResult(
        userId: userId,
        completedAt: DateTime.now(),
        responses: _responses.values.toList(),
        scores: scores,
        dominantStyle: dominantStyle,
        secondaryStyle: secondaryStyle,
        isMultiModal: isMultiModal,
        metadata: {
          'questionCount': _assessmentData!.questions.length,
          'answeredCount': _responses.length,
        },
      );

      // Update user record with VARK preferences
      final varkPreferences = VarkPreferencesStruct(
        visual: dominantStyle == 'visual',
        aural: dominantStyle == 'aural',
        readWrite: dominantStyle == 'readWrite',
        kinesthetic: dominantStyle == 'kinesthetic',
      );

      await FirebaseFirestore.instance.collection('user').doc(userId).update({
        'varkPreferences': varkPreferences.toMap(),
        'varkScores': scores.toJson(),
        'dominantLearningStyle': dominantStyle,
        'secondaryLearningStyle': secondaryStyle,
        'isMultiModal': isMultiModal,
        'assessmentDate': FieldValue.serverTimestamp(),
        'lastAssessmentResult': assessmentResult.toJson(),
      });

      // Store full assessment result in separate collection
      await FirebaseFirestore.instance
          .collection('assessment_results')
          .add(assessmentResult.toJson());

      if (mounted) {
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assessment complete! Your learning style: ${_getStyleName(dominantStyle)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving assessment: ${e.toString()}'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  /// Build image placeholder while image is being generated
  Widget _buildImagePlaceholder(FlutterFlowTheme theme, String description) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: 0.2),
            theme.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: theme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              description,
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getStyleName(String style) {
    switch (style) {
      case 'visual':
        return 'Visual';
      case 'aural':
        return 'Auditory';
      case 'readWrite':
        return 'Read/Write';
      case 'kinesthetic':
        return 'Kinesthetic';
      default:
        return 'Mixed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryText),
          onPressed: () {
            if (_responses.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Exit Assessment?'),
                  content: Text(
                    'Your progress will be saved. You can continue later.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text('Exit'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _assessmentData?.title ?? 'VARK Assessment',
          style: theme.titleLarge.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _isGenerating
                ? _buildLoadingState(theme)
                : _errorMessage != null
                    ? _buildErrorState(theme)
                    : _assessmentData == null
                        ? _buildLoadingState(theme)
                        : _buildAssessmentContent(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating your personalized assessment...',
            style: theme.titleMedium.copyWith(
              color: theme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Creating questions tailored to your golf experience',
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.titleLarge.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateAssessment,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentContent(FlutterFlowTheme theme) {
    if (_pageController == null) {
      return _buildLoadingState(theme);
    }

    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _responses.length / _assessmentData!.questions.length,
                  backgroundColor: theme.secondaryBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_responses.length}/${_assessmentData!.questions.length}',
                style: theme.bodyMedium.copyWith(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Questions
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assessmentData!.questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(
                theme,
                _assessmentData!.questions[index],
                index,
              );
            },
          ),
        ),

        // Navigation buttons
        if (_isSubmitting)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (!mounted) return;
                        setState(() {
                          _currentQuestionIndex--;
                        });
                        _pageController?.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: Icon(Icons.arrow_back),
                      label: Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryText,
                        side: BorderSide(
                          color: theme.secondaryText.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentQuestionIndex == 0 ? 1 : 1,
                  child: ElevatedButton.icon(
                    onPressed:
                        _responses.length == _assessmentData!.questions.length
                            ? _completeAssessment
                            : null,
                    icon: Icon(Icons.check_circle),
                    label: Text(
                      _responses.length == _assessmentData!.questions.length
                          ? 'Complete Assessment'
                          : 'Answer all questions to continue',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor:
                          theme.secondaryText.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(
    FlutterFlowTheme theme,
    AssessmentQuestion question,
    int index,
  ) {
    final isAnswered = _responses.containsKey(question.id);
    final selectedAnswerId =
        isAnswered ? _responses[question.id]!.answerId : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question image - generated or placeholder
          if (question.imageDescription != null)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _generatedImageUrls[question.id] != null
                    ? Image.network(
                        _generatedImageUrls[question.id]!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primary.withValues(alpha: 0.2),
                                  theme.primary.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder(theme, question.imageDescription!);
                        },
                      )
                    : _buildImagePlaceholder(theme, question.imageDescription!),
              ),
            ),

          // Question text
          Text(
            'Question ${index + 1}',
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: theme.titleLarge.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Answer options
          ...question.answers.map((answer) {
            final isSelected = selectedAnswerId == answer.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectAnswer(question, answer),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primary.withValues(alpha: 0.1)
                        : theme.secondaryBackground,
                    border: Border.all(
                      color: isSelected
                          ? theme.primary
                          : theme.secondaryText.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected ? theme.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? theme.primary
                                : theme.secondaryText.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          answer.text,
                          style: theme.bodyLarge.copyWith(
                            color: theme.primaryText,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
