import 'package:get/get.dart';
import 'package:school_app/controllers/subscription_controller.dart';
import 'package:school_app/services/subscription_service.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionService>(() => SubscriptionService());
    Get.lazyPut<SubscriptionController>(() => SubscriptionController());
  }
}