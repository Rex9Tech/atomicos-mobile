import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/home/home.dart';

class AtomDetailsController extends GetxController {
  final HomeService _home = Get.find<HomeService>();

  final RxnString atomId = RxnString();
  final Rxn<AtomModel> atom = Rxn<AtomModel>();
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxInt activeTab = 0.obs; // 0 Summary · 1 Transcript · 2 Note · 3 Assets

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final id = args is Map
        ? args['atom_id']?.toString()
        : (args is String ? args : null);
    if (id != null && id.isNotEmpty) {
      atomId.value = id;
      loadAtom();
    } else {
      hasError.value = true;
    }
  }

  Future<void> loadAtom() async {
    final id = atomId.value;
    if (id == null) return;

    isLoading.value = true;
    hasError.value = false;
    try {
      final result = await _home.getAtom(id);
      if (result.success && result.data != null) {
        atom.value = result.data;
      } else {
        hasError.value = true;
      }
    } catch (error) {
      debugPrint('📝 [AtomDetailsController] loadAtom error: $error');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int index) => activeTab.value = index;
}
