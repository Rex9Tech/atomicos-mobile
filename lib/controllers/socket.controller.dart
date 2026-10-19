// lib/controllers/socket.controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/components/components.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/services.dart';
import '../modules/ai/ai.dart';
import '../modules/atom_details/atom_details.dart';
import '../modules/home/home.dart';
import '../modules/molecule/molecule.dart';
import '../modules/auth/auth.dart';
import '../modules/payment/payment.dart';
import '../modules/notification/notification.dart';

/// Single, permanent socket event router.
///
/// Subscribes to [SocketService.stream] once for the lifetime of the app.
/// All snackbar display and per-controller data refresh go here.
/// No other controller should call `socket.stream.listen`.
///
/// To add a new notification type: edit [_showSnackbar] and/or [_dispatch].
/// SpeechLiveChannel events are forwarded to [SpeechService].
class SocketController extends GetxController {
  late final SocketService _socket;
  StreamSubscription<SocketMessage>? _sub;

  @override
  void onInit() {
    super.onInit();
    _socket = Get.find<SocketService>();
    _sub = _socket.stream.listen(_handleEvent);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  // ============================================================
  // ENTRY POINT
  // ============================================================

  Future<void> _handleEvent(SocketMessage event) async {
    if (event.channel == SpeechKeys.channel ||
        ((event.channel == null || event.channel!.isEmpty) &&
            _isSpeechPayload(event))) {
      _handleSpeechEvent(event);
      return;
    }

    if (event.type != SocketKeys.notification) return;

    final eventType = EWsEventType.fromString(
      event.data?[SocketKeys.type]?.toString() ?? '',
    );
    final message = event.message ?? '';

    debugPrint('🔔 [SocketController] type=$eventType | message="$message"');

    // When IAM roles or access entitlements are revoked or changed, invalidate session so user re-authenticates fresh
    if (eventType == EWsEventType.iamUpdated ||
        eventType == EWsEventType.accessRevoked ||
        eventType == EWsEventType.accessUpdated ||
        eventType == EWsEventType.sessionExpired ||
        eventType == EWsEventType.sessionInvalidated) {
      _showSnackbar(
        event,
        eventType,
        message.isNotEmpty
            ? message
            : 'Your access has changed. Please sign in again.',
      );
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().handleSessionExpired();
      }
      return;
    }

    await _dispatch(event, eventType);
    _showSnackbar(event, eventType, message);
  }

  void _handleSpeechEvent(SocketMessage event) {
    final eventType = ESpeechEventType.fromString(
      event.data?[SocketKeys.type]?.toString() ?? '',
    );
    debugPrint(
      '🎤 [SocketController] speech=$eventType | message="${event.message}"',
    );

    if (Get.isRegistered<SpeechService>()) {
      Get.find<SpeechService>().onSpeechEvent(event, eventType);
    }

    if (eventType == ESpeechEventType.error) {
      final message = event.message ?? '';
      if (message.isNotEmpty) {
        AppSnackbar.error(message);
      }
    }
  }

  bool _isSpeechPayload(SocketMessage event) {
    final dataType = event.data?[SocketKeys.type]?.toString() ?? '';
    return dataType == SpeechKeys.partial ||
        dataType == SpeechKeys.finalPhrase ||
        dataType == SpeechKeys.error;
  }

  // ============================================================
  // SNACKBAR — single source of truth for all socket toasts
  // ============================================================

  void _showSnackbar(
    SocketMessage event,
    EWsEventType eventType,
    String message,
  ) {
    if (message.isEmpty) return;

    switch (eventType) {
      case EWsEventType.paymentSuccess:
      case EWsEventType.subscriptionCreated:
      case EWsEventType.subscriptionResumed:
      case EWsEventType.welcome:
      case EWsEventType.assetCompressed:
      case EWsEventType.ttsReady:
      case EWsEventType.recordingCompleted:
      case EWsEventType.atomUpdated:
      case EWsEventType.assetProcessed:
        AppSnackbar.success(message);
        break;

      case EWsEventType.aiResponseReady:
        // Tap was a no-op before — openNotificationRoom exists for this toast.
        AppSnackbar.success(
          message,
          onTap: () => _openAiFromReadySnackbar(event),
        );
        break;

      case EWsEventType.paymentFailed:
      case EWsEventType.subscriptionCanceled:
      case EWsEventType.aiResponseFailed:
      case EWsEventType.assetCompressionFailed:
      case EWsEventType.ttsFailed:
        AppSnackbar.error(message);
        break;

      case EWsEventType.assetCompressing:
      case EWsEventType.signInAlert:
        AppSnackbar.info(message);
        break;

      case EWsEventType.iamUpdated:
      case EWsEventType.accessRevoked:
      case EWsEventType.sessionExpired:
        AppSnackbar.warning(message);
        break;

      default:
        AppSnackbar.info(message);
        break;
    }
  }

  /// Lands on the AI room from an "AI response ready" toast.
  void _openAiFromReadySnackbar(SocketMessage event) {
    final link = event.link?.trim();
    if (link != null && link.isNotEmpty) {
      unawaited(AppRoutes.handleDeepLink(link));
      return;
    }

    final roomId = event.data?[AiKeys.roomId]?.toString();
    final moleculeId = event.data?[CategoryKeys.categoryId]?.toString();
    final ai = AiController.active;

    // Already on chat: switch room in place instead of stacking another /ai.
    if (ai != null && Get.currentRoute == AppRoutes.ai) {
      if (roomId != null && roomId.isNotEmpty) {
        unawaited(
          ai.openNotificationRoom(
            roomId: roomId,
            moleculeId: moleculeId,
          ),
        );
      } else {
        unawaited(ai.loadHistory(ai.currentRoomId.value));
      }
      return;
    }

    AppRoutes.toAi(
      roomId: roomId,
      moleculeId: moleculeId,
    );
  }

  // ============================================================
  // DISPATCH — per-controller data refresh / navigation
  // ============================================================

  Future<void> _dispatch(SocketMessage event, EWsEventType eventType) async {
    // --- Payment ---
    if (Get.isRegistered<PaymentController>()) {
      await Get.find<PaymentController>().onSocketEvent(
        eventType,
        event.message,
      );
    }

    // --- AI (owned by the ai page instance, not a route registration) ---
    final ai = AiController.active;
    if (ai != null) {
      final roomId = event.data?[AiKeys.roomId]?.toString();
      final messageId = event.data?[AiKeys.messageId]?.toString();
      await ai.onSocketEvent(
        eventType,
        roomId,
        messageId: messageId,
      );
    }

    // --- Notification ---
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().onSocketNotification(event);
    }

    // --- Atoms / Molecules ---
    if (eventType == EWsEventType.atomUpdated ||
        eventType == EWsEventType.recordingCompleted ||
        eventType == EWsEventType.assetProcessed) {
      // An open atom-details page reloads itself when ITS atom changes —
      // audio processing finishing lands here, so summary/transcript appear
      // without leaving the page.
      final atomId = event.data?[AtomKeys.atomId]?.toString();
      if (atomId != null &&
          atomId.isNotEmpty &&
          AtomDetailsController.active?.atomId.value == atomId) {
        unawaited(AtomDetailsController.active!.loadAtom());
      }

      // The atom list now lives on the molecule screen; keep it fresh while
      // it is open (Home itself renders molecules, which don't change here).
      MoleculeController.active?.reload();
      // Home's molecule cards show atom counts — keep them in step with the
      // event that just changed an atom. Expanded molecules also reload
      // their inline atom rows.
      Get.find<CategoryService>().refresh();
      if (Get.isRegistered<HomeController>()) {
        unawaited(Get.find<HomeController>().refreshExpandedMolecules());
      }
    }
  }
}
