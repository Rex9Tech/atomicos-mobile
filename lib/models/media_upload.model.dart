// lib/models/media_upload.model.dart
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/helpers/helpers.dart';

/// One queued/active/finished background upload.
class MediaUploadModel {
  final String taskId;
  final String name;
  final String displayName;
  final String? type;
  final String folder;
  final int? durationSecs;
  final String state;
  final double progress;
  final String? errorMessage;
  final String? assetId;
  final String? atomId;
  final String followUpType;
  final String? categoryId;
  final String? language;
  final String localPath;
  final String? sourcePath;
  final bool deleteSourceAfter;
  final bool secureRetryDone;
  final DateTime? createdAt;

  const MediaUploadModel({
    required this.taskId,
    required this.name,
    this.displayName = '',
    this.type,
    this.folder = 'atoms',
    this.durationSecs,
    this.state = MediaUploadConstants.stateQueued,
    this.progress = 0,
    this.errorMessage,
    this.assetId,
    this.atomId,
    this.followUpType = MediaUploadConstants.followUpNone,
    this.categoryId,
    this.language,
    this.localPath = '',
    this.sourcePath,
    this.deleteSourceAfter = false,
    this.secureRetryDone = false,
    this.createdAt,
  });

  bool get isActive =>
      state == MediaUploadConstants.stateQueued ||
      state == MediaUploadConstants.stateUploading ||
      state == MediaUploadConstants.stateProcessing;

  bool get isDone => state == MediaUploadConstants.stateDone;

  bool get isFailed => state == MediaUploadConstants.stateFailed;

  bool get needsFollowUp =>
      state == MediaUploadConstants.stateNeedsFollowUp;

  /// Uploaded but its follow-up (atom creation / attach) has not run yet.
  bool get hasUploadedAsset => (assetId ?? '').isNotEmpty;

  MediaUploadModel copyWith({
    String? name,
    String? displayName,
    String? type,
    String? folder,
    int? durationSecs,
    String? state,
    double? progress,
    String? errorMessage,
    String? assetId,
    String? atomId,
    String? followUpType,
    String? categoryId,
    String? language,
    String? localPath,
    String? sourcePath,
    bool? deleteSourceAfter,
    bool? secureRetryDone,
    DateTime? createdAt,
    bool clearErrorMessage = false,
  }) {
    return MediaUploadModel(
      taskId: taskId,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      folder: folder ?? this.folder,
      durationSecs: durationSecs ?? this.durationSecs,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      assetId: assetId ?? this.assetId,
      atomId: atomId ?? this.atomId,
      followUpType: followUpType ?? this.followUpType,
      categoryId: categoryId ?? this.categoryId,
      language: language ?? this.language,
      localPath: localPath ?? this.localPath,
      sourcePath: sourcePath ?? this.sourcePath,
      deleteSourceAfter: deleteSourceAfter ?? this.deleteSourceAfter,
      secureRetryDone: secureRetryDone ?? this.secureRetryDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      MediaUploadConstants.jsonTaskId: taskId,
      MediaUploadConstants.jsonName: name,
      MediaUploadConstants.jsonDisplayName: displayName,
      if ((type ?? '').isNotEmpty) MediaUploadConstants.jsonType: type,
      MediaUploadConstants.jsonFolder: folder,
      if (durationSecs != null)
        MediaUploadConstants.jsonDurationSecs: durationSecs,
      MediaUploadConstants.jsonState: state,
      MediaUploadConstants.jsonProgress: progress,
      if (errorMessage != null && errorMessage!.isNotEmpty)
        MediaUploadConstants.jsonErrorMessage: errorMessage,
      if ((assetId ?? '').isNotEmpty)
        MediaUploadConstants.jsonAssetId: assetId,
      if ((atomId ?? '').isNotEmpty) MediaUploadConstants.jsonAtomId: atomId,
      MediaUploadConstants.jsonFollowUpType: followUpType,
      if ((categoryId ?? '').isNotEmpty)
        MediaUploadConstants.jsonCategoryId: categoryId,
      if ((language ?? '').isNotEmpty)
        MediaUploadConstants.jsonLanguage: language,
      MediaUploadConstants.jsonLocalPath: localPath,
      if ((sourcePath ?? '').isNotEmpty)
        MediaUploadConstants.jsonSourcePath: sourcePath,
      if (deleteSourceAfter)
        MediaUploadConstants.jsonDeleteSourceAfter: true,
      if (secureRetryDone) MediaUploadConstants.jsonSecureRetryDone: true,
      if (createdAt != null)
        MediaUploadConstants.jsonCreatedAt: AppDateTime.toUtcIso(createdAt!),
    };
  }

  factory MediaUploadModel.fromJson(Map<String, dynamic> json) {
    return MediaUploadModel(
      taskId: json[MediaUploadConstants.jsonTaskId]?.toString() ?? '',
      name: json[MediaUploadConstants.jsonName]?.toString() ?? '',
      displayName: json[MediaUploadConstants.jsonDisplayName]?.toString() ??
          json[MediaUploadConstants.jsonName]?.toString() ??
          '',
      type: json[MediaUploadConstants.jsonType]?.toString(),
      folder: json[MediaUploadConstants.jsonFolder]?.toString() ?? 'atoms',
      durationSecs: (json[MediaUploadConstants.jsonDurationSecs] as num?)
          ?.toInt(),
      state: json[MediaUploadConstants.jsonState]?.toString() ??
          MediaUploadConstants.stateQueued,
      progress: (json[MediaUploadConstants.jsonProgress] as num?)
              ?.toDouble() ??
          0,
      errorMessage:
          json[MediaUploadConstants.jsonErrorMessage]?.toString(),
      assetId: json[MediaUploadConstants.jsonAssetId]?.toString(),
      atomId: json[MediaUploadConstants.jsonAtomId]?.toString(),
      followUpType:
          json[MediaUploadConstants.jsonFollowUpType]?.toString() ??
              MediaUploadConstants.followUpNone,
      categoryId: json[MediaUploadConstants.jsonCategoryId]?.toString(),
      language: json[MediaUploadConstants.jsonLanguage]?.toString(),
      localPath: json[MediaUploadConstants.jsonLocalPath]?.toString() ?? '',
      sourcePath: json[MediaUploadConstants.jsonSourcePath]?.toString(),
      deleteSourceAfter:
          json[MediaUploadConstants.jsonDeleteSourceAfter] == true,
      secureRetryDone: json[MediaUploadConstants.jsonSecureRetryDone] == true,
      createdAt: AppDateTime.fromUtc(json[MediaUploadConstants.jsonCreatedAt]),
    );
  }
}
