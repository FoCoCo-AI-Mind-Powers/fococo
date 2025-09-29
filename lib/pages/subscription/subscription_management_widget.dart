import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/stripe_service.dart';
import '/services/biometric_auth_service.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
import 'dart:ui';
import 'subscription_management_model.dart';
export 'subscription_management_model.dart';

class SubscriptionManagementWidget extends StatefulWidget {
  const SubscriptionManagementWidget({super.key});

  static String routeName = 'subscription_management';
  static String routePath = '/subscription_management';

  @override
  State<SubscriptionManagementWidget> createState() =>
      _SubscriptionManagementWidgetState();
}

class _SubscriptionManagementWidgetState
    extends State<SubscriptionManagementWidget> with TickerProviderStateMixin {
  late SubscriptionManagementModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final StripeService _stripeService = StripeService();
  final BiometricAuthService _biometricService = BiometricAuthService();

  // Animation controllers - matching settings pattern
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserSubscriptionInfo? _currentSubscription;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubscriptionManagementModel());

    // Initialize animations - matching settings pattern
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
    _loadSubscriptionData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      // Check for biometric authentication if subscription protection is enabled
      final authResult = await _biometricService.authenticateForSubscription();

      if (!authResult.success) {
        // If authentication fails, show error and go back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authResult.error ?? 'Authentication required'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
        return;
      }

      final subscription = await _stripeService.getCurrentSubscription();
      setState(() {
        _currentSubscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load subscription: $e');
      setState(() => _isLoading = false);
    }
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
                          child: _isLoading
                              ? _buildLoadingState(theme)
                              : _currentSubscription != null
                                  ? _buildActiveSubscription(theme)
                                  : _buildNoSubscription(theme),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Voice Button
            const FloatingVoiceButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          _buildGlassButton(
            theme: theme,
            icon: Icons.arrow_back_ios,
            onTap: () => context.pop(),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Subscription Management',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Settings button
          _buildGlassButton(
            theme: theme,
            icon: Icons.settings_outlined,
            onTap: () => context.goNamed('settings'),
          ),
        ],
      ),
    );
  }

  /// Build glass design button
  Widget _buildGlassButton({
    required FlutterFlowTheme theme,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.glassBackground.withValues(alpha: 0.3),
                  theme.glassTint.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.glassBorder.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.glassShadow.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: theme.primaryText,
              size: icon == Icons.arrow_back_ios ? 20 : 24,
            ),
          ),
        ),
      ),
    );
  }

  /// Loading state
  Widget _buildLoadingState(FlutterFlowTheme theme) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Active subscription view
  Widget _buildActiveSubscription(FlutterFlowTheme theme) {
    final subscription = _currentSubscription!;
    final plan = StripeService.subscriptionPlans[subscription.membershipTier];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current plan card
          _buildCurrentPlanCard(theme, subscription, plan),

          const SizedBox(height: 32),

          // Subscription details
          _buildSubscriptionDetails(theme, subscription),

          const SizedBox(height: 32),

          // Plan features
          if (plan != null) _buildPlanFeatures(theme, plan),

          const SizedBox(height: 32),

          // Upgrade/Downgrade options
          _buildPlanOptions(theme, subscription),

          const SizedBox(height: 32),

          // Manage subscription
          _buildManageSubscription(theme, subscription),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// No subscription view
  Widget _buildNoSubscription(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withValues(alpha: 0.1),
                  theme.secondary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.crown,
              color: theme.primary,
              size: 60,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Upgrade to Premium',
            textAlign: TextAlign.center,
            style: theme.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            'Unlock advanced AI insights, premium coaching content, and exclusive features to take your mental game to the next level.',
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 40),

          // Available plans
          _buildAvailablePlans(theme),

          const SizedBox(height: 32),

          // Subscribe button
          FFButtonWidget(
            onPressed: () => _navigateToSubscriptionOnboarding(),
            text: 'Choose Your Plan',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              padding: EdgeInsets.zero,
              iconPadding: EdgeInsets.zero,
              color: theme.primary,
              textStyle: theme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  /// Current plan card
  Widget _buildCurrentPlanCard(
    FlutterFlowTheme theme,
    UserSubscriptionInfo subscription,
    SubscriptionPlan? plan,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary,
            theme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Plan',
                    style: theme.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan?.name ?? subscription.membershipTier.toUpperCase(),
                    style: theme.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subscription.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: theme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (plan != null)
            Text(
              plan.formattedPrice,
              style: theme.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Next billing: ${DateFormat('MMM dd, yyyy').format(subscription.currentPeriodEnd)}',
            style: theme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (subscription.cancelAtPeriodEnd) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your subscription will end on ${DateFormat('MMM dd, yyyy').format(subscription.currentPeriodEnd)}',
                      style: theme.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Subscription details
  Widget _buildSubscriptionDetails(
    FlutterFlowTheme theme,
    UserSubscriptionInfo subscription,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Details',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          theme: theme,
          label: 'Status',
          value: subscription.isActive ? 'Active' : 'Inactive',
          valueColor: subscription.isActive
              ? theme.performanceExcellent
              : theme.performancePoor,
        ),
        _buildDetailRow(
          theme: theme,
          label: 'Billing Cycle',
          value: 'Monthly',
        ),
        _buildDetailRow(
          theme: theme,
          label: 'Started',
          value: DateFormat('MMM dd, yyyy')
              .format(subscription.currentPeriodStart),
        ),
        _buildDetailRow(
          theme: theme,
          label: 'Auto Renewal',
          value: subscription.autoRenewing ? 'Enabled' : 'Disabled',
          valueColor: subscription.autoRenewing
              ? theme.performanceExcellent
              : theme.performancePoor,
        ),
      ],
    );
  }

  /// Detail row
  Widget _buildDetailRow({
    required FlutterFlowTheme theme,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
          ),
          Text(
            value,
            style: theme.bodyMedium.copyWith(
              color: valueColor ?? theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Plan features
  Widget _buildPlanFeatures(FlutterFlowTheme theme, SubscriptionPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Plan Includes',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        ...plan.features
            .map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.performanceExcellent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.bodyMedium.copyWith(
                            color: theme.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  /// Plan options (upgrade/downgrade)
  Widget _buildPlanOptions(
    FlutterFlowTheme theme,
    UserSubscriptionInfo subscription,
  ) {
    final currentTier = subscription.membershipTier;
    final availablePlans = StripeService.subscriptionPlans.entries
        .where((entry) => entry.key != currentTier)
        .toList();

    if (availablePlans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other Plans',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        ...availablePlans.map((entry) {
          final plan = entry.value;
          final isUpgrade = _isUpgrade(currentTier, plan.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPlanOptionCard(
              theme: theme,
              plan: plan,
              isUpgrade: isUpgrade,
              onTap: () => _changePlan(plan.id),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Plan option card
  Widget _buildPlanOptionCard({
    required FlutterFlowTheme theme,
    required SubscriptionPlan plan,
    required bool isUpgrade,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.secondaryText.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUpgrade
                    ? theme.performanceExcellent.withValues(alpha: 0.1)
                    : theme.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUpgrade ? Icons.arrow_upward : Icons.arrow_downward,
                color: isUpgrade ? theme.performanceExcellent : theme.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUpgrade
                              ? theme.performanceExcellent
                                  .withValues(alpha: 0.1)
                              : theme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isUpgrade ? 'UPGRADE' : 'DOWNGRADE',
                          style: theme.bodySmall.copyWith(
                            color: isUpgrade
                                ? theme.performanceExcellent
                                : theme.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.formattedPrice,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Available plans for non-subscribers
  Widget _buildAvailablePlans(FlutterFlowTheme theme) {
    return Column(
      children: StripeService.subscriptionPlans.entries.map((entry) {
        final plan = entry.value;
        final isPopular = plan.id == 'plus';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPopular
                    ? theme.primary
                    : theme.secondaryText.withValues(alpha: 0.1),
                width: isPopular ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: theme.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.warning,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'POPULAR',
                                style: theme.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.formattedPrice,
                        style: theme.titleMedium.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${plan.features.length} features',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Manage subscription section
  Widget _buildManageSubscription(
    FlutterFlowTheme theme,
    UserSubscriptionInfo subscription,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Subscription',
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 16),

        // Cancel subscription
        if (!subscription.cancelAtPeriodEnd)
          _buildManageButton(
            theme: theme,
            title: 'Cancel Subscription',
            subtitle: 'Cancel at the end of current period',
            icon: Icons.cancel_outlined,
            color: theme.performancePoor,
            onTap: () => _cancelSubscription(subscription),
          )
        else
          _buildManageButton(
            theme: theme,
            title: 'Reactivate Subscription',
            subtitle: 'Continue your subscription',
            icon: Icons.refresh,
            color: theme.performanceExcellent,
            onTap: () => _reactivateSubscription(subscription),
          ),

        const SizedBox(height: 12),

        // Contact support
        _buildManageButton(
          theme: theme,
          title: 'Contact Support',
          subtitle: 'Get help with your subscription',
          icon: Icons.support_agent,
          color: theme.primary,
          onTap: () => _contactSupport(),
        ),
      ],
    );
  }

  /// Manage button
  Widget _buildManageButton({
    required FlutterFlowTheme theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.secondaryText.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: theme.secondaryText,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  bool _isUpgrade(String currentTier, String newTier) {
    const tierOrder = ['base', 'plus', 'prime'];
    final currentIndex = tierOrder.indexOf(currentTier);
    final newIndex = tierOrder.indexOf(newTier);
    return newIndex > currentIndex;
  }

  void _navigateToSubscriptionOnboarding() {
    context.pushNamed('subscription_onboarding');
  }

  Future<void> _changePlan(String planId) async {
    // TODO: Implement plan change logic
    // This would typically involve calling your backend to modify the subscription
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plan changes coming soon!'),
      ),
    );
  }

  Future<void> _cancelSubscription(UserSubscriptionInfo subscription) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Cancel Subscription?',
      content:
          'Your subscription will remain active until ${DateFormat('MMM dd, yyyy').format(subscription.currentPeriodEnd)}. You can reactivate anytime before then.',
      confirmText: 'Cancel Subscription',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final success =
          await _stripeService.cancelSubscription(subscription.subscriptionId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription canceled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSubscriptionData();
      } else {
        throw Exception('Failed to cancel subscription');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _reactivateSubscription(
      UserSubscriptionInfo subscription) async {
    // TODO: Implement reactivation logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reactivation coming soon!'),
      ),
    );
  }

  void _contactSupport() {
    // TODO: Implement support contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact coming soon!'),
      ),
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FFButtonWidget(
                onPressed: () => Navigator.of(context).pop(true),
                text: confirmText,
                options: FFButtonOptions(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  iconPadding: EdgeInsets.zero,
                  color: isDestructive
                      ? Colors.red
                      : FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                  elevation: 0,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
