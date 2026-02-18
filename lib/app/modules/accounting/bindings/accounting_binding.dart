import 'package:get/get.dart';
import '../controllers/accounting_controller.dart';

class AccountingBinding extends Bindings {
  @override
  void dependencies() {
    // AccountingController is already globally registered in main.dart
    // But ensure it's available if not already registered
    if (!Get.isRegistered<AccountingController>()) {
      Get.lazyPut<AccountingController>(() => AccountingController());
    }

    // FinanceLedgerController is now globally registered in main.dart
  }
}