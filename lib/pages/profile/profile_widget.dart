import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/fococo_ui_components.dart';
import 'package:flutter/material.dart';

import 'profile_model.dart';
import 'profile_modals.dart';
export 'profile_model.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static String routeName = 'profile';
  static String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> with TickerProviderStateMixin {
  late ProfileModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Start animation after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    // Safely dispose animation controller
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).professionalPrimary,
        body: CustomScrollView(
          slivers: [
            // Revolut-inspired Professional Header
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: FlutterFlowTheme.of(context).professionalPrimary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        FlutterFlowTheme.of(context).primary,
                        FlutterFlowTheme.of(context).secondary,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 60, 24, 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Profile Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile',
                                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                                    fontFamily: 'Montserrat',
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage your account',
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white70,
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => _showSettingsModal(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Professional User Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar with Status
                              Stack(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context).premiumGold,
                                        width: 2,
                                      ),
                                    ),
                                    child: currentUserPhoto.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(30),
                                            child: Image.network(
                                              currentUserPhoto,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Color(0xFF111827),
                                            size: 32,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context).premiumGold,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              
                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentUserDisplayName.isNotEmpty 
                                        ? currentUserDisplayName 
                                        : 'Golf Champion',
                                      style: FlutterFlowTheme.of(context).titleLarge.override(
                                        fontFamily: 'Montserrat',
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentUserEmail,
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        fontFamily: 'Inter',
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context).premiumGold.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'PRIME',
                                            style: FlutterFlowTheme.of(context).labelSmall.override(
                                              fontFamily: 'Inter',
                                              color: FlutterFlowTheme.of(context).premiumGold,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Member since 2024',
                                          style: FlutterFlowTheme.of(context).labelSmall.override(
                                            fontFamily: 'Inter',
                                            color: Colors.white60,
                                            fontSize: 10,
                                            height: 1.2,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Main Content
            SliverList(
              delegate: SliverChildListDelegate([
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Section
                        _buildQuickStatsSection(),
                        const SizedBox(height: 32),
                        
                        // Subscription Management Section
                        _buildSubscriptionSection(),
                        const SizedBox(height: 32),
                        
                        // VARK Learning Style Section
                        _buildVarkSection(),
                        const SizedBox(height: 32),
                        
                        // Account Management Section
                        _buildAccountSection(),
                        const SizedBox(height: 32),
                        
                        // Security & Privacy Section
                        _buildSecuritySection(),
                        const SizedBox(height: 32),
                        
                        // Progress & Analytics Section
                        _buildProgressSection(),
                        const SizedBox(height: 32),
                        
                        // Support Section
                        _buildSupportSection(),
                        const SizedBox(height: 32),
                        
                        // Sign Out Button
                        _buildSignOutButton(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
        
        // Enhanced Bottom Navigation Bar
        bottomNavigationBar: FoCoCoAnimatedBottomNavBar(
          currentRoute: 'profile',
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildProfessionalStatCard('Mental Score', '78', '+5 this week', FlutterFlowTheme.of(context).aiPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProfessionalStatCard('Rounds', '24', '+3 this month', FlutterFlowTheme.of(context).golfPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProfessionalStatCard('Streak', '12', 'days active', FlutterFlowTheme.of(context).statusActive),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalStatCard(String label, String value, String change, Color color) {
    return FoCoCoCard(
      style: FoCoCoCardStyle.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: FlutterFlowTheme.of(context).labelMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              fontFamily: 'Montserrat',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: FlutterFlowTheme.of(context).labelSmall.override(
              fontFamily: 'Inter',
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        SubscriptionTierCard(
          title: 'PRIME',
          tierName: 'PRIME',
          price: '\$9.99',
          period: 'month',
          features: [
            'Unlimited AI Insights',
            'Advanced Analytics',
            'VARK Learning System',
            'Priority Support',
            'Custom Training Plans',
          ],
          isCurrentTier: true,
          isRecommended: true,
          onSelect: () => _showSubscriptionModal(context),
        ),
      ],
    );
  }

  Widget _buildVarkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Style',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Personalize your mental training experience',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Inter',
            color: Colors.white70,
            fontSize: 14,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: _buildVarkCard('Visual', 'V', 'Charts & Images', FlutterFlowTheme.of(context).varkVisual, 0.8),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 80,
                child: _buildVarkCard('Auditory', 'A', 'Audio & Voice', FlutterFlowTheme.of(context).varkAuditory, 0.6),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 80,
                child: _buildVarkCard('Reading', 'R', 'Text & Notes', FlutterFlowTheme.of(context).varkReadWrite, 0.7),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 80,
                child: _buildVarkCard('Kinesthetic', 'K', 'Touch & Feel', FlutterFlowTheme.of(context).varkKinesthetic, 0.9),
              ),
              const SizedBox(width: 24), // Add padding at the end
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildProfessionalMenuItem(
          Icons.psychology_outlined,
          'Retake VARK Assessment',
          'Update your learning style preferences',
          () => _showVarkAssessment(context),
        ),
      ],
    );
  }

  Widget _buildVarkCard(String type, String letter, String description, Color color, double strength) {
    return FoCoCoCard(
      style: FoCoCoCardStyle.wellness,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                letter,
                style: FlutterFlowTheme.of(context).titleSmall.override(
                  fontFamily: 'Montserrat',
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type,
            style: FlutterFlowTheme.of(context).labelMedium.override(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: FlutterFlowTheme.of(context).labelSmall.override(
              fontFamily: 'Inter',
              color: Colors.white70,
              fontSize: 10,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: strength,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        FoCoCoCard(
          style: FoCoCoCardStyle.standard,
          child: Column(
            children: [
              _buildProfessionalMenuItem(
                Icons.person_outline,
                'Personal Information',
                'Update name, email, and profile details',
                () => _showPersonalInfoModal(context),
                showDivider: true,
              ),
              _buildProfessionalMenuItem(
                Icons.credit_card_outlined,
                'Payment & Billing',
                'Manage payment methods and billing',
                () => _showBillingModal(context),
                showDivider: true,
              ),
              _buildProfessionalMenuItem(
                Icons.notifications_outlined,
                'Notifications',
                'Configure notification preferences',
                () => _showNotificationsModal(context),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security & Privacy',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        FoCoCoCard(
          style: FoCoCoCardStyle.standard,
          child: Column(
            children: [
              _buildProfessionalMenuItem(
                Icons.security_outlined,
                'Password & Security',
                'Change password and security settings',
                () => _showSecurityModal(context),
                showDivider: true,
              ),
              _buildProfessionalMenuItem(
                Icons.privacy_tip_outlined,
                'Privacy Settings',
                'Manage data sharing and privacy',
                () => _showPrivacyModal(context),
                showDivider: true,
              ),
              _buildProfessionalMenuItem(
                Icons.download_outlined,
                'Export Data',
                'Download your personal data',
                () => _showExportModal(context),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress & Analytics',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        FoCoCoCard(
          style: FoCoCoCardStyle.standard,
          child: Column(
            children: [
              _buildProfessionalMenuItem(
                Icons.emoji_events_outlined,
                'Achievements',
                'View your golf accomplishments',
                () => context.goNamed('achievements'),
                showDivider: true,
              ),
              _buildProfessionalMenuItem(
                Icons.insights_outlined,
                'Detailed Analytics',
                'Comprehensive performance insights',
                () => context.goNamed('progress'),
                showDivider: true,
              ),
              _buildProfessionalMenuItem(
                Icons.share_outlined,
                'Share Progress',
                'Share your achievements with friends',
                () => _showShareModal(context),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        FoCoCoCard(
          style: FoCoCoCardStyle.standard,
          child: Column(
            children: [
              _buildProfessionalMenuItem(
                Icons.help_outline,
                'Help Center',
                'Get help and support',
                () => _showHelpModal(context),
                showDivider: true,
              ),
              _buildProfessionalMenuItem(
                Icons.feedback_outlined,
                'Send Feedback',
                'Help us improve FoCoCo',
                () => _showFeedbackModal(context),
                showDivider: true,
              ),
              _buildProfessionalMenuItem(
                Icons.info_outline,
                'About FoCoCo',
                'App version and information',
                () => _showAboutModal(context),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return FFButtonWidget(
      onPressed: () async {
        await authManager.signOut();
        context.goNamedAuth('login', context.mounted);
      },
      text: 'Sign Out',
      icon: const Icon(
        Icons.logout_outlined,
        color: Colors.white,
        size: 20,
      ),
      options: FFButtonOptions(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
        iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
        color: Colors.red.shade600,
        textStyle: FlutterFlowTheme.of(context).titleMedium.override(
          fontFamily: 'Montserrat',
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        elevation: 0,
        borderSide: BorderSide(
          color: Colors.red.shade600,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildProfessionalMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool showDivider = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).aiPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: FlutterFlowTheme.of(context).aiPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Inter',
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_outlined,
                  color: Colors.white60,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.1),
            indent: 72,
            endIndent: 16,
          ),
      ],
    );
  }



  // Modal methods - Full implementations
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileSettingsModal(),
    );
  }
  
  void _showSubscriptionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionManagementModal(),
    );
  }
  
  void _showVarkAssessment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VarkAssessmentModal(),
    );
  }
  
  void _showPersonalInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PersonalInfoModal(),
    );
  }
  
  void _showBillingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BillingManagementModal(),
    );
  }
  
  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationSettingsModal(),
    );
  }
  
  void _showSecurityModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SecuritySettingsModal(),
    );
  }
  
  void _showPrivacyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrivacySettingsModal(),
    );
  }
  
  void _showExportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DataExportModal(),
    );
  }
  
  void _showShareModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareProgressModal(),
    );
  }
  
  void _showHelpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HelpCenterModal(),
    );
  }
  
  void _showFeedbackModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedbackModal(),
    );
  }
  
  void _showAboutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AboutFoCoCoModal(),
    );
  }
} 