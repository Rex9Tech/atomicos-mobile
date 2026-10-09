import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/api.service.dart';

import '../data/models/models.dart';

class HomeService extends GetxService {
  late final ApiService _api;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
  }

  /// GET /v1/atoms — recent list with optional search/filter/pagination.
  Future<PaginatedResponse<AtomModel>> getAtoms({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? categoryId,
  }) async {
    final query = <String, dynamic>{};
    if (page != null) query[ApiKeys.page] = page.toString();
    if (limit != null) query[ApiKeys.limit] = limit.toString();
    if (search != null && search.isNotEmpty) query[AtomKeys.search] = search;
    if (status != null && status.isNotEmpty) query[AtomKeys.status] = status;
    if (categoryId != null && categoryId.isNotEmpty) {
      query[CategoryKeys.categoryId] = categoryId;
    }

    final response = await _api.get(
      ServerRoutes.atoms,
      query: query,
      // Silent: the home surface renders its own skeleton, and socket-driven
      // refreshes (atom_updated etc.) must never flash a blocking overlay.
      showLoading: false,
    );
    return _api.parsePaginatedResponse<AtomModel>(
      response,
      (data) => AtomModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  /// GET /v1/atoms/:id — single atom.
  Future<ApiResponse<AtomModel>> getAtom(String id) async {
    final response = await _api.get(
      ServerRoutes.atomDetail(id),
      // Silent: the details surface has its own states; reloading the atom
      // after an upload must not cover the page with the global scrim.
      showLoading: false,
    );
    return _api.parseResponse<AtomModel>(response, (data) {
      final record = data is Map && data[AtomKeys.atom] is Map
          ? data[AtomKeys.atom]
          : data;
      return ApiHelper.parseRecord<AtomModel>(record, AtomModel.fromJson) ??
          AtomModel.fromJson(const {});
    });
  }

  /// POST /v1/atoms/:id/assets — attach an already-uploaded asset to the atom.
  Future<ApiResponse<AtomAssetModel>> attachAsset({
    required String atomId,
    required String assetId,
  }) async {
    final response = await _api.post(
      ServerRoutes.atomAssets(atomId),
      {AtomKeys.assetId: assetId},
      showLoading: false,
    );
    return _api.parseResponse<AtomAssetModel>(response, (data) {
      final record = data is Map && data[AssetKeys.asset] is Map
          ? data[AssetKeys.asset]
          : data;
      return ApiHelper.parseRecord<AtomAssetModel>(
            record,
            AtomAssetModel.fromJson,
          ) ??
          AtomAssetModel.fromJson(const {});
    });
  }

  /// PUT /v1/atoms/:id — rename an atom.
  Future<ApiResponse<AtomModel>> renameAtom({
    required String atomId,
    required String title,
  }) async {
    final response = await _api.put(
      ServerRoutes.atomDetail(atomId),
      {
        AtomKeys.atom: {AtomKeys.title: title},
      },
      showLoading: false,
    );
    return _api.parseResponse<AtomModel>(response, (data) {
      final record = data is Map && data[AtomKeys.atom] is Map
          ? data[AtomKeys.atom]
          : data;
      return ApiHelper.parseRecord<AtomModel>(record, AtomModel.fromJson) ??
          AtomModel.fromJson(const {});
    });
  }

  /// PUT /v1/atoms/:id — sets (or clears, with a null [categoryId]) this
  /// atom's category. Explicit null is sent so the server sees the change.
  Future<ApiResponse<AtomModel>> setCategory({
    required String atomId,
    required String? categoryId,
  }) async {
    final response = await _api.put(
      ServerRoutes.atomDetail(atomId),
      {
        AtomKeys.atom: {CategoryKeys.categoryId: categoryId},
      },
      showLoading: false,
    );
    return _api.parseResponse<AtomModel>(response, (data) {
      final record = data is Map && data[AtomKeys.atom] is Map
          ? data[AtomKeys.atom]
          : data;
      return ApiHelper.parseRecord<AtomModel>(record, AtomModel.fromJson) ??
          AtomModel.fromJson(const {});
    });
  }

  /// PUT /v1/atoms/:id — sets (or clears, with a null [meetingAt]) this
  /// atom's meeting date. Explicit null is sent so the server sees the
  /// clear; nothing touches the device calendar.
  Future<ApiResponse<AtomModel>> setMeetingDate({
    required String atomId,
    required String? meetingAt,
  }) async {
    final response = await _api.put(
      ServerRoutes.atomDetail(atomId),
      {
        AtomKeys.atom: {AtomKeys.meetingAt: meetingAt},
      },
      showLoading: false,
    );
    return _api.parseResponse<AtomModel>(response, (data) {
      final record = data is Map && data[AtomKeys.atom] is Map
          ? data[AtomKeys.atom]
          : data;
      return ApiHelper.parseRecord<AtomModel>(record, AtomModel.fromJson) ??
          AtomModel.fromJson(const {});
    });
  }

  /// DELETE /v1/atoms/:id — soft-removes the atom from the user's library.
  Future<ApiResponse<dynamic>> deleteAtom(String atomId) async {
    final response = await _api.delete(
      ServerRoutes.atomDetail(atomId),
      showLoading: false,
    );
    return _api.parseResponse(response, (data) => data);
  }
}
