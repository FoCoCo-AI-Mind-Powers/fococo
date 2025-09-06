# FoCoCo Stripe Integration Setup Guide

## Overview
This guide helps you set up Stripe payments for FoCoCo's subscription system with native payment sheets, Apple Pay, and Google Pay support.

## 1. Stripe Dashboard Setup

### Create Stripe Account
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Create an account or log in
3. Complete business verification

### Configure Products and Prices
1. Go to **Products** in the Stripe Dashboard
2. Create three products:

#### Base Plan
- **Name**: FoCoCo Base
- **Price**: $9.99/month
- **Recurring**: Monthly
- **Price ID**: `price_base_monthly` (copy this ID)

#### Plus Plan
- **Name**: FoCoCo Plus
- **Price**: $19.99/month
- **Recurring**: Monthly
- **Price ID**: `price_plus_monthly` (copy this ID)

#### Prime Plan
- **Name**: FoCoCo Prime
- **Price**: $39.99/month
- **Recurring**: Monthly
- **Price ID**: `price_prime_monthly` (copy this ID)

### Get API Keys
1. Go to **Developers** > **API Keys**
2. Copy your **Publishable Key** (starts with `pk_`)
3. Copy your **Secret Key** (starts with `sk_`)

## 2. Update Flutter App Configuration

### Update StripeService
In `lib/services/stripe_service.dart`, update these constants:

```dart
// Replace with your actual keys
static const String _publishableKey = 'pk_test_your_publishable_key_here';
static const String _merchantId = 'merchant.com.fococo.app';

// Replace with your actual backend URL
static const String _backendUrl = 'https://your-backend-url.com';

// Update price IDs to match your Stripe products
static const Map<String, SubscriptionPlan> subscriptionPlans = {
  'base': SubscriptionPlan(
    id: 'base',
    name: 'Base',
    price: 9.99,
    currency: 'USD',
    interval: 'month',
    stripePriceId: 'price_your_actual_base_price_id', // Update this
    features: [
      'Basic mental coaching modules',
      'Round logging',
      'Basic analytics',
      'VARK learning assessment',
    ],
  ),
  // ... update other plans similarly
};
```

## 3. iOS Configuration

### Update Info.plist
Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.fococo.app.payments</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fococo-payments</string>
        </array>
    </dict>
</array>
```

### Apple Pay Configuration
1. In Xcode, enable Apple Pay capability
2. Add your merchant ID: `merchant.com.fococo.app`
3. Configure payment processing certificates in Apple Developer Console

## 4. Android Configuration

### Update AndroidManifest.xml
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="com.stripe.android.PaymentAuthWebViewActivity"
    android:exported="false"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

### Google Pay Configuration
1. Add your merchant ID to Google Pay Console
2. Configure payment methods in Google Pay Business Console

## 5. Backend Setup (Required)

You need a backend server to handle Stripe webhooks and secure operations. Here's a basic Node.js/Firebase Functions example:

### Firebase Functions Setup

Create `firebase/functions/stripe.js`:

```javascript
const functions = require('firebase-functions');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const admin = require('firebase-admin');

// Create subscription
exports.createSubscription = functions.https.onCall(async (data, context) => {
  const { userId, priceId, email } = data;
  
  try {
    // Create or retrieve customer
    let customer;
    const existingCustomers = await stripe.customers.list({
      email: email,
      limit: 1
    });
    
    if (existingCustomers.data.length > 0) {
      customer = existingCustomers.data[0];
    } else {
      customer = await stripe.customers.create({
        email: email,
        metadata: { userId: userId }
      });
    }
    
    // Create subscription
    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: priceId }],
      payment_behavior: 'default_incomplete',
      expand: ['latest_invoice.payment_intent'],
    });
    
    // Create ephemeral key
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
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Confirm subscription
exports.confirmSubscription = functions.https.onCall(async (data, context) => {
  const { subscriptionId, userId, planId } = data;
  
  try {
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    
    // Update Firestore with subscription details
    await admin.firestore().collection('user_subscriptions').add({
      userId: userId,
      stripeSubscriptionId: subscriptionId,
      stripeCustomerId: subscription.customer,
      status: subscription.status,
      membershipTier: planId,
      currentPeriodStart: new Date(subscription.current_period_start * 1000),
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      createdTime: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Update user record
    await admin.firestore().collection('users').doc(userId).update({
      currentMembershipTier: planId,
      stripeCustomerId: subscription.customer,
    });
    
    return {
      subscriptionId: subscriptionId,
      customerId: subscription.customer,
    };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Cancel subscription
exports.cancelSubscription = functions.https.onCall(async (data, context) => {
  const { subscriptionId } = data;
  
  try {
    await stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true
    });
    
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Webhook handler
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = functions.config().stripe.webhook_secret;
  
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.log(`Webhook signature verification failed.`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  // Handle the event
  switch (event.type) {
    case 'invoice.payment_succeeded':
      // Handle successful payment
      break;
    case 'invoice.payment_failed':
      // Handle failed payment
      break;
    case 'customer.subscription.deleted':
      // Handle subscription cancellation
      break;
    default:
      console.log(`Unhandled event type ${event.type}`);
  }
  
  res.json({received: true});
});
```

### Deploy Functions
```bash
cd firebase/functions
npm install stripe
firebase functions:config:set stripe.secret_key="sk_test_your_secret_key"
firebase functions:config:set stripe.webhook_secret="whsec_your_webhook_secret"
firebase deploy --only functions
```

## 6. Testing

### Test Cards
Use Stripe's test cards:
- **Success**: 4242 4242 4242 4242
- **Decline**: 4000 0000 0000 0002
- **3D Secure**: 4000 0025 0000 3155

### Test Apple Pay
1. Use iOS Simulator with test Apple ID
2. Add test cards to Wallet app
3. Test payment flow

### Test Google Pay
1. Use Android emulator with Google account
2. Add test cards to Google Pay
3. Test payment flow

## 7. Production Checklist

- [ ] Replace test keys with live keys
- [ ] Update webhook endpoints to production URLs
- [ ] Configure live Apple Pay certificates
- [ ] Set up live Google Pay merchant account
- [ ] Test all payment flows in production
- [ ] Set up monitoring and alerts
- [ ] Configure proper error handling
- [ ] Implement subscription management features

## 8. Security Notes

1. **Never expose secret keys** in client-side code
2. **Always validate webhooks** using Stripe signatures
3. **Use HTTPS** for all webhook endpoints
4. **Implement proper error handling** for failed payments
5. **Store sensitive data securely** in Firebase Functions config

## Support

For issues with this integration:
1. Check Stripe Dashboard logs
2. Review Firebase Functions logs
3. Test with Stripe CLI for webhook debugging
4. Consult Stripe documentation for latest API changes

## Useful Links

- [Stripe Flutter SDK](https://pub.dev/packages/flutter_stripe)
- [Stripe Dashboard](https://dashboard.stripe.com)
- [Apple Pay Setup](https://stripe.com/docs/apple-pay)
- [Google Pay Setup](https://stripe.com/docs/google-pay)
- [Firebase Functions](https://firebase.google.com/docs/functions)
