import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';

class FeestructureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeeStructureController>(() => FeeStructureController());
  }
}