import 'package:get/get.dart';
import 'package:school_app/controllers/parent_attendance_controller.dart';

class ParentAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ParentAttendanceController>(() => ParentAttendanceController());
  }
}
