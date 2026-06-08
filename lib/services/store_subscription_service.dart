import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '/backend/backend.dart';
import '/services/subscription_state_provider.dart';

/// Store Subscription Service for Apple App Store and Google Play Store
/// Handles in-app purchases, subscription management, and grace period logic
class StoreSubscriptionService {
  static final StoreSubscriptionService _instance =
      StoreSubscriptionService._internal();
  factory StoreSubscriptionService() => _instance;
  StoreSubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isInitialized = false;

  /// Product IDs for Prime membership
  static const String productIdMonthly = 'fococo_monthly';
  static const String productIdYearly = 'fococo_yearly';

  /// Grace period in days (16 days)
  static const int gracePeriodDays = 16;

  /// Initialize the service and listen to purchase updates
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Listen to purchase updates
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () {
          _purchaseSubscription?.cancel();
        },
        onError: (error) {
          debugPrint('❌ Purchase stream error: $error');
        },
      );

      _isInitialized = true;
      debugPrint('✅ Store Subscription Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Store Subscription Service: $e');
      throw Exception('Failed to initialize Store Subscription Service: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _purchaseSubscription?.cancel();
    _isInitialized = false;
  }

  /// Get product ID based on billing period
  String getProductId({required bool isMonthly}) {
    return isMonthly ? productIdMonthly : productIdYearly;
  }

  /// Query available products from the store
  Future<ProductDetailsResponse> queryProducts({
    required bool isMonthly,
  }) async {
    final productId = getProductId(isMonthly: isMonthly);
    final Set<String> productIds = {productId};

    debugPrint('🔍 Querying product: $productId');
    final response = await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      debugPrint('❌ Product query error: ${response.error!.message}');
    } else if (response.productDetails.isEmpty) {
      debugPrint('❌ Product not found: $productId');
      debugPrint('💡 Make sure products are configured in:');
      debugPrint('   - App Store Connect (iOS): $productId');
      debugPrint('   - Google Play Console (Android): $productId');
    } else {
      final product = response.productDetails.first;
      debugPrint('✅ Product found: ${product.id} - ${product.title}');
    }

    return response;
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription({
    required bool isMonthly,
    Function(PurchaseDetails)? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      // Check if in-app purchases are available
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        final error = Platform.isIOS
            ? 'App Store is not available. Please check your connection.'
            : 'Google Play Store is not available. Please check your connection.';
        onError?.call(error);
        return false;
      }

      // Query products
      final response = await queryProducts(isMonthly: isMonthly);

      if (response.error != null) {
        final error = 'Error querying products: ${response.error!.message}';
        onError?.call(error);
        return false;
      }

      if (response.productDetails.isEmpty) {
        final error = 'Product not found. Please check your product IDs:\n'
            '- Monthly: $productIdMonthly\n'
            '- Yearly: $productIdYearly';
        onError?.call(error);
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;

      // Purchase the subscription
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      debugPrint('🛒 Initiating purchase for: ${productDetails.id}');
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        onError?.call('Failed to initiate purchase. Please try again.');
        return false;
      }

      // Store callbacks for handling purchase updates
      _onPurchaseSuccess = onSuccess;
      _onPurchaseError = onError;

      return true;
    } catch (e) {
      debugPrint('❌ Purchase error: $e');
      onError?.call('Purchase failed: $e');
      return false;
    }
  }

  // Callbacks for purchase handling
  Function(PurchaseDetails)? _onPurchaseSuccess;
  Function(String)? _onPurchaseError;

  /// Handle purchase updates from the store
  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint(
          '📦 Purchase update: ${purchaseDetails.status} - ${purchaseDetails.productID}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('⏳ Purchase pending...');
        // Handle pending state if needed
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint('✅ Purchase successful: ${purchaseDetails.productID}');

        // Update subscription in Firestore
        await _updateUserSubscription(purchaseDetails);

        // Notify subscription state provider
        SubscriptionStateProvider().updateAfterPurchase();

        // Call success callback
        _onPurchaseSuccess?.call(purchaseDetails);

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        final error = purchaseDetails.error?.message ?? 'Unknown error';
        debugPrint('❌ Purchase error: $error');
        _onPurchaseError?.call('Purchase failed: $error');
      }

      // Complete purchase if needed
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Update user subscription in Firestore
  Future<void> _updateUserSubscription(PurchaseDetails purchaseDetails) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ User not authenticated');
        return;
      }

      final isMonthly = purchaseDetails.productID == productIdMonthly;
      final platform = Platform.isIOS ? 'app_store' : 'google_play';

      // Calculate subscription period
      final now = DateTime.now();
      final periodEnd = isMonthly
          ? now.add(const Duration(days: 30))
          : now.add(const Duration(days: 365));

      // Create subscription record
      final subscriptionData = {
        'userId': user.uid,
        'platform': platform,
        'productId': purchaseDetails.productID,
        'originalTransactionId': purchaseDetails.purchaseID ?? '',
        'purchaseToken':
            purchaseDetails.verificationData.serverVerificationData,
        'status': 'active',
        'membershipTier': 'prime',
        'currentPeriodStart': Timestamp.fromDate(now),
        'currentPeriodEnd': Timestamp.fromDate(periodEnd),
        'nextBillingDate': Timestamp.fromDate(periodEnd),
        'cancelAtPeriodEnd': false,
        'autoRenewing': true,
        'purchaseDate': Timestamp.fromDate(now),
        'priceAmountMicros':
            0, // Will be updated from product details if available
        'priceCurrencyCode': 'USD',
        'isTrialPeriod': false,
        'createdTime': Timestamp.now(),
        'updatedTime': Timestamp.now(),
        'lastValidated': Timestamp.now(),
      };

      // Add subscription record
      await FirebaseFirestore.instance
          .collection('user_subscriptions')
          .add(subscriptionData);

      // Update user record
      await FirebaseFirestore.instance.collection('user').doc(user.uid).update({
        'currentMembershipTier': 'prime',
        'subscriptionStatus': 'active',
        'subscriptionPlan': 'prime',
        'subscriptionBillingPeriod': isMonthly ? 'monthly' : 'yearly',
        'subscriptionProductId': purchaseDetails.productID,
        'subscriptionTransactionId': purchaseDetails.purchaseID ?? '',
        'subscriptionPlatform': platform,
        'updatedTime': Timestamp.now(),
      });

      debugPrint('✅ Subscription updated in Firestore');
    } catch (e) {
      debugPrint('❌ Error updating subscription: $e');
      rethrow;
    }
  }

  /// Get current user subscription
  Future<StoreSubscriptionInfo?> getCurrentSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final platform = Platform.isIOS ? 'app_store' : 'google_play';

      // Query without orderBy avoids extra index coupling; pick latest in memory.
      final subscriptionQuery = await FirebaseFirestore.instance
          .collection('user_subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('platform', isEqualTo: platform)
          .get();

      if (subscriptionQuery.docs.isEmpty) return null;

      QueryDocumentSnapshot<Map<String, dynamic>>? bestDoc;
      var bestEnd = DateTime.fromMillisecondsSinceEpoch(0);
      for (final doc in subscriptionQuery.docs) {
        final data = doc.data();
        final end = (data['currentPeriodEnd'] as Timestamp?)?.toDate();
        if (end != null && end.isAfter(bestEnd)) {
          bestEnd = end;
          bestDoc = doc;
        }
      }
      final chosen = bestDoc ?? subscriptionQuery.docs.first;
      return StoreSubscriptionInfo.fromMap(chosen.data());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (kDebugMode) {
          debugPrint(
            '⚠️ user_subscriptions read denied — deploy firestore.rules + indexes, or check auth.',
          );
        }
        return null;
      }
      debugPrint('❌ Failed to get current subscription: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get current subscription: $e');
      return null;
    }
  }

  /// Check if user has active subscription (including grace period)
  Future<bool> hasActiveSubscription() async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return false;

    return subscription.isActive(gracePeriodDays: gracePeriodDays);
  }

  /// Get subscription tier for user
  Future<String> getUserTier() async {
    final subscription = await getCurrentSubscription();
    if (subscription != null &&
        subscription.isActive(gracePeriodDays: gracePeriodDays)) {
      return subscription.membershipTier;
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
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          if (kDebugMode) {
            debugPrint(
              '⚠️ user/{uid} read denied for tier — check Firestore rules (match /user/{{uid}}).',
            );
          }
        } else {
          debugPrint('❌ Error reading user tier from Firestore: $e');
        }
      }
    }

    return 'junior';
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('❌ Store not available for restore');
        return false;
      }

      await _inAppPurchase.restorePurchases();
      debugPrint('✅ Purchases restored');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to restore purchases: $e');
      return false;
    }
  }
}

/// Store subscription info model
class StoreSubscriptionInfo {
  final String subscriptionId;
  final String platform;
  final String membershipTier;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final bool autoRenewing;
  final String status;

  StoreSubscriptionInfo({
    required this.subscriptionId,
    required this.platform,
    required this.membershipTier,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.autoRenewing,
    required this.status,
  });

  /// Check if subscription is active (including grace period)
  bool isActive({int gracePeriodDays = 0}) {
    final now = DateTime.now();

    // Check if status is active
    if (status != 'active' && status != 'trialing') {
      return false;
    }

    // Check if within period or grace period
    final gracePeriodEnd =
        currentPeriodEnd.add(Duration(days: gracePeriodDays));
    final isWithinPeriod = now.isBefore(currentPeriodEnd);
    final isWithinGracePeriod = now.isBefore(gracePeriodEnd);

    // Active if within period, or within grace period if not cancelled
    if (isWithinPeriod) {
      return !cancelAtPeriodEnd || now.isBefore(currentPeriodEnd);
    }

    // Check grace period
    if (gracePeriodDays > 0 && isWithinGracePeriod && !cancelAtPeriodEnd) {
      return true;
    }

    return false;
  }

  /// Get days remaining (including grace period)
  int getDaysRemaining({int gracePeriodDays = 0}) {
    final now = DateTime.now();
    final gracePeriodEnd =
        currentPeriodEnd.add(Duration(days: gracePeriodDays));

    if (now.isBefore(currentPeriodEnd)) {
      return currentPeriodEnd.difference(now).inDays;
    } else if (now.isBefore(gracePeriodEnd)) {
      return gracePeriodEnd.difference(now).inDays;
    }

    return 0;
  }

  factory StoreSubscriptionInfo.fromMap(Map<String, dynamic> map) {
    // Handle Timestamp conversion
    DateTime currentPeriodStart;
    DateTime currentPeriodEnd;

    try {
      if (map['currentPeriodStart'] is Timestamp) {
        currentPeriodStart = (map['currentPeriodStart'] as Timestamp).toDate();
      } else if (map['currentPeriodStart'] is DateTime) {
        currentPeriodStart = map['currentPeriodStart'] as DateTime;
      } else {
        currentPeriodStart = DateTime.now();
      }

      if (map['currentPeriodEnd'] is Timestamp) {
        currentPeriodEnd = (map['currentPeriodEnd'] as Timestamp).toDate();
      } else if (map['currentPeriodEnd'] is DateTime) {
        currentPeriodEnd = map['currentPeriodEnd'] as DateTime;
      } else {
        currentPeriodEnd = DateTime.now().add(const Duration(days: 30));
      }
    } catch (e) {
      debugPrint('❌ Error parsing subscription dates: $e');
      currentPeriodStart = DateTime.now();
      currentPeriodEnd = DateTime.now().add(const Duration(days: 30));
    }

    return StoreSubscriptionInfo(
      subscriptionId: map['originalTransactionId'] as String? ??
          map['purchaseToken'] as String? ??
          map['subscriptionId'] as String? ??
          '',
      platform: map['platform'] as String? ?? 'app_store',
      membershipTier: map['membershipTier'] as String? ?? 'junior',
      currentPeriodStart: currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd,
      cancelAtPeriodEnd: map['cancelAtPeriodEnd'] as bool? ?? false,
      autoRenewing: map['autoRenewing'] as bool? ?? true,
      status: map['status'] as String? ?? 'inactive',
    );
  }
}
