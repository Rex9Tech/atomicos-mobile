import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rexone_mobile/config/config.dart';
import 'package:rexone_mobile/services/services.dart';

import '../data/models/models.dart';
import '../services/home.service.dart';

class HomeController extends GetxController {
  final VersionService _version = Get.find<VersionService>();
  final HomeService _home = Get.find<HomeService>();

  final RxString selectedFilter = 'All'.obs;
  final RxString previewState = 'content'.obs;

  final RxList<AtomModel> atoms = <AtomModel>[].obs;
  final RxBool isLoadingAtoms = false.obs;
  final RxBool hasAtomsError = false.obs;

  bool get isLoading => previewState.value == 'loading';
  bool get isEmpty => previewState.value == 'empty';
  bool get isError => previewState.value == 'error';

  @override
  void onInit() {
    super.onInit();
    if (Get.testMode) return;
    reportUserVersion();
    loadAtoms();
  }

  Future<void> reportUserVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.isNotEmpty
          ? info.version
          : AppConfig.appVersion;
      final versionCode = int.tryParse(info.buildNumber) ?? 0;
      await _version.reportUserVersion(
        version: version,
        versionCode: versionCode,
      );
    } catch (error) {
      debugPrint('Error: $error');
    }
  }

  Future<void> loadAtoms({String? search}) async {
    isLoadingAtoms.value = true;
    hasAtomsError.value = false;
    try {
      final result = await _home.getAtoms(limit: 20, search: search);
      atoms.assignAll(result.records);
    } catch (error) {
      debugPrint('HomeController.loadAtoms error: $error');
      hasAtomsError.value = true;
    } finally {
      isLoadingAtoms.value = false;
    }
  }

  void selectFilter(String value) {
    selectedFilter.value = value;
  }

  void setPreviewState(String value) {
    previewState.value = value;
  }
}
