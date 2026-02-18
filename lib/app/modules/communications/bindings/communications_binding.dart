import 'package:get/get.dart';
import 'package:school_app/app/controllers/announcement_controller.dart';

import '../controllers/communications_controller.dart';

class CommunicationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommunicationsController>(
      () => CommunicationsController(),
    );
    // Use lazyPut to avoid immediate initialization
    Get.lazyPut<AnnouncementController>(
      () => AnnouncementController(),
    );
  }
}
