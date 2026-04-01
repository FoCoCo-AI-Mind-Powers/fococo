import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/store_subscription_service.dart';
import '/services/revenuecat_service.dart';

/// Subscription State Provider
/// Tracks subscription state throughout the app and notifies listeners of changes
/// Uses RevenueCat as primary source, falls back to StoreSubscriptionService
class SubscriptionStateProvider extends ChangeNotifier {
  static final SubscriptionStateProvider _instance =
      SubscriptionStateProvider._internal();
  factory SubscriptionStateProvider() => _instance;
  SubscriptionStateProvider._internal();

  final RevenueCatService _revenueCatService = RevenueCatService();
  final StoreSubscriptionService _storeService = StoreSubscriptionService();

  StoreSubscriptionInfo? _currentSubscription;
  bool _isLoading = false;
  String _userTier = 'junior';
  bool _hasActiveSubscription = false;
  DateTime? _userCreatedTime;
  
  // Trial period constants
  static const int trialPeriodDays = 16;

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

  bool _refreshInProgress = false;

  /// Refresh subscription state from service
  /// Prioritizes RevenueCat, falls back to StoreSubscriptionService
  Future<void> refreshSubscriptionState() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    _isLoading = true;
    notifyListeners();

    try {
      // Load user creation time for trial period check
      await _loadUserCreatedTime();
      
      // Try RevenueCat first (primary)
      try {
        _hasActiveSubscription = await _revenueCatService.hasActiveEntitlement();
        _userTier = await _revenueCatService.getUserTier();
        
        final revenueCatSub = await _revenueCatService.getCurrentSubscription();
        if (revenueCatSub != null) {
          // Convert RevenueCat subscription to StoreSubscriptionInfo format
          _currentSubscription = _convertRevenueCatToStoreInfo(revenueCatSub);
        } else {
          // Fallback to StoreSubscriptionService
          _currentSubscription = await _storeService.getCurrentSubscription();
          if (!_hasActiveSubscription) {
            _hasActiveSubscription = await _storeService.hasActiveSubscription();
          }
          if (_userTier == 'junior') {
            _userTier = await _storeService.getUserTier();
          }
        }
      } catch (e) {
        debugPrint('⚠️ RevenueCat check failed, using fallback: $e');
        // Fallback to StoreSubscriptionService
        _currentSubscription = await _storeService.getCurrentSubscription();
        _hasActiveSubscription = await _storeService.hasActiveSubscription();
        _userTier = await _storeService.getUserTier();
      }

      debugPrint('📊 Subscription State Updated:');
      debugPrint('   Tier: $_userTier');
      debugPrint('   Active: $_hasActiveSubscription');
      debugPrint('   Subscription: ${_currentSubscription?.membershipTier ?? "none"}');
      debugPrint('   Trial Active: ${isWithinTrialPeriod()}');
      debugPrint('   Trial Days Remaining: ${getTrialDaysRemaining()}');
    } catch (e) {
      debugPrint('❌ Error refreshing subscription state: $e');
    } finally {
      _isLoading = false;
      _refreshInProgress = false;
      notifyListeners();
    }
  }
  
  /// Load user creation time from Firestore
  Future<void> _loadUserCreatedTime() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['createdTime'] != null) {
          final timestamp = data['createdTime'] as Timestamp;
          _userCreatedTime = timestamp.toDate();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user created time: $e');
    }
  }
  
  /// Check if user is within trial period (16 days)
  bool isWithinTrialPeriod() {
    if (_userCreatedTime == null) return false;
    
    final now = DateTime.now();
    final trialEndDate = _userCreatedTime!.add(Duration(days: trialPeriodDays));
    
    return now.isBefore(trialEndDate);
  }
  
  /// Get days remaining in trial period
  int getTrialDaysRemaining() {
    if (_userCreatedTime == null) return 0;
    
    final now = DateTime.now();
    final trialEndDate = _userCreatedTime!.add(Duration(days: trialPeriodDays));
    
    if (now.isAfter(trialEndDate)) return 0;
    
    return trialEndDate.difference(now).inDays;
  }
  
  /// Check if user should see locked state (trial expired and no subscription)
  bool shouldShowLock() {
    // If has active subscription, never show lock
    if (_hasActiveSubscription || isSubscriptionActive()) {
      return false;
    }
    
    // Show lock if trial period has expired
    return !isWithinTrialPeriod();
  }
  
  /// Convert RevenueCat subscription to StoreSubscriptionInfo format
  StoreSubscriptionInfo _convertRevenueCatToStoreInfo(
    RevenueCatSubscriptionInfo revenueCatSub,
  ) {
    // Calculate period start based on expiration and billing period
    final periodStart = revenueCatSub.isMonthly
        ? revenueCatSub.expirationDate.subtract(const Duration(days: 30))
        : revenueCatSub.expirationDate.subtract(const Duration(days: 365));
    
    return StoreSubscriptionInfo(
      subscriptionId: revenueCatSub.originalTransactionId,
      platform: revenueCatSub.platform,
      membershipTier: 'prime',
      currentPeriodStart: periodStart,
      currentPeriodEnd: revenueCatSub.expirationDate,
      cancelAtPeriodEnd: !revenueCatSub.willRenew,
      autoRenewing: revenueCatSub.willRenew,
      status: revenueCatSub.isActive ? 'active' : 'expired',
    );
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
      gracePeriodDays: RevenueCatService.gracePeriodDays,
    );
  }

  /// Get days remaining in subscription
  int getDaysRemaining() {
    if (_currentSubscription == null) return 0;
    return _currentSubscription!.getDaysRemaining(
      gracePeriodDays: RevenueCatService.gracePeriodDays,
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


