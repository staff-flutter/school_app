import 'package:get/get.dart';
import 'package:school_app/controllers/announcement_controller.dart';

class AnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnnouncementController>(() => AnnouncementController());
  }
}
