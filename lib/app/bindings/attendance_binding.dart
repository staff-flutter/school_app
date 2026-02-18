import 'package:get/get.dart';
import '../controllers/attendance_controller.dart' as old_attendance;

class OldAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<old_attendance.AttendanceController>(() => old_attendance.AttendanceController());
  }
}