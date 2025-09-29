const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe?.secret_key || "sk_test_your_secret_key");

admin.initializeApp();

// Import coaching admin functions
const coachingAdmin = require('./coaching_admin');

// ============================================================================
// STRIPE SUBSCRIPTION MANAGEMENT FUNCTIONS
// ============================================================================

/**
 * Create a new subscription with payment intent
 */
exports.createSubscription = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, priceId, email } = data;

  if (!userId || !priceId || !email) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  try {
    console.log(`Creating subscription for user: ${userId}, email: ${email}, priceId: ${priceId}`);

    // Create or retrieve customer
    let customer;
    const existingCustomers = await stripe.customers.list({
      email: email,
      limit: 1
    });

    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
      console.log(`Found existing customer: ${customer.id}`);
    } else {
      customer = await stripe.customers.create({
        email: email,
        metadata: { 
          userId: userId,
          source: 'fococo_app'
        }
      });
      console.log(`Created new customer: ${customer.id}`);
    }

    // Create subscription
    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: priceId }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent'],
      metadata: {
        userId: userId,
        source: 'fococo_app'
      }
    });

    console.log(`Created subscription: ${subscription.id}`);

    // Create ephemeral key for the customer
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: '2020-08-27' }
    );

    return {
      subscriptionId: subscription.id,
      customerId: customer.id,
      clientSecret: subscription.latest_invoice.payment_intent.client_secret,
      ephemeralKey: ephemeralKey.secret,
    };

  } catch (error) {
    console.error('Error creating subscription:', error);
    throw new functions.https.HttpsError('internal', `Failed to create subscription: ${error.message}`);
  }
});

/**
 * Confirm subscription after successful payment
 */
exports.confirmSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { subscriptionId, userId, planId } = data;

  if (!subscriptionId || !userId || !planId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  try {
    console.log(`Confirming subscription: ${subscriptionId} for user: ${userId}`);

    // Retrieve subscription from Stripe
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);

    if (subscription.status !== 'active' && subscription.status !== 'trialing') {
      throw new functions.https.HttpsError('failed-precondition', 'Subscription is not active');
    }

    // Save subscription to Firestore
    const subscriptionData = {
      userId: userId,
      platform: 'stripe',
      productId: subscription.items.data[0].price.id,
      stripeSubscriptionId: subscriptionId,
      stripeCustomerId: subscription.customer,
      stripePriceId: subscription.items.data[0].price.id,
      status: subscription.status,
      membershipTier: planId,
      currentPeriodStart: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_start * 1000)),
      currentPeriodEnd: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
      nextBillingDate: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
      cancelAtPeriodEnd: subscription.cancel_at_period_end,
      autoRenewing: !subscription.cancel_at_period_end,
      purchaseDate: admin.firestore.Timestamp.now(),
      priceAmountMicros: subscription.items.data[0].price.unit_amount,
      priceCurrencyCode: subscription.items.data[0].price.currency.toUpperCase(),
      isTrialPeriod: subscription.status === 'trialing',
      createdTime: admin.firestore.Timestamp.now(),
      updatedTime: admin.firestore.Timestamp.now(),
      lastValidated: admin.firestore.Timestamp.now(),
    };

    // Add subscription record
    await admin.firestore().collection('user_subscriptions').add(subscriptionData);

    // Update user record
    await admin.firestore().collection('user').doc(userId).update({
      currentMembershipTier: planId,
      stripeCustomerId: subscription.customer,
      updatedTime: admin.firestore.Timestamp.now(),
    });

    console.log(`Subscription confirmed and saved for user: ${userId}`);

    return {
      subscriptionId: subscriptionId,
      customerId: subscription.customer,
      status: subscription.status,
    };

  } catch (error) {
    console.error('Error confirming subscription:', error);
    throw new functions.https.HttpsError('internal', `Failed to confirm subscription: ${error.message}`);
  }
});

/**
 * Cancel subscription
 */
exports.cancelSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { subscriptionId, userId } = data;

  if (!subscriptionId || !userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  try {
    console.log(`Canceling subscription: ${subscriptionId} for user: ${userId}`);

    // Cancel subscription in Stripe (at period end)
    const subscription = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true
    });

    // Update Firestore record
    const subscriptionQuery = await admin.firestore()
      .collection('user_subscriptions')
      .where('userId', '==', userId)
      .where('stripeSubscriptionId', '==', subscriptionId)
      .limit(1)
      .get();

    if (!subscriptionQuery.empty) {
      const doc = subscriptionQuery.docs[0];
      await doc.ref.update({
        cancelAtPeriodEnd: true,
        cancellationDate: admin.firestore.Timestamp.now(),
        updatedTime: admin.firestore.Timestamp.now(),
      });
    }

    console.log(`Subscription canceled: ${subscriptionId}`);

    return { 
      success: true, 
      cancelAtPeriodEnd: subscription.cancel_at_period_end,
      currentPeriodEnd: subscription.current_period_end 
    };

  } catch (error) {
    console.error('Error canceling subscription:', error);
    throw new functions.https.HttpsError('internal', `Failed to cancel subscription: ${error.message}`);
  }
});

/**
 * Reactivate a canceled subscription
 */
exports.reactivateSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { subscriptionId, userId } = data;

  if (!subscriptionId || !userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  try {
    console.log(`Reactivating subscription: ${subscriptionId} for user: ${userId}`);

    // Reactivate subscription in Stripe
    const subscription = await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: false
    });

    // Update Firestore record
    const subscriptionQuery = await admin.firestore()
      .collection('user_subscriptions')
      .where('userId', '==', userId)
      .where('stripeSubscriptionId', '==', subscriptionId)
      .limit(1)
      .get();

    if (!subscriptionQuery.empty) {
      const doc = subscriptionQuery.docs[0];
      await doc.ref.update({
        cancelAtPeriodEnd: false,
        cancellationDate: admin.firestore.FieldValue.delete(),
        updatedTime: admin.firestore.Timestamp.now(),
      });
    }

    console.log(`Subscription reactivated: ${subscriptionId}`);

    return { 
      success: true, 
      status: subscription.status 
    };

  } catch (error) {
    console.error('Error reactivating subscription:', error);
    throw new functions.https.HttpsError('internal', `Failed to reactivate subscription: ${error.message}`);
  }
});

/**
 * Process Stripe webhook events (callable function for now)
 */
exports.processStripeWebhook = functions.https.onCall(async (data, context) => {
  // This is a temporary callable function - in production you'd use onRequest
  // For now, we'll handle webhook events manually or through Stripe dashboard
  console.log('Stripe webhook processing function deployed');
  return { success: true, message: 'Webhook processor ready' };
});

// ============================================================================
// COACHING MODULES ADMIN FUNCTIONS
// ============================================================================

// Export coaching admin functions
exports.createCoachingModule = coachingAdmin.createCoachingModule;
exports.updateCoachingModule = coachingAdmin.updateCoachingModule;
exports.deleteCoachingModule = coachingAdmin.deleteCoachingModule;
exports.listCoachingModules = coachingAdmin.listCoachingModules;
exports.bulkImportModules = coachingAdmin.bulkImportModules;
exports.updateModuleAnalytics = coachingAdmin.updateModuleAnalytics;
exports.getModuleStatistics = coachingAdmin.getModuleStatistics;

// ============================================================================
// STRIPE WEBHOOK EVENT HANDLERS
// ============================================================================

async function handlePaymentSucceeded(invoice) {
  console.log(`Payment succeeded for invoice: ${invoice.id}`);
  
  if (invoice.subscription) {
    const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
    const userId = subscription.metadata?.userId;

    if (userId) {
      // Update subscription record
      const subscriptionQuery = await admin.firestore()
        .collection('user_subscriptions')
        .where('stripeSubscriptionId', '==', subscription.id)
        .limit(1)
        .get();

      if (!subscriptionQuery.empty) {
        const doc = subscriptionQuery.docs[0];
        await doc.ref.update({
          status: subscription.status,
          lastPaymentDate: admin.firestore.Timestamp.now(),
          failedPaymentAttempts: 0,
          updatedTime: admin.firestore.Timestamp.now(),
        });
      }
    }
  }
}

async function handlePaymentFailed(invoice) {
  console.log(`Payment failed for invoice: ${invoice.id}`);
  
  if (invoice.subscription) {
    const subscription = await stripe.subscriptions.retrieve(invoice.subscription);
    const userId = subscription.metadata?.userId;

    if (userId) {
      // Update subscription record
      const subscriptionQuery = await admin.firestore()
        .collection('user_subscriptions')
        .where('stripeSubscriptionId', '==', subscription.id)
        .limit(1)
        .get();

      if (!subscriptionQuery.empty) {
        const doc = subscriptionQuery.docs[0];
        const currentData = doc.data();
        await doc.ref.update({
          failedPaymentAttempts: (currentData.failedPaymentAttempts || 0) + 1,
          updatedTime: admin.firestore.Timestamp.now(),
        });
      }
    }
  }
}

async function handleSubscriptionUpdated(subscription) {
  console.log(`Subscription updated: ${subscription.id}`);
  
  const userId = subscription.metadata?.userId;
  if (!userId) return;

  // Update subscription record
  const subscriptionQuery = await admin.firestore()
    .collection('user_subscriptions')
    .where('stripeSubscriptionId', '==', subscription.id)
    .limit(1)
    .get();

  if (!subscriptionQuery.empty) {
    const doc = subscriptionQuery.docs[0];
    await doc.ref.update({
      status: subscription.status,
      currentPeriodStart: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_start * 1000)),
      currentPeriodEnd: admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
      cancelAtPeriodEnd: subscription.cancel_at_period_end,
      autoRenewing: !subscription.cancel_at_period_end,
      updatedTime: admin.firestore.Timestamp.now(),
    });
  }
}

async function handleSubscriptionDeleted(subscription) {
  console.log(`Subscription deleted: ${subscription.id}`);
  
  const userId = subscription.metadata?.userId;
  if (!userId) return;

  // Update subscription record
  const subscriptionQuery = await admin.firestore()
    .collection('user_subscriptions')
    .where('stripeSubscriptionId', '==', subscription.id)
    .limit(1)
    .get();

  if (!subscriptionQuery.empty) {
    const doc = subscriptionQuery.docs[0];
    await doc.ref.update({
      status: 'canceled',
      cancellationDate: admin.firestore.Timestamp.now(),
      updatedTime: admin.firestore.Timestamp.now(),
    });
  }

  // Update user record
  await admin.firestore().collection('user').doc(userId).update({
    currentMembershipTier: 'junior',
    updatedTime: admin.firestore.Timestamp.now(),
  });
}