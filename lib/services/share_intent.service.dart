import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rexone_mobile/routes/app.routes.dart';

/// Listens for OS share-sheet intents (Android `ACTION_SEND`) and routes them
/// into the Atom creation flow: text/URL → share mode, media/file → upload mode.
class ShareIntentService extends GetxService {
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  @override
  void onInit() {
    super.onInit();

    // Warm-start: app already running when the user shares into it.
    _subscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleShared, onError: (_) {});

    // Cold-start: the share launched the app. Delay so the router/auth is ready.
    Future.delayed(const Duration(milliseconds: 800), () async {
      try {
        final initial = await ReceiveSharingIntent.instance.getInitialMedia();
        if (initial.isNotEmpty) _handleShared(initial);
      } catch (e) {
        debugPrint('🔗 [ShareIntent] initial media check failed: $e');
      }
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void _handleShared(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    final file = files.first;
    switch (file.type) {
      case SharedMediaType.text:
      case SharedMediaType.url:
        final text = file.path.trim();
        if (text.isNotEmpty) {
          AppRoutes.toAtomCreateShare(text: text);
        }
      case SharedMediaType.image:
      case SharedMediaType.video:
      case SharedMediaType.file:
        if (file.path.isNotEmpty) {
          AppRoutes.toAtomCreateFile(path: file.path);
        }
    }
  }
}
