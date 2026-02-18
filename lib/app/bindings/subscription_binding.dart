import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../data/services/subscription_service.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionService>(() => SubscriptionService());
    Get.lazyPut<SubscriptionController>(() => SubscriptionController());
  }
}