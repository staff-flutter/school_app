import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../core/role_modules.dart';

class RoleGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.user.value;
      
      if (user == null || route == null) {
        return const RouteSettings(name: '/login');
      }
      
      final screenName = _getScreenNameFromRoute(route);
      
      if (!RoleModules.canAccessScreen(user.role, screenName)) {
        Get.snackbar(
          'Access Denied', 
          'You don\'t have permission to access this screen',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return const RouteSettings(name: '/accounting-dashboard');
      }
      
      return null;
    } catch (e) {
      return const RouteSettings(name: '/login');
    }
  }
  
  String _getScreenNameFromRoute(String route) {
    switch (route) {
      case '/profile': return 'profileview';
      case '/student-management': return 'studentmanagementview';
      case '/academics': return 'academicsview';
      case '/fee-collection': return 'feecollectionview';
      case '/expenses': return 'expensesview';
      case '/attendance': return 'attendanceview';
      case '/communications': return 'communicationsview';
      case '/clubs-activities': return 'clubsactivitiesview';
      case '/reports': return 'reportsview';
      default: return route.replaceAll('/', '').toLowerCase();
    }
  }
}