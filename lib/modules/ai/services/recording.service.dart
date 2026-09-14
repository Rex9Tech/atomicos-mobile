import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/api.service.dart';

import '../data/models/models.dart';

class RecordingService extends GetxService {
  late final ApiService _api;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
  }

  /// POST /v1/recordings — start a recording session.
  Future<ApiResponse<RecordingModel>> start(String title) async {
    final response = await _api.post(
      ServerRoutes.recordings,
      {RecordingKeys.title: title},
      showLoading: false,
    );
    return _parse(response);
  }

  /// GET /v1/recordings/:id — poll status.
  Future<ApiResponse<RecordingModel>> getRecording(String id) async {
    final response = await _api.get(ServerRoutes.recordingDetail(id));
    return _parse(response);
  }

  /// PATCH /v1/recordings/:id — pause/resume/update (backend also accepts PUT).
  Future<ApiResponse<RecordingModel>> updateRecording(
    String id, {
    String? status,
    int? durationSecs,
  }) async {
    final response = await _api.put(
      ServerRoutes.recordingDetail(id),
      {
        RecordingKeys.recording: {
          RecordingKeys.status: ?status,
          RecordingKeys.durationSecs: ?durationSecs,
        },
      },
      showLoading: false,
    );
    return _parse(response);
  }

  /// POST /v1/recordings/:id/finish — end and turn into an Atom. The live
  /// transcript captured on the device (and any note) ride along so the atom
  /// is created with real content.
  Future<ApiResponse<RecordingModel>> finish(
    String id, {
    int? durationSecs,
    String? transcript,
    String? note,
  }) async {
    final response = await _api.post(
      ServerRoutes.recordingFinish(id),
      {
        RecordingKeys.durationSecs: ?durationSecs,
        RecordingKeys.transcript: ?transcript,
        RecordingKeys.note: ?note,
      },
      showLoading: false,
    );
    return _parse(response);
  }

  ApiResponse<RecordingModel> _parse(Response response) {
    return _api.parseResponse<RecordingModel>(response, (data) {
      final record = data is Map && data[RecordingKeys.recording] is Map
          ? data[RecordingKeys.recording]
          : data;
      return ApiHelper.parseRecord<RecordingModel>(
            record,
            RecordingModel.fromJson,
          ) ??
          RecordingModel.fromJson(const {});
    });
  }
}
