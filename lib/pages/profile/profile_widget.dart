import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'profile_model.dart';
export 'profile_model.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static String routeName = 'profile';
  static String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late ProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());
  }

  @override
  void dispose() {
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
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B4D2C), Color(0xFF2E8B57)],
                      stops: [0.0, 1.0],
                      begin: AlignmentDirectional(-1.0, -1.0),
                      end: AlignmentDirectional(1.0, 1.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                                  onPressed: () => context.pop(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Profile',
                                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                              onPressed: () {
                                // Navigate to settings
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Profile Info
                        Column(
                          children: [
                            // Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 20,
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: currentUserPhoto.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        currentUserPhoto,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Color(0xFF0B4D2C),
                                      size: 50,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Name
                            Text(
                              currentUserDisplayName.isNotEmpty 
                                ? currentUserDisplayName 
                                : 'Golf Champion',
                              style: FlutterFlowTheme.of(context).headlineMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Email
                            Text(
                              currentUserEmail,
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Subscription Badge
                            Container(
                              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pro Member',
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: Colors.amber,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Stats Section
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Streak', '12', 'days'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('Rounds', '24', 'played'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('Avg Score', '78.5', 'strokes'),
                      ),
                    ],
                  ),
                ),
                
                // Menu Section
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 0),
                  child: Column(
                    children: [
                      // Account Section
                      _buildMenuSection('Account', [
                        _buildMenuItem(
                          Icons.person_outline,
                          'Personal Information',
                          'Update your profile details',
                          () {},
                        ),
                        _buildMenuItem(
                          Icons.security_outlined,
                          'Privacy & Security',
                          'Manage your account security',
                          () {},
                        ),
                        _buildMenuItem(
                          Icons.notifications_outlined,
                          'Notifications',
                          'Configure notification preferences',
                          () {},
                        ),
                      ]),
                      const SizedBox(height: 24),
                      
                      // Subscription Section
                      _buildMenuSection('Subscription', [
                        _buildMenuItem(
                          Icons.star_outline,
                          'Upgrade to Pro',
                          'Unlock premium features',
                          () => context.goNamed('subscription'),
                          trailing: Container(
                            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PRO',
                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        _buildMenuItem(
                          Icons.credit_card_outlined,
                          'Billing',
                          'Manage payment methods',
                          () {},
                        ),
                      ]),
                      const SizedBox(height: 24),
                      
                      // Progress Section
                      _buildMenuSection('Progress', [
                        _buildMenuItem(
                          Icons.emoji_events_outlined,
                          'Achievements',
                          'View your golf accomplishments',
                          () => context.goNamed('achievements'),
                        ),
                        _buildMenuItem(
                          Icons.insights_outlined,
                          'Statistics',
                          'Detailed performance analytics',
                          () => context.goNamed('progress'),
                        ),
                        _buildMenuItem(
                          Icons.download_outlined,
                          'Export Data',
                          'Download your golf data',
                          () {},
                        ),
                      ]),
                      const SizedBox(height: 24),
                      
                      // Support Section
                      _buildMenuSection('Support', [
                        _buildMenuItem(
                          Icons.help_outline,
                          'Help Center',
                          'Get help and support',
                          () {},
                        ),
                        _buildMenuItem(
                          Icons.feedback_outlined,
                          'Send Feedback',
                          'Help us improve FoCoCo',
                          () {},
                        ),
                        _buildMenuItem(
                          Icons.info_outline,
                          'About',
                          'App version and information',
                          () {},
                        ),
                      ]),
                      const SizedBox(height: 32),
                      
                      // Logout Button
                      FFButtonWidget(
                        onPressed: () async {
                          await authManager.signOut();
                          context.goNamedAuth('login', context.mounted);
                        },
                        text: 'Sign Out',
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 56,
                          padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                          iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                          color: Colors.red,
                          textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                          elevation: 3,
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subtitle) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
              fontFamily: 'Inter',
              color: const Color(0xFF0B4D2C),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          Text(
            subtitle,
            style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: Colors.grey[600],
              fontSize: 12,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FlutterFlowTheme.of(context).headlineSmall.override(
            fontFamily: 'Inter',
            color: const Color(0xFF0B4D2C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0B4D2C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0B4D2C),
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
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 