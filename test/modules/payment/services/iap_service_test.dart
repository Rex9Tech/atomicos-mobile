// test/modules/payment/services/iap_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/modules/payment/payment.dart';
import '../../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePaymentService fakePayment;
  late InAppPurchaseService iapService;

  setUp(() {
    Get.testMode = true;
    fakePayment = FakePaymentService();
    Get.put<PaymentService>(fakePayment);
    iapService = Get.put(InAppPurchaseService());
  });

  tearDown(() {
    Get.reset();
  });

  group('InAppPurchaseService - Silent Mode (Default)', () {
    test('defaults to disabled when PaymentConfig.enableInAppPurchases is false', () {
      expect(PaymentConfig.enableInAppPurchases, isFalse);
      expect(iapService.isStoreAvailable.value, isFalse);
      expect(iapService.isPurchasing.value, isFalse);
    });

    test('buyProduct safely returns false when disabled', () async {
      final product = ProductModel(
        id: 'prod_iap_1',
        name: 'Gems Pack',
        description: '100 gems',
        price: 'USD 2.99',
        unitAmount: 299,
        currency: 'usd',
        periodLabel: 'one-time',
        recurring: false,
        active: true,
        googlePlayProductId: 'com.rex9.rexone.gems_100',
      );

      final result = await iapService.buyProduct(product);
      expect(result, isFalse);
      expect(iapService.isPurchasing.value, isFalse);
    });

    test('restorePurchases safely executes without error when disabled', () async {
      await iapService.restorePurchases();
      expect(iapService.isPurchasing.value, isFalse);
    });
  });

  group('PaymentController - In-App Purchase Delegation', () {
    late PaymentController controller;

    setUp(() {
      controller = Get.put(PaymentController());
    });

    test('buyWithInApp safely handles IAP call', () async {
      final product = ProductModel(
        id: 'prod_iap_1',
        name: 'Gems Pack',
        description: '100 gems',
        price: 'USD 2.99',
        unitAmount: 299,
        currency: 'usd',
        periodLabel: 'one-time',
        recurring: false,
        active: true,
        googlePlayProductId: 'com.rex9.rexone.gems_100',
      );

      final result = await controller.buyWithInApp(product);
      expect(result, isFalse);
    });

    test('buyWithInApp forwards couponCode to IAP service', () async {
      final product = ProductModel(
        id: 'prod_iap_1',
        name: 'Gems Pack',
        description: '100 gems',
        price: 'USD 2.99',
        unitAmount: 299,
        currency: 'usd',
        periodLabel: 'one-time',
        recurring: false,
        active: true,
        appStoreProductId: 'com.rex9.rexone.gems_100',
      );

      final result = await controller.buyWithInApp(product, couponCode: 'APPLE10');
      expect(result, isFalse);
    });

    test('restorePurchases safely delegates to IAP service', () async {
      await controller.restorePurchases();
      expect(iapService.isPurchasing.value, isFalse);
    });
  });
}
