import 'package:flutter/material.dart';
import 'package:fo_co_co/pages/vark_onboarding/vark_onboarding_widget.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/flutter_flow/flutter_flow_util.dart';

class VarkOnboardingModel extends FlutterFlowModel<VarkOnboardingWidget> {
  // Current slide tracking (0-17 for 18 slides total)
  int currentSlide = 0;
  final int totalSlides = 18;

  // Slide 5: Age Verification
  DateTime? dateOfBirth;
  bool termsAccepted = false;
  bool hasParentalPermission = false; // For ages 16-17
  bool noParentalPermission = false; // For ages 16-17

  // Slides 8-14: VARK Assessment (7 questions)
  int currentQuestionIndex = 0;
  List<int> varkAnswers = []; // Answers for Q1-Q7
  final List<Map<String, dynamic>> varkQuestions = [
    {
      'question': 'When you\'re learning something new, what helps you most?',
      'options': [
        {
          'text': 'Seeing a diagram or example',
          'type': 'visual'
        },
        {
          'text': 'Listening to someone explain it',
          'type': 'aural'
        },
        {
          'text': 'Reading instructions',
          'type': 'readWrite'
        },
        {
          'text': 'Doing it myself. Hands-on approach',
          'type': 'kinesthetic'
        }
      ]
    },
    {
      'question': 'In class or a meeting, how do you stay focused?',
      'options': [
        {
          'text': 'Doodling or fidgeting while listening',
          'type': 'kinesthetic'
        },
        {
          'text': 'Watching visual slides or handouts',
          'type': 'visual'
        },
        {
          'text': 'Taking detailed notes',
          'type': 'readWrite'
        },
        {
          'text': 'Listening carefully to the speaker\'s voice',
          'type': 'aural'
        }
      ]
    },
    {
      'question': 'What do you do first when setting up a new phone or device?',
      'options': [
        {
          'text': 'Ask someone to walk me through it',
          'type': 'aural'
        },
        {
          'text': 'Start tapping and exploring to figure it out',
          'type': 'kinesthetic'
        },
        {
          'text': 'Look at the diagrams or images in the guide',
          'type': 'visual'
        },
        {
          'text': 'Read the full setup instructions',
          'type': 'readWrite'
        }
      ]
    },
    {
      'question': 'When remembering a destination, like a restaurant, what sticks in your mind?',
      'options': [
        {
          'text': 'Names, signs, or things I read there',
          'type': 'readWrite'
        },
        {
          'text': 'Background sounds or music',
          'type': 'aural'
        },
        {
          'text': 'How I felt or what I did there',
          'type': 'kinesthetic'
        },
        {
          'text': 'The way it looked visually',
          'type': 'visual'
        }
      ]
    },
    {
      'question': 'When following directions, which do you prefer?',
      'options': [
        {
          'text': 'A written list of steps',
          'type': 'readWrite'
        },
        {
          'text': 'Spoken instructions or someone guiding me',
          'type': 'aural'
        },
        {
          'text': 'Figuring it out as I go through it physically',
          'type': 'kinesthetic'
        },
        {
          'text': 'A map, diagram, or visual cues',
          'type': 'visual'
        }
      ]
    },
    {
      'question': 'How do you prepare for a test or big event?',
      'options': [
        {
          'text': 'Simulating the real experience or practicing',
          'type': 'kinesthetic'
        },
        {
          'text': 'Reviewing visuals like mind maps or flashcards',
          'type': 'visual'
        },
        {
          'text': 'Writing notes or rewriting material',
          'type': 'readWrite'
        },
        {
          'text': 'Saying information out loud or listening to recordings',
          'type': 'aural'
        }
      ]
    },
    {
      'question': 'What helps you remember someone\'s name?',
      'options': [
        {
          'text': 'Saying their name out loud',
          'type': 'aural'
        },
        {
          'text': 'Reading their name or visualizing the spelling',
          'type': 'readWrite'
        },
        {
          'text': 'Remembering what you did together or how you met',
          'type': 'kinesthetic'
        },
        {
          'text': 'Seeing their face or profile image',
          'type': 'visual'
        }
      ]
    },
  ];

  // Slide 15: VARK Results
  Map<String, double> varkScores = {};
  String dominantLearningStyle = '';

  // Slide 16: Goals Selection
  String selectedGoal = '';

  // Slide 17: Membership Selection
  String selectedMembershipPlan = ''; // 'base', 'plus', 'prime'
  String selectedBillingPeriod = 'monthly'; // 'monthly' or 'yearly'

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  // Calculate age from date of birth
  int? getAge() {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Check if can proceed from age verification slide
  bool canProceedFromAgeVerification() {
    if (dateOfBirth == null || !termsAccepted) return false;
    final age = getAge();
    if (age == null) return false;
    
    if (age < 16) return false; // Will show exit message
    if (age >= 16 && age < 18) {
      return hasParentalPermission; // Need parental permission
    }
    return true; // 18+
  }

  // Check if all VARK questions answered
  bool areAllVarkQuestionsAnswered() {
    return varkAnswers.length == varkQuestions.length;
  }

  // Calculate VARK scores based on answer key mapping
  Map<String, double> calculateVARKScores() {
    final scores = {
      'visual': 0.0,
      'aural': 0.0,
      'readWrite': 0.0,
      'kinesthetic': 0.0,
    };

    // Answer key mapping: V = Visual, A = Aural, R = Read/Write, K = Kinesthetic
    // Each array represents the VARK type for options 0, 1, 2, 3
    final answerKey = [
      ['visual', 'aural', 'readWrite', 'kinesthetic'], // Q1: V / A / R / K
      ['kinesthetic', 'visual', 'readWrite', 'aural'], // Q2: K / V / R / A
      ['aural', 'kinesthetic', 'visual', 'readWrite'], // Q3: A / K / V / R
      ['readWrite', 'aural', 'kinesthetic', 'visual'], // Q4: R / A / K / V
      ['readWrite', 'aural', 'kinesthetic', 'visual'], // Q5: R / A / K / V
      ['kinesthetic', 'visual', 'readWrite', 'aural'], // Q6: K / V / R / A
      ['aural', 'readWrite', 'kinesthetic', 'visual'], // Q7: A / R / K / V
    ];

    for (int i = 0; i < varkAnswers.length && i < answerKey.length; i++) {
      final answerIndex = varkAnswers[i];
      if (answerIndex >= 0 && answerIndex < answerKey[i].length) {
        final varkType = answerKey[i][answerIndex];
        scores[varkType] = scores[varkType]! + 1;
      }
    }

    final total = scores.values.reduce((a, b) => a + b);
    if (total > 0) {
      scores.forEach((key, value) {
        scores[key] = (value / total) * 100;
      });
    }

    return scores;
  }

  // Get dominant learning style
  String getDominantStyle() {
    if (varkScores.isEmpty) {
      varkScores = calculateVARKScores();
    }
    
    double maxScore = 0;
    String dominantStyle = 'visual';

    varkScores.forEach((style, score) {
      if (score > maxScore) {
        maxScore = score;
        dominantStyle = style;
      }
    });

    return dominantStyle;
  }

  // Get display name for learning style
  String getLearningStyleDisplayName(String style) {
    switch (style) {
      case 'visual':
        return 'Visual';
      case 'aural':
        return 'Aural';
      case 'readWrite':
        return 'Read/Write';
      case 'kinesthetic':
        return 'Kinesthetic';
      default:
        return 'Multi-Modal';
    }
  }
}
