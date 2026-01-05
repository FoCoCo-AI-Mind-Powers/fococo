import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/subscription_state_provider.dart';

/// RevenueCat Service for managing subscriptions
/// Handles subscription purchases, entitlements, and customer info
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;
  
  // RevenueCat API Keys
  // Note: RevenueCat SDK blocks test keys in release builds for security.
  // - Debug builds: Use test key (allows test purchases)
  // - Release builds: Must use platform-specific production keys
  static const String _testApiKey = 'test_YoethHbymgTmQuFGgiEjipuTQAS';
  static const String _appleApiKey = 'appl_AiEOIuToXpfzdJlKMIrYJGzNdGs';
  static const String _googleApiKey = 'goog_VRIyNIpAyuumxHnhLkClLEKbxuR';
  
  // Get the appropriate API key based on platform and build mode
  static String _getApiKey() {
    // In debug mode, always use test key (RevenueCat allows this)
    if (kDebugMode) {
      return _testApiKey;
    }
    
    // In release mode, RevenueCat requires platform-specific production keys
    // Using test keys in release will cause the SDK to show an error and close the app
    if (Platform.isIOS) {
      return _appleApiKey;
    } else if (Platform.isAndroid) {
      return _googleApiKey;
    }
    
    // Fallback to test key if platform not determined (shouldn't happen)
    return _testApiKey;
  }
  
  // Entitlement identifier
  static const String _entitlementId = 'FoCoCo Pro';
  
  // Product identifiers
  static const String _productIdMonthly = 'fococo_monthly';
  static const String _productIdYearly = 'fococo_yearly';
  static const String _productIdYear = 'fococo-year';
  static const String _productIdMonthlyAlt = 'fococo-monthly';
  
  /// Grace period in days (16 days)
  static const int gracePeriodDays = 16;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ RevenueCat already initialized');
      return;
    }

    try {
      // Get current user ID for RevenueCat user identification
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      // Configure RevenueCat with platform and build-mode appropriate API key
      final apiKey = _getApiKey();
      final isTestKey = apiKey.startsWith('test_');
      
      if (kDebugMode) {
        debugPrint('🔑 Using RevenueCat API Key: ${apiKey.substring(0, 15)}... (${Platform.isIOS ? 'iOS' : 'Android'} - Debug Mode)');
      } else {
        debugPrint('🔑 Using RevenueCat API Key: ${apiKey.substring(0, 15)}... (${Platform.isIOS ? 'iOS' : 'Android'} - Release Mode)');
        if (isTestKey) {
          debugPrint('⚠️ WARNING: Test key detected in release build. RevenueCat SDK will block this and close the app.');
        }
      }
      
      PurchasesConfiguration configuration;
      
      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(apiKey)
          ..appUserID = userId;
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(apiKey)
          ..appUserID = userId;
      } else {
        throw UnsupportedError('RevenueCat is only supported on iOS and Android');
      }

      await Purchases.configure(configuration);
      
      // Set user ID if available
      if (userId != null) {
        await Purchases.logIn(userId);
      }

      // Enable debug logs in development
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener(_handleCustomerInfoUpdate);

      // Get initial customer info
      await refreshCustomerInfo();

      _isInitialized = true;
      debugPrint('✅ RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize RevenueCat: $e');
      throw Exception('Failed to initialize RevenueCat: $e');
    }
  }

  /// Handle customer info updates
  void _handleCustomerInfoUpdate(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    debugPrint('🔄 Customer info updated');
    
    // Update subscription state provider
    SubscriptionStateProvider().updateAfterPurchase();
    
    // Sync with Firestore
    _syncSubscriptionToFirestore(customerInfo);
  }

  /// Refresh customer info from RevenueCat
  Future<CustomerInfo> refreshCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      debugPrint('✅ Customer info refreshed');
      
      // Sync with Firestore
      await _syncSubscriptionToFirestore(_customerInfo!);
      
      return _customerInfo!;
    } catch (e) {
      debugPrint('❌ Failed to refresh customer info: $e');
      rethrow;
    }
  }

  /// Get current customer info
  CustomerInfo? get customerInfo => _customerInfo;

  /// Check if user has active entitlement
  Future<bool> hasActiveEntitlement() async {
    try {
      final info = await refreshCustomerInfo();
      final entitlement = info.entitlements.active[_entitlementId];
      
      if (entitlement != null) {
        debugPrint('✅ User has active entitlement: ${entitlement.identifier}');
        return true;
      }
      
      debugPrint('❌ User does not have active entitlement');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking entitlement: $e');
      return false;
    }
  }

  /// Get available offerings (packages)
  /// 
  /// IMPORTANT: For this to work, you must configure in RevenueCat Dashboard:
  /// 1. Go to RevenueCat Dashboard > Products
  /// 2. Add your test products (fococo_monthly_test, fococo_yearly_test) 
  /// 3. Go to Offerings section
  /// 4. Create an Offering (or use default)
  /// 5. Add the products to the Offering
  /// 6. Set the Offering as "Current"
  /// 
  /// The product IDs in code don't need to match exactly - RevenueCat maps them
  /// through the dashboard configuration.
  Future<Offerings> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current == null) {
        debugPrint('⚠️ No current offering found');
        debugPrint('💡 RevenueCat Configuration Checklist:');
        debugPrint('   1. Products created in RevenueCat Dashboard (fococo_monthly_test, fococo_yearly_test)');
        debugPrint('   2. Products added to an Offering in RevenueCat Dashboard');
        debugPrint('   3. Offering set as "Current" in RevenueCat Dashboard');
        debugPrint('   4. Products configured in App Store Connect (iOS) or Google Play Console (Android)');
        debugPrint('   5. Products linked in RevenueCat Dashboard to store products');
      } else {
        debugPrint('✅ Found ${offerings.current!.availablePackages.length} packages in current offering');
        for (final package in offerings.current!.availablePackages) {
          debugPrint('   - Package: ${package.identifier}, Product: ${package.storeProduct.identifier}');
        }
      }
      
      return offerings;
    } catch (e) {
      debugPrint('❌ Failed to get offerings: $e');
      debugPrint('💡 This usually means:');
      debugPrint('   - Products not configured in RevenueCat Dashboard');
      debugPrint('   - No Offering created or set as Current');
      debugPrint('   - Products not linked to App Store/Google Play products');
      debugPrint('   - API key mismatch (test vs production)');
      rethrow;
    }
  }

  /// Purchase a package
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      debugPrint('🛒 Purchasing package: ${package.identifier}');
      
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      
      if (purchaseResult.customerInfo == null) {
        throw Exception('Purchase completed but customer info is null');
      }
      
      final customerInfo = purchaseResult.customerInfo!;
      
      debugPrint('✅ Purchase successful');
      
      // Update local customer info
      _customerInfo = customerInfo;
      
      // Sync with Firestore
      await _syncSubscriptionToFirestore(customerInfo);
      
      // Update subscription state provider
      SubscriptionStateProvider().updateAfterPurchase();
      
      return customerInfo;
    } on PurchasesError catch (e) {
      debugPrint('❌ Purchase error: ${e.message}');
      
      // Handle specific error codes
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        throw Exception('Purchase was cancelled');
      } else if (e.code == PurchasesErrorCode.purchaseNotAllowedError) {
        throw Exception('Purchase not allowed');
      } else if (e.code == PurchasesErrorCode.purchaseInvalidError) {
        throw Exception('Purchase invalid');
      } else {
        throw Exception('Purchase failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Purchase error: $e');
      rethrow;
    }
  }

  /// Restore purchases
  Future<CustomerInfo> restorePurchases() async {
    try {
      debugPrint('🔄 Restoring purchases...');
      
      final customerInfo = await Purchases.restorePurchases();
      
      debugPrint('✅ Purchases restored');
      
      // Update local customer info
      _customerInfo = customerInfo;
      
      // Sync with Firestore
      await _syncSubscriptionToFirestore(customerInfo);
      
      // Update subscription state provider
      SubscriptionStateProvider().updateAfterPurchase();
      
      return customerInfo;
    } catch (e) {
      debugPrint('❌ Failed to restore purchases: $e');
      rethrow;
    }
  }

  /// Get current subscription info
  Future<RevenueCatSubscriptionInfo?> getCurrentSubscription() async {
    try {
      final info = await refreshCustomerInfo();
      final entitlement = info.entitlements.active[_entitlementId];
      
      if (entitlement == null) {
        return null;
      }
      
      return RevenueCatSubscriptionInfo.fromEntitlementInfo(entitlement, info);
    } catch (e) {
      debugPrint('❌ Failed to get current subscription: $e');
      return null;
    }
  }

  /// Check if user has active subscription (including grace period)
  Future<bool> hasActiveSubscription() async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return false;
    
    return subscription.isActiveWithGracePeriod(gracePeriodDays: gracePeriodDays);
  }

  /// Get subscription tier for user
  Future<String> getUserTier() async {
    final hasEntitlement = await hasActiveEntitlement();
    
    if (hasEntitlement) {
      return 'prime';
    }
    
    // Fallback: check user document
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final tier = userData?['currentMembershipTier'] as String?;
          if (tier != null && tier.isNotEmpty && tier != 'junior') {
            return tier;
          }
        }
      } catch (e) {
        debugPrint('❌ Error getting user tier: $e');
      }
    }
    
    return 'junior';
  }

  /// Sync subscription to Firestore
  Future<void> _syncSubscriptionToFirestore(CustomerInfo customerInfo) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ User not authenticated');
        return;
      }

      final entitlement = customerInfo.entitlements.active[_entitlementId];
      
      if (entitlement == null) {
        debugPrint('ℹ️ No active entitlement to sync');
        return;
      }

      final productIdentifier = entitlement.productIdentifier;
      final isMonthly = productIdentifier.contains('monthly') || 
                       productIdentifier == _productIdMonthly ||
                       productIdentifier == _productIdMonthlyAlt;
      
      final platform = Platform.isIOS ? 'app_store' : 'google_play';
      
      // Get expiration date
      final expirationDate = (entitlement.expirationDate as DateTime?) ?? 
                             DateTime.now().add(const Duration(days: 30));
      final now = DateTime.now();
      
      // Calculate period start (assume 30 days for monthly, 365 for yearly)
      final periodStart = isMonthly 
          ? expirationDate.subtract(const Duration(days: 30))
          : expirationDate.subtract(const Duration(days: 365));
      
      // Get original transaction ID from latest transaction or customer ID
      final latestPurchase = entitlement.latestPurchaseDate;
      String originalTransactionId = customerInfo.originalAppUserId;
      
      if (latestPurchase != null) {
        try {
          // Try to cast to DateTime
          final purchaseDate = latestPurchase as DateTime;
          originalTransactionId = purchaseDate.millisecondsSinceEpoch.toString();
        } catch (e) {
          // If not DateTime, use string representation
          originalTransactionId = latestPurchase.toString();
        }
      }
      
      // Create subscription record
      final subscriptionData = {
        'userId': user.uid,
        'platform': platform,
        'productId': productIdentifier,
        'originalTransactionId': originalTransactionId,
        'purchaseToken': customerInfo.originalAppUserId,
        'status': entitlement.isActive ? 'active' : 'expired',
        'membershipTier': 'prime',
        'currentPeriodStart': Timestamp.fromDate(periodStart),
        'currentPeriodEnd': Timestamp.fromDate(expirationDate),
        'nextBillingDate': Timestamp.fromDate(expirationDate),
        'cancelAtPeriodEnd': entitlement.willRenew == false,
        'autoRenewing': entitlement.willRenew ?? true,
        'purchaseDate': Timestamp.fromDate(now),
        'priceAmountMicros': 0, // RevenueCat handles pricing
        'priceCurrencyCode': 'USD',
        'isTrialPeriod': entitlement.periodType == PeriodType.trial,
        'createdTime': Timestamp.now(),
        'updatedTime': Timestamp.now(),
        'lastValidated': Timestamp.now(),
        'revenueCatUserId': customerInfo.originalAppUserId,
      };

      // Check if subscription already exists
      final existingQuery = await FirebaseFirestore.instance
          .collection('user_subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('originalTransactionId', isEqualTo: originalTransactionId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing subscription
        await existingQuery.docs.first.reference.update(subscriptionData);
        debugPrint('✅ Subscription updated in Firestore');
      } else {
        // Add new subscription record
        await FirebaseFirestore.instance
            .collection('user_subscriptions')
            .add(subscriptionData);
        debugPrint('✅ Subscription added to Firestore');
      }

      // Update user record
      await FirebaseFirestore.instance.collection('user').doc(user.uid).update({
        'currentMembershipTier': 'prime',
        'subscriptionStatus': entitlement.isActive ? 'active' : 'expired',
        'subscriptionPlan': 'prime',
        'subscriptionBillingPeriod': isMonthly ? 'monthly' : 'yearly',
        'subscriptionProductId': productIdentifier,
        'subscriptionTransactionId': originalTransactionId,
        'subscriptionPlatform': platform,
        'updatedTime': Timestamp.now(),
        'revenueCatUserId': customerInfo.originalAppUserId,
      });

      debugPrint('✅ User record updated in Firestore');
    } catch (e) {
      debugPrint('❌ Error syncing subscription to Firestore: $e');
      // Don't throw - this is a background sync operation
    }
  }

  /// Identify user with RevenueCat
  Future<void> identifyUser(String userId) async {
    try {
      await Purchases.logIn(userId);
      debugPrint('✅ User identified: $userId');
      await refreshCustomerInfo();
    } catch (e) {
      debugPrint('❌ Failed to identify user: $e');
      rethrow;
    }
  }

  /// Log out user from RevenueCat
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      _customerInfo = null;
      debugPrint('✅ User logged out from RevenueCat');
    } catch (e) {
      debugPrint('❌ Failed to log out: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    _customerInfo = null;
  }
}

/// RevenueCat subscription info model
class RevenueCatSubscriptionInfo {
  final String productIdentifier;
  final String originalTransactionId;
  final DateTime expirationDate;
  final bool isActive;
  final bool willRenew;
  final PeriodType periodType;
  final String platform;

  RevenueCatSubscriptionInfo({
    required this.productIdentifier,
    required this.originalTransactionId,
    required this.expirationDate,
    required this.isActive,
    required this.willRenew,
    required this.periodType,
    required this.platform,
  });

  /// Check if subscription is active (including grace period)
  bool isActiveWithGracePeriod({int gracePeriodDays = 0}) {
    if (!isActive) return false;
    
    final now = DateTime.now();
    final gracePeriodEnd = expirationDate.add(Duration(days: gracePeriodDays));
    
    if (now.isBefore(expirationDate)) {
      return true;
    }
    
    if (gracePeriodDays > 0 && now.isBefore(gracePeriodEnd) && willRenew) {
      return true;
    }
    
    return false;
  }

  /// Get days remaining (including grace period)
  int getDaysRemaining({int gracePeriodDays = 0}) {
    final now = DateTime.now();
    final gracePeriodEnd = expirationDate.add(Duration(days: gracePeriodDays));
    
    if (now.isBefore(expirationDate)) {
      return expirationDate.difference(now).inDays;
    } else if (now.isBefore(gracePeriodEnd)) {
      return gracePeriodEnd.difference(now).inDays;
    }
    
    return 0;
  }

  /// Check if subscription is monthly
  bool get isMonthly {
    return productIdentifier.contains('monthly') || 
           productIdentifier == 'fococo_monthly' ||
           productIdentifier == 'fococo-monthly';
  }

  factory RevenueCatSubscriptionInfo.fromEntitlementInfo(
    EntitlementInfo entitlement,
    CustomerInfo customerInfo,
  ) {
    // Get original transaction ID from latest purchase date or customer ID
    final latestPurchase = entitlement.latestPurchaseDate;
    String originalTransactionId = customerInfo.originalAppUserId;
    
    if (latestPurchase != null) {
      try {
        // Try to cast to DateTime
        final purchaseDate = latestPurchase as DateTime;
        originalTransactionId = purchaseDate.millisecondsSinceEpoch.toString();
      } catch (e) {
        // If not DateTime, use string representation
        originalTransactionId = latestPurchase.toString();
      }
    }
    
    // Get expiration date
    final expirationDate = (entitlement.expirationDate as DateTime?) ?? 
                           DateTime.now().add(const Duration(days: 30));
    
    return RevenueCatSubscriptionInfo(
      productIdentifier: entitlement.productIdentifier,
      originalTransactionId: originalTransactionId,
      expirationDate: expirationDate,
      isActive: entitlement.isActive,
      willRenew: entitlement.willRenew ?? false,
      periodType: entitlement.periodType,
      platform: Platform.isIOS ? 'app_store' : 'google_play',
    );
  }
}
