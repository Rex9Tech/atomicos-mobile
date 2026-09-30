import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../home/data/models/models.dart';
import '../../home/services/home.service.dart';

class AtomDetailsController extends GetxController {
  final HomeService _home = Get.find<HomeService>();
  final MediaService _media = Get.find<MediaService>();
  final CategoryService _categories = Get.find<CategoryService>();
  final AudioPlayer _player = AudioPlayer();

  final RxnString atomId = RxnString();
  final Rxn<AtomModel> atom = Rxn<AtomModel>();
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxInt activeTab = 0.obs; // 0 Summary · 1 Transcript · 2 Note · 3 Assets

  // ===== Recording playback (the atom's source audio) =====
  final RxBool isPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxnString audioUrl = RxnString();

  // ===== Supporting files =====
  final RxBool isUploadingAsset = false.obs;

  // ===== Meeting date (device calendar sync) =====
  final Rxn<DateTime> meetingAt = Rxn<DateTime>();
  final RxBool isSavingDate = false.obs;

  /// The atom's persisted event in the device calendar, when one exists.
  final Rxn<CalendarEventLink> calendarLink = Rxn<CalendarEventLink>();

  /// Supporting files — the raw source recording is excluded (it lives in the
  /// player card instead of the file list).
  List<AtomAssetModel> get attachments => _allAssets
      .where((asset) => !asset.isSourceRecording)
      .toList(growable: false);

  AtomAssetModel? get sourceAudio {
    for (final asset in _allAssets) {
      if (asset.isSourceRecording && asset.url.isNotEmpty) return asset;
    }
    return null;
  }

  List<AtomAssetModel> get _allAssets =>
      atom.value?.assets ?? const <AtomAssetModel>[];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final id = args is Map
        ? args['atom_id']?.toString()
        : (args is String ? args : null);
    if (id != null && id.isNotEmpty) {
      atomId.value = id;
      loadAtom();
    } else {
      hasError.value = true;
    }

    // The category chip / picker need the current user's list — silent
    // refresh keeps whatever is already loaded on failure.
    unawaited(_categories.refresh());

    _player.playingStream.listen((value) => isPlaying.value = value);
    _player.positionStream.listen((value) => position.value = value);
    _player.durationStream.listen(
      (value) => duration.value = value ?? Duration.zero,
    );
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }

  Future<void> loadAtom() async {
    final id = atomId.value;
    if (id == null) return;

    isLoading.value = true;
    hasError.value = false;
    try {
      final result = await _home.getAtom(id);
      if (result.success && result.data != null) {
        atom.value = result.data;
        _syncAudioSource();
        resolveMeetingDate();
        _loadCalendarLink();
      } else {
        hasError.value = true;
      }
    } catch (error) {
      debugPrint('📝 [AtomDetailsController] loadAtom error: $error');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int index) => activeTab.value = index;

  /// PUT /v1/atoms/:id — rename this atom from the details menu.
  Future<bool> renameAtom(String title) async {
    final id = atomId.value;
    final clean = title.trim();
    if (id == null || id.isEmpty || clean.isEmpty) return false;
    try {
      final result = await _home.renameAtom(atomId: id, title: clean);
      if (result.success && result.data != null) {
        atom.value = result.data;
        _syncAudioSource();
        AppSnackbar.success('Renamed');
        return true;
      }
      AppSnackbar.error(result.error ?? 'Could not rename this atom.');
    } catch (error) {
      debugPrint('📝 [AtomDetailsController] rename error: $error');
      AppSnackbar.error('Could not rename this atom.');
    }
    return false;
  }

  /// PUT /v1/atoms/:id — sets (or clears, with null) this atom's category
  /// from the details menu / category chip.
  Future<bool> updateCategory(String? categoryId) async {
    final id = atomId.value;
    if (id == null || id.isEmpty) return false;
    try {
      final result = await _home.setCategory(
        atomId: id,
        categoryId: categoryId,
      );
      if (result.success && result.data != null) {
        atom.value = result.data;
        AppSnackbar.success(AppLocales.category.updated.tr);
        return true;
      }
      AppSnackbar.error(result.error ?? 'Could not update the category.');
    } catch (error) {
      debugPrint('🏷️ [AtomDetailsController] category error: $error');
      AppSnackbar.error('Could not update the category.');
    }
    return false;
  }

  /// Meeting date shown on the details header. The device calendar owns the
  /// event once synced; otherwise this resolves from the atom's own date.
  void resolveMeetingDate() {
    meetingAt.value = _fallbackMeetingDate();
  }

  DateTime? _fallbackMeetingDate() {
    final iso = atom.value?.createdAt;
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }

  /// Restores the persisted device-calendar link for this atom — once an
  /// event exists, its date is the source of truth for the chip.
  void _loadCalendarLink() {
    if (!Get.isRegistered<DeviceCalendarService>()) return;
    final id = atom.value?.id ?? '';
    if (id.isEmpty) return;
    final link = Get.find<DeviceCalendarService>().linkFor(id);
    calendarLink.value = link;
    if (link != null) meetingAt.value = link.date.toLocal();
  }

  /// Writes the meeting into the DEVICE calendar — silently, keeping one
  /// event per atom in sync on every later edit. When access was refused it
  /// falls back to the calendar app's prefilled insert screen.
  Future<CalendarSyncResult?> saveMeetingDate(DateTime value) async {
    final atomId = atom.value?.id ?? '';
    if (atomId.isEmpty) return null;
    final title = (atom.value?.title ?? '').trim();
    final safeTitle = title.isEmpty ? 'AtomicOS meeting' : title;

    isSavingDate.value = true;
    try {
      final service = Get.find<DeviceCalendarService>();
      final result = await service.syncMeeting(
        atomId: atomId,
        title: safeTitle,
        start: value,
      );
      if (result == CalendarSyncResult.synced) {
        meetingAt.value = value;
        calendarLink.value = service.linkFor(atomId);
        AppSnackbar.success(AppLocales.calendar.addedToCalendar.tr);
      } else if (result == CalendarSyncResult.permissionDenied) {
        // No provider access — hand off to the calendar app instead.
        final opened = await service.addEvent(
          title: safeTitle,
          start: value,
          end: value.add(const Duration(hours: 1)),
        );
        if (!opened) {
          AppSnackbar.error(AppLocales.calendar.syncFailed.tr);
          return result;
        }
        meetingAt.value = value;
        AppSnackbar.info(AppLocales.calendar.saveInCalendarApp.tr);
      } else if (result == CalendarSyncResult.needCalendar) {
        AppSnackbar.warning(AppLocales.calendar.noWritableCalendar.tr);
      } else {
        AppSnackbar.error(AppLocales.calendar.syncFailed.tr);
      }
      return result;
    } catch (error) {
      debugPrint('📅 [AtomDetailsController] saveMeetingDate error: $error');
      AppSnackbar.error(AppLocales.calendar.syncFailed.tr);
      return CalendarSyncResult.failed;
    } finally {
      isSavingDate.value = false;
    }
  }

  /// Removes this atom's event from the device calendar.
  Future<void> removeMeetingFromCalendar() async {
    final atomId = atom.value?.id ?? '';
    if (atomId.isEmpty) return;
    final removed = await Get.find<DeviceCalendarService>().removeMeeting(atomId);
    if (removed) {
      calendarLink.value = null;
      AppSnackbar.success(AppLocales.calendar.removedFromCalendar.tr);
    } else {
      AppSnackbar.error(AppLocales.calendar.syncFailed.tr);
    }
  }

  /// Moves the synced meeting into another device calendar.
  Future<void> moveMeetingToCalendar(DeviceCalendar calendar) async {
    final service = Get.find<DeviceCalendarService>();
    await service.setTargetCalendar(calendar);
    final atomId = atom.value?.id ?? '';
    if (atomId.isEmpty) return;
    if (calendarLink.value != null) {
      await service.removeMeeting(atomId);
      calendarLink.value = null;
    }
    final date = meetingAt.value;
    if (date != null) await saveMeetingDate(date);
  }

  /// Keeps the player's source url + duration in sync with the loaded atom.
  void _syncAudioSource() {
    final asset = sourceAudio;
    final url = asset?.url ?? '';
    if (audioUrl.value != url) {
      audioUrl.value = url.isEmpty ? null : url;
    }
    final secs = atom.value?.durationSecs ?? 0;
    if (!isPlaying.value && _player.position == Duration.zero && secs > 0) {
      duration.value = Duration(seconds: secs);
    }
  }

  // ===== Playback =====

  Future<void> togglePlayback() async {
    final url = audioUrl.value;
    if (url == null || url.isEmpty) return;
    try {
      if (_player.playing) {
        await _player.pause();
        return;
      }
      if (_player.audioSource == null) {
        await _player.setAudioSource(_atomAudioSource(url));
      }
      unawaited(_player.play());
    } catch (error) {
      debugPrint('▶️ [AtomDetailsController] playback error: $error');
      AppSnackbar.error('Could not play this recording');
    }
  }

  /// just_audio_background (initialized in main) requires every audio source to
  /// carry a MediaItem tag — an untagged source (plain `setUrl`) fails with
  /// "type 'Null' is not a subtype of type 'MediaItem'" and the recording never
  /// plays. That was the atom-details play bug.
  AudioSource _atomAudioSource(String url) {
    final title = (atom.value?.title ?? '').trim();
    return AudioSource.uri(
      Uri.parse(url),
      tag: MediaItem(
        id: atomId.value ?? url,
        title: title.isEmpty ? 'Recording' : title,
        album: 'AtomicOS',
      ),
    );
  }

  Future<void> skip(int seconds) async {
    if (audioUrl.value == null) return;
    final total = duration.value;
    var target = _player.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (total > Duration.zero && target > total) target = total;
    await _player.seek(target);
  }

  // ===== Supporting files =====

  /// Picks a file, uploads it, then attaches it to this atom
  /// (`POST /v1/media/upload` → `POST /v1/atoms/:id/assets`).
  Future<void> addAttachment() async {
    if (isUploadingAsset.value) return;
    final id = atomId.value;
    if (id == null || id.isEmpty) return;

    final picked = await FilePickerPlatform.instance.pickFile(
      type: FileType.any,
    );
    if (picked == null) return;
    final path = picked.path;
    if (path == null || path.isEmpty) {
      AppSnackbar.info('No file path available');
      return;
    }

    isUploadingAsset.value = true;
    try {
      final upload = await _media.uploadImage(
        filePath: path,
        filename: picked.name,
        type: AssetKeys.typeAttachment,
        folder: 'atoms',
        showLoading: false,
      );
      final assetId = upload.data?.id;
      if (!upload.success || assetId == null || assetId.isEmpty) {
        AppSnackbar.error('Upload failed. Please try again.');
        return;
      }

      final attached = await _home.attachAsset(atomId: id, assetId: assetId);
      if (!attached.success) {
        AppSnackbar.error('Could not attach this file.');
        return;
      }

      await loadAtom();
      AppSnackbar.success('${picked.name} added');
    } catch (error) {
      debugPrint('📎 [AtomDetailsController] addAttachment error: $error');
      AppSnackbar.error('Could not add the file. Please try again.');
    } finally {
      isUploadingAsset.value = false;
    }
  }
}
