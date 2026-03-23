import 'package:get/get.dart';
import 'package:school_app/controllers/attendance_controller.dart' as old_attendance;

class OldAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<old_attendance.AttendanceController>(() => old_attendance.AttendanceController());
  }
}