import 'package:get/get.dart';
import '../controllers/academics_controller.dart';

class AcademicsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AcademicsController>(() => AcademicsController());
  }
}