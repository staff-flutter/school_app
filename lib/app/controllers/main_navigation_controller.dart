import 'package:get/get.dart';
import '../core/rbac/api_rbac.dart';
import '../modules/auth/controllers/auth_controller.dart';

class MainNavigationController extends GetxController {
  final selectedIndex = 0.obs;

  List<NavigationItem> get navigationItems {
    try {
      final authController = Get.find<AuthController>();
      final userRole = authController.user.value?.role?.toLowerCase() ?? '';

      switch (userRole) {
        case 'parent':
          return [
            NavigationItem('My Children', '/my-children'),
            NavigationItem('Timetable', '/timetable-management'),
            NavigationItem('Homework', '/homework-management'),
            NavigationItem('Clubs', '/clubs-activities'),
            NavigationItem('Profile', '/profile'),
          ];

        case 'teacher':
          return [
            NavigationItem('Dashboard', '/accounting-dashboard'),
            NavigationItem('My Classes', '/teacher-classes'),
            NavigationItem('Timetable', '/timetable-management'),
            NavigationItem('Homework', '/homework-management'),
            NavigationItem('Attendance', '/school-management?initialTab=attendance'),
            NavigationItem('Profile', '/profile'),
          ];

        case 'accountant':
          return [
            NavigationItem('Dashboard', '/accounting-dashboard'),
            NavigationItem('Timetable', '/timetable-management'),
            NavigationItem('Profile', '/profile'),
          ];

        case 'administrator':
          return [
            NavigationItem('Dashboard', '/accounting-dashboard'),
            NavigationItem('School', '/school-management'),
            NavigationItem('Homework', '/homework-management'),
            NavigationItem('Timetable', '/timetable-management'),
            NavigationItem('Profile', '/profile'),
          ];

        default:
          return [
            NavigationItem('Dashboard', '/accounting-dashboard'),
            NavigationItem('School', '/school-management'),
            NavigationItem('Timetable', '/timetable-management'),
            NavigationItem('Homework', '/homework-management'),
            NavigationItem('Subscription', '/subscription-management'),
            NavigationItem('Profile', '/profile'),
          ];
      }
    } catch (e) {
      return [NavigationItem('Dashboard', '/accounting-dashboard')];
    }
  }

  void onItemTapped(int index) {
    selectedIndex.value = index;

    if (index < navigationItems.length) {
      final route = navigationItems[index].route;

      if (route.contains('?')) {
        final parts = route.split('?');
        final baseRoute = parts[0];
        final params = <String, dynamic>{};

        if (parts.length > 1) {
          for (final p in parts[1].split('&')) {
            final kv = p.split('=');
            if (kv.length == 2) {
              params[kv[0]] = kv[1];
            }
          }
        }
        Get.offNamed(baseRoute, arguments: params);
      } else {
        Get.offNamed(route);
      }
    }
  }
}

/// ================= MODEL =================

class NavigationItem {
  final String label;
  final String route;

  NavigationItem(this.label, this.route);
}
