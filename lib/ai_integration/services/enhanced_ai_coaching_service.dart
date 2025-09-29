import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '/backend/schema/structs/vark_preferences_struct.dart';
import '../config/gemini_config.dart';

/// Enhanced AI response with structured coaching content
class EnhancedCoachingResponse {
  final String textResponse;
  final Map<String, dynamic>? structuredData;
  final String responseType; // 'text', 'routine', 'visualization', 'analysis'
  final bool hasStructuredContent;

  EnhancedCoachingResponse({
    required this.textResponse,
    this.structuredData,
    this.responseType = 'text',
    this.hasStructuredContent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'textResponse': textResponse,
      'structuredData': structuredData,
      'responseType': responseType,
      'hasStructuredContent': hasStructuredContent,
    };
  }
}

/// Enhanced AI Coaching Service with structured responses
/// Uses Firebase AI Logic for golf mental coaching with structured outputs
class EnhancedAICoachingService {
  late GenerativeModel _model;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _model = GeminiConfig.createModel(
        modelName: GeminiConfig.coachingModel,
        generationConfig: GeminiConfig.coachingGenerationConfig,
        systemInstruction: _buildSystemInstruction(),
      );

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Enhanced AI Coaching Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Enhanced AI Coaching Service: $e');
      }
      rethrow;
    }
  }

  /// Generate enhanced coaching response with structured content
  Future<EnhancedCoachingResponse> generateCoachingResponse({
    required String userMessage,
    VarkPreferencesStruct? varkPreferences,
    Map<String, dynamic>? conversationContext,
    bool enableStructuredOutput = true,
  }) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      // Build enhanced prompt that encourages structured responses
      final enhancedPrompt = _buildEnhancedPrompt(
        userMessage: userMessage,
        varkPreferences: varkPreferences,
        conversationContext: conversationContext,
        enableStructuredOutput: enableStructuredOutput,
      );

      // Generate response
      final response =
          await _model.generateContent([Content.text(enhancedPrompt)]);
      final responseText = response.text ??
          'I apologize, but I couldn\'t generate a response right now.';

      // Parse response for structured content
      final parsedResponse = _parseStructuredResponse(responseText);

      if (kDebugMode) {
        print('🤖 Enhanced coaching response generated');
        print('📊 Structured content: ${parsedResponse.hasStructuredContent}');
      }

      return parsedResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating enhanced coaching response: $e');
      }

      // Return fallback response
      return EnhancedCoachingResponse(
        textResponse: _generateFallbackResponse(userMessage, varkPreferences),
        responseType: 'text',
      );
    }
  }

  /// Create a pre-shot routine based on user input
  Future<Map<String, dynamic>> createPreShotRoutine({
    required String shotType,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    final prompt = '''
Create a personalized pre-shot routine for a $shotType. Structure your response as JSON with the following format:

{
  "shotType": "$shotType",
  "totalTime": "30-45 seconds",
  "steps": [
    {"step": "Step description", "duration": 5, "visualization": "What to visualize"},
    ...
  ],
  "focusPoints": ["Key focus point 1", "Key focus point 2", ...],
  "mentalCues": ["Mental cue 1", "Mental cue 2", ...],
  "varkAdaptation": "How this routine adapts to the user's learning style"
}

VARK Learning Style: ${_getVarkDescription(varkPreferences)}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      // Try to parse JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }

      // Fallback structured response
      return _createFallbackRoutine(shotType);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating pre-shot routine: $e');
      }
      return _createFallbackRoutine(shotType);
    }
  }

  /// Create visualization exercise
  Future<Map<String, dynamic>> createVisualizationExercise({
    required String scenario,
    int duration = 5,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    final prompt = '''
Create a guided visualization exercise for: $scenario

Structure as JSON:
{
  "scenario": "$scenario",
  "duration": $duration,
  "phases": [
    {"phase": "Phase name", "time": "X minutes", "focus": "What to focus on"},
    ...
  ],
  "script": "Detailed visualization script...",
  "sensoryDetails": [
    {"sense": "Visual", "detail": "What to see"},
    {"sense": "Auditory", "detail": "What to hear"},
    {"sense": "Kinesthetic", "detail": "What to feel"}
  ],
  "outcome": "Desired successful outcome",
  "varkAdaptation": "Learning style specific adaptations"
}

VARK Learning Style: ${_getVarkDescription(varkPreferences)}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }

      return _createFallbackVisualization(scenario);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating visualization: $e');
      }
      return _createFallbackVisualization(scenario);
    }
  }

  /// Analyze golf performance and provide insights
  Future<Map<String, dynamic>> analyzePerformance({
    required Map<String, dynamic> performanceData,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    final prompt = '''
Analyze this golf performance data and provide structured insights:

Performance Data: ${jsonEncode(performanceData)}

Structure response as JSON:
{
  "overallScore": 7.5,
  "strengths": ["Strength 1", "Strength 2", ...],
  "weakAreas": ["Weak area 1", "Weak area 2", ...],
  "mentalGameAssessment": {
    "score": 6.5,
    "level": "Developing",
    "keyArea": "Confidence building"
  },
  "recommendations": [
    {"area": "Focus", "action": "Specific recommendation", "priority": "High"},
    ...
  ],
  "nextSteps": ["Step 1", "Step 2", ...],
  "timeframe": "Expected improvement timeline",
  "varkAdaptation": "Learning style specific recommendations"
}

VARK Learning Style: ${_getVarkDescription(varkPreferences)}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }

      return _createFallbackAnalysis(performanceData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error analyzing performance: $e');
      }
      return _createFallbackAnalysis(performanceData);
    }
  }

  /// Set mental performance goals
  Future<Map<String, dynamic>> setMentalGoals({
    required String goalType,
    String timeframe = 'weekly',
    VarkPreferencesStruct? varkPreferences,
  }) async {
    final prompt = '''
Create specific mental performance goals for: $goalType
Timeframe: $timeframe

Structure as JSON:
{
  "goalType": "$goalType",
  "timeframe": "$timeframe",
  "specificGoals": [
    {"goal": "Specific goal", "metric": "How to measure", "target": "Target value"},
    ...
  ],
  "actionSteps": ["Action step 1", "Action step 2", ...],
  "metrics": ["Metric 1", "Metric 2", ...],
  "checkpoints": [
    {"frequency": "When to check", "review": "What to review"}
  ],
  "rewards": ["Reward for milestone 1", "Reward for milestone 2"],
  "varkAdaptation": "Learning style specific approach"
}

VARK Learning Style: ${_getVarkDescription(varkPreferences)}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }

      return _createFallbackGoals(goalType, timeframe);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting mental goals: $e');
      }
      return _createFallbackGoals(goalType, timeframe);
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Build system instruction for enhanced coaching
  String _buildSystemInstruction() {
    return '''
You are an expert AI mental performance coach for golf, specializing in sports psychology.

Your capabilities include:
- Creating personalized pre-shot routines
- Developing visualization exercises  
- Analyzing performance data
- Setting mental performance goals
- Providing pressure management techniques

Communication style:
- Professional yet approachable
- Use golf-specific terminology
- Provide actionable, practical advice
- Adapt to user's VARK learning preferences
- Structure complex information clearly

When asked for structured content (routines, visualizations, analysis), provide detailed JSON responses that can be easily parsed and displayed in the app.

Always consider the user's learning style (VARK) and adapt your response accordingly:
- Visual: Include imagery, diagrams, visualization techniques
- Auditory: Focus on verbal cues, sounds, rhythm
- Read/Write: Provide lists, written instructions, note-taking suggestions  
- Kinesthetic: Emphasize physical sensations, practice, hands-on techniques

Your goal is to help golfers develop unshakeable mental strength and consistency on the course.
''';
  }

  /// Build enhanced prompt with context and structure requirements
  String _buildEnhancedPrompt({
    required String userMessage,
    VarkPreferencesStruct? varkPreferences,
    Map<String, dynamic>? conversationContext,
    bool enableStructuredOutput = true,
  }) {
    final buffer = StringBuffer();

    // Add conversation context if available
    if (conversationContext != null && conversationContext.isNotEmpty) {
      buffer.writeln('Previous conversation context:');
      buffer.writeln(jsonEncode(conversationContext));
      buffer.writeln();
    }

    // Add VARK preferences
    buffer.writeln(
        'User learning style (VARK): ${_getVarkDescription(varkPreferences)}');
    buffer.writeln();

    // Add structure requirements if enabled
    if (enableStructuredOutput) {
      buffer.writeln('RESPONSE FORMAT:');
      buffer.writeln(
          '- Use rich markdown formatting with headers, lists, tables when appropriate');
      buffer.writeln('- For complex advice, structure your response clearly');
      buffer.writeln('- Include specific examples and actionable steps');
      buffer.writeln(
          '- If creating routines/exercises, be detailed and specific');
      buffer.writeln();
    }

    // Add user message
    buffer.writeln('User request: $userMessage');

    return buffer.toString();
  }

  /// Parse response for structured content
  EnhancedCoachingResponse _parseStructuredResponse(String responseText) {
    // Check for JSON content
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);

    if (jsonMatch != null) {
      try {
        final jsonString = jsonMatch.group(0)!;
        final structuredData = jsonDecode(jsonString) as Map<String, dynamic>;

        // Determine response type based on content
        String responseType = 'text';
        if (structuredData.containsKey('shotType') ||
            structuredData.containsKey('routineSteps')) {
          responseType = 'routine';
        } else if (structuredData.containsKey('scenario') ||
            structuredData.containsKey('visualization')) {
          responseType = 'visualization';
        } else if (structuredData.containsKey('overallScore') ||
            structuredData.containsKey('analysis')) {
          responseType = 'analysis';
        } else if (structuredData.containsKey('goalType') ||
            structuredData.containsKey('goals')) {
          responseType = 'goals';
        }

        return EnhancedCoachingResponse(
          textResponse: responseText,
          structuredData: structuredData,
          responseType: responseType,
          hasStructuredContent: true,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing structured content: $e');
        }
      }
    }

    // Check if response contains structured elements (tables, lists, etc.)
    final hasStructuredElements = responseText.contains('|') || // Tables
        responseText.contains('##') || // Headers
        responseText.contains('1.') || // Numbered lists
        responseText.contains('- '); // Bullet lists

    return EnhancedCoachingResponse(
      textResponse: responseText,
      responseType: 'text',
      hasStructuredContent: hasStructuredElements,
    );
  }

  /// Get VARK learning style description
  String _getVarkDescription(VarkPreferencesStruct? varkPreferences) {
    if (varkPreferences == null) return 'Balanced learning style';

    if (varkPreferences.visual)
      return 'Visual learner - prefer diagrams, charts, and visual explanations';
    if (varkPreferences.aural)
      return 'Auditory learner - prefer spoken explanations and sound-based learning';
    if (varkPreferences.readWrite)
      return 'Read/Write learner - prefer text, lists, and written instructions';
    if (varkPreferences.kinesthetic)
      return 'Kinesthetic learner - prefer hands-on practice and physical demonstrations';
    return 'Balanced learning style';
  }

  /// Generate fallback response when AI fails
  String _generateFallbackResponse(
      String userInput, VarkPreferencesStruct? varkPreferences) {
    final input = userInput.toLowerCase();

    if (input.contains('routine') || input.contains('pre-shot')) {
      return '''## Pre-Shot Routine Fundamentals

Here's a solid foundation for any shot:

### **Basic Steps:**
1. **Assess** - Read conditions and select target (3-5 seconds)
2. **Visualize** - See your ideal shot and ball flight (2-3 seconds) 
3. **Feel** - Take practice swing with correct tempo (2-3 seconds)
4. **Commit** - Address ball with confidence and execute (2-3 seconds)

### **Key Focus Points:**
- Maintain consistent timing
- Trust your preparation
- Stay present-focused
- Use positive self-talk

${_getVarkAdaptation('routine', varkPreferences)}''';
    }

    if (input.contains('pressure') || input.contains('nerves')) {
      return '''## Pressure Management Techniques

### **Immediate Techniques:**
- **4-7-8 Breathing:** Inhale 4, hold 7, exhale 8 counts
- **Present Focus:** Focus only on this shot, not outcomes
- **Physical Reset:** Relax shoulders, loosen grip
- **Positive Self-Talk:** "I'm prepared and ready"

### **Long-term Strategies:**
- Practice pressure situations in training
- Develop consistent routines you can trust
- Build confidence through preparation
- Use visualization to rehearse success

${_getVarkAdaptation('pressure', varkPreferences)}''';
    }

    return '''## Mental Game Coaching

I'm here to help you develop unshakeable mental strength on the golf course. I can assist with:

- **Pre-shot routines** for consistency
- **Pressure management** techniques
- **Confidence building** strategies  
- **Focus and concentration** training
- **Visualization exercises** for success
- **Performance analysis** and improvement

What specific aspect of your mental game would you like to work on?

${_getVarkAdaptation('general', varkPreferences)}''';
  }

  /// Get VARK-specific adaptation suggestions
  String _getVarkAdaptation(
      String topic, VarkPreferencesStruct? varkPreferences) {
    if (varkPreferences == null) return '';

    if (varkPreferences.visual) {
      return '\n**Visual Learning Tip:** Create mental images and use visualization techniques to reinforce these concepts.';
    } else if (varkPreferences.aural) {
      return '\n**Auditory Learning Tip:** Practice saying these steps aloud and use verbal cues during your routine.';
    } else if (varkPreferences.readWrite) {
      return '\n**Read/Write Learning Tip:** Write down your personalized routine and keep notes on what works best.';
    } else if (varkPreferences.kinesthetic) {
      return '\n**Kinesthetic Learning Tip:** Practice these techniques physically and focus on how they feel in your body.';
    }

    return '';
  }

  // Fallback structured data creators
  Map<String, dynamic> _createFallbackRoutine(String shotType) {
    return {
      'shotType': shotType,
      'totalTime': '30-45 seconds',
      'steps': [
        {
          'step': 'Assess target and conditions',
          'duration': 5,
          'visualization': 'See ideal landing area'
        },
        {
          'step': 'Feel the swing needed',
          'duration': 3,
          'visualization': 'Perfect contact sensation'
        },
        {
          'step': 'Set up with intention',
          'duration': 2,
          'visualization': 'Confident ready position'
        },
        {
          'step': 'Execute with trust',
          'duration': 1,
          'visualization': 'Successful outcome'
        },
      ],
      'focusPoints': [
        'Target focus',
        'Smooth tempo',
        'Solid contact',
        'Balanced finish'
      ],
      'mentalCues': ['Stay present', 'Trust preparation', 'Commit fully'],
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _createFallbackVisualization(String scenario) {
    return {
      'scenario': scenario,
      'duration': 5,
      'script':
          'Close your eyes and see yourself in this situation. Feel confident and prepared. Execute perfectly and experience success.',
      'sensoryDetails': [
        {
          'sense': 'Visual',
          'detail': 'Crystal clear target and perfect ball flight'
        },
        {'sense': 'Auditory', 'detail': 'Perfect contact sound'},
        {'sense': 'Kinesthetic', 'detail': 'Smooth, powerful swing feeling'},
      ],
      'outcome': 'Perfect execution and successful result',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _createFallbackAnalysis(Map<String, dynamic> data) {
    return {
      'overallScore': 6.0,
      'strengths': ['Consistent preparation', 'Good attitude'],
      'weakAreas': ['Focus under pressure', 'Confidence in key moments'],
      'recommendations': [
        {
          'area': 'Focus',
          'action': 'Practice concentration exercises',
          'priority': 'High'
        },
        {
          'area': 'Confidence',
          'action': 'Build success through visualization',
          'priority': 'Medium'
        },
      ],
      'nextSteps': [
        'Practice pressure situations',
        'Develop stronger routines'
      ],
      'timeframe': '2-4 weeks for noticeable improvement',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _createFallbackGoals(String goalType, String timeframe) {
    return {
      'goalType': goalType,
      'timeframe': timeframe,
      'specificGoals': [
        {
          'goal': 'Improve $goalType consistency',
          'metric': 'Success rate',
          'target': '80%'
        },
      ],
      'actionSteps': ['Practice daily', 'Track progress', 'Stay committed'],
      'metrics': [
        'Consistency',
        'Confidence level',
        'Performance under pressure'
      ],
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
