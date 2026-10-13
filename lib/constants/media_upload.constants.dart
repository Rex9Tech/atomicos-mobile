// lib/constants/media_upload.constants.dart

/// Background upload queue: task group, persisted field names, and states.
/// Mirrors [MediaDownloadConstants] so the media stack stays symmetric.
class MediaUploadConstants {
  const MediaUploadConstants._();

  /// Task group registered with the background downloader for uploads.
  static const uploadTaskGroup = 'media_upload';

  /// Folder (under application support) that holds queued upload copies.
  static const uploadsDirName = 'uploads';

  static const notificationChannelId = 'media_upload';

  // ===== Entry states (persisted) =====
  static const stateQueued = 'queued';
  static const stateUploading = 'uploading';
  static const stateProcessing = 'processing';
  static const stateDone = 'done';
  static const stateFailed = 'failed';
  static const stateNeedsFollowUp = 'needs_follow_up';

  // ===== Follow-up actions that run after a successful upload =====
  static const followUpNone = 'none';
  static const followUpAtomFromAsset = 'atom_from_asset';
  static const followUpAttachToAtom = 'attach_to_atom';

  // ===== Persisted JSON keys =====
  static const jsonTaskId = 'taskId';
  static const jsonName = 'name';
  static const jsonDisplayName = 'displayName';
  static const jsonType = 'type';
  static const jsonFolder = 'folder';
  static const jsonDurationSecs = 'durationSecs';
  static const jsonState = 'state';
  static const jsonProgress = 'progress';
  static const jsonErrorMessage = 'errorMessage';
  static const jsonAssetId = 'assetId';
  static const jsonAtomId = 'atomId';
  static const jsonFollowUpType = 'followUpType';
  static const jsonCategoryId = 'categoryId';
  static const jsonLanguage = 'language';
  static const jsonLocalPath = 'localPath';
  static const jsonSourcePath = 'sourcePath';
  static const jsonDeleteSourceAfter = 'deleteSourceAfter';
  static const jsonSecureRetryDone = 'secureRetryDone';
  static const jsonCreatedAt = 'createdAt';

  static const metaTaskId = 'taskId';
}
