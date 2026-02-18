import 'package:get/get.dart';

class ApiGuard {
  static bool checkPermission(String permission) {
    return true; // Simplified for demo
  }

  static void enforcePermission(String permission) {
    if (!checkPermission(permission)) {
      Get.snackbar('Access Denied', 'No permission');
      throw Exception('Permission denied: $permission');
    }
  }

  static bool canCollectFees() => true;
  static bool canCancelReceipt() => true;
  static bool canViewFinancialReports() => true;
  static bool canAddExpense() => true;
  static bool canVerifyExpense() => true;
  static bool canDeleteExpense() => true;
  static bool canApplyConcession() => true;
  static bool canOverrideConcession() => true;
  static bool canViewStudents() => true;
  static bool canEditStudents() => true;
  static bool canMarkAttendance() => true;
  static bool canViewAttendance() => true;
  static bool canConfigureClasses() => true;
  static bool canCreateNotices() => true;
}