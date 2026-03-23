import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/permissions/permission_system.dart';

class PermissionWrapper extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionWrapper({
    Key? key,
    required this.permission,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        if (authController.hasPermission(permission)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

class RoleBasedWidget extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    Key? key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final userRole = authController.user.value?.role.toLowerCase();
        if (userRole != null && allowedRoles.map((r) => r.toLowerCase()).contains(userRole)) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

// Convenience widgets for common role checks
class CorrespondentOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const CorrespondentOnly({Key? key, required this.child, this.fallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: const ['correspondent'],
      child: child,
      fallback: fallback,
    );
  }
}

class AccountantOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AccountantOnly({Key? key, required this.child, this.fallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: const ['accountant', 'correspondent'],
      child: child,
      fallback: fallback,
    );
  }
}

class TeacherOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const TeacherOnly({Key? key, required this.child, this.fallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: const ['teacher'],
      child: child,
      fallback: fallback,
    );
  }
}