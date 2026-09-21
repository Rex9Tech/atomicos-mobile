// lib/services/category.service.dart
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/helpers/helpers.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/home/data/models/category.model.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/api.service.dart';

/// Shared atom-category taxonomy.
///
/// Everyone reads it (home chips, create-flow picker); only admins create or
/// delete (via the settings → Categories screen). All calls are silent —
/// surfaces render whatever is already loaded and refresh in place.
class CategoryService extends GetxService {
  late final ApiService _api;

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isAdmin = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
  }

  /// GET /v1/categories
  Future<ApiResponse<List<CategoryModel>>> list() async {
    final response = await _api.get(
      ServerRoutes.categories,
      showLoading: false,
    );
    return _api.parseResponse<List<CategoryModel>>(
      response,
      (data) => ApiHelper.parseList<CategoryModel>(
        data,
        CategoryModel.fromJson,
      ),
    );
  }

  /// Silent refresh into [categories] — chips keep their last state on failure.
  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await list();
      if (result.success) {
        categories.assignAll(result.data ?? const []);
        hasLoaded.value = true;
      }
    } catch (_) {
      // Best-effort.
    } finally {
      isLoading.value = false;
    }
  }

  /// GET /v1/users/current/iam — gates the admin-only management screen.
  /// Cached: subsequent calls are no-ops unless [force] is set.
  bool _iamLoaded = false;
  Future<void> loadIam({bool force = false}) async {
    if (_iamLoaded && !force) return;
    try {
      final response = await _api.get(
        ServerRoutes.currentUserIam,
        showLoading: false,
      );
      final data = response.body is Map
          ? Map<String, dynamic>.from(response.body as Map)[ApiKeys.data]
          : null;
      final payload = data is Map ? Map<String, dynamic>.from(data) : null;
      isAdmin.value = payload?[CategoryKeys.isAdmin] == true;
      _iamLoaded = true;
    } catch (_) {
      isAdmin.value = false;
    }
  }

  /// POST /v1/categories — the CURRENT USER's own list (every user manages
  /// their own; no admin gate).
  Future<ApiResponse<CategoryModel>> create(String name) async {
    final response = await _api.post(
      ServerRoutes.categories,
      {
        CategoryKeys.category: {CategoryKeys.name: name},
      },
      showLoading: false,
    );
    return _api.parseResponse<CategoryModel>(response, (data) {
      final record = data is Map && data[CategoryKeys.category] is Map
          ? data[CategoryKeys.category]
          : data;
      return ApiHelper.parseRecord<CategoryModel>(
            record,
            CategoryModel.fromJson,
          ) ??
          const CategoryModel(id: '', name: '');
    });
  }

  /// DELETE /v1/categories/:id (soft discard server-side).
  Future<ApiResponse<CategoryModel>> delete(String id) async {
    final response = await _api.delete(
      ServerRoutes.category(id),
      showLoading: false,
    );
    return _api.parseResponse<CategoryModel>(
      response,
      (_) => CategoryModel(id: id, name: ''),
    );
  }
}
