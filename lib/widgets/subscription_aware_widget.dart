import 'package:flutter/material.dart';
import '/services/subscription_state_provider.dart';

/// Example widget showing how to use SubscriptionStateProvider
/// This demonstrates how to control widgets based on subscription state
class SubscriptionAwareWidget extends StatelessWidget {
  final Widget child;
  final String? requiredTier;
  final Widget? fallbackWidget;

  const SubscriptionAwareWidget({
    super.key,
    required this.child,
    this.requiredTier,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SubscriptionStateProvider(),
      builder: (context, _) {
        final provider = SubscriptionStateProvider();
        
        // If no tier requirement, just show child
        if (requiredTier == null) {
          return child;
        }

        // Check if user has required tier
        if (provider.canAccessFeature(requiredTier: requiredTier!)) {
          return child;
        }

        // Show fallback or locked widget
        return fallbackWidget ?? 
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature requires $requiredTier subscription',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
      },
    );
  }
}

/// Helper extension for easy subscription checks
extension SubscriptionExtension on BuildContext {
  SubscriptionStateProvider get subscription => SubscriptionStateProvider();
  
  bool canAccess(String tier) => 
    SubscriptionStateProvider().canAccessFeature(requiredTier: tier);
  
  bool get isPrime => SubscriptionStateProvider().isPrime;
  bool get isPlus => SubscriptionStateProvider().isPlus;
  bool get isBase => SubscriptionStateProvider().isBase;
  bool get hasActiveSubscription => 
    SubscriptionStateProvider().hasActiveSubscription;
}


