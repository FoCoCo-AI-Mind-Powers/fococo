import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/revenuecat_service.dart';
import '/services/subscription_state_provider.dart';

/// Subscription Lock Widget
/// Shows a glass-style lock overlay with FoCoCo logo
/// Displays paywall when clicked if user is not subscribed
class SubscriptionLockWidget extends StatefulWidget {
  const SubscriptionLockWidget({
    super.key,
    this.message,
    this.showPaywallOnTap = true,
  });

  final String? message;
  final bool showPaywallOnTap;

  @override
  State<SubscriptionLockWidget> createState() => _SubscriptionLockWidgetState();
}

class _SubscriptionLockWidgetState extends State<SubscriptionLockWidget> {
  final RevenueCatService _revenueCatService = RevenueCatService();
  final SubscriptionStateProvider _subscriptionProvider =
      SubscriptionStateProvider();
  Offerings? _offerings;
  bool _shouldShowLock = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    _checkLockState();
    // Listen to subscription state changes
    _subscriptionProvider.addListener(_checkLockState);
  }
  
  @override
  void dispose() {
    _subscriptionProvider.removeListener(_checkLockState);
    super.dispose();
  }
  
  void _checkLockState() {
    final shouldShow = _subscriptionProvider.shouldShowLock();
    if (mounted && _shouldShowLock != shouldShow) {
      setState(() {
        _shouldShowLock = shouldShow;
      });
    }
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await _revenueCatService.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
        });
      }
    } catch (e) {
      debugPrint('Failed to load offerings: $e');
    }
  }

  Future<void> _showPaywall() async {
    if (_offerings?.current == null) {
      // Fallback: navigate to subscription onboarding
      if (mounted) {
        context.pushNamed('subscription_onboarding');
      }
      return;
    }

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Paywall View
              Expanded(
                child: PaywallView(
                  offering: _offerings!.current!,
                ),
              ),
            ],
          ),
        ),
      );

      // Check subscription status after paywall is dismissed
      await Future.delayed(const Duration(milliseconds: 500));
      await _subscriptionProvider.refreshSubscriptionState();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (!_shouldShowLock) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.showPaywallOnTap ? _showPaywall : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.glassBackground.withValues(alpha: 0.4),
                  theme.glassTint.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.glassBorder.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.glassShadow.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FoCoCo Logo Lock Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primary.withValues(alpha: 0.2),
                          theme.secondary.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // FoCoCo Logo (using text as placeholder - replace with actual logo asset)
                        Text(
                          'FoCoCo',
                          style: theme.titleLarge.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        // Lock overlay
                        Positioned(
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.error.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Lock Message
                  Text(
                    widget.message ?? 'Premium Feature',
                    style: theme.titleMedium.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLockMessage(),
                    style: theme.bodyMedium.copyWith(
                      color: theme.secondaryText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Unlock Button
                  if (widget.showPaywallOnTap)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primary, theme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showPaywall,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_open,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Unlock Premium',
                                  style: theme.titleSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
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
            ),
          ),
        ),
      ),
    );
  }

  String _getLockMessage() {
    if (!_subscriptionProvider.isWithinTrialPeriod()) {
      return 'Your 16-day trial has ended. Subscribe to continue accessing premium features.';
    }
    return 'Subscribe to unlock this premium feature and access all FoCoCo benefits.';
  }
}
