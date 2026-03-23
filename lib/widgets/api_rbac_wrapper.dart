import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/controllers/auth_controller.dart';

/// Widget that enforces API-level RBAC permissions
/// Only shows child widget if user has access to the specified API
class ApiRbacWrapper extends StatelessWidget {
  final String apiEndpoint;
  final Widget child;
  final Widget? fallback;
  final bool showReadOnlyIndicator;

  const ApiRbacWrapper({
    Key? key,
    required this.apiEndpoint,
    required this.child,
    this.fallback,
    this.showReadOnlyIndicator = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      final authController = Get.find<AuthController>();
      final userRole = authController.user.value?.role?.toLowerCase() ?? '';
      
      if (userRole.isEmpty) {
        return fallback ?? const SizedBox.shrink();
      }

      final hasAccess = ApiPermissions.hasApiAccess(userRole, apiEndpoint);
      
      if (!hasAccess) {
        return fallback ?? const SizedBox.shrink();
      }

      if (showReadOnlyIndicator && _isReadOnlyForRole(userRole, apiEndpoint)) {
        return Stack(
          children: [
            child,
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'READ ONLY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return child;
    } catch (e) {
      return fallback ?? const SizedBox.shrink();
    }
  }

  bool _isReadOnlyForRole(String role, String api) {
    // Define read-only scenarios based on role and API
    switch (role) {
      case 'principal':
        return api.startsWith('GET ') || 
               api == 'PUT /api/studentrecord/updatevalue' ||
               api == 'PUT /api/studentrecord/revertreceipt';
      case 'viceprincipal':
        return api.startsWith('GET ');
      case 'teacher':
        return api.startsWith('GET ') && api != 'POST /api/attendance/mark';
      case 'parent':
        return api.startsWith('GET ');
      default:
        return false;
    }
  }
}

/// Convenience wrapper for common button types
class RbacButton extends StatelessWidget {
  final String apiEndpoint;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;

  const RbacButton({
    Key? key,
    required this.apiEndpoint,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ApiRbacWrapper(
      apiEndpoint: apiEndpoint,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: child,
      ),
    );
  }
}

/// Icon button with RBAC
class RbacIconButton extends StatelessWidget {
  final String apiEndpoint;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;

  const RbacIconButton({
    Key? key,
    required this.apiEndpoint,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ApiRbacWrapper(
      apiEndpoint: apiEndpoint,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
      ),
    );
  }
}