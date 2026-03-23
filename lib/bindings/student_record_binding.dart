import 'package:get/get.dart';
import 'package:school_app/controllers/student_record_controller.dart';

class StudentRecordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentRecordController>(() => StudentRecordController());
  }
}