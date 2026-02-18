import 'package:get/get.dart';
import '../controllers/clubs_controller.dart';

class ClubsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClubsController>(() => ClubsController());
  }
}