import 'package:rexone_mobile/constants/constants.dart';

class AtomAssetModel {
  final String id;
  final String name;
  final String url;
  final String type;
  final String format;

  const AtomAssetModel({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.format,
  });

  factory AtomAssetModel.fromJson(Map<String, dynamic> json) {
    return AtomAssetModel(
      id: json[ApiKeys.id]?.toString() ?? '',
      name: json[AtomKeys.name]?.toString() ?? '',
      url: json[AtomKeys.url]?.toString() ?? '',
      type: json[AtomKeys.type]?.toString() ?? '',
      format: json[AtomKeys.format]?.toString() ?? '',
    );
  }
}

class AtomModel {
  final String id;
  final String title;
  final String source;
  final String status;
  final int? durationSecs;
  final int? participantsCount;
  final List<dynamic> summaryBlocks;
  final List<dynamic> transcriptSegments;
  final String? note;
  final String? roomId;
  final String? recordingStatus;
  final Map<String, dynamic> metadata;
  final List<AtomAssetModel> assets;
  final String createdAt;
  final String updatedAt;

  const AtomModel({
    required this.id,
    required this.title,
    required this.source,
    required this.status,
    this.durationSecs,
    this.participantsCount,
    this.summaryBlocks = const [],
    this.transcriptSegments = const [],
    this.note,
    this.roomId,
    this.recordingStatus,
    this.metadata = const {},
    this.assets = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory AtomModel.fromJson(Map<String, dynamic> json) {
    final rawAssets = json[AtomKeys.assets];
    final assets = rawAssets is List
        ? rawAssets
            .whereType<Map>()
            .map((e) => AtomAssetModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AtomAssetModel>[];

    return AtomModel(
      id: json[ApiKeys.id]?.toString() ?? '',
      title: json[AtomKeys.title]?.toString() ?? '',
      source: json[AtomKeys.source]?.toString() ?? '',
      status: json[AtomKeys.status]?.toString() ?? '',
      durationSecs: _toInt(json[AtomKeys.durationSecs]),
      participantsCount: _toInt(json[AtomKeys.participantsCount]),
      summaryBlocks: json[AtomKeys.summaryBlocks] is List
          ? List<dynamic>.from(json[AtomKeys.summaryBlocks] as List)
          : const [],
      transcriptSegments: json[AtomKeys.transcriptSegments] is List
          ? List<dynamic>.from(json[AtomKeys.transcriptSegments] as List)
          : const [],
      note: json[AtomKeys.note]?.toString(),
      roomId: json[AtomKeys.roomId]?.toString(),
      recordingStatus: json[AtomKeys.recordingStatus]?.toString(),
      metadata: json[AtomKeys.metadata] is Map
          ? Map<String, dynamic>.from(json[AtomKeys.metadata] as Map)
          : const {},
      assets: assets,
      createdAt: json[AtomKeys.createdAt]?.toString() ?? '',
      updatedAt: json[AtomKeys.updatedAt]?.toString() ?? '',
    );
  }

  static int? _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '');
}
