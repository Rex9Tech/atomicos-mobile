import 'package:rexone_mobile/constants/constants.dart';

class RecordingModel {
  final String id;
  final String title;
  final String status;
  final int? durationSecs;
  final String? startedAt;
  final String? endedAt;
  final String? atomId;
  final String createdAt;
  final String updatedAt;

  const RecordingModel({
    required this.id,
    required this.title,
    required this.status,
    this.durationSecs,
    this.startedAt,
    this.endedAt,
    this.atomId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json[ApiKeys.id]?.toString() ?? '',
      title: json[RecordingKeys.title]?.toString() ?? '',
      status: json[RecordingKeys.status]?.toString() ?? '',
      durationSecs: json[RecordingKeys.durationSecs] is int
          ? json[RecordingKeys.durationSecs] as int
          : int.tryParse(json[RecordingKeys.durationSecs]?.toString() ?? ''),
      startedAt: json[RecordingKeys.startedAt]?.toString(),
      endedAt: json[RecordingKeys.endedAt]?.toString(),
      atomId: json[RecordingKeys.atomId]?.toString(),
      createdAt: json[RecordingKeys.createdAt]?.toString() ?? '',
      updatedAt: json[RecordingKeys.updatedAt]?.toString() ?? '',
    );
  }
}
