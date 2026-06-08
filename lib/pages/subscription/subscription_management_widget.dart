import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/fococo_tab/fococo_tab_widget.dart';
import '/services/revenuecat_service.dart';
import '/services/subscription_state_provider.dart';
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

  bool _isLoading = true;
  bool _hasProAccess = false;
  Offerings? _offerings;
  String? _errorMessage;
  String? _priceString;
  String? _trialStatusLabel;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubscriptionManagementModel());
    _load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasAccess = await _revenueCatService.hasProAccess();
      _hasProAccess = hasAccess;

      if (!hasAccess) {
        final offerings = await _revenueCatService.getOfferings();
        _offerings = offerings;
        final yearly = offerings.current?.annual?.storeProduct;
        _priceString = _revenueCatService.annualPricingSubtitle(yearly);
        _trialStatusLabel = _buildTrialLabel();
        if (offerings.current == null) {
          _errorMessage =
              'Subscription plans are temporarily unavailable. Please try again.';
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load subscription information.';
        _isLoading = false;
      });
    }
  }

  String? _buildTrialLabel() {
    final sub = SubscriptionStateProvider();
    if (!sub.isWithinTrialPeriod() || sub.hasActiveSubscription) {
      return null;
    }
    final remaining = sub.getTrialDaysRemaining();
    final total = SubscriptionStateProvider.trialPeriodDays;
    if (remaining <= 0) return 'Trial ends today';
    if (remaining == 1) return 'Trial ends tomorrow';
    if (remaining <= 7) return '$remaining days left in your trial';
    return 'Day ${total - remaining} of $total — 14-day free trial';
  }

  Future<void> _openNativeManageSubscriptions() async {
    await _revenueCatService.openManageSubscriptions();
  }

  void _exitSubscription() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(FoCoCoTabWidget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitSubscription();
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
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(theme),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hasProAccess
                          ? _buildPrimeStatus(theme)
                          : _offerings?.current != null
                              ? _buildPaywallView(theme)
                              : _buildErrorState(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.primaryText,
              size: 20,
            ),
            onPressed: _exitSubscription,
          ),
          const SizedBox(width: 16),
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

  Widget _buildPrimeStatus(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            "You're on FoCoCo Prime",
            style: theme.headlineSmall.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your membership is active. Manage billing, renewal, or cancellation in your app store account.',
            style: theme.bodyMedium.copyWith(color: theme.secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FFButtonWidget(
            onPressed: _openNativeManageSubscriptions,
            text: 'Manage Subscription',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              color: theme.primary,
              textStyle: theme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallView(FlutterFlowTheme theme) {
    return Column(
      children: [
        if (_trialStatusLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              _trialStatusLabel!,
              style: theme.bodyMedium.copyWith(color: theme.secondaryText),
              textAlign: TextAlign.center,
            ),
          ),
        if (_priceString != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              _priceString!,
              style: theme.titleMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text(
            _revenueCatService.trialButtonLabel(),
            style: theme.bodyMedium.copyWith(color: theme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: PaywallView(
            offering: _offerings!.current!,
            onRestoreCompleted: (_) => _load(),
            onRestoreError: (_) {},
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.error_outline, color: theme.error, size: 64),
          const SizedBox(height: 24),
          Text(
            'Unable to Load Subscription Plans',
            style: theme.headlineSmall.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          FFButtonWidget(
            onPressed: _load,
            text: 'Retry',
            options: FFButtonOptions(
              width: double.infinity,
              height: 56,
              color: theme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
