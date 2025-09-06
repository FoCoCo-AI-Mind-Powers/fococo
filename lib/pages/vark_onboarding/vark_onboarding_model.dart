import 'package:flutter/material.dart';
import 'package:fo_co_co/pages/vark_onboarding/vark_onboarding_widget.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_util.dart';

class VarkOnboardingModel extends FlutterFlowModel<VarkOnboardingWidget> {
  // Current step tracking
  int currentStep = 0;
  final int totalSteps = 6;

  // Step 1: Welcome data
  bool welcomeCompleted = false;

  // Step 2: Personal Foundation
  int age = 25;
  String coachingName = '';
  String golfExperience =
      ''; // Beginner/Recreational/Intermediate/Advanced/Competitive
  String golfDraws =
      ''; // Relaxation/Competition/Social/Personal Challenge/Professional
  double handicap = 18.0;

  // Step 3: Golf & Mental Game Profile
  List<String> mentalChallenges = [];
  String mentalGoals = '';
  String playingFrequency = '';

  // Step 4: VARK Assessment
  int currentQuestionIndex = 0;
  List<int> varkAnswers = [];
  final List<Map<String, dynamic>> varkQuestions = [
    {
      'question': 'Before a crucial putt, how do you best prepare?',
      'context':
          'You\'re on the 18th green with a chance to break your personal best.',
      'options': [
        {
          'text': 'Visualize the ball\'s path to the hole',
          'description': 'See the line and the ball rolling',
          'type': 'visual'
        },
        {
          'text': 'Listen to your breathing rhythm',
          'description': 'Focus on calming sounds',
          'type': 'aural'
        },
        {
          'text': 'Review your mental checklist',
          'description': 'Go through written steps',
          'type': 'readWrite'
        },
        {
          'text': 'Feel the weight of the putter',
          'description': 'Focus on physical sensations',
          'type': 'kinesthetic'
        }
      ]
    },
    {
      'question': 'When learning a new golf technique, you prefer to:',
      'context': 'Your coach is teaching you a new swing adjustment.',
      'options': [
        {
          'text': 'Watch a detailed video demonstration',
          'description': 'See the technique in action',
          'type': 'visual'
        },
        {
          'text': 'Listen to verbal instructions',
          'description': 'Hear the explanation step by step',
          'type': 'aural'
        },
        {
          'text': 'Read detailed written instructions',
          'description': 'Study the technique description',
          'type': 'readWrite'
        },
        {
          'text': 'Practice the movement immediately',
          'description': 'Feel it in your body',
          'type': 'kinesthetic'
        }
      ]
    },
    {
      'question': 'Your ideal pre-round preparation includes:',
      'context': 'You have 30 minutes before your tee time.',
      'options': [
        {
          'text': 'Visualizing successful shots on each hole',
          'description': 'Mental imagery of your round',
          'type': 'visual'
        },
        {
          'text': 'Listening to music or guided meditation',
          'description': 'Audio to get in the zone',
          'type': 'aural'
        },
        {
          'text': 'Writing down goals and intentions',
          'description': 'Document your game plan',
          'type': 'readWrite'
        },
        {
          'text': 'Physical warm-up and practice swings',
          'description': 'Get your body ready',
          'type': 'kinesthetic'
        }
      ]
    },
    {
      'question': 'After a round, you best process your experience by:',
      'context': 'You just finished an important round.',
      'options': [
        {
          'text': 'Replaying key shots in your mind',
          'description': 'Visualize what happened',
          'type': 'visual'
        },
        {
          'text': 'Talking through the round with others',
          'description': 'Verbally process the experience',
          'type': 'aural'
        },
        {
          'text': 'Writing detailed notes about each hole',
          'description': 'Document your performance',
          'type': 'readWrite'
        },
        {
          'text': 'Going to the range to work on feels',
          'description': 'Physical practice and adjustment',
          'type': 'kinesthetic'
        }
      ]
    },
    {
      'question': 'When dealing with pressure on the course:',
      'context': 'You\'re facing a challenging shot with water in play.',
      'options': [
        {
          'text': 'Picture a successful outcome',
          'description': 'See the ball landing safely',
          'type': 'visual'
        },
        {
          'text': 'Use positive self-talk',
          'description': 'Tell yourself you can do it',
          'type': 'aural'
        },
        {
          'text': 'Remember your written game plan',
          'description': 'Recall your strategy notes',
          'type': 'readWrite'
        },
        {
          'text': 'Focus on your grip and stance',
          'description': 'Feel physically grounded',
          'type': 'kinesthetic'
        }
      ]
    },
    {
      'question': 'You learn new mental techniques best when you:',
      'context': 'Your mental performance coach introduces a new strategy.',
      'options': [
        {
          'text': 'See diagrams and visual examples',
          'description': 'Visual representations help',
          'type': 'visual'
        },
        {
          'text': 'Hear explanations and examples',
          'description': 'Verbal instruction works best',
          'type': 'aural'
        },
        {
          'text': 'Read case studies and research',
          'description': 'Written material helps understanding',
          'type': 'readWrite'
        },
        {
          'text': 'Try techniques immediately on course',
          'description': 'Experience it firsthand',
          'type': 'kinesthetic'
        }
      ]
    },
    {
      'question': 'Your confidence is boosted most by:',
      'context': 'You need a confidence boost before a tournament.',
      'options': [
        {
          'text': 'Watching videos of your best shots',
          'description': 'Visual evidence of success',
          'type': 'visual'
        },
        {
          'text': 'Hearing encouraging words',
          'description': 'Verbal affirmations and support',
          'type': 'aural'
        },
        {
          'text': 'Reading your achievement journal',
          'description': 'Written record of successes',
          'type': 'readWrite'
        },
        {
          'text': 'Feeling a solid practice session',
          'description': 'Physical confirmation of skill',
          'type': 'kinesthetic'
        }
      ]
    },
    {
      'question': 'When stuck in a mental rut, you prefer to:',
      'context': 'Your mental game feels off lately.',
      'options': [
        {
          'text': 'Watch inspirational golf content',
          'description': 'Visual motivation and examples',
          'type': 'visual'
        },
        {
          'text': 'Listen to a motivational podcast',
          'description': 'Audio inspiration and advice',
          'type': 'aural'
        },
        {
          'text': 'Journal about your feelings',
          'description': 'Write through the challenge',
          'type': 'readWrite'
        },
        {
          'text': 'Change your practice routine',
          'description': 'Physical variety and new feels',
          'type': 'kinesthetic'
        }
      ]
    }
  ];

  // Step 5: Mental Performance History
  String pastCoachingExperience = '';
  List<String> currentMentalPractices = [];
  String biggestBreakthrough = '';
  String frustrationPoint = '';

  // Step 6: Results
  Map<String, double> varkScores = {};
  String dominantLearningStyle = '';
  String secondaryLearningStyle = '';

  // Mental challenge options
  final List<Map<String, dynamic>> mentalChallengeOptions = [
    {
      'id': 'focus_pressure',
      'label': 'Maintaining focus under pressure',
      'icon': Icons.center_focus_strong
    },
    {
      'id': 'confidence_bad_shots',
      'label': 'Bouncing back from bad shots',
      'icon': Icons.refresh
    },
    {
      'id': 'composure',
      'label': 'Keeping composure throughout the round',
      'icon': Icons.self_improvement
    },
    {
      'id': 'pre_round_nerves',
      'label': 'Managing pre-round nerves',
      'icon': Icons.psychology
    },
    {
      'id': 'consistency',
      'label': 'Consistent mental approach',
      'icon': Icons.timeline
    },
    {
      'id': 'negative_thoughts',
      'label': 'Overcoming negative self-talk',
      'icon': Icons.block
    },
    {
      'id': 'visualization',
      'label': 'Effective visualization',
      'icon': Icons.visibility
    },
    {
      'id': 'pressure_putts',
      'label': 'Making pressure putts',
      'icon': Icons.golf_course
    },
    {
      'id': 'competition_anxiety',
      'label': 'Competition anxiety',
      'icon': Icons.emoji_events
    },
    {
      'id': 'course_management',
      'label': 'Smart course management',
      'icon': Icons.map
    },
  ];

  // Mental practice options
  final List<Map<String, dynamic>> mentalPracticeOptions = [
    {'id': 'breathing', 'label': 'Breathing exercises', 'icon': Icons.air},
    {
      'id': 'visualization',
      'label': 'Visualization techniques',
      'icon': Icons.remove_red_eye
    },
    {
      'id': 'meditation',
      'label': 'Meditation or mindfulness',
      'icon': Icons.self_improvement
    },
    {
      'id': 'positive_self_talk',
      'label': 'Positive self-talk',
      'icon': Icons.chat_bubble
    },
    {
      'id': 'pre_shot_routine',
      'label': 'Pre-shot routines',
      'icon': Icons.repeat
    },
    {'id': 'journaling', 'label': 'Performance journaling', 'icon': Icons.book},
    {'id': 'goal_setting', 'label': 'Goal setting', 'icon': Icons.flag},
    {'id': 'none', 'label': 'None currently', 'icon': Icons.not_interested},
  ];

  // Form controllers
  final coachingNameController = TextEditingController();
  final mentalGoalsController = TextEditingController();
  final biggestBreakthroughController = TextEditingController();
  final frustrationPointController = TextEditingController();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    coachingNameController.dispose();
    mentalGoalsController.dispose();
    biggestBreakthroughController.dispose();
    frustrationPointController.dispose();
  }

  // Helper methods
  bool canProceedToNextStep() {
    switch (currentStep) {
      case 0: // Welcome
        return true;
      case 1: // Personal Foundation
        return coachingName.isNotEmpty &&
            golfExperience.isNotEmpty &&
            golfDraws.isNotEmpty;
      case 2: // Golf & Mental Game Profile
        return mentalChallenges.isNotEmpty &&
            mentalGoals.isNotEmpty &&
            playingFrequency.isNotEmpty;
      case 3: // VARK Assessment
        return varkAnswers.length == varkQuestions.length;
      case 4: // Mental Performance History
        return pastCoachingExperience.isNotEmpty &&
            currentMentalPractices.isNotEmpty;
      case 5: // Results
        return true;
      default:
        return false;
    }
  }

  String getStepTitle() {
    switch (currentStep) {
      case 0:
        return 'Welcome to Your Journey';
      case 1:
        return 'Personal Foundation';
      case 2:
        return 'Your Mental Game';
      case 3:
        return 'Learning Style Assessment';
      case 4:
        return 'Mental Performance History';
      case 5:
        return 'Your Personalized Profile';
      default:
        return '';
    }
  }

  String getStepSubtitle() {
    switch (currentStep) {
      case 0:
        return 'Let\'s build your personalized mental performance blueprint';
      case 1:
        return 'Tell us about yourself and your golf journey';
      case 2:
        return 'Identify your challenges and set your goals';
      case 3:
        return 'Discover how your mind best absorbs new strategies';
      case 4:
        return 'Share your experience with mental training';
      case 5:
        return 'Review your coaching profile';
      default:
        return '';
    }
  }
}
