// lib/modules/payment/services/iap.service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/app_info.helper.dart';
import 'package:rexone_mobile/modules/auth/auth.dart';
import '../models/models.dart';
import '../controllers/payment.controller.dart';
import 'payment.service.dart';

/// Service managing In-App Purchases for Google Play Store and Apple App Store.
/// Pluggable and silent: if [PaymentConfig.enableInAppPurchases] is false,
/// no store initialization or listeners occur.
class InAppPurchaseService extends GetxService {
  late final PaymentService _paymentService;
  InAppPurchase? _iapInstance;
  InAppPurchase get _inAppPurchase => _iapInstance ??= InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final RxBool isStoreAvailable = false.obs;
  final RxBool isPurchasing = false.obs;
  String? _currentPurchasingProductId;
  String? _currentPurchasingCouponCode;

  @visibleForTesting
  void setInAppPurchaseInstance(InAppPurchase instance) {
    _iapInstance = instance;
  }

  @override
  void onInit() {
    super.onInit();
    _paymentService = Get.find<PaymentService>();
    if (PaymentConfig.enableInAppPurchases) {
      _initStore();
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> _initStore() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      isStoreAvailable.value = available;
      if (!available) return;

      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseStream,
        onError: (dynamic error) {
          debugPrint('🛒 [IAP] Purchase stream error: $error');
          isPurchasing.value = false;
        },
      );
    } catch (e) {
      debugPrint('🛒 [IAP] Failed to initialize store: $e');
      isStoreAvailable.value = false;
    }
  }

  Future<void> _onPurchaseStream(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasing.value = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handlePurchased(purchase);
          break;

        case PurchaseStatus.error:
          isPurchasing.value = false;
          _currentPurchasingProductId = null;
          AppSnackbar.error(
            purchase.error?.message ?? AppLocales.payment.iap.failed.tr,
          );
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          isPurchasing.value = false;
          _currentPurchasingProductId = null;
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
          break;
      }
    }
  }

  Future<void> _handlePurchased(PurchaseDetails purchase) async {
    try {
      final isIos = Platform.isIOS;
      final provider = isIos ? PaymentProviders.appStore : PaymentProviders.googlePlay;
      final productId = _currentPurchasingProductId ?? purchase.productID;

      final body = <String, dynamic>{
        PaymentKeys.provider: provider,
        PaymentKeys.productId: productId,
        PaymentKeys.transactionId: purchase.purchaseID,
      };

      if (_currentPurchasingCouponCode != null &&
          _currentPurchasingCouponCode!.isNotEmpty) {
        body[PaymentKeys.couponCode] = _currentPurchasingCouponCode;
      }

      if (isIos) {
        body[PaymentKeys.receiptData] =
            purchase.verificationData.serverVerificationData;
      } else {
        body[PaymentKeys.purchaseToken] =
            purchase.verificationData.serverVerificationData;
        body[PaymentKeys.packageName] = AppInfo.packageName;
      }

      final response = await _paymentService.verifyInAppPurchase(body);

      if (response.success) {
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
        AppSnackbar.success(
          response.message.isNotEmpty
              ? response.message
              : AppLocales.payment.iap.verifySuccess.tr,
        );

        // Refresh user access and payment list
        if (Get.isRegistered<AuthController>()) {
          unawaited(Get.find<AuthController>().getCurrentUser());
        }
        if (Get.isRegistered<PaymentController>()) {
          unawaited(Get.find<PaymentController>().fetchData());
        }
      } else {
        AppSnackbar.error(
          response.error ??
              (response.message.isNotEmpty
                  ? response.message
                  : AppLocales.payment.iap.verifyFailed.tr),
        );
      }
    } catch (e) {
      debugPrint('🛒 [IAP] Exception verifying purchase: $e');
      AppSnackbar.error(AppLocales.payment.iap.verifyFailed.tr);
    } finally {
      isPurchasing.value = false;
      _currentPurchasingProductId = null;
      _currentPurchasingCouponCode = null;
    }
  }

  /// Initiates an in-app purchase for the given product.
  Future<bool> buyProduct(ProductModel product, {String? couponCode}) async {
    if (!PaymentConfig.enableInAppPurchases) {
      AppSnackbar.error(AppLocales.payment.iap.disabled.tr);
      return false;
    }

    if (!isStoreAvailable.value) {
      final available = await _inAppPurchase.isAvailable();
      isStoreAvailable.value = available;
      if (!available) {
        AppSnackbar.error(AppLocales.payment.iap.storeUnavailable.tr);
        return false;
      }
    }

    final storeProductId = product.storeId ?? product.id;
    isPurchasing.value = true;
    _currentPurchasingProductId = product.id;
    _currentPurchasingCouponCode = couponCode;

    try {
      final response = await _inAppPurchase.queryProductDetails({storeProductId});
      if (response.notFoundIDs.contains(storeProductId) ||
          response.productDetails.isEmpty) {
        isPurchasing.value = false;
        _currentPurchasingProductId = null;
        _currentPurchasingCouponCode = null;
        AppSnackbar.error(
          AppLocales.payment.iap.productNotFound.trParams({'id': storeProductId}),
        );
        return false;
      }

      final productDetails = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: productDetails);

      if (product.recurring) {
        return await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        return await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
        );
      }
    } catch (e) {
      isPurchasing.value = false;
      _currentPurchasingProductId = null;
      _currentPurchasingCouponCode = null;
      AppSnackbar.error(
        AppLocales.payment.iap.initiateFailed.trParams({'error': e.toString()}),
      );
      return false;
    }
  }

  /// Restores previous purchases for the signed-in store account.
  Future<void> restorePurchases() async {
    if (!PaymentConfig.enableInAppPurchases) {
      AppSnackbar.error(AppLocales.payment.iap.disabled.tr);
      return;
    }

    try {
      isPurchasing.value = true;
      await _inAppPurchase.restorePurchases();
      AppSnackbar.info(AppLocales.payment.iap.restoringPurchases.tr);
    } catch (e) {
      isPurchasing.value = false;
      AppSnackbar.error(
        AppLocales.payment.iap.restoreFailed.trParams({'error': e.toString()}),
      );
    }
  }
}
