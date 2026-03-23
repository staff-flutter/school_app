import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/permissions/feature_flag_service.dart';
import 'package:school_app/core/permissions/module_visibility.dart';
import 'package:school_app/core/permissions/api_permissions.dart';
import 'package:school_app/controllers/auth_controller.dart';

class PermissionWrapper extends StatelessWidget {
  final Widget child;
  final String? requiredModule;
  final String? requiredPermission;
  final List<String>? allowedRoles;
  final Widget? fallback;
  final bool hideIfNoAccess;

  const PermissionWrapper({
    super.key,
    required this.child,
    this.requiredModule,
    this.requiredPermission,
    this.allowedRoles,
    this.fallback,
    this.hideIfNoAccess = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final user = authController.user.value;
        if (user == null) {
          return hideIfNoAccess ? const SizedBox.shrink() : (fallback ?? child);
        }

        final userRole = user.role.toLowerCase();
        
        if (allowedRoles != null && !allowedRoles!.contains(userRole)) {
          return hideIfNoAccess ? const SizedBox.shrink() : (fallback ?? child);
        }

        if (requiredModule != null && !ModuleVisibility.isModuleVisible(userRole, requiredModule!)) {
          return hideIfNoAccess ? const SizedBox.shrink() : (fallback ?? child);
        }

        if (requiredPermission != null && !_hasPermission(userRole, requiredPermission!)) {
          return hideIfNoAccess ? const SizedBox.shrink() : (fallback ?? child);
        }

        return child;
      },
    );
  }

  bool _hasPermission(String role, String permission) {
    // Handle legacy feature flags
    switch (permission) {
      case 'DELETE_BUTTONS':
        return FeatureFlagService.canShowDeleteButtons();
      case 'CREATE_CLUBS':
        return FeatureFlagService.canCreateClubs();
      case 'MANAGE_USERS':
        return FeatureFlagService.canManageUsers();
      default:
        // Check API-based permissions
        return _checkApiPermission(role, permission);
    }
  }

  bool _checkApiPermission(String role, String permission) {
    // Parse permission string (format: "METHOD_entity" or "action_entity")
    final parts = permission.split('_');
    if (parts.length >= 2) {
      final action = parts[0];
      final entity = parts.sublist(1).join('_');

      switch (action.toUpperCase()) {
        case 'CREATE':
          return ApiPermissions.canCreate(entity, role);
        case 'UPDATE':
          return ApiPermissions.canUpdate(entity, role);
        case 'DELETE':
          return ApiPermissions.canDelete(entity, role);
        case 'VIEW':
          return ApiPermissions.canView(entity, role);
        case 'MARK':
          if (entity == 'ATTENDANCE') {
            return ApiPermissions.canMarkAttendance(role);
          }
          break;
        case 'COLLECT':
          if (entity == 'FEES') {
            return ApiPermissions.canCollectFees(role);
          }
          break;
        case 'MANAGE':
          if (entity == 'TEACHERASSIGNMENTS') {
            return ApiPermissions.canManageTeacherAssignments(role);
          }
          break;
        case 'SET':
          if (entity == 'FEESTRUCTURE') {
            return ApiPermissions.canSetFeeStructure(role);
          }
          break;
      }
    }
    return false;
  }
}