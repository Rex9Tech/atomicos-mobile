import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/analytics.service.dart';

import 'package:rexone_mobile/controllers/pagy.mixin.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/auth/auth.dart';
import '../payment.dart';

class PaymentController extends GetxController with PagyControllerMixin<ProductModel> {
  late final PaymentService _payment;
  AnalyticsService? _analytics;
  final Set<String> _viewedProductIds = <String>{};

  /// Aliases [items] from [PagyControllerMixin] for full backward compatibility.
  RxList<ProductModel> get products => items;
  final RxList<SubscriptionModel> subscriptions = <SubscriptionModel>[].obs;
  final RxList<PurchaseModel> purchases = <PurchaseModel>[].obs;
  final RxList<AccessModel> accesses = <AccessModel>[].obs;

  // Filter Chip Constants
  static const filterAll = 'all';
  static const filterSubscription = 'subscription';
  static const filterOneTime = 'one_time';

  String get selectedFilterId {
    final recurring = activeFilters[PaymentKeys.recurring] as bool?;
    if (recurring == true) return filterSubscription;
    if (recurring == false) return filterOneTime;
    return filterAll;
  }

  void selectFilterId(String id) {
    switch (id) {
      case filterSubscription:
        setFilter(PaymentKeys.recurring, true);
        break;
      case filterOneTime:
        setFilter(PaymentKeys.recurring, false);
        break;
      case filterAll:
      default:
        setFilter(PaymentKeys.recurring, null);
        break;
    }
  }

  // Coupon state
  final Rx<CouponValidationModel?> appliedCoupon = Rx<CouponValidationModel?>(null);
  final RxBool isValidatingCoupon = false.obs;
  final RxString couponError = ''.obs;
  final RxInt couponCooldownSecondsLeft = 0.obs;
  Timer? _couponCooldownTimer;

  @override
  void onInit() {
    super.onInit();
    _payment = Get.find<PaymentService>();
    _analytics = Get.isRegistered<AnalyticsService>()
        ? Get.find<AnalyticsService>()
        : null;
  }

  @override
  void onReady() {
    super.onReady();
    fetchData();
  }

  @override
  void onClose() {
    _couponCooldownTimer?.cancel();
    super.onClose();
  }

  // ============================================================
  // SOCKET EVENT HANDLER (called by SocketController)
  // ============================================================

  /// Called by [SocketController] for every inbound notification event.
  ///
  /// Payment success/failure: dismiss the checkout WebView (if open) so the
  /// user lands back on the payment page; then refresh data.
  /// The success snackbar is shown globally by [SocketController].
  ///
  /// Subscription cancel/resume: just refresh data so the card updates.
  Future<void> onSocketEvent(EWsEventType eventType, String? message) async {
    switch (eventType) {
      case EWsEventType.paymentSuccess:
      case EWsEventType.subscriptionCreated:
      case EWsEventType.subscriptionUpdated:
      case EWsEventType.paymentIntentSucceeded:
      case EWsEventType.paymentFailed:
      case EWsEventType.paymentIntentPaymentFailed:
        // Pop the checkout WebView back to the payment page.
        if (Get.currentRoute == AppRoutes.checkout) {
          Get.back();
        }
        if (Get.isRegistered<AuthController>()) {
          unawaited(Get.find<AuthController>().getCurrentUser());
        }
        await fetchData();
        break;
      case EWsEventType.subscriptionCanceled:
      case EWsEventType.subscriptionResumed:
        if (Get.isRegistered<AuthController>()) {
          unawaited(Get.find<AuthController>().getCurrentUser());
        }
        await fetchData();
        break;
      default:
        break;
    }
  }

  // ============================================================
  // DATA FETCHING & PAGY PAGINATION
  // ============================================================

  @override
  Future<PaginatedResponse<ProductModel>> fetchPage({
    required int page,
    required int limit,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    final recurring = filters?[PaymentKeys.recurring] as bool?;
    var res = await _payment.getProducts(
      page: page,
      limit: limit,
      search: search,
      recurring: recurring,
      showLoading: false,
    );

    if (!res.success && items.isEmpty && page == 1) {
      debugPrint(
        '💳 [PaymentController] getProducts failed (${res.statusCode}), retrying in 400ms...',
      );
      await Future.delayed(const Duration(milliseconds: 400));
      res = await _payment.getProducts(
        page: page,
        limit: limit,
        search: search,
        recurring: recurring,
        showLoading: false,
      );
    }

    debugPrint(
      '💳 [PaymentController] getProducts success=${res.success} (status ${res.statusCode}), count=${res.records.length}',
    );

    if (res.success) {
      for (final product in res.records) {
        if (_viewedProductIds.add(product.id)) {
          _analytics?.logViewProduct(
            productId: product.id,
            productName: product.name,
          );
        }
      }
    }

    return res;
  }

  Future<void> fetchData() async {
    try {
      await Future.wait([
        refreshList(),
        _payment.getSubscriptions(showLoading: false).then((res) {
          if (res.success) {
            subscriptions.assignAll(res.records);
          }
        }),
        _payment.getPurchases(showLoading: false).then((res) {
          if (res.success) {
            purchases.assignAll(res.records);
          }
        }),
        _payment.getActiveAccesses(showLoading: false).then((res) {
          if (res.success) {
            accesses.assignAll(res.records);
          }
        }),
      ]);
    } catch (e, stk) {
      debugPrint(
        '💳 [PaymentController] Failed to fetch payment data: $e\n$stk',
      );
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  InAppPurchaseService? get _iap => Get.isRegistered<InAppPurchaseService>()
      ? Get.find<InAppPurchaseService>()
      : null;

  Future<bool> buyWithInApp(ProductModel product, {String? couponCode}) async {
    if (_iap == null) {
      AppSnackbar.error(AppLocales.payment.iap.serviceUnavailable.tr);
      return false;
    }
    return await _iap!.buyProduct(product, couponCode: couponCode);
  }

  Future<void> restorePurchases() async {
    if (_iap == null) {
      AppSnackbar.error(AppLocales.payment.iap.serviceUnavailable.tr);
      return;
    }
    await _iap!.restorePurchases();
  }

  Future<void> startCheckout(String productId, {String? couponCode}) async {
    try {
      final effectiveCode = couponCode ?? appliedCoupon.value?.code;
      final response = await _payment.createCheckout(
        CreateCheckoutRequest(
          productId: productId,
          couponCode: effectiveCode,
        ),
      );
      if (response.success && response.data != null) {
        final isFreeAccessGranted =
            response.data![PaymentKeys.freeAccessGranted] == true;

        if (isFreeAccessGranted) {
          removeCoupon();
          AppSnackbar.success(AppLocales.payment.accessGranted.tr);
          if (Get.isRegistered<AuthController>()) {
            unawaited(Get.find<AuthController>().getCurrentUser());
          }
          await fetchData();
          return;
        }

        final checkoutUrl = response.data![PaymentKeys.checkoutUrl]?.toString();

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          removeCoupon();
          // Navigate to the in-app WebView — Flutter stays in foreground so
          // the WebSocket connection is preserved throughout checkout.
          AppRoutes.toCheckout(url: checkoutUrl);
        } else {
          AppSnackbar.error(
            response.error ?? AppLocales.payment.invalidCheckout.tr,
          );
        }
      } else {
        AppSnackbar.error(response.error ?? response.message);
      }
    } catch (e) {
      AppSnackbar.error(
        AppLocales.payment.checkoutFailed.trParams({'error': e.toString()}),
      );
    }
  }

  Future<bool> applyCoupon(String code, String productId) async {
    if (couponCooldownSecondsLeft.value > 0) return false;

    final cleanCode = code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleanCode.isEmpty) {
      couponError.value = 'Please enter a coupon code';
      return false;
    }
    if (cleanCode.length < 6) {
      couponError.value = 'Coupon code must be at least 6 alphanumeric characters';
      return false;
    }

    isValidatingCoupon.value = true;
    couponError.value = '';

    try {
      final res = await _payment.validateCoupon(cleanCode, productId);
      isValidatingCoupon.value = false;

      if (res.success && res.data != null && res.data!.valid) {
        appliedCoupon.value = res.data;
        couponError.value = '';
        _stopCouponCooldown();
        return true;
      } else {
        appliedCoupon.value = null;
        couponError.value = res.error ?? res.message;
        final cooldown = res.meta?[PaymentKeys.cooldownRemaining] as int? ?? 0;
        if (cooldown > 0) {
          _startCouponCooldown(cooldown);
        }
        return false;
      }
    } catch (e) {
      isValidatingCoupon.value = false;
      appliedCoupon.value = null;
      couponError.value = AppLocales.payment.couponValidationFailed.trParams({
        'error': e.toString(),
      });
      return false;
    }
  }

  void _startCouponCooldown(int seconds) {
    _couponCooldownTimer?.cancel();
    couponCooldownSecondsLeft.value = seconds;
    _couponCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (couponCooldownSecondsLeft.value <= 1) {
        _stopCouponCooldown();
      } else {
        couponCooldownSecondsLeft.value--;
      }
    });
  }

  void _stopCouponCooldown() {
    _couponCooldownTimer?.cancel();
    _couponCooldownTimer = null;
    couponCooldownSecondsLeft.value = 0;
  }

  void removeCoupon() {
    appliedCoupon.value = null;
    couponError.value = '';
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final res = await _payment.cancelSubscription(subscriptionId);
      if (res.success) {
        AppSnackbar.info(res.message);
        await fetchData();
      } else {
        AppSnackbar.error(res.error ?? res.message);
      }
    } catch (e) {
      AppSnackbar.error(AppLocales.payment.cancelFailed.tr);
    }
  }

  Future<void> resumeSubscription(String subscriptionId) async {
    try {
      final res = await _payment.resumeSubscription(subscriptionId);
      if (res.success) {
        AppSnackbar.success(res.message);
        await fetchData();
      } else {
        AppSnackbar.error(res.error ?? res.message);
      }
    } catch (e) {
      AppSnackbar.error(AppLocales.payment.resumeFailed.tr);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool hasActiveAccess(String productId) {
    if (Get.isRegistered<AuthController>()) {
      if (Get.find<AuthController>().hasAccess(productId)) {
        return true;
      }
    }
    return accesses.any((a) => a.productId == productId && a.isCurrentlyActive);
  }

  SubscriptionModel? getActiveSubscription(String productId) {
    try {
      return subscriptions.firstWhere(
        (s) =>
            s.productId == productId &&
            s.active &&
            !s.scheduledForCancellation &&
            s.canceledAt == null &&
            s.endedAt == null,
      );
    } catch (_) {
      return null;
    }
  }

  SubscriptionModel? getCanceledSubscription(String productId) {
    try {
      return subscriptions.firstWhere(
        (s) =>
            s.productId == productId &&
            (s.scheduledForCancellation || s.canceledAt != null) &&
            s.endedAt == null &&
            s.status != 'canceled',
      );
    } catch (_) {
      return null;
    }
  }

  SubscriptionModel? getFullyCanceledSubscription(String productId) {
    try {
      return subscriptions.firstWhere(
        (s) =>
            s.productId == productId &&
            (s.status == 'canceled' || s.endedAt != null),
      );
    } catch (_) {
      return null;
    }
  }

  int getPurchaseCount(String productId) {
    return purchases.where((t) => t.productId == productId && t.paid).length;
  }
}
