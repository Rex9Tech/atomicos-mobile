import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../home/data/models/models.dart';
import '../data/requests/requests.dart';
import '../services/atom_create.service.dart';

class AtomCreateController extends GetxController {
  final AtomCreateService _service = Get.find<AtomCreateService>();
  final MediaService _media = Get.find<MediaService>();

  final RxString selectedMode = 'import'.obs;
  final RxString importStage = 'youtube'.obs;
  final RxString noteStage = 'draft'.obs;
  final RxString shareStage = 'preview'.obs;
  final RxnString pickedUploadPath = RxnString();
  final RxnString pickedUploadName = RxnString();
  final RxBool isSubmitting = false.obs;
  final urlController = TextEditingController();
  final shareTextController = TextEditingController(
    text:
        'Product launch retrospective\n\n- Align launch checklist with design review\n- Confirm owners for the next sprint checkpoint\n- Share customer feedback summary with the team',
  );
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
    shareTextController.dispose();
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

  Future<void> pickUploadAsset() async {
    try {
      final file = await FilePickerPlatform.instance.pickFile(
        type: FileType.any,
      );
      if (file == null) return;
      if (file.path == null || file.path!.isEmpty) {
        AppSnackbar.info('No file path available');
        return;
      }
      pickedUploadPath.value = file.path;
      pickedUploadName.value = file.name;
      AppSnackbar.info('Attached ${file.name}');
    } catch (e) {
      AppSnackbar.error('Could not open file picker: $e');
    }
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
    await _submit(() => _service.createFromUrl(AtomFromUrlRequest(url: url)));
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

  Future<void> createFromUpload() async {
    if (isSubmitting.value) return;
    final path = pickedUploadPath.value;
    if (path == null || path.isEmpty) {
      await pickUploadAsset();
      if ((pickedUploadPath.value ?? '').isEmpty) return;
    }

    isSubmitting.value = true;
    try {
      final upload = await _media.uploadImage(
        filePath: pickedUploadPath.value!,
        filename: pickedUploadName.value,
        folder: 'atoms',
      );

      if (!upload.success) {
        AppSnackbar.error(upload.error ?? upload.message);
        return;
      }

      final assetId = upload.data?.asset.id ?? '';
      if (assetId.isEmpty) {
        AppSnackbar.error('Upload finished without an asset id');
        return;
      }

      final result = await _service.createFromAsset(
        AtomFromAssetRequest(assetId: assetId),
      );
      if (result.success) {
        AppSnackbar.success(result.message);
        final atomId = result.data?.id ?? '';
        if (atomId.isNotEmpty) {
          AppRoutes.toAtomDetail(atomId: atomId);
        } else {
          AppRoutes.toHome();
        }
      } else {
        AppSnackbar.error(result.error ?? result.message);
      }
    } catch (e) {
      AppSnackbar.error('Failed: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> createFromShare() async {
    final text = shareTextController.text.trim();
    if (text.isEmpty) {
      AppSnackbar.error('Shared text is empty');
      return;
    }

    await _submit(
      () => _service.createFromShare(
        AtomFromShareRequest(
          title: text.length > 50 ? text.substring(0, 50) : text,
          text: text,
        ),
      ),
    );
  }

  Future<void> _submit(Future<ApiResponse<AtomModel>> Function() action) async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final result = await action();
      if (result.success) {
        AppSnackbar.success(result.message);
        final atomId = result.data?.id ?? '';
        if (atomId.isNotEmpty) {
          AppRoutes.toAtomDetail(atomId: atomId);
        } else {
          AppRoutes.toHome();
        }
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
