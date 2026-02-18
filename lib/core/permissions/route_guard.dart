import 'package:get/get.dart';
import 'module_visibility.dart';
import 'sidebar_config.dart';
import '../../app/modules/auth/controllers/auth_controller.dart';

class RouteGuard {
  static bool canAccess(String route, {String? requiredRole}) {
    final authController = Get.find<AuthController>();
    final user = authController.user.value;
    
    if (user == null) return false;
    
    final userRole = user.role.toLowerCase();
    
    // Check specific role requirement
    if (requiredRole != null && userRole != requiredRole.toLowerCase()) {
      return false;
    }
    
    // Check route access based on module visibility
    return SidebarConfig.canAccessRoute(userRole, route);
  }

  static void guardRoute(String route, {String? requiredRole}) {
    if (!canAccess(route, requiredRole: requiredRole)) {
      Get.offAllNamed('/unauthorized');
    }
  }

  static List<String> getAllowedRoles(String apiEndpoint) {
    // Map API endpoints to allowed roles based on your API table
    const Map<String, List<String>> apiRoles = {
      '/api/user/create': ['correspondent'],
      '/api/user/login': ['anyone'],
      '/api/user/logout': ['anyone'],
      '/api/user/isauthenticated': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
      '/api/user/delete': ['correspondent'],
      '/api/user/update': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
      '/api/user/assignrole': ['correspondent', 'administrator'],
      '/api/school/create': ['correspondent'],
      '/api/school/getall': ['correspondent'],
      '/api/school/getsingle': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
      '/api/school/update': ['correspondent'],
      '/api/school/delete': ['correspondent'],
      '/api/class/getall': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
      '/api/class/create': ['correspondent', 'administrator'],
      '/api/class/update': ['correspondent', 'administrator'],
      '/api/class/delete': ['correspondent', 'administrator'],
      '/api/section/getall': ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'],
      '/api/section/create': ['correspondent', 'administrator'],
      '/api/section/update': ['correspondent', 'administrator'],
      '/api/section/delete': ['correspondent'],
      '/api/teacher/assignments/manage': ['correspondent', 'administrator'],
      '/api/feestructure/set': ['correspondent', 'administrator'],
      '/api/feestructure/getbyclass': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],
      '/api/student/create': ['correspondent', 'administrator', 'accountant'],
      '/api/student/update': ['correspondent', 'administrator', 'accountant'],
      '/api/student/delete': ['correspondent'],
      '/api/student/get': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],
      '/api/student/getall': ['correspondent', 'administrator', 'principal', 'accountant', 'teacher'],
      '/api/studentrecord/applyconcession': ['correspondent', 'accountant', 'principal'],
      '/api/studentrecord/collectfee': ['correspondent', 'accountant'],
      '/api/studentrecord/getrecord': ['administrator', 'correspondent', 'principal', 'viceprincipal', 'accountant'],
      '/api/studentrecord/deleterecord': ['correspondent'],
      '/api/attendance/sheet': ['administrator', 'correspondent', 'principal', 'teacher'],
      '/api/attendance/mark': ['correspondent', 'teacher'],
      '/api/attendance/getallclass': ['administrator', 'correspondent', 'principal', 'teacher'],
      '/api/expense/add': ['correspondent', 'accountant'],
      '/api/expense/getall': ['correspondent', 'accountant', 'principal'],
      '/api/announcement/create': ['correspondent', 'principal', 'administrator'],
      '/api/announcement/getall': ['correspondent', 'principal', 'viceprincipal', 'teacher', 'parent', 'administrator'],
      '/api/club/getall': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
      '/api/club/create': ['correspondent', 'administrator'],
      '/api/club/video/getall': ['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'],
      '/api/club/video/upload': ['correspondent', 'administrator'],
      '/api/financeledger/getall': ['correspondent', 'accountant', 'principal'],
      '/api/subscription/update': ['correspondent'],
      '/api/audit/getall': ['administrator', 'correspondent', 'principal', 'viceprincipal'],
    };
    
    return apiRoles[apiEndpoint] ?? [];
  }

  static bool canCallApi(String apiEndpoint, String userRole) {
    final allowedRoles = getAllowedRoles(apiEndpoint);
    return allowedRoles.contains('anyone') || allowedRoles.contains(userRole.toLowerCase());
  }
}