import 'package:get/get.dart';
import 'package:school_app/controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // DashboardController is already globally registered in main.dart
    // But ensure it's available if not already registered
    if (!Get.isRegistered<DashboardController>()) {
      Get.lazyPut<DashboardController>(() => DashboardController());
    }
  }
}