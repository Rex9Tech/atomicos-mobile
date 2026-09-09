import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/api.service.dart';

import '../../home/data/models/models.dart';
import '../data/requests/requests.dart';

class AtomCreateService extends GetxService {
  late final ApiService _api;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
  }

  /// POST /v1/atoms/from-note
  Future<ApiResponse<AtomModel>> createFromNote(
    AtomFromNoteRequest request,
  ) async {
    return _create(ServerRoutes.atomFromNote, request.toJson());
  }

  /// POST /v1/atoms/from-url
  Future<ApiResponse<AtomModel>> createFromUrl(
    AtomFromUrlRequest request,
  ) async {
    return _create(ServerRoutes.atomFromUrl, request.toJson());
  }

  /// POST /v1/atoms/from-asset (asset already uploaded via MediaService)
  Future<ApiResponse<AtomModel>> createFromAsset(
    AtomFromAssetRequest request,
  ) async {
    return _create(ServerRoutes.atomFromAsset, request.toJson());
  }

  Future<ApiResponse<AtomModel>> _create(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await _api.post(url, body, showLoading: false);
    return _api.parseResponse<AtomModel>(response, (data) {
      final record = data is Map && data[AtomKeys.atom] is Map
          ? data[AtomKeys.atom]
          : data;
      return ApiHelper.parseRecord<AtomModel>(record, AtomModel.fromJson) ??
          AtomModel.fromJson(const {});
    });
  }
}
