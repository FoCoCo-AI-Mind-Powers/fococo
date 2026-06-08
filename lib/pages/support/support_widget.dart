import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/pages/fococo_tab/fococo_tab_widget.dart';
import '/pages/support/support_submission_widget.dart';
import '/services/support_submission_service.dart';
import 'support_model.dart';
export 'support_model.dart';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
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

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportModel());

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
        body: Container(
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
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: FoCoCoInlineScreenHeader(
                        title: 'Support',
                        subtitle: 'Help & contact',
                        leading: IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 44,
                          ),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: theme.primaryText,
                            size: 20,
                          ),
                          tooltip: 'Back',
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.goNamed(FoCoCoTabWidget.routeName);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSupportSection(theme),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: EnhancedFoCoCoNavBar(
          currentRoute: 'support',
          barBackgroundColor: theme.primaryBackground,
          onTap: (route) => context.goNamed(route),
          currentUser: null,
        ),
      ),
    );
  }

  Widget _buildSupportSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Help & Support',
      subtitle: 'Contact the FoCoCo team',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildContactItem(
              theme,
              Icons.email_outlined,
              'Email Support',
              'support@fococo.ai',
              () => _launchEmail(
                'support@fococo.ai',
                subject: 'FoCoCo Support',
              ),
            ),
            _buildContactItem(
              theme,
              Icons.bug_report_outlined,
              'Report a Bug',
              'Help us improve the app',
              () => SupportSubmissionWidget.open(
                context,
                SupportSubmissionType.bug,
              ),
            ),
            _buildContactItem(
              theme,
              Icons.feedback_outlined,
              'Send Feedback',
              'Share your thoughts',
              () => SupportSubmissionWidget.open(
                context,
                SupportSubmissionType.feedback,
              ),
            ),
            _buildContactItem(
              theme,
              Icons.star_outline_rounded,
              'Rate App',
              'Leave a review on the App Store or Google Play',
              _rateApp,
            ),
          ],
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
          child: Icon(icon, color: theme.primary, size: 22),
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
          style: theme.labelSmall.copyWith(color: theme.secondaryText),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.secondaryText,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _rateApp() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    }
  }

  Future<void> _launchEmail(
    String email, {
    String? subject,
    String? body,
  }) async {
    final queryParts = <String>[];
    if (subject != null) {
      queryParts.add('subject=${Uri.encodeComponent(subject)}');
    }
    if (body != null) {
      queryParts.add('body=${Uri.encodeComponent(body)}');
    }
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: queryParts.isEmpty ? null : queryParts.join('&'),
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open email app'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }
}
