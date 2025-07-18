import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/fococo_ui_components.dart';

/// Base Modal Widget for consistent styling
class BaseModal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;

  const BaseModal({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).professionalPrimary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: child,
            ),
          ),
          
          // Actions
          if (actions != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}

/// Profile Settings Modal with Audio Preferences
class ProfileSettingsModal extends StatefulWidget {
  const ProfileSettingsModal({super.key});

  @override
  State<ProfileSettingsModal> createState() => _ProfileSettingsModalState();
}

class _ProfileSettingsModalState extends State<ProfileSettingsModal> {
  AudioPreferencesStruct _audioPreferences = AudioPreferencesStruct();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();
      
      if (userDoc.exists && userDoc.data()?['audioPreferences'] != null) {
        setState(() {
          _audioPreferences = AudioPreferencesStruct.fromMap(
            userDoc.data()!['audioPreferences'] as Map<String, dynamic>
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        'audioPreferences': _audioPreferences.toMap(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Settings',
      subtitle: 'Customize your FoCoCo experience',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio Settings Section
          const Text(
            'Audio Settings',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          FoCoCoCard(
            style: FoCoCoCardStyle.standard,
            child: Column(
              children: [
                _buildToggleSetting(
                  'Enable Text-to-Speech',
                  'Convert AI insights to audio',
                  _audioPreferences.enableTextToSpeech,
                  (value) => setState(() {
                    _audioPreferences = AudioPreferencesStruct(
                      enableTextToSpeech: value,
                      speechRate: _audioPreferences.speechRate,
                      voicePitch: _audioPreferences.voicePitch,
                      voiceVolume: _audioPreferences.voiceVolume,
                      backgroundAudioEnabled: _audioPreferences.backgroundAudioEnabled,
                      backgroundVolume: _audioPreferences.backgroundVolume,
                      preferredVoiceGender: _audioPreferences.preferredVoiceGender,
                      audioFeedbackEnabled: _audioPreferences.audioFeedbackEnabled,
                    );
                  }),
                ),
                
                const Divider(color: Colors.white12),
                _buildToggleSetting(
                  'Background Audio',
                  'Play ambient sounds during coaching',
                  _audioPreferences.backgroundAudioEnabled,
                  (value) => setState(() {
                    _audioPreferences = AudioPreferencesStruct(
                      enableTextToSpeech: _audioPreferences.enableTextToSpeech,
                      speechRate: _audioPreferences.speechRate,
                      voicePitch: _audioPreferences.voicePitch,
                      voiceVolume: _audioPreferences.voiceVolume,
                      backgroundAudioEnabled: value,
                      backgroundVolume: _audioPreferences.backgroundVolume,
                      preferredVoiceGender: _audioPreferences.preferredVoiceGender,
                      audioFeedbackEnabled: _audioPreferences.audioFeedbackEnabled,
                    );
                  }),
                ),
                
                const Divider(color: Colors.white12),
                _buildToggleSetting(
                  'Audio Feedback',
                  'Enable sound effects and audio cues',
                  _audioPreferences.audioFeedbackEnabled,
                  (value) => setState(() {
                    _audioPreferences = AudioPreferencesStruct(
                      enableTextToSpeech: _audioPreferences.enableTextToSpeech,
                      speechRate: _audioPreferences.speechRate,
                      voicePitch: _audioPreferences.voicePitch,
                      voiceVolume: _audioPreferences.voiceVolume,
                      backgroundAudioEnabled: _audioPreferences.backgroundAudioEnabled,
                      backgroundVolume: _audioPreferences.backgroundVolume,
                      preferredVoiceGender: _audioPreferences.preferredVoiceGender,
                      audioFeedbackEnabled: value,
                    );
                  }),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
      actions: [
        Expanded(
          child: FFButtonWidget(
            onPressed: _isLoading ? null : _saveSettings,
            text: _isLoading ? 'Saving...' : 'Save Settings',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              color: FlutterFlowTheme.of(context).aiPrimary,
              textStyle: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: FlutterFlowTheme.of(context).aiPrimary,
          ),
        ],
      ),
    );
  }
}

/// Simple Modal Placeholders for other functionality
class SubscriptionManagementModal extends StatelessWidget {
  const SubscriptionManagementModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Subscription',
      subtitle: 'Manage your FoCoCo membership',
      child: Column(
        children: [
          FoCoCoCard(
            style: FoCoCoCardStyle.standard,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Current Plan: PRIME',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Next billing: \$9.99 on Feb 15, 2024',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VarkAssessmentModal extends StatefulWidget {
  const VarkAssessmentModal({super.key});

  @override
  State<VarkAssessmentModal> createState() => _VarkAssessmentModalState();
}

class _VarkAssessmentModalState extends State<VarkAssessmentModal> {
  final PageController _pageController = PageController();
  int _currentQuestion = 0;
  Map<String, int> _scores = {'visual': 0, 'aural': 0, 'readWrite': 0, 'kinesthetic': 0};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Before a crucial putt, how do you best prepare mentally?',
      'answers': [
        {'text': 'Visualize the ball\'s path to the hole', 'type': 'visual'},
        {'text': 'Listen to your breathing rhythm', 'type': 'aural'},
        {'text': 'Review your mental checklist', 'type': 'readWrite'},
        {'text': 'Feel the weight of the putter', 'type': 'kinesthetic'},
      ]
    },
    {
      'question': 'When learning a new golf technique, you prefer to:',
      'answers': [
        {'text': 'Watch instructional videos', 'type': 'visual'},
        {'text': 'Listen to verbal instructions', 'type': 'aural'},
        {'text': 'Read detailed guides', 'type': 'readWrite'},
        {'text': 'Practice the movement repeatedly', 'type': 'kinesthetic'},
      ]
    },
    {
      'question': 'To remember your pre-shot routine, you:',
      'answers': [
        {'text': 'Picture each step in your mind', 'type': 'visual'},
        {'text': 'Repeat verbal cues to yourself', 'type': 'aural'},
        {'text': 'Write down the steps', 'type': 'readWrite'},
        {'text': 'Practice the physical motions', 'type': 'kinesthetic'},
      ]
    },
    {
      'question': 'When analyzing your golf performance, you prefer:',
      'answers': [
        {'text': 'Charts and visual statistics', 'type': 'visual'},
        {'text': 'Discussing with others', 'type': 'aural'},
        {'text': 'Written performance notes', 'type': 'readWrite'},
        {'text': 'Feeling the difference in swings', 'type': 'kinesthetic'},
      ]
    },
    {
      'question': 'During mental coaching sessions, you learn best through:',
      'answers': [
        {'text': 'Visual imagery exercises', 'type': 'visual'},
        {'text': 'Audio guidance and mantras', 'type': 'aural'},
        {'text': 'Reading and journaling', 'type': 'readWrite'},
        {'text': 'Physical relaxation techniques', 'type': 'kinesthetic'},
      ]
    },
  ];

  void _selectAnswer(String type) {
    setState(() {
      _scores[type] = (_scores[type] ?? 0) + 1;
    });

    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeAssessment();
    }
  }

  Future<void> _completeAssessment() async {
    setState(() => _isLoading = true);

    try {
      // Determine dominant style
      String dominantStyle = _scores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Convert to boolean preferences
      VarkPreferencesStruct varkPreferences = VarkPreferencesStruct(
        visual: dominantStyle == 'visual',
        aural: dominantStyle == 'aural',
        readWrite: dominantStyle == 'readWrite',
        kinesthetic: dominantStyle == 'kinesthetic',
      );

      // Update user record
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        'varkPreferences': varkPreferences.toMap(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assessment complete! Your learning style: ${_getStyleName(dominantStyle)}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving assessment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStyleName(String type) {
    switch (type) {
      case 'visual': return 'Visual';
      case 'aural': return 'Auditory';
      case 'readWrite': return 'Read/Write';
      case 'kinesthetic': return 'Kinesthetic';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BaseModal(
        title: 'Processing...',
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return BaseModal(
      title: 'VARK Assessment',
      subtitle: 'Question ${_currentQuestion + 1} of ${_questions.length}',
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / _questions.length,
            backgroundColor: Colors.white30,
            valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).aiPrimary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question['question'],
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    ...List.generate(
                      question['answers'].length,
                      (answerIndex) {
                        final answer = question['answers'][answerIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: FFButtonWidget(
                              onPressed: () => _selectAnswer(answer['type']),
                              text: answer['text'],
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 56,
                                color: Colors.white.withOpacity(0.1),
                                textStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.white30,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class PersonalInfoModal extends StatefulWidget {
  const PersonalInfoModal({super.key});

  @override
  State<PersonalInfoModal> createState() => _PersonalInfoModalState();
}

class _PersonalInfoModalState extends State<PersonalInfoModal> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _handicapController = TextEditingController();
  final _homeClubController = TextEditingController();
  
  String _selectedExperience = '';
  bool _isLoading = false;

  final List<String> _experienceOptions = [
    'Beginner (0-2 years)',
    'Intermediate (3-5 years)',
    'Advanced (6-10 years)',
    'Expert (10+ years)',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _displayNameController.text = data['displayName'] ?? '';
          _handicapController.text = (data['handicap'] ?? 0.0).toString();
          _homeClubController.text = data['homeClub'] ?? '';
          _selectedExperience = data['golfExperience'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        'displayName': _displayNameController.text.trim(),
        'handicap': double.tryParse(_handicapController.text) ?? 0.0,
        'homeClub': _homeClubController.text.trim(),
        'golfExperience': _selectedExperience,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Personal Information',
      subtitle: 'Update your profile details',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Name
            const Text(
              'Display Name',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _displayNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your display name',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).aiPrimary),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Display name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Handicap
            const Text(
              'Handicap',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _handicapController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter your handicap',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).aiPrimary),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final handicap = double.tryParse(value);
                  if (handicap == null || handicap < -10 || handicap > 54) {
                    return 'Enter a valid handicap (-10 to 54)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Golf Experience
            const Text(
              'Golf Experience',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedExperience.isEmpty ? null : _selectedExperience,
              style: const TextStyle(color: Colors.white),
              dropdownColor: FlutterFlowTheme.of(context).professionalPrimary,
              decoration: InputDecoration(
                hintText: 'Select your experience level',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).aiPrimary),
                ),
              ),
              items: _experienceOptions.map((String experience) {
                return DropdownMenuItem<String>(
                  value: experience,
                  child: Text(experience, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedExperience = newValue ?? '';
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Home Club
            const Text(
              'Home Club',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _homeClubController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your home golf club',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).aiPrimary),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      actions: [
        Expanded(
          child: FFButtonWidget(
            onPressed: _isLoading ? null : _saveProfile,
            text: _isLoading ? 'Saving...' : 'Save Changes',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              color: FlutterFlowTheme.of(context).aiPrimary,
              textStyle: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _handicapController.dispose();
    _homeClubController.dispose();
    super.dispose();
  }
}

class BillingManagementModal extends StatelessWidget {
  const BillingManagementModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Billing & Payment',
      subtitle: 'Manage payment methods and billing',
      child: const Column(
        children: [
          Text(
            'View billing history and manage payment methods.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsModal extends StatefulWidget {
  const NotificationSettingsModal({super.key});

  @override
  State<NotificationSettingsModal> createState() => _NotificationSettingsModalState();
}

class _NotificationSettingsModalState extends State<NotificationSettingsModal> {
  NotificationSettingsStruct _notificationSettings = NotificationSettingsStruct();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();
      
      if (userDoc.exists && userDoc.data()?['notificationSettings'] != null) {
        setState(() {
          _notificationSettings = NotificationSettingsStruct.fromMap(
            userDoc.data()!['notificationSettings'] as Map<String, dynamic>
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        'notificationSettings': _notificationSettings.toMap(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Notifications',
      subtitle: 'Configure notification preferences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoCoCoCard(
            style: FoCoCoCardStyle.standard,
            child: Column(
              children: [
                _buildNotificationToggle(
                  'Daily Reminders',
                  'Daily mental coaching reminders',
                  _notificationSettings.dailyReminders,
                  (value) => setState(() {
                    _notificationSettings = NotificationSettingsStruct(
                      dailyReminders: value,
                      insightNotifications: _notificationSettings.insightNotifications,
                      achievementAlerts: _notificationSettings.achievementAlerts,
                      weeklyProgress: _notificationSettings.weeklyProgress,
                    );
                  }),
                ),
                
                const Divider(color: Colors.white12),
                _buildNotificationToggle(
                  'Insight Notifications',
                  'Get notified of new AI insights',
                  _notificationSettings.insightNotifications,
                  (value) => setState(() {
                    _notificationSettings = NotificationSettingsStruct(
                      dailyReminders: _notificationSettings.dailyReminders,
                      insightNotifications: value,
                      achievementAlerts: _notificationSettings.achievementAlerts,
                      weeklyProgress: _notificationSettings.weeklyProgress,
                    );
                  }),
                ),
                
                const Divider(color: Colors.white12),
                _buildNotificationToggle(
                  'Achievement Alerts',
                  'Get notified of new achievements',
                  _notificationSettings.achievementAlerts,
                  (value) => setState(() {
                    _notificationSettings = NotificationSettingsStruct(
                      dailyReminders: _notificationSettings.dailyReminders,
                      insightNotifications: _notificationSettings.insightNotifications,
                      achievementAlerts: value,
                      weeklyProgress: _notificationSettings.weeklyProgress,
                    );
                  }),
                ),
                
                const Divider(color: Colors.white12),
                _buildNotificationToggle(
                  'Weekly Progress',
                  'Weekly progress summary notifications',
                  _notificationSettings.weeklyProgress,
                  (value) => setState(() {
                    _notificationSettings = NotificationSettingsStruct(
                      dailyReminders: _notificationSettings.dailyReminders,
                      insightNotifications: _notificationSettings.insightNotifications,
                      achievementAlerts: _notificationSettings.achievementAlerts,
                      weeklyProgress: value,
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      actions: [
        Expanded(
          child: FFButtonWidget(
            onPressed: _isLoading ? null : _saveNotificationSettings,
            text: _isLoading ? 'Saving...' : 'Save Settings',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              color: FlutterFlowTheme.of(context).aiPrimary,
              textStyle: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: FlutterFlowTheme.of(context).aiPrimary,
          ),
        ],
      ),
    );
  }
}

class SecuritySettingsModal extends StatelessWidget {
  const SecuritySettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Security Settings',
      subtitle: 'Manage your account security',
      child: const Column(
        children: [
          Text(
            'Update password and security preferences.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacySettingsModal extends StatelessWidget {
  const PrivacySettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Privacy Settings',
      subtitle: 'Control your data and privacy',
      child: const Column(
        children: [
          Text(
            'Manage your privacy preferences and data sharing.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class DataExportModal extends StatelessWidget {
  const DataExportModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Export Data',
      subtitle: 'Download your personal data',
      child: const Column(
        children: [
          Text(
            'Export your golf rounds, mental sessions, and other data.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class ShareProgressModal extends StatelessWidget {
  const ShareProgressModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Share Progress',
      subtitle: 'Share your achievements',
      child: const Column(
        children: [
          Text(
            'Share your golf mental game progress with friends.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class HelpCenterModal extends StatelessWidget {
  const HelpCenterModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Help Center',
      subtitle: 'Get help and support',
      child: const Column(
        children: [
          Text(
            'Find answers to common questions and get support.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackModal extends StatelessWidget {
  const FeedbackModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Send Feedback',
      subtitle: 'Help us improve FoCoCo',
      child: const Column(
        children: [
          Text(
            'Share your thoughts and suggestions with our team.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutFoCoCoModal extends StatelessWidget {
  const AboutFoCoCoModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'About FoCoCo',
      subtitle: 'App information and version',
      child: Column(
        children: [
          FoCoCoLogo(
            size: LogoSize.medium,
            showText: true,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          const Text(
            'FoCoCo - Golf Mental Coaching',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Version 1.0.0',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Focus • Confidence • Control\nMaster Your Mental Game',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
} 