import 'package:get/get.dart';

class CalendarController extends GetxController {
  final RxString selectedRange = 'Week'.obs;
  final RxInt selectedDay = 7.obs;

  void selectRange(String value) {
    selectedRange.value = value;
  }

  void selectDay(int value) {
    selectedDay.value = value;
  }
}
