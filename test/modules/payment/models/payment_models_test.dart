// test/modules/payment/models/payment_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rexone_mobile/modules/payment/models/models.dart';

void main() {
  group('ProductModel', () {
    test('parses free product correctly', () {
      final json = {
        'id': 'prod_free_1',
        'name': 'Free Course',
        'description': 'A free course',
        'price': 'Free',
        'unit_amount': 0,
        'currency': 'usd',
        'interval': null,
        'period_label': 'One-time purchase',
        'recurring': false,
        'active': true,
        'free': true,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'prod_free_1');
      expect(product.name, 'Free Course');
      expect(product.unitAmount, 0);
      expect(product.price, 'Free');
      expect(product.isFree, true);
      expect(product.recurring, false);
      expect(product.active, true);
    });

    test('parses paid product correctly', () {
      final json = {
        'id': 'prod_paid_1',
        'name': 'Pro Plan',
        'description': 'Monthly subscription',
        'price': 'USD 10.00',
        'unit_amount': 1000,
        'currency': 'usd',
        'interval': 'month',
        'period_label': 'monthly',
        'recurring': true,
        'active': true,
        'free': false,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'prod_paid_1');
      expect(product.unitAmount, 1000);
      expect(product.isFree, false);
      expect(product.recurring, true);
    });
    test('parses omnichannel product correctly across Stripe, Google Play, and App Store', () {
      final json = {
        'id': 'prod_omni_1',
        'name': 'Pro Subscription',
        'description': 'Cross-platform pro access',
        'price': 'USD 9.99',
        'unit_amount': 999,
        'currency': 'usd',
        'interval': 'month',
        'period_label': 'monthly',
        'recurring': true,
        'active': true,
        'free': false,
        'stripe_product_id': 'prod_stripe_1',
        'stripe_price_id': 'price_stripe_1',
        'google_play_product_id': 'com.rex9.rexone.pro_play',
        'app_store_product_id': 'com.rex9.rexone.pro_store',
        'supported_providers': ['stripe', 'google_play', 'app_store'],
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'prod_omni_1');
      expect(product.stripeProductId, 'prod_stripe_1');
      expect(product.stripePriceId, 'price_stripe_1');
      expect(product.googlePlayProductId, 'com.rex9.rexone.pro_play');
      expect(product.appStoreProductId, 'com.rex9.rexone.pro_store');
      expect(product.supportedProviders, containsAll(['stripe', 'google_play', 'app_store']));
      expect(product.supportsStripe, isTrue);
      expect(product.recurring, isTrue);
      expect(product.isFree, isFalse);
    });
  });

  group('PurchaseModel', () {
    test('parses purchase with universal provider fields', () {
      final purchase = PurchaseModel.fromJson({
        'id': 'pur_123',
        'product_id': 'prod_play_1',
        'unit_amount': 299,
        'currency': 'usd',
        'paid': true,
        'status': 'succeeded',
        'product_name': 'Gems Pack',
        'created_at': '2026-09-28T00:00:00Z',
        'provider': 'google_play',
        'provider_payment_id': 'GPA.1234-5678-9012',
      });

      expect(purchase.id, 'pur_123');
      expect(purchase.productId, 'prod_play_1');
      expect(purchase.paid, isTrue);
      expect(purchase.provider, 'google_play');
      expect(purchase.providerPaymentId, 'GPA.1234-5678-9012');
    });
  });

  group('SubscriptionModel', () {
    test('parses universal provider subscription fields', () {
      final subscription = SubscriptionModel.fromJson({
        'id': 'sub_123',
        'product_id': 'prod_appstore_1',
        'status': 'active',
        'provider': 'app_store',
        'provider_subscription_id': 'sub_ios_999',
        'provider_price_id': 'price_monthly_ios',
        'currency': 'usd',
        'unit_amount': 999,
        'quantity': 1,
        'interval': 'month',
        'interval_count': 1,
        'current_period_start': '2026-09-01T00:00:00Z',
        'current_period_end': '2026-10-01T00:00:00Z',
        'started_at': '2026-09-01T00:00:00Z',
        'active': true,
        'canceled': false,
        'scheduled_for_cancellation': false,
      });

      expect(subscription.provider, 'app_store');
      expect(subscription.providerSubscriptionId, 'sub_ios_999');
      expect(subscription.providerPriceId, 'price_monthly_ios');
      expect(subscription.isActive, isTrue);
    });

    test('parses the subscription item price snapshot', () {
      final subscription = SubscriptionModel.fromJson({
        'id': 'subscription_1',
        'product_id': 'product_1',
        'status': 'active',
        'provider': 'stripe',
        'provider_subscription_id': 'sub_1',
        'provider_price_id': 'price_1',
        'currency': 'usd',
        'unit_amount': 2500,
        'quantity': 2,
        'interval': 'month',
        'interval_count': 1,
        'current_period_start': '2026-09-01T00:00:00Z',
        'current_period_end': '2026-10-01T00:00:00Z',
        'started_at': '2026-09-01T00:00:00Z',
        'active': true,
        'canceled': false,
        'scheduled_for_cancellation': false,
      });

      expect(subscription.providerSubscriptionId, 'sub_1');
      expect(subscription.providerPriceId, 'price_1');
      expect(subscription.unitAmount, 2500);
      expect(subscription.quantity, 2);
      expect(subscription.interval, 'month');
      expect(subscription.intervalCount, 1);
      expect(subscription.startedAt, '2026-09-01T00:00:00Z');
    });
  });

  group('AccessModel', () {
    test('parses active access correctly', () {
      final json = {
        'id': 'acc_123',
        'status': 'active',
        'granted_at': '2026-09-01T00:00:00Z',
        'expires_at': null,
        'product_id': 'prod_free_1',
        'product_name': 'Free Course',
        'days_remaining': null,
        'active': true,
      };

      final access = AccessModel.fromJson(json);

      expect(access.id, 'acc_123');
      expect(access.productId, 'prod_free_1');
      expect(access.status, 'active');
      expect(access.active, true);
      expect(access.productName, 'Free Course');
    });

    test('parses revoked access with timestamps', () {
      final json = {
        'id': 'acc_456',
        'status': 'revoked',
        'granted_at': '2026-08-01T00:00:00Z',
        'revoked_at': '2026-08-15T12:00:00Z',
        'expires_at': null,
        'product_id': 'prod_free_1',
        'product_name': 'Free Course',
        'days_remaining': null,
        'active': false,
      };

      final access = AccessModel.fromJson(json);

      expect(access.id, 'acc_456');
      expect(access.status, 'revoked');
      expect(access.active, false);
      expect(access.revokedAt, '2026-08-15T12:00:00Z');
    });
  });
}
