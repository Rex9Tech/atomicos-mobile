// test/modules/payment/controllers/payment_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/payment/payment.dart';
import '../../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePaymentService fakePayment;
  late PaymentController controller;

  setUp(() {
    Get.testMode = true;
    fakePayment = FakePaymentService();
    Get.put<PaymentService>(fakePayment);
    controller = Get.put(PaymentController());
  });

  tearDown(() {
    Get.reset();
  });

  group('PaymentController - Fetch and State', () {
    test(
      'fetchData populates products, subscriptions, purchases, and accesses',
      () async {
        final mockProduct = ProductModel(
          id: 'prod_1',
          name: 'Pro Plan',
          description: 'Pro subscription',
          price: '\$19.99',
          unitAmount: 1999,
          currency: 'USD',
          interval: 'month',
          periodLabel: 'monthly',
          recurring: true,
          active: true,
        );

        final mockAccess = AccessModel(
          id: 'acc_1',
          status: 'active',
          productId: 'prod_1',
          active: true,
        );

        final mockSub = SubscriptionModel(
          id: 'sub_1',
          status: 'active',
          productId: 'prod_1',
          provider: 'stripe',
          providerSubscriptionId: 'sub_1',
          providerPriceId: 'price_1',
          currency: 'usd',
          unitAmount: 1999,
          quantity: 1,
          interval: 'month',
          intervalCount: 1,
          active: true,
          canceled: false,
          scheduledForCancellation: false,
        );

        final mockPurchase = PurchaseModel(
          id: 'pur_1',
          productId: 'prod_1',
          unitAmount: 1999,
          currency: 'USD',
          paid: true,
          status: 'succeeded',
        );

        fakePayment.productsResponse = PaginatedResponse<ProductModel>(
          records: [mockProduct],
          message: 'OK',
          statusCode: 200,
          success: true,
        );

        fakePayment.accessesResponse = PaginatedResponse<AccessModel>(
          records: [mockAccess],
          message: 'OK',
          statusCode: 200,
          success: true,
        );

        fakePayment.subscriptionsResponse =
            PaginatedResponse<SubscriptionModel>(
              records: [mockSub],
              message: 'OK',
              statusCode: 200,
              success: true,
            );

        fakePayment.purchasesResponse = PaginatedResponse<PurchaseModel>(
          records: [mockPurchase],
          message: 'OK',
          statusCode: 200,
          success: true,
        );

        await controller.fetchData();

        expect(controller.products.length, equals(1));
        expect(controller.products.first.id, equals('prod_1'));
        expect(controller.accesses.length, equals(1));
        expect(controller.subscriptions.length, equals(1));
        expect(controller.purchases.length, equals(1));

        expect(controller.hasActiveAccess('prod_1'), isTrue);
        expect(controller.hasActiveAccess('prod_unknown'), isFalse);
        expect(controller.getActiveSubscription('prod_1'), isNotNull);
        expect(controller.getPurchaseCount('prod_1'), equals(1));
      },
    );
  });

  group('PaymentController - Actions and Socket Events', () {
    test('cancelSubscription calls service and triggers data reload', () async {
      fakePayment.cancelResponse = ApiResponse.success(
        message: 'Canceled successfully',
        statusCode: 200,
      );

      await controller.cancelSubscription('sub_1');
      expect(controller.subscriptions, isEmpty);
    });

    test('resumeSubscription calls service and triggers data reload', () async {
      fakePayment.resumeResponse = ApiResponse.success(
        message: 'Resumed successfully',
        statusCode: 200,
      );

      await controller.resumeSubscription('sub_1');
      expect(controller.subscriptions, isEmpty);
    });

    test('onSocketEvent refreshes data on paymentSuccess', () async {
      final mockProduct = ProductModel(
        id: 'prod_premium',
        name: 'Premium',
        description: 'Yearly access',
        price: '\$49.99',
        unitAmount: 4999,
        currency: 'USD',
        interval: 'year',
        periodLabel: 'yearly',
        recurring: true,
        active: true,
      );

      fakePayment.productsResponse = PaginatedResponse<ProductModel>(
        records: [mockProduct],
        message: 'OK',
        statusCode: 200,
        success: true,
      );

      await controller.onSocketEvent(EWsEventType.paymentSuccess, 'Success!');

      expect(controller.products.any((p) => p.id == 'prod_premium'), isTrue);
    });
  });

  group('PaymentController - Coupons', () {
    test('applyCoupon succeeds with valid code', () async {
      fakePayment.validateCouponResponse = ApiResponse.success(
        message: 'Coupon is valid',
        statusCode: 200,
        data: const CouponValidationModel(
          valid: true,
          discountAmount: 200,
          finalAmount: 800,
          originalAmount: 1000,
          currency: 'usd',
          coupon: CouponModel(
            id: 'c-test-1',
            title: 'Test Coupon',
            code: 'SAVE20',
            couponType: CouponTypes.fixed,
            amount: 200,
            currency: 'usd',
            maxUsage: 100,
            maxUsagePerUser: 1,
            usedCount: 0,
            targetRoleIds: [],
            targetUserIds: [],
            targetProductIds: [],
            active: true,
            exhausted: false,
            expired: false,
          ),
        ),
      );

      final result = await controller.applyCoupon('SAVE20', 'prod_1');
      expect(result, isTrue);
      expect(controller.appliedCoupon.value, isNotNull);
      expect(controller.appliedCoupon.value!.discountAmount, equals(200));
      expect(controller.couponError.value, isEmpty);
    });

    test('applyCoupon rejects code shorter than 6 characters', () async {
      final result = await controller.applyCoupon('ABC', 'prod_1');
      expect(result, isFalse);
      expect(
        controller.couponError.value,
        equals('Coupon code must be at least 6 alphanumeric characters'),
      );
    });

    test('applyCoupon handles failure and extracts cooldown from meta', () async {
      fakePayment.validateCouponResponse = ApiResponse.error(
        message: 'Too many attempts',
        statusCode: 429,
        error: 'Too many invalid coupon attempts. Please wait 30 seconds before trying again.',
        meta: {
          PaymentKeys.remainingAttempts: 0,
          PaymentKeys.cooldownRemaining: 30,
        },
      );

      final result = await controller.applyCoupon('BADCODE', 'prod_1');
      expect(result, isFalse);
      expect(controller.appliedCoupon.value, isNull);
      expect(controller.couponError.value, contains('Too many invalid coupon attempts'));
      expect(controller.couponCooldownSecondsLeft.value, equals(30));
      expect(controller.couponCooldownSecondsLeft.value > 0, isTrue);
    });
  });

  group('PaymentController - Pagy, Search and Filter', () {
    test('onSearchChanged triggers fetch with search parameter', () async {
      controller.onSearchChanged('membership');
      await Future.delayed(const Duration(milliseconds: 400));

      expect(controller.searchQuery.value, equals('membership'));
      expect(fakePayment.lastGetProductsSearch, equals('membership'));
    });

    test('selectFilterId with filterSubscription passes recurring=true to service', () async {
      controller.selectFilterId(PaymentController.filterSubscription);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.activeFilters[PaymentKeys.recurring], isTrue);
      expect(fakePayment.lastGetProductsRecurring, isTrue);
    });

    test('selectFilterId with filterOneTime passes recurring=false to service', () async {
      controller.selectFilterId(PaymentController.filterOneTime);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.activeFilters[PaymentKeys.recurring], isFalse);
      expect(fakePayment.lastGetProductsRecurring, isFalse);
    });

    test('loadMore requests next page and appends products', () async {
      final page1Product = ProductModel(
        id: 'prod_1',
        name: 'Product 1',
        description: 'First product',
        price: '\$10',
        unitAmount: 1000,
        currency: 'USD',
        periodLabel: 'one-time',
        recurring: false,
        active: true,
      );
      final page2Product = ProductModel(
        id: 'prod_2',
        name: 'Product 2',
        description: 'Second product',
        price: '\$20',
        unitAmount: 2000,
        currency: 'USD',
        periodLabel: 'one-time',
        recurring: false,
        active: true,
      );

      fakePayment.productsResponse = PaginatedResponse<ProductModel>(
        records: [page1Product],
        message: 'OK',
        statusCode: 200,
        success: true,
        pagination: const PaginationMeta(
          currentPage: 1,
          limit: 10,
          totalCount: 2,
          totalPages: 2,
          nextPage: 2,
          prevPage: null,
        ),
      );

      await controller.refreshList();
      expect(controller.products.length, equals(1));
      expect(controller.hasMore, isTrue);

      fakePayment.productsResponse = PaginatedResponse<ProductModel>(
        records: [page2Product],
        message: 'OK',
        statusCode: 200,
        success: true,
        pagination: const PaginationMeta(
          currentPage: 2,
          limit: 10,
          totalCount: 2,
          totalPages: 2,
          nextPage: null,
          prevPage: 1,
        ),
      );

      await controller.loadMore();
      expect(fakePayment.lastGetProductsPage, equals(2));
      expect(controller.products.length, equals(2));
      expect(controller.products.map((p) => p.id), containsAll(['prod_1', 'prod_2']));
      expect(controller.hasMore, isFalse);
    });
  });
}
