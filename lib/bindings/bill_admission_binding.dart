
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:school_app/controllers/bill_admission_controller.dart';

class BillAdmissionBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already globally registered in main.dart
    // But ensure it's available if not already registered
    if (!Get.isRegistered<BillAdmissionController>()) {
      Get.put(BillAdmissionController());
    }
  }
}