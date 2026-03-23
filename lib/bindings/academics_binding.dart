import 'package:get/get.dart';
import 'package:school_app/controllers/academics_controller.dart';

class AcademicsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AcademicsController>(() => AcademicsController());
  }
}