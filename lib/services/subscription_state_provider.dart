import 'package:flutter/material.dart';
import '/services/store_subscription_service.dart';

/// Subscription State Provider
/// Tracks subscription state throughout the app and notifies listeners of changes
class SubscriptionStateProvider extends ChangeNotifier {
  static final SubscriptionStateProvider _instance =
      SubscriptionStateProvider._internal();
  factory SubscriptionStateProvider() => _instance;
  SubscriptionStateProvider._internal();

  final StoreSubscriptionService _storeService = StoreSubscriptionService();

  StoreSubscriptionInfo? _currentSubscription;
  bool _isLoading = false;
  String _userTier = 'junior';
  bool _hasActiveSubscription = false;

  // Getters
  StoreSubscriptionInfo? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String get userTier => _userTier;
  bool get hasActiveSubscription => _hasActiveSubscription;
  bool get isPrime => _userTier == 'prime';
  bool get isPlus => _userTier == 'plus';
  bool get isBase => _userTier == 'base';
  bool get isJunior => _userTier == 'junior';

  /// Initialize and load subscription state
  Future<void> initialize() async {
    await refreshSubscriptionState();
  }

  /// Refresh subscription state from service
  Future<void> refreshSubscriptionState() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentSubscription = await _storeService.getCurrentSubscription();
      _hasActiveSubscription = await _storeService.hasActiveSubscription();
      _userTier = await _storeService.getUserTier();

      debugPrint('📊 Subscription State Updated:');
      debugPrint('   Tier: $_userTier');
      debugPrint('   Active: $_hasActiveSubscription');
      debugPrint('   Subscription: ${_currentSubscription?.membershipTier ?? "none"}');
    } catch (e) {
      debugPrint('❌ Error refreshing subscription state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if user can access a feature based on tier
  bool canAccessFeature({
    required String requiredTier,
  }) {
    final tierHierarchy = {'junior': 0, 'base': 1, 'plus': 2, 'prime': 3};
    final userLevel = tierHierarchy[_userTier] ?? 0;
    final requiredLevel = tierHierarchy[requiredTier] ?? 0;
    return userLevel >= requiredLevel;
  }

  /// Check if subscription is active (including grace period)
  bool isSubscriptionActive() {
    if (_currentSubscription == null) return false;
    return _currentSubscription!.isActive(
      gracePeriodDays: StoreSubscriptionService.gracePeriodDays,
    );
  }

  /// Get days remaining in subscription
  int getDaysRemaining() {
    if (_currentSubscription == null) return 0;
    return _currentSubscription!.getDaysRemaining(
      gracePeriodDays: StoreSubscriptionService.gracePeriodDays,
    );
  }

  /// Update subscription state after purchase
  void updateAfterPurchase() {
    refreshSubscriptionState();
  }

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}


