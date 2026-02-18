import 'package:get/get.dart';
import '../controllers/attendance_controller.dart';

class ParentAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ParentAttendanceController>(() => ParentAttendanceController());
  }
}
