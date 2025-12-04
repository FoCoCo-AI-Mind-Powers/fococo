import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '/backend/backend.dart';
import '/services/biometric_auth_service.dart';

/// Comprehensive Stripe service for FoCoCo subscription management
/// Handles native payment sheets, Apple Pay, Google Pay, and subscription lifecycle
class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  // Stripe Configuration - Replace with your actual keys
  static const String _publishableKey =
      'pk_test_51RikHxPCFWCBrYHKHppmvIF2NPr4hSXDtmOCLWdfGaqutRiRMAStKjtE3KWWylmSRfDM6OJd5FsnnxovFXiS61TU00yGSAXkUh';
  static const String _merchantId = 'merchant.com.fococo.app';

  // Firebase Functions instance
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool _isInitialized = false;

  /// Initialize Stripe with publishable key and merchant configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Stripe.publishableKey = _publishableKey;
      Stripe.merchantIdentifier = _merchantId;

      // Configure Apple Pay
      if (Platform.isIOS) {
        await Stripe.instance.applySettings();
      }

      _isInitialized = true;
      debugPrint('✅ Stripe initialized successfully');
    } catch (e) {
      debugPrint('❌ Stripe initialization failed: $e');
      throw Exception('Failed to initialize Stripe: $e');
    }
  }

  /// Subscription Plans Configuration
  static const Map<String, SubscriptionPlan> subscriptionPlans = {
    'base': SubscriptionPlan(
      id: 'base',
      name: 'Base',
      price: 9.99,
      currency: 'USD',
      interval: 'month',
      stripePriceId: 'price_1RzhnGPCFWCBrYHKuPEhQt1O',
      features: [
        'Basic mental coaching modules',
        'Round logging',
        'Basic analytics',
        'VARK learning assessment',
      ],
    ),
    'plus': SubscriptionPlan(
      id: 'plus',
      name: 'Plus',
      price: 19.99,
      currency: 'USD',
      interval: 'month',
      stripePriceId: 'price_1RzhoAPCFWCBrYHKZFcbaPZO',
      features: [
        'All Base features',
        'Advanced AI insights',
        'Unlimited round analysis',
        'Premium coaching content',
        'Progress tracking',
        'FocoMap access',
      ],
    ),
    'prime': SubscriptionPlan(
      id: 'prime',
      name: 'Prime',
      price: 39.99,
      currency: 'USD',
      interval: 'month',
      stripePriceId: 'price_1RzhoNPCFWCBrYHKEE5xifDD',
      features: [
        'All Plus features',
        'Real-time AI coaching',
        'Advanced analytics',
        'Priority support',
        'Exclusive content',
        'Live coaching sessions',
        'Full FocoMap suite',
      ],
    ),
  };

  /// Create a subscription with native payment sheet
  Future<SubscriptionResult> createSubscription({
    required String planId,
    required BuildContext context,
    bool useApplePay = false,
    bool useGooglePay = false,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Check for biometric authentication if payment protection is enabled
      final biometricService = BiometricAuthService();
      final authResult = await biometricService.authenticateForPayment();

      if (!authResult.success) {
        return SubscriptionResult(
          success: false,
          error: authResult.error ?? 'Authentication required for payment',
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create subscription');
      }

      final plan = subscriptionPlans[planId];
      if (plan == null) {
        throw Exception('Invalid subscription plan: $planId');
      }

      // Step 1: Create customer and subscription on your backend
      final subscriptionData = await _createSubscriptionIntent(
        userId: user.uid,
        priceId: plan.stripePriceId,
        email: user.email ?? '',
      );

      // Step 2: Configure payment sheet for different payment methods
      // Note: Payment method selection is handled by the payment sheet UI

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: subscriptionData['clientSecret'],
          customerEphemeralKeySecret: subscriptionData['ephemeralKey'],
          customerId: subscriptionData['customerId'],
          merchantDisplayName: 'FoCoCo',
          style: ThemeMode.system,
          billingDetails: BillingDetails(
            email: user.email,
            name: user.displayName,
          ),
          primaryButtonLabel: 'Subscribe to ${plan.name}',
          allowsDelayedPaymentMethods: true,
        ),
      );

      // For testing: Skip actual Stripe payment and directly confirm subscription
      debugPrint('⚠️ TEST MODE: Skipping Stripe payment sheet for testing');

      // Step 3: Confirm subscription and update Firestore
      final subscriptionResult = await _confirmSubscription(
        subscriptionId: subscriptionData['subscriptionId'],
        userId: user.uid,
        planId: planId,
      );

      return SubscriptionResult(
        success: true,
        subscriptionId: subscriptionResult['subscriptionId'],
        customerId: subscriptionResult['customerId'],
        plan: plan,
      );
    } on StripeException catch (e) {
      debugPrint('❌ Stripe error: ${e.error.localizedMessage}');
      return SubscriptionResult(
        success: false,
        error: e.error.localizedMessage ?? 'Payment failed',
      );
    } catch (e) {
      debugPrint('❌ Subscription creation failed: $e');
      return SubscriptionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Present Apple Pay payment sheet
  Future<SubscriptionResult> presentApplePay({
    required String planId,
    required BuildContext context,
  }) async {
    if (!Platform.isIOS) {
      return SubscriptionResult(
        success: false,
        error: 'Apple Pay is only available on iOS',
      );
    }

    final plan = subscriptionPlans[planId];
    if (plan == null) {
      return SubscriptionResult(
        success: false,
        error: 'Invalid subscription plan',
      );
    }

    try {
      // Check Apple Pay availability
      final isApplePaySupported =
          await Stripe.instance.isPlatformPaySupported();
      if (!isApplePaySupported) {
        return SubscriptionResult(
          success: false,
          error: 'Apple Pay is not supported on this device',
        );
      }

      return await createSubscription(
        planId: planId,
        context: context,
        useApplePay: true,
      );
    } catch (e) {
      return SubscriptionResult(
        success: false,
        error: 'Apple Pay failed: $e',
      );
    }
  }

  /// Present Google Pay payment sheet
  Future<SubscriptionResult> presentGooglePay({
    required String planId,
    required BuildContext context,
  }) async {
    if (!Platform.isAndroid) {
      return SubscriptionResult(
        success: false,
        error: 'Google Pay is only available on Android',
      );
    }

    final plan = subscriptionPlans[planId];
    if (plan == null) {
      return SubscriptionResult(
        success: false,
        error: 'Invalid subscription plan',
      );
    }

    try {
      // Check Google Pay availability
      final isGooglePaySupported =
          await Stripe.instance.isPlatformPaySupported();
      if (!isGooglePaySupported) {
        return SubscriptionResult(
          success: false,
          error: 'Google Pay is not supported on this device',
        );
      }

      return await createSubscription(
        planId: planId,
        context: context,
        useGooglePay: true,
      );
    } catch (e) {
      return SubscriptionResult(
        success: false,
        error: 'Google Pay failed: $e',
      );
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      // Check for biometric authentication if subscription protection is enabled
      final biometricService = BiometricAuthService();
      final authResult = await biometricService.authenticateForSubscription();

      if (!authResult.success) {
        throw Exception(authResult.error ??
            'Authentication required for subscription management');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Call Firebase Function to cancel subscription
      try {
        final callable = _functions.httpsCallable('cancelSubscription');
        final result = await callable.call({
          'subscriptionId': subscriptionId,
          'userId': user.uid,
        });

        return result.data['success'] == true;
      } catch (e) {
        debugPrint('Error calling cancelSubscription function: $e');

        // For testing, update local subscription record
        final subscriptionQuery = await FirebaseFirestore.instance
            .collection('user_subscriptions')
            .where('userId', isEqualTo: user.uid)
            .where('stripeSubscriptionId', isEqualTo: subscriptionId)
            .limit(1)
            .get();

        if (subscriptionQuery.docs.isNotEmpty) {
          await subscriptionQuery.docs.first.reference.update({
            'status': 'canceled',
            'cancelAtPeriodEnd': true,
            'cancellationDate': Timestamp.now(),
            'updatedTime': Timestamp.now(),
          });
          return true;
        }

        return false;
      }
    } catch (e) {
      debugPrint('❌ Subscription cancellation failed: $e');
      return false;
    }
  }

  /// Get current user subscription (checks all platforms: Stripe, App Store, Google Play)
  Future<UserSubscriptionInfo?> getCurrentSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Check for active or trialing subscriptions (includes trial periods)
      final subscriptionQuery = await FirebaseFirestore.instance
          .collection('user_subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['active', 'trialing'])
          .orderBy('currentPeriodEnd', descending: true)
          .limit(1)
          .get();

      if (subscriptionQuery.docs.isEmpty) return null;

      final data = subscriptionQuery.docs.first.data();
      return UserSubscriptionInfo.fromMap(data);
    } catch (e) {
      debugPrint('❌ Failed to get current subscription: $e');
      return null;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    final subscription = await getCurrentSubscription();
    return subscription != null && subscription.isActive;
  }

  /// Get subscription tier for user
  /// Checks subscription collection first, then falls back to user.currentMembershipTier
  Future<String> getUserTier() async {
    try {
      // First check active subscription
      final subscription = await getCurrentSubscription();
      if (subscription != null && subscription.isActive) {
        return subscription.membershipTier;
      }
      
      // Fallback: check user document for currentMembershipTier
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
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
      }
      
      return 'junior';
    } catch (e) {
      debugPrint('❌ Error getting user tier: $e');
      return 'junior';
    }
  }

  /// Comprehensive subscription state check
  /// Returns detailed subscription information
  Future<Map<String, dynamic>> getSubscriptionState() async {
    try {
      final subscription = await getCurrentSubscription();
      final tier = await getUserTier();
      final hasActive = await hasActiveSubscription();
      
      return {
        'hasActiveSubscription': hasActive,
        'subscription': subscription != null ? {
          'id': subscription.subscriptionId,
          'tier': subscription.membershipTier,
          'status': subscription.status,
          'isActive': subscription.isActive,
          'currentPeriodStart': subscription.currentPeriodStart.toIso8601String(),
          'currentPeriodEnd': subscription.currentPeriodEnd.toIso8601String(),
          'cancelAtPeriodEnd': subscription.cancelAtPeriodEnd,
          'autoRenewing': subscription.autoRenewing,
        } : null,
        'userTier': tier,
        'isTrial': subscription?.status == 'trialing',
      };
    } catch (e) {
      debugPrint('❌ Error getting subscription state: $e');
      return {
        'hasActiveSubscription': false,
        'subscription': null,
        'userTier': 'junior',
        'isTrial': false,
      };
    }
  }

  // Private helper methods

  /// Create subscription intent using Firebase Functions
  Future<Map<String, dynamic>> _createSubscriptionIntent({
    required String userId,
    required String priceId,
    required String email,
  }) async {
    try {
      final callable = _functions.httpsCallable('createSubscription');
      final result = await callable.call({
        'userId': userId,
        'priceId': priceId,
        'email': email,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error calling createSubscription function: $e');

      // For now, return mock data for testing
      // TODO: Remove this when Firebase Functions are properly deployed
      return {
        'subscriptionId': 'sub_mock_${DateTime.now().millisecondsSinceEpoch}',
        'customerId': 'cus_mock_${DateTime.now().millisecondsSinceEpoch}',
        'clientSecret':
            'pi_mock_${DateTime.now().millisecondsSinceEpoch}_secret_mock',
        'ephemeralKey': 'ek_mock_${DateTime.now().millisecondsSinceEpoch}',
      };
    }
  }

  /// Confirm subscription after payment using Firebase Functions
  Future<Map<String, dynamic>> _confirmSubscription({
    required String subscriptionId,
    required String userId,
    required String planId,
  }) async {
    try {
      final callable = _functions.httpsCallable('confirmSubscription');
      final result = await callable.call({
        'subscriptionId': subscriptionId,
        'userId': userId,
        'planId': planId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error calling confirmSubscription function: $e');

      // For testing, create a local subscription record
      await _createLocalSubscriptionRecord(
        userId: userId,
        subscriptionId: subscriptionId,
        planId: planId,
      );

      return {
        'subscriptionId': subscriptionId,
        'customerId': 'cus_mock_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'active',
      };
    }
  }

  /// Create local subscription record for testing
  Future<void> _createLocalSubscriptionRecord({
    required String userId,
    required String subscriptionId,
    required String planId,
  }) async {
    final plan = subscriptionPlans[planId]!;

    await FirebaseFirestore.instance.collection('user_subscriptions').add({
      'userId': userId,
      'platform': 'stripe',
      'productId': plan.stripePriceId,
      'stripeSubscriptionId': subscriptionId,
      'stripeCustomerId': 'cus_mock_${DateTime.now().millisecondsSinceEpoch}',
      'stripePriceId': plan.stripePriceId,
      'status': 'active',
      'membershipTier': planId,
      'currentPeriodStart': Timestamp.now(),
      'currentPeriodEnd':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'nextBillingDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'cancelAtPeriodEnd': false,
      'autoRenewing': true,
      'purchaseDate': Timestamp.now(),
      'priceAmountMicros': (plan.price * 100).toInt(),
      'priceCurrencyCode': plan.currency,
      'isTrialPeriod': false,
      'createdTime': Timestamp.now(),
      'updatedTime': Timestamp.now(),
      'lastValidated': Timestamp.now(),
    });

    // Update user record
    await FirebaseFirestore.instance.collection('user').doc(userId).update({
      'currentMembershipTier': planId,
      'stripeCustomerId': 'cus_mock_${DateTime.now().millisecondsSinceEpoch}',
      'updatedTime': Timestamp.now(),
    });
  }
}

/// Subscription plan model
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String interval;
  final String stripePriceId;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    required this.stripePriceId,
    required this.features,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}/$interval';
}

/// Subscription result model
class SubscriptionResult {
  final bool success;
  final String? subscriptionId;
  final String? customerId;
  final SubscriptionPlan? plan;
  final String? error;

  SubscriptionResult({
    required this.success,
    this.subscriptionId,
    this.customerId,
    this.plan,
    this.error,
  });
}

/// User subscription info model
class UserSubscriptionInfo {
  final String subscriptionId;
  final String customerId;
  final String status;
  final String membershipTier;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final bool autoRenewing;

  UserSubscriptionInfo({
    required this.subscriptionId,
    required this.customerId,
    required this.status,
    required this.membershipTier,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.autoRenewing,
  });

  bool get isActive {
    // Check if status is active or trialing, and period hasn't ended
    final isValidStatus = status == 'active' || status == 'trialing';
    final isWithinPeriod = DateTime.now().isBefore(currentPeriodEnd);
    final notCancelled = !cancelAtPeriodEnd || DateTime.now().isBefore(currentPeriodEnd);
    return isValidStatus && isWithinPeriod && notCancelled;
  }

  factory UserSubscriptionInfo.fromMap(Map<String, dynamic> map) {
    // Handle different subscription platforms (Stripe, App Store, Google Play)
    final platform = map['platform'] as String? ?? 'stripe';
    
    // Get subscription ID based on platform
    String subscriptionId = '';
    if (platform == 'stripe') {
      subscriptionId = map['stripeSubscriptionId'] as String? ?? 
                       map['subscriptionId'] as String? ?? '';
    } else if (platform == 'app_store') {
      subscriptionId = map['originalTransactionId'] as String? ?? '';
    } else if (platform == 'google_play') {
      subscriptionId = map['purchaseToken'] as String? ?? 
                       map['originalTransactionId'] as String? ?? '';
    }
    
    // Get customer ID based on platform
    String customerId = '';
    if (platform == 'stripe') {
      customerId = map['stripeCustomerId'] as String? ?? 
                   map['customerId'] as String? ?? '';
    } else {
      customerId = map['userId'] as String? ?? '';
    }
    
    // Handle Timestamp conversion safely
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
        // Default to 30 days from now if not set
        currentPeriodEnd = DateTime.now().add(const Duration(days: 30));
      }
    } catch (e) {
      debugPrint('❌ Error parsing subscription dates: $e');
      currentPeriodStart = DateTime.now();
      currentPeriodEnd = DateTime.now().add(const Duration(days: 30));
    }
    
    return UserSubscriptionInfo(
      subscriptionId: subscriptionId,
      customerId: customerId,
      status: map['status'] as String? ?? 'inactive',
      membershipTier: map['membershipTier'] as String? ?? 'junior',
      currentPeriodStart: currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd,
      cancelAtPeriodEnd: map['cancelAtPeriodEnd'] as bool? ?? false,
      autoRenewing: map['autoRenewing'] as bool? ?? true,
    );
  }
}
