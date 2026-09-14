import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/app.routes.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../ai/services/ai.service.dart';
import '../../home/data/models/models.dart';
import '../data/requests/requests.dart';
import '../services/atom_create.service.dart';

class AtomCreateController extends GetxController {
  final AtomCreateService _service = Get.find<AtomCreateService>();
  final MediaService _media = Get.find<MediaService>();
  final AiService _ai = Get.find<AiService>();

  final RxString selectedMode = 'import'.obs;
  final RxString importStage = 'youtube'.obs;
  final RxString noteStage = 'draft'.obs;
  final RxString shareStage = 'preview'.obs;
  final RxnString pickedUploadPath = RxnString();
  final RxnString pickedUploadName = RxnString();
  final RxBool isSubmitting = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isUploading = false.obs;
  final RxString urlText = ''.obs;
  final RxBool isGeneratingSummary = false.obs;
  final RxBool isExtractingTasks = false.obs;
  final RxnString noteSummary = RxnString();
  final RxList<String> noteTaskItems = <String>[].obs;
  final urlController = TextEditingController();
  final shareTextController = TextEditingController();
  final noteController = TextEditingController();
  final meetingLinkController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    urlController.addListener(() => urlText.value = urlController.text);
    final args = Get.arguments;
    if (args is Map) {
      if (args['mode'] != null) {
        selectedMode.value = args['mode'].toString();
      }
      // OS share-sheet handoff: shared text → share mode, prefilled.
      final shareText = args['share_text']?.toString();
      if (shareText != null && shareText.isNotEmpty) {
        shareTextController.text = shareText;
      }
      // OS share-sheet handoff: shared file → upload mode, prefilled.
      final shareFile = args['share_file']?.toString();
      if (shareFile != null && shareFile.isNotEmpty) {
        pickedUploadPath.value = shareFile;
        pickedUploadName.value = shareFile.split('/').last;
        importStage.value = 'upload';
      }
    }
  }

  @override
  void onClose() {
    urlController.dispose();
    shareTextController.dispose();
    noteController.dispose();
    meetingLinkController.dispose();
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
    isUploading.value = true;
    uploadProgress.value = 0.0;
    try {
      final upload = await _media.uploadImage(
        filePath: pickedUploadPath.value!,
        filename: pickedUploadName.value,
        folder: 'atoms',
        showLoading: false,
        uploadProgress: (percent) {
          uploadProgress.value = percent / 100.0;
        },
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
      isUploading.value = false;
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

  /// POST /v1/ai/summarize — real AI summary of the drafted note.
  Future<void> generateNoteSummary() async {
    final note = noteController.text.trim();
    if (note.isEmpty) {
      AppSnackbar.error('Note is empty');
      return;
    }
    if (isGeneratingSummary.value) return;
    isGeneratingSummary.value = true;
    try {
      final result = await _ai.summarize(note);
      if (result.success) {
        final summary = (result.data?['summary'] ?? '').toString().trim();
        noteSummary.value = summary.isEmpty ? null : summary;
        if (summary.isEmpty) AppSnackbar.error('No summary returned');
      } else {
        AppSnackbar.error(result.error ?? result.message);
      }
    } catch (e) {
      AppSnackbar.error('Failed: $e');
    } finally {
      isGeneratingSummary.value = false;
    }
  }

  /// POST /v1/ai/tasks — real task extraction from the drafted note.
  Future<void> extractNoteTasks() async {
    final note = noteController.text.trim();
    if (note.isEmpty) {
      AppSnackbar.error('Note is empty');
      return;
    }
    if (isExtractingTasks.value) return;
    isExtractingTasks.value = true;
    try {
      final result = await _ai.generateTasks(note);
      if (result.success) {
        noteTaskItems.clear();
        final tasks = result.data?['tasks'];
        if (tasks is List) {
          for (final t in tasks) {
            final title = t is Map
                ? (t['title'] ?? '').toString().trim()
                : t.toString().trim();
            if (title.isNotEmpty) noteTaskItems.add(title);
          }
        }
        if (noteTaskItems.isEmpty) AppSnackbar.error('No tasks returned');
      } else {
        AppSnackbar.error(result.error ?? result.message);
      }
    } catch (e) {
      AppSnackbar.error('Failed: $e');
    } finally {
      isExtractingTasks.value = false;
    }
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
