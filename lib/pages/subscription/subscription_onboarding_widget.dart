import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/data/store_subscription_plans.dart';
// import '/services/stripe_service.dart';
import 'subscription_onboarding_model.dart';
export 'subscription_onboarding_model.dart';

class SubscriptionOnboardingWidget extends StatefulWidget {
  const SubscriptionOnboardingWidget({
    super.key,
    this.skipToApp = false,
  });

  final bool skipToApp;

  static String routeName = 'subscription_onboarding';
  static String routePath = '/subscription_onboarding';

  @override
  State<SubscriptionOnboardingWidget> createState() =>
      _SubscriptionOnboardingWidgetState();
}

class _SubscriptionOnboardingWidgetState
    extends State<SubscriptionOnboardingWidget> with TickerProviderStateMixin {
  late SubscriptionOnboardingModel _model;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  // final StripeService _stripeService = StripeService();

  String? _selectedPlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubscriptionOnboardingModel());

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Skip button
                    if (widget.skipToApp)
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: () => _skipToApp(),
                          child: Text(
                            'Skip for now',
                            style: theme.bodyMedium.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Header
                    _buildHeader(theme),

                    const SizedBox(height: 40),

                    // Subscription plans
                    _buildSubscriptionPlans(theme),

                    const SizedBox(height: 40),

                    // Payment methods
                    if (_selectedPlan != null) _buildPaymentMethods(theme),

                    const SizedBox(height: 40),

                    // Terms and privacy
                    _buildTermsAndPrivacy(theme),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header section with branding and value proposition
  Widget _buildHeader(FlutterFlowTheme theme) {
    return Column(
      children: [
        // Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary,
                theme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            FontAwesomeIcons.brain,
            color: Colors.white,
            size: 60,
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          'Unlock Your Mental Game',
          textAlign: TextAlign.center,
          style: theme.headlineLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
            fontFamily: 'Montserrat',
          ),
        ),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          'Choose your plan and start improving your golf performance with AI-powered mental coaching',
          textAlign: TextAlign.center,
          style: theme.bodyLarge.copyWith(
            color: theme.secondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Subscription plans grid
  Widget _buildSubscriptionPlans(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: theme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 20),

        // Plans
        ...storeSubscriptionPlans.entries.map((entry) {
          final plan = entry.value;
          final isSelected = _selectedPlan == plan.id;
          final isPopular = plan.id == 'plus';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPlanCard(
              theme: theme,
              plan: plan,
              isSelected: isSelected,
              isPopular: isPopular,
              onTap: () => setState(() => _selectedPlan = plan.id),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Individual plan card
  Widget _buildPlanCard({
    required FlutterFlowTheme theme,
    required StoreSubscriptionPlan plan,
    required bool isSelected,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.1),
                    theme.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.primary
                : theme.secondaryText.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with popular badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.formattedPrice,
                      style: theme.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.primary,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
                if (isPopular)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'POPULAR',
                      style: theme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Features
            ...plan.features
                .map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: theme.performanceExcellent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
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
        ),
      ),
    );
  }

  /// Payment methods section
  Widget _buildPaymentMethods(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscribe with your store',
          style: theme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 20),

        if (Platform.isIOS)
          _buildPaymentMethodButton(
            theme: theme,
            title: 'App Store Subscription',
            subtitle: 'Secure purchase with Touch ID / Face ID',
            icon: FontAwesomeIcons.apple,
            onTap: () => _handleAppStoreSubscription(),
          ),

        // Google Pay (Android only)
        if (Platform.isAndroid)
          _buildPaymentMethodButton(
            theme: theme,
            title: 'Google Play Subscription',
            subtitle: 'Use your Google account for billing',
            icon: FontAwesomeIcons.google,
            onTap: () => _handleGooglePlaySubscription(),
          ),
        if (!Platform.isIOS && !Platform.isAndroid)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.secondaryText.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              'Native subscriptions are currently available only on iOS and Android builds.',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
              ),
            ),
          ),
      ],
    );
  }

  /// Payment method button
  Widget _buildPaymentMethodButton({
    required FlutterFlowTheme theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.secondaryText.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.primaryText,
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
            if (_isLoading)
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

  /// Terms and privacy section
  Widget _buildTermsAndPrivacy(FlutterFlowTheme theme) {
    return Text(
      'By subscribing, you agree to our Terms of Service and Privacy Policy. Cancel anytime.',
      textAlign: TextAlign.center,
      style: theme.bodySmall.copyWith(
        color: theme.secondaryText,
        height: 1.4,
      ),
    );
  }

  // Payment handlers

  Future<void> _handleAppStoreSubscription() async {
    if (!Platform.isIOS) {
      _showErrorDialog('App Store subscriptions are only available on iOS.');
      return;
    }

    if (_selectedPlan == null) {
      _showErrorDialog('Please select a plan to continue.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Integrate StoreKit purchase flow
      await Future<void>.delayed(const Duration(milliseconds: 800));
      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('App Store subscription failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGooglePlaySubscription() async {
    if (!Platform.isAndroid) {
      _showErrorDialog(
        'Google Play subscriptions are only available on Android.',
      );
      return;
    }

    if (_selectedPlan == null) {
      _showErrorDialog('Please select a plan to continue.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Integrate Google Play Billing flow
      await Future<void>.delayed(const Duration(milliseconds: 800));
      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('Google Play subscription failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Welcome to FoCoCo!'),
          ],
        ),
        content: const Text(
          'Your subscription is now active. Start improving your mental game today!',
        ),
        actions: [
          FFButtonWidget(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToApp();
            },
            text: 'Get Started',
            options: FFButtonOptions(
              width: double.infinity,
              height: 48,
              padding: EdgeInsets.zero,
              iconPadding: EdgeInsets.zero,
              color: FlutterFlowTheme.of(context).primary,
              textStyle: FlutterFlowTheme.of(context).titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
              elevation: 0,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _skipToApp() {
    _navigateToApp();
  }

  void _navigateToApp() {
    context.goNamed('dashboard');
  }
}
