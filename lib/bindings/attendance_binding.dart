import '../controllers/attendance_controller.dart';
import 'package:get/get.dart';
class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AttendanceController>(() => AttendanceController());
  }
}