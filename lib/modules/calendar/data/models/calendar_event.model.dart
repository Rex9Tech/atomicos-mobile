import 'package:rexone_mobile/constants/constants.dart';

class CalendarEventModel {
  final String id;
  final String title;
  final String? startAt;
  final String? endAt;
  final String? description;
  final String status;
  final String createdAt;
  final String updatedAt;

  const CalendarEventModel({
    required this.id,
    required this.title,
    this.startAt,
    this.endAt,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json[ApiKeys.id]?.toString() ?? '',
      title: json[CalendarKeys.title]?.toString() ?? '',
      startAt: json[CalendarKeys.startAt]?.toString(),
      endAt: json[CalendarKeys.endAt]?.toString(),
      description: json[CalendarKeys.description]?.toString(),
      status: json[CalendarKeys.status]?.toString() ?? 'scheduled',
      createdAt: json[CalendarKeys.createdAt]?.toString() ?? '',
      updatedAt: json[CalendarKeys.updatedAt]?.toString() ?? '',
    );
  }
}
