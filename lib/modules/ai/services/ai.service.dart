// lib/modules/ai/services/ai.service.dart
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/helpers/api.helper.dart';
import 'package:rexone_mobile/services/api.service.dart';

import '../requests/requests.dart';
import '../models/models.dart';

class AiService extends GetxService {
  late final ApiService _api;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
  }

  // ============================================================
  // CHAT
  // ============================================================
  Future<ApiResponse<AiMessageModel>> chat(AiChatRequest request) async {
    final response = await _api.post(
      ServerRoutes.aiChat,
      request.toJson(),
      showLoading: false,
    );
    return _api.parseRecord<AiMessageModel>(
      response,
      AiMessageModel.fromJson,
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================
  Future<PaginatedResponse<AiMessageModel>> getHistory({
    String? roomId,
  }) async {
    final query = <String, dynamic>{};
    if (roomId != null && roomId.isNotEmpty) query[AiKeys.roomId] = roomId;
    final response = await _api.get(
      ServerRoutes.aiHistory,
      query: query,
      // Silent: the chat owns its inline states (thinking bubble / message
      // list). A global blocking scrim on every reload "craps" the chat UI
      // right as the AI response lands.
      showLoading: false,
    );
    return _api.parsePaginatedResponse(
      response,
      AiMessageModel.fromJson,
    );
  }

  Future<ApiResponse<void>> clearHistory({String? roomId}) async {
    final query = <String, dynamic>{};
    if (roomId != null && roomId.isNotEmpty) query[AiKeys.roomId] = roomId;
    final response = await _api.delete(
      ServerRoutes.aiClear,
      query: query,
      showLoading: false,
    );
    return _api.parseResponse(response, (data) => data);
  }

  // ============================================================
  // ROOMS
  // ============================================================
  Future<PaginatedResponse<AiRoomModel>> getRooms({int? page, int? limit}) async {
    final query = <String, dynamic>{};
    if (page != null) query[ApiKeys.page] = page.toString();
    if (limit != null) query[ApiKeys.limit] = limit.toString();
    final response = await _api.get(
      ServerRoutes.aiRooms,
      query: query,
      showLoading: false,
    );
    return _api.parsePaginatedResponse<AiRoomModel>(
      response,
      AiRoomModel.fromJson,
    );
  }

  Future<ApiResponse<AiRoomModel>> createRoom(CreateRoomRequest request) async {
    final response = await _api.post(
      ServerRoutes.aiRooms,
      request.toJson(),
      showLoading: false,
    );
    return _api.parseResponse<AiRoomModel>(response, (data) {
      final record = data is Map && data[AiKeys.room] is Map
          ? data[AiKeys.room]
          : data;
      return ApiHelper.parseRecord<AiRoomModel>(record, AiRoomModel.fromJson) ??
          AiRoomModel.fromJson(const {});
    });
  }

  Future<ApiResponse<AiRoomModel>> renameRoom(
    String roomId,
    String title,
  ) async {
    final response = await _api.put(
      ServerRoutes.aiRename,
      {'room_id': roomId, 'title': title},
      showLoading: false,
    );
    return _api.parseResponse<AiRoomModel>(response, (data) {
      final record = data is Map && data[AiKeys.room] is Map
          ? data[AiKeys.room]
          : data;
      return ApiHelper.parseRecord<AiRoomModel>(record, AiRoomModel.fromJson) ??
          AiRoomModel.fromJson(const {});
    });
  }

  Future<ApiResponse<dynamic>> deleteRoom(String roomId) async {
    final response = await _api.delete(
      ServerRoutes.aiDeleteRoom(roomId),
      showLoading: false,
    );
    return _api.parseResponse(response, (data) => data);
  }

  // ============================================================
  // AI ACTIONS (summarize / translate / analyze)
  // ============================================================
  Future<ApiResponse<Map<String, dynamic>>> summarize(String text) async {
    final response = await _api.post(
      ServerRoutes.aiSummarize,
      {'text': text},
      showLoading: false,
    );
    return _api.parseResponse<Map<String, dynamic>>(
      response,
      (data) => data is Map ? Map<String, dynamic>.from(data) : {},
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> translate(
    String text, {
    String language = 'en',
  }) async {
    final response = await _api.post(
      ServerRoutes.aiTranslate,
      {'text': text, 'language': language},
      showLoading: false,
    );
    return _api.parseResponse<Map<String, dynamic>>(
      response,
      (data) => data is Map ? Map<String, dynamic>.from(data) : {},
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> analyze(
    String text, {
    String? type,
  }) async {
    final response = await _api.post(
      ServerRoutes.aiAnalyze,
      {'text': text, if (type != null && type.isNotEmpty) 'type': type},
      showLoading: false,
    );
    return _api.parseResponse<Map<String, dynamic>>(
      response,
      (data) => data is Map ? Map<String, dynamic>.from(data) : {},
    );
  }

  // ============================================================
  // STRUCTURED AI ACTIONS (decisions / tasks / report)
  // ============================================================
  Future<ApiResponse<Map<String, dynamic>>> extractDecisions(
    String text, {
    String? atomId,
  }) =>
      _structured(ServerRoutes.aiDecisions, text, atomId: atomId);

  Future<ApiResponse<Map<String, dynamic>>> generateTasks(
    String text, {
    String? atomId,
  }) =>
      _structured(ServerRoutes.aiTasks, text, atomId: atomId);

  Future<ApiResponse<Map<String, dynamic>>> generateReport(
    String text, {
    String? atomId,
  }) =>
      _structured(ServerRoutes.aiReport, text, atomId: atomId);

  Future<ApiResponse<Map<String, dynamic>>> _structured(
    String url,
    String text, {
    String? atomId,
  }) async {
    final response = await _api.post(
      url,
      {
        'text': text,
        if (atomId != null && atomId.isNotEmpty) 'atom_id': atomId,
      },
      showLoading: false,
    );
    return _api.parseResponse<Map<String, dynamic>>(
      response,
      (data) => data is Map ? Map<String, dynamic>.from(data) : {},
    );
  }
}
