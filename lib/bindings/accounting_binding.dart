import 'package:get/get.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/controllers/reports_controller.dart';

class AccountingBinding extends Bindings {
  @override
  void dependencies() {
    // AccountingController is already globally registered in main.dart
    if (!Get.isRegistered<AccountingController>()) {
      Get.lazyPut<AccountingController>(() => AccountingController());
    }

    // ReportsController — lazily registered when the reports route is opened
    if (!Get.isRegistered<ReportsController>()) {
      Get.lazyPut<ReportsController>(() => ReportsController());
    }

    // FinanceLedgerController is now globally registered in main.dart
  }
}