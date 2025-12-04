class StoreSubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String interval;
  final String appStoreProductId;
  final String googlePlayProductId;
  final List<String> features;

  const StoreSubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    required this.appStoreProductId,
    required this.googlePlayProductId,
    required this.features,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}/$interval';
}

const Map<String, StoreSubscriptionPlan> storeSubscriptionPlans = {
  'base': StoreSubscriptionPlan(
    id: 'base',
    name: 'Base',
    price: 9.99,
    currency: 'USD',
    interval: 'month',
    appStoreProductId: 'com.fococo.base.monthly',
    googlePlayProductId: 'com.fococo.base.monthly',
    features: [
      'Basic mental coaching modules',
      'Round logging',
      'Basic analytics',
      'VARK learning assessment',
    ],
  ),
  'plus': StoreSubscriptionPlan(
    id: 'plus',
    name: 'Plus',
    price: 19.99,
    currency: 'USD',
    interval: 'month',
    appStoreProductId: 'com.fococo.plus.monthly',
    googlePlayProductId: 'com.fococo.plus.monthly',
    features: [
      'All Base features',
      'Advanced AI insights',
      'Unlimited round analysis',
      'Premium coaching content',
      'Progress tracking',
      'FocoMap access',
    ],
  ),
  'prime': StoreSubscriptionPlan(
    id: 'prime',
    name: 'Prime',
    price: 39.99,
    currency: 'USD',
    interval: 'month',
    appStoreProductId: 'com.fococo.prime.monthly',
    googlePlayProductId: 'com.fococo.prime.monthly',
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
