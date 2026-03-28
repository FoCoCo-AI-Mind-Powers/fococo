import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/revenuecat_service.dart';
import '/services/auth_flow_service.dart';
import 'subscription_onboarding_model.dart';
export 'subscription_onboarding_model.dart';

class SubscriptionOnboardingWidget extends StatefulWidget {
  const SubscriptionOnboardingWidget({
    super.key,
    this.isMandatory = false,
  });

  final bool isMandatory;

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
  final RevenueCatService _revenueCatService = RevenueCatService();

  bool _isLoading = false;
  Offering? _selectedOffering;

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

    // Load RevenueCat offerings
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    try {
      final offerings = await _revenueCatService.getOfferings();
      final selectedOffering =
          _revenueCatService.getPreferredOffering(offerings);
      setState(() {
        _selectedOffering = selectedOffering;
        _isLoading = false;
      });

      if (selectedOffering == null) {
        debugPrint(
            '⚠️ No default/current offering found. Check RevenueCat dashboard configuration.');
        debugPrint('   Make sure you have:');
        debugPrint(
            '   1. Created an offering with lookup key "default" or marked one as Current');
        debugPrint('   2. Added the yearly products to the offering package');
        debugPrint(
            '   3. Linked those RevenueCat products to App Store / Play store products');
      }
    } catch (e) {
      debugPrint('❌ Failed to load offerings: $e');
      setState(() {
        _isLoading = false;
      });
    }
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

    return PopScope(
      canPop: !widget.isMandatory,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.isMandatory) {
          _showMandatoryMessage();
        }
      },
      child: GestureDetector(
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedOffering != null
                        ? _buildPaywallDirect(theme)
                        : _buildErrorState(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build paywall directly - main view
  Widget _buildPaywallDirect(FlutterFlowTheme theme) {
    return Column(
      children: [
        Expanded(
          child: PaywallView(
            offering: _selectedOffering!,
            displayCloseButton: !widget.isMandatory,
            onPurchaseCompleted: (customerInfo, storeTransaction) async {
              await _handlePaywallUnlock();
            },
            onRestoreCompleted: (customerInfo) async {
              await _handlePaywallUnlock();
            },
            onPurchaseError: (error) {
              _showSnack('Purchase failed: ${error.message}');
            },
            onRestoreError: (error) {
              _showSnack('Restore failed: ${error.message}');
            },
            onDismiss: () {
              if (widget.isMandatory) {
                _showMandatoryMessage();
              }
            },
          ),
        ),
      ],
    );
  }

  /// Error state when offerings are not available
  Widget _buildErrorState(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),

          // Header
          _buildHeader(theme),

          const SizedBox(height: 40),

          // Error message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to Load Subscription Plans',
                  style: theme.titleMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your RevenueCat dashboard configuration:\n\n'
                  '1. Offering lookup key "default" exists, or one offering is current\n'
                  '2. The annual package is attached to your yearly products\n'
                  '3. RevenueCat products are linked to App Store / Google Play products\n'
                  '4. The products are approved and available in the store',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Retry button
          FFButtonWidget(
            onPressed: () {
              _loadOfferings();
            },
            text: 'Retry',
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
          child: Icon(
            Icons.psychology,
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

  Future<void> _handlePaywallUnlock() async {
    setState(() => _isLoading = true);
    try {
      await _revenueCatService.refreshCustomerInfo();
      await AuthFlowService.instance.markMandatoryPaywallCompleted();
      if (!mounted) return;
      context.goNamed('mind_coach');
    } catch (e) {
      _showSnack('Unable to finalize subscription access: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMandatoryMessage() {
    _showSnack('Complete trial or purchase to continue.');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
