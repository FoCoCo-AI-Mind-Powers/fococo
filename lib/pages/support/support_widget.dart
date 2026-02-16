import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import 'support_model.dart';
export 'support_model.dart';

import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportWidget extends StatefulWidget {
  const SupportWidget({Key? key}) : super(key: key);

  static const String routeName = 'support';
  static const String routePath = '/support';

  @override
  State<SupportWidget> createState() => _SupportWidgetState();
}

class _SupportWidgetState extends State<SupportWidget>
    with TickerProviderStateMixin {
  late SupportModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportModel());

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _model.dispose();
    super.dispose();
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
        drawer: loggedIn
            ? StreamBuilder<UserRecord>(
                stream: UserRecord.getDocument(
                    FirebaseFirestore.instance.doc('user/${currentUserUid}')),
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  return EnhancedFoCoCoDrawer(
                    currentUser: userData,
                    currentRoute: 'support',
                    onNavigate: (route) => context.goNamed(route),
                  );
                },
              )
            : null,
        body: Stack(
          children: [
            // Main content
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryBackground,
                    theme.secondaryBackground.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Custom App Bar
                        _buildCustomAppBar(theme),

                        // Main Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Quick Help
                                _buildQuickHelpSection(theme),

                                const SizedBox(height: 24),

                                // FAQ
                                _buildFAQSection(theme),

                                const SizedBox(height: 24),

                                // Contact Support
                                _buildContactSection(theme),

                                const SizedBox(height: 24),

                                // Resources
                                _buildResourcesSection(theme),

                                const SizedBox(height: 100), // Space for navbar
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: EnhancedFoCoCoNavBar(
          currentRoute: 'support',
          onTap: (route) {
            print('🔄 Support page: Navigation requested to route: $route');
            context.goNamed(route);
          },
          currentUser: null,
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Menu button
          GestureDetector(
            onTap: () => scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.glassBackground.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.glassBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: theme.primaryText,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Help & Support',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Search button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.glassBackground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.glassBorder.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.search,
              color: theme.primaryText,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Quick Help',
      subtitle: 'Get started with common tasks',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpCard(
                    theme,
                    Icons.golf_course,
                    'Open CaddyPlay',
                    'Capture a round or practice session',
                    () => context.goNamed('caddy_play'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickHelpCard(
                    theme,
                    Icons.chat_bubble_outline_rounded,
                    'Open GolfChat',
                    'Reflect on what happened',
                    () => context.goNamed('golf_chat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpCard(
                    theme,
                    Icons.insights,
                    'View Insights',
                    'Check AI recommendations',
                    () => context.goNamed('ai_insights'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickHelpCard(
                    theme,
                    Icons.person,
                    'Edit Profile',
                    'Update your information',
                    () => context.goNamed('edit_profile'),
                  ),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildFAQSection(FlutterFlowTheme theme) {
    final faqs = [
      {
        'question': 'How do I log my first golf round?',
        'answer':
            'Go to the Golf Rounds page and tap the "+" button. Fill in your course, score, and mental performance ratings.',
      },
      {
        'question': 'What is the Mental Performance Index?',
        'answer':
            'The MPI combines your Focus, Confidence, and Control scores to give you an overall mental game rating.',
      },
      {
        'question': 'How do AI Insights work?',
        'answer':
            'Our AI analyzes your performance data and provides personalized recommendations to improve your mental game.',
      },
      {
        'question': 'Can I use FoCoCo offline?',
        'answer':
            'Some features work offline, but you\'ll need an internet connection for AI insights and data sync.',
      },
      {
        'question': 'How do I cancel my subscription?',
        'answer':
            'Go to Settings > Subscription Management to view and manage your subscription.',
      },
    ];

    return GlassDashboardCard(
      title: 'Frequently Asked Questions',
      subtitle: 'Find answers to common questions',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            ...faqs
                .map((faq) => _buildFAQItem(
                      theme,
                      faq['question']!,
                      faq['answer']!,
                    ))
                .toList(),
          ],
        )
      ],
    );
  }

  Widget _buildContactSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Contact Support',
      subtitle: 'Get in touch with our team',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildContactItem(
              theme,
              Icons.email_outlined,
              'Email Support',
              'support@fococo.app',
              () => _launchEmail('support@fococo.app'),
            ),
            _buildContactItem(
              theme,
              Icons.chat_outlined,
              'Live Chat',
              'Available 9 AM - 5 PM EST',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Live chat coming soon!'),
                    backgroundColor: theme.primary,
                  ),
                );
              },
            ),
            _buildContactItem(
              theme,
              Icons.bug_report_outlined,
              'Report a Bug',
              'Help us improve the app',
              () => _launchEmail('bugs@fococo.app', subject: 'Bug Report'),
            ),
            _buildContactItem(
              theme,
              Icons.feedback_outlined,
              'Send Feedback',
              'Share your thoughts',
              () =>
                  _launchEmail('feedback@fococo.app', subject: 'App Feedback'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildResourcesSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Resources',
      subtitle: 'Learn more about FoCoCo',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildResourceItem(
              theme,
              Icons.book_outlined,
              'User Guide',
              'Complete guide to using FoCoCo',
              () => _launchURL('https://fococo.app/guide'),
            ),
            _buildResourceItem(
              theme,
              FontAwesomeIcons.youtube,
              'Video Tutorials',
              'Watch how-to videos',
              () => _launchURL('https://youtube.com/@fococo'),
            ),
            _buildResourceItem(
              theme,
              Icons.article_outlined,
              'Blog',
              'Tips and insights for better golf',
              () => _launchURL('https://fococo.app/blog'),
            ),
            _buildResourceItem(
              theme,
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'How we protect your data',
              () => _launchURL('https://fococo.app/privacy'),
            ),
            _buildResourceItem(
              theme,
              Icons.description_outlined,
              'Terms of Service',
              'App usage terms and conditions',
              () => _launchURL('https://fococo.app/terms'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildQuickHelpCard(
    FlutterFlowTheme theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.glassBackground.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.labelSmall.copyWith(
                color: theme.secondaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FlutterFlowTheme theme, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: theme.bodyMedium.copyWith(
          color: theme.primaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    FlutterFlowTheme theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.labelSmall.copyWith(
            color: theme.secondaryText,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.secondaryText,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildResourceItem(
    FlutterFlowTheme theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.secondary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.labelSmall.copyWith(
            color: theme.secondaryText,
          ),
        ),
        trailing: Icon(
          Icons.open_in_new,
          color: theme.secondaryText,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email app'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open URL'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }
}
