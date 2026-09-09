import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/api.service.dart';

import '../data/models/calendar_event.model.dart';

class CalendarService extends GetxService {
  late final ApiService _api;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
  }

  /// GET /v1/calendar/events
  Future<PaginatedResponse<CalendarEventModel>> getEvents({
    int? page,
    int? limit,
    bool upcoming = false,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query[ApiKeys.page] = page.toString();
    if (limit != null) query[ApiKeys.limit] = limit.toString();
    if (upcoming) query[CalendarKeys.upcoming] = 'true';

    final response = await _api.get(ServerRoutes.calendarEvents, query: query);
    return _api.parsePaginatedResponse<CalendarEventModel>(
      response,
      (data) => CalendarEventModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /v1/calendar/events
  Future<ApiResponse<CalendarEventModel>> createEvent({
    required String title,
    String? startAt,
    String? endAt,
    String? description,
  }) async {
    final response = await _api.post(
      ServerRoutes.calendarEvents,
      {
        CalendarKeys.calendarEvent: {
          CalendarKeys.title: title,
          CalendarKeys.startAt: ?startAt,
          CalendarKeys.endAt: ?endAt,
          CalendarKeys.description: ?description,
        },
      },
      showLoading: false,
    );
    return _parse(response);
  }

  /// GET /v1/calendar/events/:id
  Future<ApiResponse<CalendarEventModel>> getEvent(String id) async {
    final response = await _api.get(ServerRoutes.calendarEventDetail(id));
    return _parse(response);
  }

  ApiResponse<CalendarEventModel> _parse(Response response) {
    return _api.parseResponse<CalendarEventModel>(response, (data) {
      final record = data is Map && data[CalendarKeys.calendarEvent] is Map
          ? data[CalendarKeys.calendarEvent]
          : data;
      return ApiHelper.parseRecord<CalendarEventModel>(
            record,
            CalendarEventModel.fromJson,
          ) ??
          CalendarEventModel.fromJson(const {});
    });
  }
}
