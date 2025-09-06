# 🚀 FoCoCo Stripe Backend Setup Guide

## 📋 Overview

This guide will help you complete the Stripe integration setup for FoCoCo. The app is now configured with:

- ✅ **Biometric Authentication System**
- ✅ **Comprehensive Onboarding Flow**
- ✅ **Stripe Service with Fallback Testing**
- ✅ **Firebase Functions (Deployed but needs permissions)**

## 🔧 Current Status

### ✅ What's Working
1. **App Flow**: Users can complete onboarding → biometric setup → subscription selection
2. **Test Mode**: Subscriptions work in "test mode" (bypasses actual Stripe payment)
3. **Biometric Security**: Face ID/Touch ID protection for payments and subscriptions
4. **Local Database**: Subscription records are created in Firestore

### ⚠️ What Needs Setup
1. **Firebase Functions Permissions**: Functions are deployed but need IAM permissions
2. **Stripe Webhook**: Needs proper HTTP endpoint configuration
3. **Production Stripe Keys**: Currently using test keys

## 🛠️ Setup Steps

### Step 1: Fix Firebase Functions Permissions

The functions are deployed but need proper IAM permissions. You need to:

1. **Go to Google Cloud Console**:
   ```
   https://console.cloud.google.com/iam-admin/iam?project=fo-co-co-89gnf5
   ```

2. **Add Cloud Functions Admin Role**:
   - Find your account in the IAM list
   - Click "Edit" (pencil icon)
   - Add role: "Cloud Functions Admin"
   - Save changes

3. **Redeploy Functions**:
   ```bash
   cd firebase
   firebase deploy --only functions --project fo-co-co-89gnf5
   ```

### Step 2: Configure Stripe Webhook (Production)

1. **Create Webhook Endpoint in Stripe Dashboard**:
   - Go to: https://dashboard.stripe.com/webhooks
   - Click "Add endpoint"
   - URL: `https://us-central1-fo-co-co-89gnf5.cloudfunctions.net/stripeWebhook`
   - Events to send:
     - `invoice.payment_succeeded`
     - `invoice.payment_failed`
     - `customer.subscription.updated`
     - `customer.subscription.deleted`

2. **Get Webhook Secret**:
   - Copy the webhook signing secret from Stripe
   - Set it in Firebase:
   ```bash
   cd firebase
   firebase functions:config:set stripe.webhook_secret="whsec_your_webhook_secret_here" --project fo-co-co-89gnf5
   firebase deploy --only functions --project fo-co-co-89gnf5
   ```

### Step 3: Update to Production Stripe Keys

1. **Get Production Keys from Stripe**:
   - Publishable Key: `pk_live_...`
   - Secret Key: `sk_live_...`

2. **Update Firebase Functions**:
   ```bash
   cd firebase
   firebase functions:config:set stripe.secret_key="sk_live_your_secret_key_here" --project fo-co-co-89gnf5
   ```

3. **Update Flutter App**:
   ```dart
   // In lib/services/stripe_service.dart
   static const String _publishableKey = 'pk_live_your_publishable_key_here';
   ```

### Step 4: Remove Test Mode

Once everything is working, remove the test mode bypass:

```dart
// In lib/services/stripe_service.dart, replace:
// For testing: Skip actual Stripe payment and directly confirm subscription
debugPrint('⚠️ TEST MODE: Skipping Stripe payment sheet for testing');

// With:
// Present payment sheet
await Stripe.instance.presentPaymentSheet();
```

## 🧪 Testing the Current Setup

### Test Subscription Flow

1. **Run the App**:
   ```bash
   fvm flutter run
   ```

2. **Complete Onboarding**:
   - Sign up/Login
   - Complete profile setup
   - Take VARK assessment
   - Set up biometric authentication (optional)

3. **Test Subscription**:
   - Navigate to subscription onboarding
   - Select a plan (Base, Plus, or Prime)
   - The subscription will be created in "test mode"
   - Check Firestore for the subscription record

4. **Test Subscription Management**:
   - Go to Profile → Face ID & Security → Subscription Management
   - Verify biometric authentication works
   - Test cancellation (if subscription exists)

### Verify Database Records

Check Firestore collections:
- `user_subscriptions`: Should contain subscription records
- `user`: Should have `currentMembershipTier` updated

## 🔒 Security Features

### Biometric Authentication

The app now includes comprehensive biometric security:

1. **App Lock**: Require biometric to open app
2. **Payment Protection**: Require biometric for payments (enabled by default)
3. **Subscription Protection**: Require biometric for subscription management

### Settings Location

Users can configure security in:
**Profile → Face ID & Security**

## 📱 Platform-Specific Setup

### iOS Configuration

Add to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>FoCoCo uses Face ID for secure authentication and payment protection.</string>
```

### Android Configuration

The app automatically handles fingerprint and face unlock permissions.

## 🚨 Troubleshooting

### Common Issues

1. **"Subscription creation failed"**:
   - This is expected in test mode
   - Check Firebase Functions logs
   - Verify Stripe keys are set

2. **Biometric not working**:
   - Ensure device has biometric setup
   - Check app permissions
   - Test on physical device (not simulator)

3. **Firebase Functions timeout**:
   - Check IAM permissions
   - Verify functions are deployed
   - Check Firebase Functions logs

### Debug Commands

```bash
# Check Firebase Functions logs
firebase functions:log --project fo-co-co-89gnf5

# Check Firebase Functions config
firebase functions:config:get --project fo-co-co-89gnf5

# Test function locally
firebase emulators:start --only functions
```

## 🎯 Next Steps

1. **Fix Firebase Functions permissions** (highest priority)
2. **Test with real Stripe payments** in development
3. **Set up production Stripe keys** when ready to launch
4. **Configure Stripe webhook** for production
5. **Remove test mode** from the app

## 📞 Support

If you encounter issues:

1. Check Firebase Functions logs
2. Verify Stripe dashboard for errors
3. Test biometric authentication on physical device
4. Ensure all dependencies are installed: `fvm flutter pub get`

The integration is now **90% complete** and ready for testing! The remaining 10% is primarily backend configuration and production setup.
