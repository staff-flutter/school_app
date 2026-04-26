import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/main_navigation_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/admin_sidebar.dart';

/// Roles that use the persistent left-rail sidebar instead of the
/// bottom navigation bar that non-administrative roles use.
const _kAdminRoles = {'accountant', 'correspondent'};

class MainWrapper extends StatelessWidget {
  final Widget child;

  const MainWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainNavigationController>(
      init: MainNavigationController(),
      builder: (navController) {
        // Resolve current role (guard against controller not-yet-registered)
        String role = '';
        try {
          final auth = Get.find<AuthController>();
          role = auth.user.value?.role.toLowerCase() ?? '';
        } catch (_) {}

        final isAdminRole = _kAdminRoles.contains(role);

        // ── Admin layout: persistent left rail sidebar + content ─────────
        if (isAdminRole) {
          return Scaffold(
            backgroundColor: AppTheme.appBackground,
            body: SafeArea(
              child: Row(
                children: [
                  // Always-visible collapsible sidebar
                  const AdminSidebar(),

                  // Main page content fills the remaining width
                  Expanded(child: child),
                ],
              ),
            ),
          );
        }

        // ── Non-admin layout: original scaffold (unchanged) ──────────────
        return Scaffold(
          extendBody: true,
          backgroundColor: AppTheme.appBackground,
          body: SafeArea(
            bottom: false,
            child: child,
          ),
        );
      },
    );
  }
}
