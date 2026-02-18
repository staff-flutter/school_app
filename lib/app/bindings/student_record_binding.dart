import 'package:get/get.dart';
import '../controllers/student_record_controller.dart';

class StudentRecordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentRecordController>(() => StudentRecordController());
  }
}