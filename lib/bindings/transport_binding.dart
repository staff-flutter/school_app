import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:school_app/controllers/transport_controller.dart';

class TransportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransportController>(() => TransportController());

  }
}