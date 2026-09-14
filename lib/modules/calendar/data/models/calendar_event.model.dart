import 'package:rexone_mobile/constants/constants.dart';

class CalendarEventModel {
  final String id;
  final String title;
  final String? startAt;
  final String? endAt;
  final String? description;
  final String status;
  final Map<String, dynamic> metadata;
  final String createdAt;
  final String updatedAt;

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.startAt,
    this.endAt,
    this.description,
    required this.status,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Set when the event was created from an atom — links planner rows back
  /// to the atom they belong to.
  String? get atomId => metadata[CalendarKeys.atomId]?.toString();

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json[ApiKeys.id]?.toString() ?? '',
      title: json[CalendarKeys.title]?.toString() ?? '',
      startAt: json[CalendarKeys.startAt]?.toString(),
      endAt: json[CalendarKeys.endAt]?.toString(),
      description: json[CalendarKeys.description]?.toString(),
      status: json[CalendarKeys.status]?.toString() ?? 'scheduled',
      metadata: json[CalendarKeys.metadata] is Map
          ? Map<String, dynamic>.from(json[CalendarKeys.metadata] as Map)
          : const {},
      createdAt: json[CalendarKeys.createdAt]?.toString() ?? '',
      updatedAt: json[CalendarKeys.updatedAt]?.toString() ?? '',
    );
  }
}
