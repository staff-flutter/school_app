import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:school_app/controllers/marks_controller.dart';

class MarksUploadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MarksController>(() => MarksController());
  }
}