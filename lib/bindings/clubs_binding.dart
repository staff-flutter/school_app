import 'package:get/get.dart';
import 'package:school_app/controllers/clubs_controller.dart';

class ClubsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClubsController>(() => ClubsController());
  }
}