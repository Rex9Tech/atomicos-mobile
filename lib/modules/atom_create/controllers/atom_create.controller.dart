import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/app.routes.dart';

import '../../home/data/models/models.dart';
import '../data/requests/requests.dart';
import '../services/atom_create.service.dart';

class AtomCreateController extends GetxController {
  final AtomCreateService _service = Get.find<AtomCreateService>();

  final RxString selectedMode = 'import'.obs;
  final RxString importStage = 'youtube'.obs;
  final RxString noteStage = 'draft'.obs;
  final RxString shareStage = 'preview'.obs;
  final RxBool isSubmitting = false.obs;
  final urlController = TextEditingController();
  final noteController = TextEditingController(
    text:
        'Scientists believe the Solar System formed out of a gas and dust cloud as the solar nebula.',
  );

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['mode'] != null) {
      selectedMode.value = args['mode'].toString();
    }
  }

  @override
  void onClose() {
    urlController.dispose();
    noteController.dispose();
    super.onClose();
  }

  void selectMode(String value) {
    selectedMode.value = value;
    if (value == 'import' && importStage.value.isEmpty) {
      importStage.value = 'youtube';
    }
  }

  void selectImportStage(String value) {
    importStage.value = value;
  }

  void selectNoteStage(String value) {
    noteStage.value = value;
  }

  void selectShareStage(String value) {
    shareStage.value = value;
  }

  /// POST /v1/atoms/from-note — creates an Atom from the typed note.
  Future<void> createFromNote() async {
    final note = noteController.text.trim();
    if (note.isEmpty) {
      AppSnackbar.error('Note is empty');
      return;
    }
    await _submit(
      () => _service.createFromNote(
        AtomFromNoteRequest(
          title: note.length > 50 ? note.substring(0, 50) : note,
          note: note,
        ),
      ),
    );
  }

  /// POST /v1/atoms/from-url — creates an Atom from a YouTube/link URL.
  Future<void> createFromUrl() async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      AppSnackbar.error('URL is empty');
      return;
    }
    await _submit(
      () => _service.createFromUrl(AtomFromUrlRequest(url: url)),
    );
  }

  /// POST /v1/atoms/from-asset — creates an Atom around an uploaded asset.
  Future<void> createFromAsset(String assetId) async {
    if (assetId.isEmpty) {
      AppSnackbar.error('Asset is missing');
      return;
    }
    await _submit(
      () => _service.createFromAsset(AtomFromAssetRequest(assetId: assetId)),
    );
  }

  Future<void> _submit(Future<ApiResponse<AtomModel>> Function() action) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final result = await action();
      if (result.success) {
        AppSnackbar.success(result.message);
        AppRoutes.toHome();
      } else {
        AppSnackbar.error(result.error ?? result.message);
      }
    } catch (e) {
      AppSnackbar.error('Failed: $e');
    } finally {
      isSubmitting.value = false;
    }
  }
}
