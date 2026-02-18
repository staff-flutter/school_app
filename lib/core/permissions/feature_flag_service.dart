import 'package:get/get.dart';
import 'module_visibility.dart';
import '../../app/modules/auth/controllers/auth_controller.dart';

class FeatureFlagService {
  static String? _getCurrentUserRole() {
    try {
      final authController = Get.find<AuthController>();
      return authController.user.value?.role.toLowerCase();
    } catch (e) {
      return null;
    }
  }

  // Delete Operations
  static bool canShowDeleteButtons() {
    final role = _getCurrentUserRole();
    return role != null && ModuleVisibility.hasFeatureFlag(role, 'allowDeleteButtons');
  }

  // School Management
  static bool canEditSchool() {
    final role = _getCurrentUserRole();
    return role != null && ModuleVisibility.hasFeatureFlag(role, 'allowEditSchool');
  }

  // Fee Operations
  static bool canCollectFees() {
    final role = _getCurrentUserRole();
    return role != null && ModuleVisibility.hasFeatureFlag(role, 'allowFeeCollection');
  }

  // Attendance Operations
  static bool canMarkAttendance() {
    final role = _getCurrentUserRole();
    return role != null && ModuleVisibility.hasFeatureFlag(role, 'allowAttendanceMarking');
  }

  // Role Management
  static bool canAssignRoles() {
    final role = _getCurrentUserRole();
    return role != null && ModuleVisibility.hasFeatureFlag(role, 'allowRoleAssignment');
  }

  // Expense Operations
  static bool canApproveExpenses() {
    final role = _getCurrentUserRole();
    return role != null && ModuleVisibility.hasFeatureFlag(role, 'allowExpenseApproval');
  }

  // Audit Operations
  static bool canViewAuditLogs() {
    final role = _getCurrentUserRole();
    return role != null && ModuleVisibility.hasFeatureFlag(role, 'allowAuditView');
  }

  // Module-specific permissions
  static bool canCreateClubs() {
    final role = _getCurrentUserRole();
    return role == 'correspondent' || role == 'administrator';
  }

  static bool canManageUsers() {
    final role = _getCurrentUserRole();
    return role == 'correspondent';
  }

  static bool canManageSchools() {
    final role = _getCurrentUserRole();
    return role == 'correspondent';
  }

  static bool canManageClasses() {
    final role = _getCurrentUserRole();
    return role == 'correspondent' || role == 'administrator';
  }

  static bool canManageStudents() {
    final role = _getCurrentUserRole();
    return role == 'correspondent' || role == 'administrator' || role == 'accountant';
  }

  static bool canViewFinancials() {
    final role = _getCurrentUserRole();
    return role == 'correspondent' || role == 'accountant' || role == 'principal';
  }

  static bool canCreateAnnouncements() {
    final role = _getCurrentUserRole();
    return role == 'correspondent' || role == 'principal' || role == 'administrator';
  }

  // Permission level checks
  static String getStudentRecordPermission() {
    final role = _getCurrentUserRole();
    return ModuleVisibility.getModulePermission(role ?? '', 'studentRecords') ?? 'none';
  }

  static String getAttendancePermission() {
    final role = _getCurrentUserRole();
    return ModuleVisibility.getModulePermission(role ?? '', 'attendance') ?? 'none';
  }

  static String getStudentPermission() {
    final role = _getCurrentUserRole();
    return ModuleVisibility.getModulePermission(role ?? '', 'students') ?? 'none';
  }

  // UI Helper methods
  static bool shouldShowCreateButton(String module) {
    final role = _getCurrentUserRole();
    if (role == null) return false;

    switch (module) {
      case 'clubs':
        return canCreateClubs();
      case 'users':
        return canManageUsers();
      case 'schools':
        return canManageSchools();
      case 'classes':
      case 'sections':
        return canManageClasses();
      case 'students':
        return canManageStudents();
      case 'announcements':
        return canCreateAnnouncements();
      default:
        return false;
    }
  }

  static bool shouldShowEditButton(String module) {
    return shouldShowCreateButton(module);
  }

  static bool shouldShowDeleteButton(String module) {
    return shouldShowCreateButton(module) && canShowDeleteButtons();
  }
}