import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../controllers/school_controller.dart';

class SchoolBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SchoolController>()) {
      Get.put(SchoolController(), permanent: true);
    }
  }
}
