import '/flutter_flow/flutter_flow_util.dart';
import 'comprehensive_onboarding_widget.dart'
    show ComprehensiveOnboardingWidget;
import 'package:flutter/material.dart';

class ComprehensiveOnboardingModel
    extends FlutterFlowModel<ComprehensiveOnboardingWidget> {
  // VARK Questions
  final List<VarkQuestion> varkQuestions = [
    VarkQuestion(
      question: "When learning a new golf technique, you prefer to:",
      options: [
        VarkOption(text: "Watch a video demonstration", type: "visual"),
        VarkOption(
            text: "Listen to detailed verbal instructions", type: "aural"),
        VarkOption(
            text: "Read step-by-step written instructions", type: "readWrite"),
        VarkOption(
            text: "Practice the movement immediately", type: "kinesthetic"),
      ],
    ),
    VarkQuestion(
      question: "Before an important shot, you:",
      options: [
        VarkOption(
            text: "Visualize the ball's path to the target", type: "visual"),
        VarkOption(text: "Talk yourself through the shot", type: "aural"),
        VarkOption(text: "Review your mental checklist", type: "readWrite"),
        VarkOption(
            text: "Feel the club and take practice swings",
            type: "kinesthetic"),
      ],
    ),
    VarkQuestion(
      question: "To remember course management strategies, you:",
      options: [
        VarkOption(text: "Create mental images of each hole", type: "visual"),
        VarkOption(
            text: "Discuss strategies with your playing partners",
            type: "aural"),
        VarkOption(text: "Write notes about each hole", type: "readWrite"),
        VarkOption(
            text: "Walk the course and feel the terrain", type: "kinesthetic"),
      ],
    ),
    VarkQuestion(
      question: "When analyzing your swing, you prefer to:",
      options: [
        VarkOption(
            text: "Watch slow-motion video of your swing", type: "visual"),
        VarkOption(text: "Have someone describe what they see", type: "aural"),
        VarkOption(
            text: "Read detailed swing analysis reports", type: "readWrite"),
        VarkOption(
            text: "Feel the differences in your swing positions",
            type: "kinesthetic"),
      ],
    ),
    VarkQuestion(
      question: "To improve your putting, you would:",
      options: [
        VarkOption(
            text: "Study putting alignment charts and diagrams",
            type: "visual"),
        VarkOption(text: "Listen to putting tips from a coach", type: "aural"),
        VarkOption(
            text: "Keep a detailed putting statistics journal",
            type: "readWrite"),
        VarkOption(
            text: "Practice different putting grips and stances",
            type: "kinesthetic"),
      ],
    ),
    VarkQuestion(
      question: "When learning course rules, you prefer to:",
      options: [
        VarkOption(
            text: "See illustrated examples of rule situations",
            type: "visual"),
        VarkOption(
            text: "Have rules explained verbally with examples", type: "aural"),
        VarkOption(text: "Read the official rulebook", type: "readWrite"),
        VarkOption(
            text: "Experience rule situations during play",
            type: "kinesthetic"),
      ],
    ),
    VarkQuestion(
      question: "To manage pre-round nerves, you:",
      options: [
        VarkOption(
            text: "Visualize successful shots and outcomes", type: "visual"),
        VarkOption(
            text: "Use positive self-talk and affirmations", type: "aural"),
        VarkOption(
            text: "Write down your goals and strategies", type: "readWrite"),
        VarkOption(text: "Do physical warm-up exercises", type: "kinesthetic"),
      ],
    ),
    VarkQuestion(
      question: "When tracking your progress, you prefer:",
      options: [
        VarkOption(
            text: "Charts and graphs showing improvement", type: "visual"),
        VarkOption(
            text: "Verbal feedback from coaches or friends", type: "aural"),
        VarkOption(
            text: "Detailed written scorecards and notes", type: "readWrite"),
        VarkOption(
            text: "Feeling the improvement in your swing", type: "kinesthetic"),
      ],
    ),
  ];

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}

class VarkQuestion {
  final String question;
  final List<VarkOption> options;

  VarkQuestion({
    required this.question,
    required this.options,
  });
}

class VarkOption {
  final String text;
  final String type;

  VarkOption({
    required this.text,
    required this.type,
  });
}
