import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rexone_mobile/services/services.dart';

/// Tracks mic/camera/photos permission state and drives the onboarding flow.
class PermissionOnboardingController extends GetxController {
  final PermissionService _permissions = Get.find<PermissionService>();

  final RxBool isLoading = false.obs;
  final RxBool micGranted = false.obs;
  final RxBool cameraGranted = false.obs;
  final RxBool photosGranted = false.obs;

  bool get allGranted =>
      micGranted.value && cameraGranted.value && photosGranted.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    micGranted.value = await _permissions.isAllowed(Permission.microphone);
    cameraGranted.value = await _permissions.isAllowed(Permission.camera);
    photosGranted.value = await _permissions.isAllowed(Permission.photos);
    isLoading.value = false;
  }

  Future<void> requestAll() async {
    isLoading.value = true;
    if (!micGranted.value) {
      micGranted.value = await _permissions.requestMicrophone();
    }
    if (!cameraGranted.value) {
      cameraGranted.value = await _permissions.request(Permission.camera);
    }
    if (!photosGranted.value) {
      photosGranted.value = await _permissions.request(Permission.photos);
    }
    isLoading.value = false;
  }

  Future<void> requestMic() async =>
      micGranted.value = await _permissions.requestMicrophone();

  Future<void> requestCamera() async =>
      cameraGranted.value = await _permissions.request(Permission.camera);

  Future<void> requestPhotos() async =>
      photosGranted.value = await _permissions.request(Permission.photos);
}
