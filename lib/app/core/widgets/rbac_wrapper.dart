import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../rbac/api_rbac.dart';
import '../../modules/auth/controllers/auth_controller.dart';

class RBACWrapper extends StatelessWidget {
  final String apiEndpoint;
  final Widget child;
  final Widget? fallback;

  const RBACWrapper({
    Key? key,
    required this.apiEndpoint,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final userRole = authController.user.value?.role ?? '';
        final hasAccess = ApiPermissions.hasApiAccess(userRole, apiEndpoint);
        
        if (hasAccess) {
          return child;
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

class ModuleWrapper extends StatelessWidget {
  final String moduleName;
  final Widget child;
  final Widget? fallback;

  const ModuleWrapper({
    Key? key,
    required this.moduleName,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final userRole = authController.user.value?.role ?? '';
        final moduleAccess = RoleBasedAccess.getModuleAccess(userRole);
        final visibleModules = List<String>.from(moduleAccess['visibleModules'] ?? []);
        
        if (visibleModules.contains(moduleName)) {
          return child;
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}