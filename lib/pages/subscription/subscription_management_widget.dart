import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/revenuecat_service.dart';
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
    extends State<SubscriptionManagementWidget> {
  late SubscriptionManagementModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final RevenueCatService _revenueCatService = RevenueCatService();

  bool _isLoading = false;
  Offerings? _offerings;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubscriptionManagementModel());
    _loadOfferings();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final offerings = await _revenueCatService.getOfferings();
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });

      if (offerings.current == null) {
        setState(() {
          _errorMessage = 'No current offering found. Check RevenueCat dashboard configuration.';
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load offerings: $e');
      setState(() {
        _errorMessage = 'Failed to load subscription plans: $e';
        _isLoading = false;
      });
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
        body: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(theme),

              // Main Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _offerings?.current != null
                        ? _buildPaywallView(theme)
                        : _buildErrorState(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Simple App Bar with back button
  Widget _buildAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.primaryText,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Subscription',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Paywall View - Full Screen
  Widget _buildPaywallView(FlutterFlowTheme theme) {
    return PaywallView(
      offering: _offerings!.current!,
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

          // Error icon
          Icon(
            Icons.error_outline,
            color: theme.error,
            size: 64,
          ),

          const SizedBox(height: 24),

          // Error title
          Text(
            'Unable to Load Subscription Plans',
            style: theme.headlineSmall.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

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
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: theme.bodyMedium.copyWith(
                      color: theme.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                Text(
                  'Please check your RevenueCat dashboard configuration:\n\n'
                  '1. Products created (fococo_monthly_test, fococo_yearly_test)\n'
                  '2. Products added to an Offering\n'
                  '3. Offering set as "Current"\n'
                  '4. Products linked to App Store/Google Play',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Retry button
          FFButtonWidget(
            onPressed: _loadOfferings,
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
}
