import 'package:get/get.dart';

class LiveActivityController extends GetxController {
  final RxString selectedSurface = 'Expanded'.obs;
  final RxBool isRecording = true.obs;

  void selectSurface(String value) {
    selectedSurface.value = value;
  }

  void toggleRecording() {
    isRecording.toggle();
  }
}
