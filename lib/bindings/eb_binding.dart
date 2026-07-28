import 'package:get/get.dart';
import 'package:school_app/controllers/dashboard_controller.dart';
import 'package:school_app/controllers/eb_controller.dart';

class EbBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EBController>()) {
      Get.lazyPut<EBController>(() => EBController());
    }
  }
}