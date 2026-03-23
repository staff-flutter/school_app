import 'package:get/get.dart';
import 'package:school_app/controllers/student_controller.dart';

class StudentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentController>(() => StudentController());
  }
}