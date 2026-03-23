import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already globally registered in main.dart
    // But ensure it's available if not already registered
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
  }
}