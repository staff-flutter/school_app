import 'package:get/get.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/controllers/auth_controller.dart';

class Permission {
  static const String FEES_COLLECT = 'POST /api/studentrecord/collectfee';
  static const String FEES_CANCEL_RECEIPT = 'PUT /api/studentrecord/revertreceipt';
  static const String FEES_VIEW_REPORTS = 'GET /api/financeledger/getall';
  static const String FEES_VIEW_OWN_PAYMENTS = 'GET /api/attendance/student';
  
  static const String EXPENSE_ADD = 'POST /api/expense/add';
  static const String EXPENSE_VERIFY = 'PATCH /api/expense/updatestatus';
  static const String EXPENSE_DELETE = 'DELETE /api/expense/delete';
  static const String EXPENSE_VIEW = 'GET /api/expense/getall';
  
  static const String CONCESSION_APPLY_WITH_PROOF = 'POST /api/studentrecord/applyconcession';
  static const String CONCESSION_APPLY_OVERRIDE = 'PUT /api/studentrecord/updatevalue';
  
  static const String REPORTS_VIEW_FINANCIAL = 'GET /api/financeledger/stats';
  
  static const String STUDENTS_VIEW = 'GET /api/student/getall';
  static const String STUDENTS_CREATE_EDIT = 'POST /api/student/create';
  
  static const String ATTENDANCE_MARK = 'POST /api/attendance/mark';
  static const String ATTENDANCE_VIEW = 'GET /api/attendance/sheet';
  
  static const String CLASSES_CONFIGURE = 'POST /api/class/create';
  
  static const String NOTICES_CREATE = 'POST /api/announcement/create';
  static const String NOTICES_VIEW = 'GET /api/announcement/getall';
  
  static const String CLUBS_CREATE = 'POST /api/club/create';
  static const String CLUBS_EDIT = 'PUT /api/club/updatetext';
  static const String CLUBS_DELETE = 'DELETE /api/club/delete';
  static const String CLUBS_VIEW = 'GET /api/club/getall';
  static const String CLUBS_UPLOAD_VIDEO = 'POST /api/club/video/upload';
}

class RolePermissions {
  static bool hasPermission(String role, String permission) {
    return ApiPermissions.hasApiAccess(role, permission);
  }

  static List<String> getPermissions(String role) {
    final moduleAccess = RoleBasedAccess.getModuleAccess(role);
    return List<String>.from(moduleAccess['visibleModules'] ?? []);
  }

  static bool requiresOTP(String role) {
    return role.toLowerCase() != 'correspondent';
  }

  // Check specific action permissions
  static bool canUpdateConcessionValue(String role) {
    return ApiPermissions.hasApiAccess(role, Permission.CONCESSION_APPLY_OVERRIDE);
  }

  static bool canCollectFees(String role) {
    return ApiPermissions.hasApiAccess(role, Permission.FEES_COLLECT);
  }

  static bool canMarkAttendance(String role) {
    return ApiPermissions.hasApiAccess(role, Permission.ATTENDANCE_MARK);
  }

  static bool canManageExpenses(String role) {
    return ApiPermissions.hasApiAccess(role, Permission.EXPENSE_ADD);
  }

  static bool canCreateAnnouncements(String role) {
    return ApiPermissions.hasApiAccess(role, Permission.NOTICES_CREATE);
  }

  static bool canManageClubs(String role) {
    return ApiPermissions.hasApiAccess(role, Permission.CLUBS_CREATE);
  }
}