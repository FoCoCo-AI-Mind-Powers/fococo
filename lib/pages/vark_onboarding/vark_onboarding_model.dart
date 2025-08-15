import '/flutter_flow/flutter_flow_model.dart';
import 'package:flutter/material.dart';

class VarkOnboardingModel extends FlutterFlowModel {
  // Current question index
  int currentQuestionIndex = 0;
  
  // User answers (list of selected option indices)
  List<int> answers = [];
  
  // Golf-specific VARK assessment questions
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Before a crucial putt, how do you best prepare your mind?',
      'context': 'You\'re standing over a 6-foot putt to save par on the 18th hole.',
      'options': [
        {
          'text': 'Visualize the ball\'s path to the hole',
          'description': 'Create a mental image of the perfect line',
          'type': 'visual',
        },
        {
          'text': 'Listen to your breathing rhythm',
          'description': 'Focus on the sound and tempo of your breath',
          'type': 'aural',
        },
        {
          'text': 'Review your mental checklist',
          'description': 'Go through written putting fundamentals',
          'type': 'readWrite',
        },
        {
          'text': 'Feel the weight of the putter',
          'description': 'Focus on grip pressure and balance',
          'type': 'kinesthetic',
        },
      ],
    },
    {
      'question': 'When learning a new swing technique, what helps you most?',
      'context': 'Your coach is teaching you to improve your driver swing.',
      'options': [
        {
          'text': 'Watching slow-motion video analysis',
          'description': 'See the swing mechanics in detail',
          'type': 'visual',
        },
        {
          'text': 'Hearing the coach explain the movement',
          'description': 'Listen to verbal instruction and tempo cues',
          'type': 'aural',
        },
        {
          'text': 'Reading about the technique',
          'description': 'Study written instructions and diagrams',
          'type': 'readWrite',
        },
        {
          'text': 'Practice the motion repeatedly',
          'description': 'Feel the muscle memory through repetition',
          'type': 'kinesthetic',
        },
      ],
    },
    {
      'question': 'After a bad shot, how do you reset mentally?',
      'context': 'You just hit your tee shot into the water hazard.',
      'options': [
        {
          'text': 'Picture yourself hitting the next shot perfectly',
          'description': 'Create positive mental imagery',
          'type': 'visual',
        },
        {
          'text': 'Talk yourself through positive self-talk',
          'description': 'Use verbal affirmations and mantras',
          'type': 'aural',
        },
        {
          'text': 'Write down what went wrong and how to fix it',
          'description': 'Make notes for future reference',
          'type': 'readWrite',
        },
        {
          'text': 'Take deep breaths and feel your muscles relax',
          'description': 'Use physical relaxation techniques',
          'type': 'kinesthetic',
        },
      ],
    },
    {
      'question': 'How do you best remember course management strategies?',
      'context': 'Planning your approach to a challenging par 4 with water.',
      'options': [
        {
          'text': 'Draw the hole layout and yardages',
          'description': 'Sketch the strategy visually',
          'type': 'visual',
        },
        {
          'text': 'Talk through the strategy out loud',
          'description': 'Verbalize your game plan',
          'type': 'aural',
        },
        {
          'text': 'Write detailed notes in your yardage book',
          'description': 'Document specific strategies',
          'type': 'readWrite',
        },
        {
          'text': 'Practice the shot selection on the range',
          'description': 'Feel the shots before playing them',
          'type': 'kinesthetic',
        },
      ],
    },
    {
      'question': 'What type of pre-round preparation works best for you?',
      'context': 'Getting ready for an important tournament round.',
      'options': [
        {
          'text': 'Watch highlight videos of great rounds',
          'description': 'Visual inspiration and imagery',
          'type': 'visual',
        },
        {
          'text': 'Listen to motivational music or podcasts',
          'description': 'Audio preparation and mood setting',
          'type': 'aural',
        },
        {
          'text': 'Review your written game plan and goals',
          'description': 'Study your preparation notes',
          'type': 'readWrite',
        },
        {
          'text': 'Do stretching and feel-good swings',
          'description': 'Physical preparation and muscle activation',
          'type': 'kinesthetic',
        },
      ],
    },
    {
      'question': 'When facing course pressure, how do you stay focused?',
      'context': 'Playing in front of a large gallery on the final holes.',
      'options': [
        {
          'text': 'Focus on a specific target spot',
          'description': 'Use visual concentration techniques',
          'type': 'visual',
        },
        {
          'text': 'Repeat a calming phrase or mantra',
          'description': 'Use verbal anchoring',
          'type': 'aural',
        },
        {
          'text': 'Go through your written routine checklist',
          'description': 'Follow documented processes',
          'type': 'readWrite',
        },
        {
          'text': 'Feel your feet grounded and center yourself',
          'description': 'Use physical grounding techniques',
          'type': 'kinesthetic',
        },
      ],
    },
    {
      'question': 'How do you best track your mental game progress?',
      'context': 'Wanting to improve your mental performance over time.',
      'options': [
        {
          'text': 'Create charts and graphs of your performance',
          'description': 'Visual progress tracking',
          'type': 'visual',
        },
        {
          'text': 'Record voice memos about your rounds',
          'description': 'Audio reflection and analysis',
          'type': 'aural',
        },
        {
          'text': 'Keep detailed written journals',
          'description': 'Document thoughts and patterns',
          'type': 'readWrite',
        },
        {
          'text': 'Notice how you feel during different situations',
          'description': 'Track physical and emotional sensations',
          'type': 'kinesthetic',
        },
      ],
    },
    {
      'question': 'What helps you learn from watching professional golfers?',
      'context': 'Studying tour players to improve your mental game.',
      'options': [
        {
          'text': 'Watch their body language and expressions',
          'description': 'Observe visual cues and behaviors',
          'type': 'visual',
        },
        {
          'text': 'Listen to their interviews and commentary',
          'description': 'Hear their thought processes',
          'type': 'aural',
        },
        {
          'text': 'Read their tips and strategy articles',
          'description': 'Study written insights',
          'type': 'readWrite',
        },
        {
          'text': 'Try to mimic their tempo and feel',
          'description': 'Copy their physical approach',
          'type': 'kinesthetic',
        },
      ],
    },
  ];

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
} 