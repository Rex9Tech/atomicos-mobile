// lib/modules/payment/controllers/mmpay_checkout.controller.dart
import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/modules/auth/auth.dart';
import 'package:rexone_mobile/routes/routes.dart';

import '../payment.dart';

/// Drives the MyanMyanPay (MMQR) checkout screen: countdown to the QR expiry,
/// polling our backend for the final status (the verified webhook is the
/// source of truth), and saving the QR image to the device.
class MmpayCheckoutController extends GetxController {
  late final PaymentService _payment;

  final orderId = ''.obs;
  final qr = ''.obs;
  final amount = 0.obs;
  final currency = 'MMK'.obs;
  final productId = ''.obs;

  /// pending | succeeded | failed | expired
  final status = 'pending'.obs;
  final secondsLeft = 0.obs;

  DateTime? _expiresAt;
  Timer? _countdownTimer;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    _payment = Get.find<PaymentService>();

    final args = (Get.arguments as Map?) ?? const {};
    orderId.value = args['order_id']?.toString() ?? '';
    qr.value = args['qr']?.toString() ?? '';
    amount.value = args['amount'] is num ? (args['amount'] as num).toInt() : 0;
    currency.value = args['currency']?.toString() ?? 'MMK';
    productId.value = args['product_id']?.toString() ?? '';

    final expiresAtRaw = args['expires_at']?.toString();
    _expiresAt = expiresAtRaw != null && expiresAtRaw.isNotEmpty
        ? DateTime.tryParse(expiresAtRaw)?.toLocal()
        : null;
    _expiresAt ??= DateTime.now().add(const Duration(minutes: 15));

    _startCountdown();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  @override
  void onClose() {
    _stopTimers();
    super.onClose();
  }

  String get formattedAmount =>
      formatPaymentAmount(amount.value, currency.value);

  String get countdownLabel {
    final total = secondsLeft.value;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startCountdown() {
    void tick() {
      final remaining = _expiresAt!.difference(DateTime.now()).inSeconds;
      secondsLeft.value = remaining > 0 ? remaining : 0;
      if (remaining <= 0 && status.value == 'pending') {
        status.value = 'expired';
        _stopTimers();
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _poll() async {
    if (status.value != 'pending' || orderId.value.isEmpty) return;
    try {
      final response = await _payment.getMmpayStatus(orderId.value);
      if (!response.success || response.data == null) return;
      final remoteStatus = response.data![PaymentKeys.status]?.toString();
      if (remoteStatus == 'succeeded') {
        _finishSuccess();
      } else if (remoteStatus == 'failed') {
        status.value = 'failed';
        _stopTimers();
      } else if (remoteStatus == 'expired') {
        status.value = 'expired';
        _stopTimers();
      }
    } catch (_) {
      // Transient failure — the next tick retries.
    }
  }

  void _finishSuccess() {
    if (status.value == 'succeeded') return;
    status.value = 'succeeded';
    _stopTimers();
    AppSnackbar.success(AppLocales.payment.mmpayPaid.tr);
    if (Get.isRegistered<AuthController>()) {
      unawaited(Get.find<AuthController>().getCurrentUser());
    }
    if (Get.isRegistered<PaymentController>()) {
      unawaited(Get.find<PaymentController>().fetchData());
    }
    if (Get.currentRoute == AppRoutes.mmpayCheckout) {
      Get.back();
    }
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Leave the expired/failed screen and request a fresh QR.
  void retry() {
    final targetProductId = productId.value;
    if (Get.currentRoute == AppRoutes.mmpayCheckout) {
      Get.back();
    }
    if (targetProductId.isNotEmpty && Get.isRegistered<PaymentController>()) {
      Get.find<PaymentController>().startCheckout(targetProductId);
    }
  }

  /// Save the QR as a PNG into the app's external files directory.
  Future<void> saveQrImage() async {
    if (qr.value.isEmpty) return;
    try {
      final painter = QrPainter(
        data: qr.value,
        version: QrVersions.auto,
        gapless: true,
      );
      final imageData = await painter.toImageData(1024);
      if (imageData == null) {
        AppSnackbar.error(AppLocales.payment.mmpaySaveFailed.tr);
        return;
      }
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mmpay_${orderId.value}.png');
      await file.writeAsBytes(imageData.buffer.asUint8List(), flush: true);
      AppSnackbar.success('${AppLocales.payment.mmpaySaved.tr}\n${file.path}');
    } catch (_) {
      AppSnackbar.error(AppLocales.payment.mmpaySaveFailed.tr);
    }
  }
}
